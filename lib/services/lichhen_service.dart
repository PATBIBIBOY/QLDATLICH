import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lichhen_model.dart';


class LichHenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _colLichHen = 'LichHen';
  static const String _colPhongKham = 'PhongKham';

  static const List<String> _tenColKhoa = ['khoa', 'danh_sach'];
  static const List<String> _tenColPhong = ['phong_kham', 'danh_sach'];

  /// Các ca dùng khi ngày đó CHƯA có trong LichHen (chưa có ca nào), và để bù
  /// thông tin (tên ca, giờ) nếu document ca thiếu field.
  /// ⚠️ Sửa id / tên / giờ cho đúng với bệnh viện của bạn.
  static const List<Map<String, String>> _caMacDinh = [
    {
      'id': 'ca_sang',
      'ten_ca': 'Ca sáng',
      'gio_bat_dau': '07:30',
      'gio_ket_thuc': '11:30',
    },
    {
      'id': 'ca_chieu',
      'ten_ca': 'Ca chiều',
      'gio_bat_dau': '13:30',
      'gio_ket_thuc': '17:00',
    },
  ];

  /// Cache số bệnh nhân tối đa lấy từ PhongKham: "bv|khoa|phong" -> số.
  final Map<String, int> _tongSoCache = {};

  /// Đọc số nguyên từ Firestore (chấp nhận num hoặc chuỗi "31").
  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

  static String ngayId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DocumentReference<Map<String, dynamic>> _phongKhamRef({
    required DateTime ngay,
    required String caId,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) {
    return _firestore
        .collection(_colLichHen)
        .doc(ngayId(ngay))
        .collection('ca')
        .doc(caId)
        .collection('benh_vien')
        .doc(benhVienId)
        .collection('khoa')
        .doc(khoaId)
        .collection('phong_kham')
        .doc(phongKhamId);
  }

  /// Lấy so_benh_nhan_toi_da của phòng khám từ collection PhongKham:
  /// PhongKham/{benhVienId}/.../{khoaId}/.../{phongKhamId}.
  /// Trả về null nếu không tìm thấy.
  Future<int?> _layTongSoTuPhongKham({
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) async {
    final cacheKey = '$benhVienId|$khoaId|$phongKhamId';
    final cached = _tongSoCache[cacheKey];
    if (cached != null) return cached;

    final base = _firestore.collection(_colPhongKham).doc(benhVienId);

    // Thử song song mọi tổ hợp tên subcollection
    final futures = <Future<int?>>[];
    for (final colKhoa in _tenColKhoa) {
      for (final colPhong in _tenColPhong) {
        futures.add(() async {
          try {
            final doc = await base
                .collection(colKhoa)
                .doc(khoaId)
                .collection(colPhong)
                .doc(phongKhamId)
                .get();
            if (!doc.exists) return null;
            final v = _toInt(doc.data()?['so_benh_nhan_toi_da']);
            if (v != null) {
              debugPrint(
                '✅ PhongKham/$benhVienId/$colKhoa/$khoaId/$colPhong/$phongKhamId'
                ' -> so_benh_nhan_toi_da = $v',
              );
            }
            return v;
          } catch (e) {
            return null;
          }
        }());
      }
    }

    final found = (await Future.wait(futures)).whereType<int>().toList();
    if (found.isEmpty) {
      debugPrint(
        '⚠️ Không tìm thấy so_benh_nhan_toi_da trong PhongKham cho '
        '$benhVienId/$khoaId/$phongKhamId (kiểm tra tên subcollection)',
      );
      return null;
    }
    _tongSoCache[cacheKey] = found.first;
    return found.first;
  }

  Future<List<CaSlotModel>> getCaSlotsTheoPhong({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    int soBenhNhanToiDa = 0,
  }) async {
    // 1. Danh sách ca của ngày; chưa có ca nào (ngày chưa có lịch) thì dùng ca mặc định
    final caSnapshot = await _firestore
        .collection(_colLichHen)
        .doc(ngayId(ngay))
        .collection('ca')
        .get();

    final List<MapEntry<String, Map<String, dynamic>>> caList =
        caSnapshot.docs.isNotEmpty
        ? caSnapshot.docs.map((d) => MapEntry(d.id, d.data())).toList()
        : _caMacDinh
              .map((c) => MapEntry(c['id']!, <String, dynamic>{...c}))
              .toList();

    final macDinhTheoId = {for (final c in _caMacDinh) c['id']!: c};

    // Chỉ truy vấn PhongKham khi cần, và chỉ 1 lần cho cả các ca
    Future<int?>? tongSoPhongKhamFuture;
    Future<int?> tongSoPhongKham() => tongSoPhongKhamFuture ??=
        _layTongSoTuPhongKham(
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        );

    // 2. Với mỗi ca: đọc phòng khám trong LichHen + đếm bệnh nhân song song
    final results = await Future.wait<CaSlotModel>(
      caList.map((entry) async {
        final caId = entry.key;
        final caData = entry.value;
        final macDinh = macDinhTheoId[caId];

        // Lấy field của ca; thiếu thì dùng giá trị mặc định / id ca
        String caField(String key, String fallback) {
          final v = caData[key]?.toString() ?? '';
          return v.isNotEmpty ? v : (macDinh?[key] ?? fallback);
        }

        final phongRef = _phongKhamRef(
          ngay: ngay,
          caId: caId,
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        );

        final responses = await Future.wait([
          phongRef.get(),
          phongRef.collection('benh_nhan').count().get(),
        ]);
        final phongDoc = responses[0] as DocumentSnapshot<Map<String, dynamic>>;
        final countSnapshot = responses[1] as AggregateQuerySnapshot;

        // Phòng chưa có trong LichHen -> phongData rỗng, daDat = 0
        final phongData = phongDoc.data() ?? <String, dynamic>{};

        // Tổng số chỗ: ưu tiên số trong LichHen, không có thì lấy từ PhongKham
        final tongSo =
            _toInt(phongData['so_benh_nhan_toi_da']) ??
            await tongSoPhongKham() ??
            soBenhNhanToiDa;

        return CaSlotModel(
          caId: caId,
          tenCa: caField('ten_ca', caId),
          gioBatDau: caField('gio_bat_dau', ''),
          gioKetThuc: caField('gio_ket_thuc', ''),
          tongSo: tongSo,
          daDat: countSnapshot.count ?? 0,
        );
      }),
    );

    return results..sort((a, b) => a.gioBatDau.compareTo(b.gioBatDau));
  }

   /// Lưu lịch hẹn mới vào Firestore theo cấu trúc nested sâu
  Future<void> saveBooking({
  required String trangThaiId, // Ví dụ: "1"
  required DateTime ngayDat,
  required String caId,
  required String benhVienId,
  required String khoaId,
  required String phongKhamId,
  required String benhNhanId,
  required String lichHenId,
  String? tenBenhVien,
  String? tenKhoa,
  String? tenPhongKham,
}) async {
  final ngayStr = LichHenService.ngayId(ngayDat);
 
  final docRef = _firestore
      .collection(_colLichHen)
      .doc(trangThaiId)
      .collection('danh_sach').doc(ngayStr)
      .collection('ca').doc(caId)
      .collection('benh_vien').doc(benhVienId)
      .collection('khoa').doc(khoaId)
      .collection('phong_kham').doc(phongKhamId)
      .collection('benh_nhan').doc(benhNhanId)
      .collection('lich_hen').doc(lichHenId);
 
  await docRef.set({
    'id': lichHenId,
    'trang_thai_id': trangThaiId,
    'ngay_dat': Timestamp.fromDate(ngayDat),
    'ca_id': caId,
    'benh_vien_id': benhVienId,
    'khoa_id': khoaId,
    'phong_kham_id': phongKhamId,
    'benh_nhan_id': benhNhanId,
    if (tenBenhVien != null) 'ten_benh_vien': tenBenhVien,
    if (tenKhoa != null) 'ten_khoa': tenKhoa,
    if (tenPhongKham != null) 'ten_phong_kham': tenPhongKham,
    'ma_qr': null,
    'ngay_tao': FieldValue.serverTimestamp(),
  });
}
 

Future<List<LichHenModel>> getLichHenCuaBenhNhan(String benhNhanId) async {
  try {
    final snapshot = await _firestore
        .collectionGroup('lich_hen')
        .where('benh_nhan_id', isEqualTo: benhNhanId)
        .get();
 
    final bookings = snapshot.docs
        .map((doc) => LichHenModel.fromJson(doc.data(), id: doc.id))
        .toList();
    if (bookings.isEmpty) return bookings;
 
    // ── Tra cứu tên ca: Ca/{caId} ──
    final caIds = bookings
        .where((b) => b.tenCa == null || b.gioBatDau == null)
        .map((b) => b.caId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final caEntries = await Future.wait(
      caIds.map((id) async {
        final doc = await _firestore.collection('Ca').doc(id).get();
        return MapEntry(id, doc.data());
      }),
    );
    final caMap = {for (final e in caEntries) e.key: e.value};
 
    // ── Tra cứu tên khoa: Khoa/{benhVienId}/danh_sach/{khoaId} ──
    final khoaKeys = bookings
        .where(
          (b) => b.tenKhoa == null && b.benhVienId.isNotEmpty && b.khoaId.isNotEmpty,
        )
        .map((b) => '${b.benhVienId}|${b.khoaId}')
        .toSet();
    final khoaEntries = await Future.wait(
      khoaKeys.map((key) async {
        final parts = key.split('|');
        final doc = await _firestore
            .collection('Khoa')
            .doc(parts[0])
            .collection('danh_sach')
            .doc(parts[1])
            .get();
        return MapEntry(key, doc.data());
      }),
    );
    final khoaMap = {for (final e in khoaEntries) e.key: e.value};
 
    // ── Gộp thông tin vào từng lịch hẹn ──
    final result = bookings.map((b) {
      final ca = caMap[b.caId];
      final khoa = khoaMap['${b.benhVienId}|${b.khoaId}'];
      return b.copyWith(
        tenCa: ca?['ten_ca']?.toString(),
        gioBatDau: ca?['gio_bat_dau']?.toString(),
        gioKetThuc: ca?['gio_ket_thuc']?.toString(),
        tenKhoa: khoa?['ten_khoa']?.toString(),
      );
    }).toList();
 
    // Mới đặt nhất lên đầu
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    result.sort((a, b) {
      final ta = a.ngayTao ?? a.ngayDat ?? epoch;
      final tb = b.ngayTao ?? b.ngayDat ?? epoch;
      return tb.compareTo(ta);
    });
    return result;
  } on FirebaseException catch (e) {
    // failed-precondition: thông báo gốc có chứa LINK TẠO INDEX trong Debug Console
    debugPrint('Lỗi Firestore khi tải lịch hẹn [${e.code}]: ${e.message}');
    switch (e.code) {
      case 'failed-precondition':
        throw Exception(
          'Cần tạo chỉ mục (index) Firestore cho lịch hẹn. '
          'Xem Debug Console để lấy liên kết tạo.',
        );
      case 'permission-denied':
        throw Exception('Không có quyền đọc lịch hẹn (kiểm tra Security Rules).');
      default:
        throw Exception('Không thể tải lịch hẹn. Vui lòng thử lại.');
    }
  }
}
Future<Map<String, dynamic>?> getBookingDetail({
    required String trangThaiId,
    required String ngayId,
    required String caId,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required String benhNhanId,
    required String lichHenId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_colLichHen)
          .doc(trangThaiId)
          .collection('danh_sach').doc(ngayId)
          .collection('ca').doc(caId)
          .collection('benh_vien').doc(benhVienId)
          .collection('khoa').doc(khoaId)
          .collection('phong_kham').doc(phongKhamId)
          .collection('benh_nhan').doc(benhNhanId)
          .collection('lich_hen').doc(lichHenId)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Lỗi khi lấy chi tiết lịch hẹn: $e');
      return null;
    }
  }
  /// DANH SÁCH LỊCH HẸN của 1 phòng khám trong 1 ngày.
  /// [caId] = null: lấy tất cả các ca.
  Future<List<LichHenModel>> getDanhSachLichHen({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    String? caId,
  }) async {
    final ngayRef = _firestore.collection(_colLichHen).doc(ngayId(ngay));

    final List<String> caIds = caId != null
        ? [caId]
        : (await ngayRef.collection('ca').get()).docs.map((d) => d.id).toList();

    final perCa = await Future.wait<List<LichHenModel>>(
      caIds.map((id) async {
        final phongRef = _phongKhamRef(
          ngay: ngay,
          caId: id,
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        );

        final benhNhanSnapshot = await phongRef.collection('benh_nhan').get();
        final lichHenSnapshots = await Future.wait(
          benhNhanSnapshot.docs.map(
            (bn) => bn.reference.collection('lich_hen').get(),
          ),
        );

        return [
          for (final snap in lichHenSnapshots)
            for (final doc in snap.docs)
              LichHenModel.fromJson(doc.data(), id: doc.id),
        ];
      }),
    );

    return perCa.expand((list) => list).toList()
      ..sort((a, b) {
        final byCa = a.caId.compareTo(b.caId);
        return byCa != 0 ? byCa : a.soThuTu.compareTo(b.soThuTu);
      });
  }
}