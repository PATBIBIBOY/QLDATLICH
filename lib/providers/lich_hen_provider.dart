import 'package:flutter/foundation.dart';
import '../models/lichhen_model.dart';
import '../services/lichhen_service.dart';
import 'dart:async';

class LichHenProvider extends ChangeNotifier {
  final LichHenService _service = LichHenService();

  // ── Tình trạng các ca (Còn x/y chỗ) ──
  final Map<String, List<CaSlotModel>> _slotsCache = {};
  final Set<String> _loadingSlotKeys = {};
  final Map<String, String> _slotErrors = {};

  // ── Danh sách lịch hẹn ──
  final Map<String, List<LichHenModel>> _lichHenCache = {};
  final Set<String> _loadingLichHenKeys = {};
  final Map<String, String> _lichHenErrors = {};
  List<LichHenModel> _activeQueue = [];
  bool _queueLoaded = false;
  String? _queueError;

  StreamSubscription<List<LichHenModel>>? _queueSubscription;
  bool _isListeningToQueue = false;

  // ── Lịch hẹn của tôi ──
  List<LichHenModel> _myBookings = [];

  bool _isLoadingMyBookings = false;
  String? _myBookingsError;
  int _myBookingsToken = 0;

  static const Set<String> _historyStatusIds = {'5', '6'};

  /// Khoá để tra cứu cache: bệnh viện | khoa | phòng | ngày | (ca)
  static String makeKey({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    String? caId,
  }) {
    return [
      benhVienId,
      khoaId,
      phongKhamId,
      LichHenService.ngayId(ngay),
      if (caId != null) caId,
    ].join('|');
  }

  // ───────────────────────── Tình trạng các ca ─────────────────────────

  List<CaSlotModel> slotsOf(String key) => _slotsCache[key] ?? const [];
  bool hasLoadedSlots(String key) => _slotsCache.containsKey(key);
  bool isLoadingSlots(String key) => _loadingSlotKeys.contains(key);
  String? slotsErrorOf(String key) => _slotErrors[key];

  Future<void> loadSlots({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    int soBenhNhanToiDa = 0,
    bool force = false,
  }) async {
    final key = makeKey(
      ngay: ngay,
      benhVienId: benhVienId,
      khoaId: khoaId,
      phongKhamId: phongKhamId,
    );

    if (_loadingSlotKeys.contains(key)) return;
    if (!force && _slotsCache.containsKey(key)) return;

    _loadingSlotKeys.add(key);
    _slotErrors.remove(key);
    notifyListeners();

    try {
      _slotsCache[key] = await _service.getCaSlotsTheoPhong(
        ngay: ngay,
        benhVienId: benhVienId,
        khoaId: khoaId,
        phongKhamId: phongKhamId,
        soBenhNhanToiDa: soBenhNhanToiDa,
      );
    } catch (e) {
      debugPrint('Lỗi khi tải tình trạng ca: $e');
      _slotErrors[key] = 'Không thể tải lịch khám của ngày này.';
    } finally {
      _loadingSlotKeys.remove(key);
      notifyListeners();
    }
  }

  // ───────────────────────── Danh sách lịch hẹn ─────────────────────────

  List<LichHenModel> lichHenOf(String key) => _lichHenCache[key] ?? const [];
  bool hasLoadedLichHen(String key) => _lichHenCache.containsKey(key);
  bool isLoadingLichHen(String key) => _loadingLichHenKeys.contains(key);
  String? lichHenErrorOf(String key) => _lichHenErrors[key];

  @override
  void dispose() {
    stopListeningQueue(); // Dọn dẹp khi Provider bị hủy
    super.dispose();
  }

  Future<void> loadLichHenList({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    String? caId,
    bool force = false,
  }) async {
    final key = makeKey(
      ngay: ngay,
      benhVienId: benhVienId,
      khoaId: khoaId,
      phongKhamId: phongKhamId,
      caId: caId,
    );

    if (_loadingLichHenKeys.contains(key)) return;
    if (!force && _lichHenCache.containsKey(key)) return;

    _loadingLichHenKeys.add(key);
    _lichHenErrors.remove(key);
    notifyListeners();

    try {
      _lichHenCache[key] = await _service.getDanhSachLichHen(
        ngay: ngay,
        benhVienId: benhVienId,
        khoaId: khoaId,
        phongKhamId: phongKhamId,
        caId: caId,
      );
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách lịch hẹn: $e');
      _lichHenErrors[key] = 'Không thể tải danh sách lịch hẹn.';
    } finally {
      _loadingLichHenKeys.remove(key);
      notifyListeners();
    }
  }

  // ───────────────────────── Lịch hẹn của tôi ─────────────────────────

  List<LichHenModel> get myBookings => _myBookings;
  bool get isLoadingMyBookings => _isLoadingMyBookings;
  String? get myBookingsError => _myBookingsError;
  List<LichHenModel> get activeQueue => _activeQueue;
  bool get isListeningToQueue => _isListeningToQueue;
  bool get queueLoaded => _queueLoaded;
  String? get queueError => _queueError;

  /// Lịch hẹn đang theo dõi (Chờ duyệt, Đã xác nhận, Đã hủy...).
  List<LichHenModel> get activeBookings => _myBookings
      .where((b) => !_historyStatusIds.contains(b.trangThaiId))
      .toList();

  /// Lịch hẹn đã khám xong (lịch sử).
  List<LichHenModel> get historyBookings => _myBookings
      .where((b) => _historyStatusIds.contains(b.trangThaiId))
      .toList();

  List<LichHenModel> activeBookingsOf(String? profileId) => profileId == null
      ? activeBookings
      : activeBookings.where((b) => b.profileKey == profileId).toList();

  List<LichHenModel> historyBookingsOf(String? profileId) => profileId == null
      ? historyBookings
      : historyBookings.where((b) => b.profileKey == profileId).toList();

  /// Tải tất cả lịch hẹn của bệnh nhân [benhNhanId].
  Future<void> loadMyBookings(String benhNhanId) async {
    final token = ++_myBookingsToken;
    _isLoadingMyBookings = true;
    _myBookingsError = null;
    notifyListeners();

    try {
      final result = await _service.getLichHenCuaBenhNhan(benhNhanId);
      if (token != _myBookingsToken) return; // đã có lần tải mới hơn
      _myBookings = result;
    } catch (e) {
      if (token != _myBookingsToken) return;
      _myBookingsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (token == _myBookingsToken) {
        _isLoadingMyBookings = false;
        notifyListeners();
      }
    }
  }

  Future<void> huyLichHen({
    required String benhNhanId,
    required String lichHenId,
    String? lyDoHuy,
  }) async {
    await _service.huyLichHenTheoId(
      benhNhanId: benhNhanId,
      lichHenId: lichHenId,
      lyDoHuy: lyDoHuy,
    );

    final token = ++_myBookingsToken;
    try {
      final result = await _service.getLichHenCuaBenhNhan(benhNhanId);
      if (token == _myBookingsToken) _myBookings = result;
    } catch (e) {
      debugPrint('Không tải lại được lịch hẹn sau khi hủy: $e');
    }

    clearCache(); // số chỗ của ca vừa hủy có thể thay đổi (đã notifyListeners)
  }

  Future<void> xoaLichHen({
    required String benhNhanId,
    required String lichHenId,
  }) async {
    await _service.xoaLichHenTheoId(
      benhNhanId: benhNhanId,
      lichHenId: lichHenId,
    );

    final token = ++_myBookingsToken;
    try {
      final result = await _service.getLichHenCuaBenhNhan(benhNhanId);
      if (token == _myBookingsToken) _myBookings = result;
    } catch (e) {
      debugPrint('Không tải lại được lịch hẹn sau khi xóa: $e');
    }
    notifyListeners();
  }

  /// Gọi khi đăng xuất để không lộ lịch hẹn của tài khoản trước.
  void clearMyBookings() {
    _myBookingsToken++; // huỷ mọi lần tải đang chạy
    _myBookings = [];
    _myBookingsError = null;
    _isLoadingMyBookings = false;
    notifyListeners();
  }

  /// Xoá cache (ví dụ sau khi đặt lịch xong để lần sau tải lại số chỗ mới).
  void clearCache() {
    _slotsCache.clear();
    _lichHenCache.clear();
    _slotErrors.clear();
    _lichHenErrors.clear();
    notifyListeners();
  }

  void startListeningQueue({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) {
    _queueSubscription?.cancel(); // cho phép đổi sang phòng khác
    _isListeningToQueue = true;
    _queueLoaded = false;
    _queueError = null;
    _activeQueue = [];
    notifyListeners();

    _queueSubscription = _service
        .listenToQueue(
          ngay: ngay,
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        )
        .listen(
          (queue) {
            _activeQueue = queue;
            _queueLoaded = true; // đã nhận dữ liệu thật từ Firestore
            _queueError = null;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Lỗi khi lắng nghe hàng chờ: $e');
            _queueError =
                'Không tải được hàng chờ. Vui lòng kéo xuống để thử lại.';
            notifyListeners();
          },
        );
  }

  void stopListeningQueue() {
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _isListeningToQueue = false;
    _queueLoaded = false;
    _queueError = null;
    _activeQueue = [];
    notifyListeners();
  }
}
