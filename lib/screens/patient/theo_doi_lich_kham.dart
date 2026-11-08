import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_routes.dart';
import '../../providers/family_profile_provider.dart';
import '../../providers/lich_hen_provider.dart';
import '../../models/lichhen_model.dart';
import '../../models/appointment_item.dart';
import '../../utils/queue_time_estimator.dart';
import '../../services/hospital_service.dart';
import '../../widgets/family_widgets.dart';

/// ---------------------------------------------------------------------------
/// Design tokens
/// ---------------------------------------------------------------------------
class AppColors {
  static const background = Color(0xFFF2F6F8);
  static const surface = Colors.white;
  static const primary = Color(0xFF0B5CAD);
  static const primaryDark = Color(0xFF083D75);
  static const teal = Color(0xFF12A594);
  static const tealDark = Color(0xFF0B7A6C);
  static const ink = Color(0xFF14232F);
  static const muted = Color(0xFF6B7C89);
  static const line = Color(0xFFDCE5EB);
  static const warnBg = Color(0xFFFFF5E1);
  static const warnBorder = Color(0xFFF2C46D);
  static const warnText = Color(0xFF8A5A00);
  static const danger = Color(0xFFD64545);

  // Trạng thái "Đến trễ"
  static const late = Color(0xFFF97316);
  static const lateDark = Color(0xFF9A3412);
  static const lateBg = Color(0xFFFFF3E0);
  static const lateBorder = Color(0xFFFED7AA);
}

TextStyle _font(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
}) => GoogleFonts.beVietnamPro(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
);

/// Các trạng thái được hiển thị trên màn hình theo dõi.
/// 1 chờ duyệt, 2 đã xác nhận, 5 hoàn thành, 6 vắng mặt, 7 đến trễ.
const Set<String> _trackableStatuses = {'1', '2', '5', '6', '7'};

/// Các trạng thái KHÔNG còn nằm trong hàng chờ khám.
const Set<String> _outOfQueueStatuses = {'3', '4', '5', '6', '7'};

IconData _statusIcon(AppointmentStatus s) {
  switch (s) {
    case AppointmentStatus.pending:
      return Icons.hourglass_empty_rounded;
    case AppointmentStatus.approved:
      return Icons.verified_rounded;
    case AppointmentStatus.cancelled:
      return Icons.cancel_rounded;
    case AppointmentStatus.completed:
      return Icons.check_circle_rounded;
    case AppointmentStatus.missed:
      return Icons.person_off_rounded;
    case AppointmentStatus.late:
      return Icons.schedule_rounded;
  }
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Theo dõi lịch khám',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const AppointmentTrackingScreen(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Màn hình chính
/// ---------------------------------------------------------------------------
class AppointmentTrackingScreen extends StatefulWidget {
  /// Id lịch hẹn cần theo dõi. Có thể truyền qua constructor hoặc qua
  /// `arguments` của route (String, LichHenModel hoặc MyAppointmentItem).
  final String? bookingId;

  const AppointmentTrackingScreen({super.key, this.bookingId});

  @override
  State<AppointmentTrackingScreen> createState() =>
      _AppointmentTrackingScreenState();
}

class _AppointmentTrackingScreenState extends State<AppointmentTrackingScreen> {
  late final LichHenProvider _provider;
  final QueueTimeEstimator _queueTimeEstimator = QueueTimeEstimator();
  final HospitalService _hospitalService = HospitalService();
  int? _thoiGianKham; // phút / bệnh nhân, lấy từ Firestore
  Timer? _queueEstimateTimer;

  String? _listeningKey;

  // Lịch hẹn đang được chọn để theo dõi
  String? _selectedId;
  bool _argsRead = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<LichHenProvider>();
    _queueEstimateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBookings();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;

    _selectedId = widget.bookingId;
    if (_selectedId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _selectedId = args;
      } else if (args is LichHenModel) {
        _selectedId = args.id;
      } else if (args is MyAppointmentItem) {
        _selectedId = args.id;
      }
    }
  }

  @override
  void dispose() {
    _queueEstimateTimer?.cancel();
    final provider = _provider;
    Future.microtask(provider.stopListeningQueue);
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _provider.loadMyBookings(userId);
    }
  }

  // Bắt đầu lắng nghe hàng chờ thời gian thực (chỉ 1 lần / lịch).
  void _ensureListening(LichHenModel booking) {
    if (booking.phongKhamId.isEmpty || booking.ngayDat == null) return;

    final key =
        '${booking.id}|${booking.benhVienId}|${booking.khoaId}|${booking.phongKhamId}|${booking.ngayDat}';
    if (_listeningKey == key) return;
    _listeningKey = key;
    _queueTimeEstimator.reset();
    _thoiGianKham = null;

    // Lấy thời gian khám của phòng (có cache sẵn trong service)
    _hospitalService
        .getThoiGianKhamPhong(
          hospitalId: booking.benhVienId,
          khoaId: booking.khoaId,
          phongKhamId: booking.phongKhamId,
        )
        .then((minutes) {
          if (!mounted || _listeningKey != key) return; // đã đổi sang lịch khác
          setState(() => _thoiGianKham = minutes);
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider.startListeningQueue(
        ngay: booking.ngayDat!,
        benhVienId: booking.benhVienId,
        khoaId: booking.khoaId,
        phongKhamId: booking.phongKhamId,
      );
    });
  }

  /// Ghép giờ "HH:mm" với một ngày cụ thể.
  DateTime? _atTime(DateTime day, String? hhmm) {
    if (hhmm == null) return null;
    final p = hhmm.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0].trim());
    final m = int.tryParse(p[1].trim());
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Tính giờ dự kiến đến lượt dựa trên giờ ca khám.
  ({DateTime eta, bool exceeds, bool shiftNotStarted}) _estimateTurn({
    required DateTime ngayKham,
    required String? gioBatDau,
    required String? gioKetThuc,
    required int waitMinutes,
  }) {
    final now = DateTime.now();
    final start = _atTime(ngayKham, gioBatDau);
    final end = _atTime(ngayKham, gioKetThuc);

    final notStarted = start != null && now.isBefore(start);
    final base = notStarted ? start : now;

    final eta = base.add(Duration(minutes: waitMinutes));
    final exceeds = end != null && eta.isAfter(end);

    return (eta: eta, exceeds: exceeds, shiftNotStarted: notStarted);
  }

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    toolbarHeight: 64,
    automaticallyImplyLeading: false,
    leading: Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theo dõi lịch khám', style: _font(19, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(
          'Số thứ tự cập nhật theo thời gian thực',
          style: _font(12, color: AppColors.muted),
        ),
      ],
    ),
  );

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  int _statusPriority(String s) {
    switch (s) {
      case '2':
        return 0;
      case '7':
        return 1;
      case '1':
        return 2;
      case '5':
        return 3;
      default:
        return 4;
    }
  }

  /// Lịch còn hiệu lực (1, 2, 7) lên trước, lịch đã kết thúc (5, 6) xuống cuối.
  /// Cùng nhóm thì theo ngày, cùng ngày thì theo độ ưu tiên trạng thái.
  int _compareBookings(LichHenModel a, LichHenModel b) {
    final sa = a.trangThaiId.toString();
    final sb = b.trangThaiId.toString();
    final finishedA = sa == '5' || sa == '6';
    final finishedB = sb == '5' || sb == '6';
    if (finishedA != finishedB) return finishedA ? 1 : -1;

    final byDate = a.ngayDat!.compareTo(b.ngayDat!);
    if (byDate != 0) return byDate;
    return _statusPriority(sa).compareTo(_statusPriority(sb));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LichHenProvider>();
    final family = context.watch<FamilyProfileProvider>();
    final profile = family.current;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final upcomingBookings = provider.activeBookingsOf(profile?.id).where((b) {
      return _trackableStatuses.contains(b.trangThaiId.toString()) &&
          b.ngayDat != null &&
          !b.ngayDat!.isBefore(startOfDay);
    }).toList()..sort(_compareBookings);

    // 1. Đang tải lần đầu
    if (provider.isLoadingMyBookings && upcomingBookings.isEmpty) {
      return Scaffold(
        appBar: _appBar(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Đang tải lịch khám...',
                style: _font(14, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Lỗi và chưa có dữ liệu
    if (provider.myBookingsError != null && upcomingBookings.isEmpty) {
      return Scaffold(
        appBar: _appBar(context),
        body: _StateView(
          icon: Icons.cloud_off_rounded,
          color: AppColors.danger,
          title: 'Không tải được lịch khám',
          message: provider.myBookingsError!,
          actionLabel: 'Thử lại',
          actionIcon: Icons.refresh_rounded,
          onAction: _loadBookings,
        ),
      );
    }

    // 3. Không có lịch hẹn sắp tới
    if (upcomingBookings.isEmpty) {
      return Scaffold(
        appBar: _appBar(context),
        body: _StateView(
          icon: Icons.event_busy_rounded,
          color: AppColors.primary,
          title: 'Không có lịch khám nào sắp tới',
          message: 'Hãy đặt lịch khám để theo dõi số thứ tự tại đây.',
          actionLabel: 'Đặt lịch khám',
          actionIcon: Icons.add_rounded,
          onAction: () =>
              Navigator.pushNamed(context, AppRoutes.hospitalFilter),
        ),
      );
    }

    // 4. Lịch hẹn cần theo dõi: ưu tiên lịch được chọn, không có thì lấy
    //    lịch đầu tiên theo thứ tự ưu tiên.
    var booking = upcomingBookings.first;
    if (_selectedId != null) {
      final matches = upcomingBookings.where((b) => b.id == _selectedId);
      if (matches.isNotEmpty) booking = matches.first;
    }
    final status = statusFromTrangThaiId(booking.trangThaiId);

    // Chỉ cần lắng nghe hàng chờ khi đang chờ khám (2) hoặc đến trễ (7)
    if (status == AppointmentStatus.approved ||
        status == AppointmentStatus.late) {
      _ensureListening(booking);
    }

    final department = booking.tenKhoa ?? 'Khoa chưa cập nhật';
    final room = booking.tenPhongKham ?? 'Phòng khám chưa cập nhật';
    final hospital = booking.tenBenhVien ?? 'Bệnh viện';
    final dateLabel = _formatDate(booking.ngayDat!);
    final hasTime = booking.gioBatDau != null && booking.gioKetThuc != null;
    final timeLabel = hasTime
        ? '${booking.gioBatDau} - ${booking.gioKetThuc}'
        : 'Chưa có giờ khám';

    // Hàng chờ thật sự: loại những người đã xong (5), vắng (6), đến trễ (7)...
    // → bệnh nhân trạng thái 7 không bao giờ nằm trong danh sách này.
    final List<LichHenModel> queue = provider.activeQueue
        .where((b) => !_outOfQueueStatuses.contains(b.trangThaiId.toString()))
        .toList();

    final showPrep =
        status == AppointmentStatus.pending ||
        status == AppointmentStatus.approved ||
        status == AppointmentStatus.late;

    final children = <Widget>[
      if (profile != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_pin_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.isSelf
                      ? 'Đang theo dõi cho: Tôi'
                      : 'Đang theo dõi cho: ${profile.quanHe} - ${profile.hoTen}',
                  style: _font(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showProfileSwitcherSheet(context),
                child: const Text('Đổi'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      // Thanh chọn lịch khi có nhiều hơn 1 lịch
      if (upcomingBookings.length > 1) ...[
        _BookingSelector(
          bookings: upcomingBookings,
          selectedId: booking.id,
          onSelect: (id) => setState(() => _selectedId = id),
        ),
        const SizedBox(height: 14),
      ],
      _HospitalInfoCard(
        hospital: hospital,
        department: department,
        room: room,
        date: dateLabel,
        time: timeLabel,
        status: status,
      ),
      const SizedBox(height: 16),
      ..._statusSection(
        provider: provider,
        booking: booking,
        status: status,
        queue: queue,
        timeLabel: timeLabel,
      ),
      if (showPrep) ...const [
        SizedBox(height: 24),
        _PrepareChecklist(),
        SizedBox(height: 14),
        _ImportantNotice(),
      ],
    ];

    return Scaffold(
      appBar: _appBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadBookings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: children,
          ),
        ),
      ),
    );
  }

  /// Phần nội dung thay đổi theo trạng thái của lịch hẹn.
  List<Widget> _statusSection({
    required LichHenProvider provider,
    required LichHenModel booking,
    required AppointmentStatus status,
    required List<LichHenModel> queue,
    required String timeLabel,
  }) {
    // Số đang khám = số nhỏ nhất còn trong hàng chờ (đã loại người đến trễ).
    final currentServing = queue.isNotEmpty ? queue.first.soThuTu : 0;

    switch (status) {
      case AppointmentStatus.pending:
        return const [
          _StatusMessageCard(
            icon: Icons.hourglass_empty_rounded,
            color: AppColors.primary,
            title: 'Lịch hẹn đang chờ duyệt',
            message:
                'Bệnh viện sẽ xem xét và xác nhận lịch hẹn của bạn. '
                'Bạn sẽ nhận được thông báo khi lịch được duyệt.',
          ),
        ];

      case AppointmentStatus.cancelled:
        return const [
          _StatusMessageCard(
            icon: Icons.cancel_rounded,
            color: AppColors.danger,
            title: 'Lịch hẹn đã bị hủy',
            message: 'Bạn có thể đặt lại lịch khám mới bất cứ lúc nào.',
          ),
        ];

      case AppointmentStatus.completed:
        return const [_CompletedCard()];

      case AppointmentStatus.missed:
        return const [
          _StatusMessageCard(
            icon: Icons.person_off_rounded,
            color: AppColors.muted,
            title: 'Bạn đã vắng mặt',
            message:
                'Lịch khám này được ghi nhận là vắng mặt. '
                'Bạn có thể đặt lại lịch khám khi cần.',
          ),
        ];

      case AppointmentStatus.late:
        // "Đang khám số" hiện số tiếp theo của hàng chờ,
        // phần số của bạn / dự kiến chuyển sang giao diện đến trễ.
        return [
          _NowServingCard(number: currentServing),
          const SizedBox(height: 16),
          _LateTicketCard(number: booking.soThuTu),
          const SizedBox(height: 16),
          const _LateSteps(),
          const SizedBox(height: 16),
          const _LateEstimateCard(),
        ];

      case AppointmentStatus.approved:
        return _approvedSection(
          provider: provider,
          booking: booking,
          queue: queue,
          currentServing: currentServing,
          timeLabel: timeLabel,
        );
    }
  }

  /// Trạng thái 2: đang chờ khám theo hàng chờ thời gian thực.
  List<Widget> _approvedSection({
    required LichHenProvider provider,
    required LichHenModel booking,
    required List<LichHenModel> queue,
    required int currentServing,
    required String timeLabel,
  }) {
    final queueReady = provider.queueLoaded;

    final myIndex = queue.indexWhere((b) => b.id == booking.id);
    final myNumber = myIndex != -1
        ? queue[myIndex].soThuTu
        : (booking.soThuTu > 0 ? booking.soThuTu : 0);

    if (myNumber <= 0) {
      return [_NoTicketCard(timeLabel: timeLabel)];
    }

    final widgets = <Widget>[
      _NowServingCard(number: currentServing),
      const SizedBox(height: 16),
    ];

    if (provider.queueError != null) {
      widgets.add(
        _QueueStatusCard(loading: false, message: provider.queueError!),
      );
      return widgets;
    }

    if (!queueReady) {
      widgets.add(
        _QueueStatusCard(
          loading: true,
          message: 'Số của bạn: $myNumber. Đang đồng bộ hàng chờ...',
        ),
      );
      return widgets;
    }

    if (myIndex == -1) {
      widgets.add(
        const _StatusMessageCard(
          icon: Icons.info_outline_rounded,
          color: AppColors.primary,
          title: 'Chưa thấy số của bạn trong hàng chờ',
          message:
              'Kéo xuống để làm mới. Nếu vẫn chưa thấy, vui lòng liên hệ '
              'nhân viên hỗ trợ tại phòng khám.',
        ),
      );
      return widgets;
    }

    final peopleAhead = myIndex;

    // Vẫn gọi update để estimator tiếp tục cập nhật trạng thái bên trong.
    final estimator = _queueTimeEstimator.update(currentServing);
    // Ưu tiên thời gian khám cấu hình của phòng, không có mới dùng estimator.
    final perPatient = _thoiGianKham ?? estimator.perPatient;
    final waitMinutes = _queueTimeEstimator.waitMinutes(
      peopleAhead,
      perPatient,
    );

    final estimate = _estimateTurn(
      ngayKham: booking.ngayDat!,
      gioBatDau: booking.gioBatDau,
      gioKetThuc: booking.gioKetThuc,
      waitMinutes: waitMinutes,
    );

    widgets.addAll([
      _MyTurnCard(
        number: myNumber,
        peopleAhead: peopleAhead,
        waitMinutes: waitMinutes,
      ),
      const SizedBox(height: 16),
      _QueueTrack(serving: currentServing, mine: myNumber),
      const SizedBox(height: 16),
      _EstimateCard(
        waitMinutes: waitMinutes,
        estimatedTimeStr: _hhmm(estimate.eta),
        isExceedingShift: estimate.exceeds,
        shiftNotStarted: estimate.shiftNotStarted,
        shiftStart: booking.gioBatDau,
      ),
    ]);
    return widgets;
  }
}

/// ---------------------------------------------------------------------------
/// Thanh chọn lịch hẹn (hiện khi có nhiều hơn 1 lịch cần theo dõi)
/// ---------------------------------------------------------------------------
class _BookingSelector extends StatelessWidget {
  const _BookingSelector({
    required this.bookings,
    required this.selectedId,
    required this.onSelect,
  });

  final List<LichHenModel> bookings;
  final String selectedId;
  final ValueChanged<String> onSelect;

  String _date(DateTime? d) => d == null
      ? '--/--'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final b = bookings[i];
          final selected = b.id == selectedId;
          final status = statusFromTrangThaiId(b.trangThaiId);
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(b.id),
            child: Container(
              constraints: const BoxConstraints(minWidth: 130, maxWidth: 190),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.line,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_date(b.ngayDat)} · ${status.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _font(
                      12.5,
                      weight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.tenKhoa ?? 'Chuyên khoa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _font(
                      12,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Trạng thái toàn màn hình (lỗi / không có lịch)
/// ---------------------------------------------------------------------------
class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.07),
                  ),
                ),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.13),
                  ),
                  child: Icon(icon, size: 44, color: color),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _font(18.5, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _font(14, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 20),
              label: Text(
                actionLabel,
                style: _font(15, weight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Thông tin bệnh viện / phòng khám (có đủ mọi trạng thái lịch hẹn)
/// ---------------------------------------------------------------------------
class _HospitalInfoCard extends StatelessWidget {
  const _HospitalInfoCard({
    required this.hospital,
    required this.department,
    required this.room,
    required this.date,
    required this.time,
    required this.status,
  });

  final String hospital;
  final String department;
  final String room;
  final String date;
  final String time;
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Đầu thẻ: tên bệnh viện + trạng thái
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bệnh viện',
                        style: _font(
                          12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _font(
                          16.5,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge trạng thái: lấy màu + nhãn từ AppointmentStatus
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: status.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 14,
                        color: status.foreground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: _font(
                          11.5,
                          weight: FontWeight.w700,
                          color: status.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Phòng khám nổi bật để bệnh nhân dễ tìm
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.teal.withValues(alpha: 0.14),
                        AppColors.teal.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.teal, AppColors.tealDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.meeting_room_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PHÒNG KHÁM',
                              style: _font(
                                10.5,
                                weight: FontWeight.w800,
                                color: AppColors.tealDark,
                              ).copyWith(letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              room,
                              style: _font(
                                17,
                                weight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.medical_services_outlined,
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    department,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _font(13, color: AppColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày khám',
                        value: date,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeTile(
                        icon: Icons.access_time_rounded,
                        label: 'Giờ khám',
                        value: time,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _font(11.5, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _font(14, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Số đang khám (thẻ nổi bật có họa tiết nhịp tim)
/// ---------------------------------------------------------------------------
class _NowServingCard extends StatelessWidget {
  const _NowServingCard({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(right: -50, top: -50, child: _ring(180)),
            Positioned(right: -15, top: -15, child: _ring(110)),
            // Đường nhịp tim chạy dưới nền
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 56,
              child: CustomPaint(painter: _PulsePainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Đang khám số',
                            style: _font(
                              15,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      const _LiveChip(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    number > 0 ? '$number' : '---',
                    style:
                        _font(
                          88,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tự động cập nhật theo thời gian thực',
                        style: _font(
                          13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 2),
    ),
  );
}

// Vẽ đường điện tim (ECG) lặp lại, rất mờ, làm họa tiết y tế.
class _PulsePainter extends CustomPainter {
  const _PulsePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height * 0.62;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(0, mid);
    const period = 132.0;
    for (double x = 0; x < size.width; x += period) {
      path
        ..lineTo(x + 34, mid)
        ..lineTo(x + 42, mid - 9)
        ..lineTo(x + 50, mid + 7)
        ..lineTo(x + 58, mid - 30)
        ..lineTo(x + 67, mid + 22)
        ..lineTo(x + 75, mid)
        ..lineTo(x + 85, mid - 7)
        ..lineTo(x + 95, mid)
        ..lineTo(x + period, mid);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveChip extends StatefulWidget {
  const _LiveChip();

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF5CF2D6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Trực tiếp',
            style: _font(12.5, weight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Số của bạn + thông báo mức độ gần đến lượt
/// ---------------------------------------------------------------------------
class _MyTurnCard extends StatelessWidget {
  const _MyTurnCard({
    required this.number,
    required this.peopleAhead,
    required this.waitMinutes,
  });

  final int number;
  final int peopleAhead;
  final int waitMinutes;

  // Mức độ khẩn: sắp đến lượt / gần đến lượt / còn lâu.
  ({Color color, Color bg, IconData icon, String text}) get _banner {
    if (peopleAhead == 0) {
      return (
        color: AppColors.tealDark,
        bg: AppColors.teal.withValues(alpha: 0.13),
        icon: Icons.notifications_active_rounded,
        text: 'Sắp đến lượt bạn! Vui lòng có mặt tại phòng khám.',
      );
    }
    if (peopleAhead <= 3) {
      return (
        color: AppColors.warnText,
        bg: AppColors.warnBg,
        icon: Icons.directions_walk_rounded,
        text: 'Còn $peopleAhead người nữa. Hãy di chuyển đến phòng khám.',
      );
    }
    return (
      color: AppColors.primaryDark,
      bg: AppColors.primary.withValues(alpha: 0.08),
      icon: Icons.chair_alt_rounded,
      text: 'Bạn có thể nghỉ ngơi, chúng tôi sẽ báo khi gần đến lượt.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: AppColors.teal),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Số của bạn
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.teal.withValues(alpha: 0.16),
                                AppColors.teal.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.teal.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'SỐ CỦA BẠN',
                                style: _font(
                                  10.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.tealDark,
                                ).copyWith(letterSpacing: 0.8),
                              ),
                              Text(
                                '$number',
                                style:
                                    _font(
                                      46,
                                      weight: FontWeight.w800,
                                      color: AppColors.tealDark,
                                      height: 1.1,
                                    ).copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Còn phía trước',
                              style: _font(13, color: AppColors.muted),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$peopleAhead',
                                    style: _font(32, weight: FontWeight.w800),
                                  ),
                                  TextSpan(
                                    text: ' người',
                                    style: _font(
                                      15,
                                      weight: FontWeight.w600,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '~$waitMinutes phút',
                                    style: _font(
                                      12.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: banner.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(banner.icon, size: 19, color: banner.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              banner.text,
                              style: _font(
                                13,
                                weight: FontWeight.w600,
                                color: banner.color,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tiến độ hàng chờ: từ số đang khám tới số của bạn
/// ---------------------------------------------------------------------------
class _QueueTrack extends StatelessWidget {
  const _QueueTrack({required this.serving, required this.mine});

  final int serving;
  final int mine;

  @override
  Widget build(BuildContext context) {
    final progress = (mine > 0 && serving > 0)
        ? (serving / mine).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tiến độ hàng chờ',
                style: _font(14.5, weight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: _font(
                  14.5,
                  weight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Đường tiến độ có đầu tròn chạy theo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  const thumb = 22.0;
                  final trackWidth = constraints.maxWidth;
                  final fillWidth = (trackWidth - thumb) * value + thumb / 2;

                  return SizedBox(
                    height: thumb,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: fillWidth,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.teal],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Positioned(
                          left: (trackWidth - thumb) * value,
                          child: Container(
                            width: thumb,
                            height: thumb,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trackLabel(
                'Đang khám',
                serving > 0 ? '#$serving' : '---',
                AppColors.primary,
                CrossAxisAlignment.start,
              ),
              _trackLabel(
                'Số của bạn',
                '#$mine',
                AppColors.tealDark,
                CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackLabel(
    String label,
    String value,
    Color color,
    CrossAxisAlignment align,
  ) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: _font(12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: _font(17, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Dự kiến giờ đến lượt
/// ---------------------------------------------------------------------------
class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.waitMinutes,
    required this.estimatedTimeStr,
    this.isExceedingShift = false,
    this.shiftNotStarted = false,
    this.shiftStart,
  });

  final int waitMinutes;
  final String estimatedTimeStr;
  final bool isExceedingShift;
  final bool shiftNotStarted;
  final String? shiftStart;

  @override
  Widget build(BuildContext context) {
    // Nếu vượt quá giờ khám, đổi màu sắc để cảnh báo
    final mainColor = isExceedingShift
        ? AppColors.warnText
        : AppColors.primaryDark;
    final bgColor = isExceedingShift
        ? AppColors.warnBg
        : AppColors.primary.withValues(alpha: 0.07);
    final borderColor = isExceedingShift
        ? AppColors.warnBorder
        : AppColors.primary.withValues(alpha: 0.18);
    final iconColor = isExceedingShift ? AppColors.warnText : AppColors.primary;
    final iconBgColor = isExceedingShift
        ? AppColors.warnBorder.withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isExceedingShift
                  ? Icons.warning_amber_rounded
                  : Icons.timer_outlined,
              color: iconColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExceedingShift
                      ? 'Cảnh báo thời gian'
                      : 'Dự kiến đến lượt khoảng',
                  style: _font(12.5, color: mainColor),
                ),
                const SizedBox(height: 2),
                Text(
                  isExceedingShift
                      ? 'Có thể sang ca khám sau'
                      : estimatedTimeStr,
                  style: _font(22, weight: FontWeight.w800, color: mainColor),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              isExceedingShift
                  ? 'Số lượng bệnh nhân đông, vui lòng liên hệ quầy tiếp đón.'
                  : shiftNotStarted
                  ? 'Ca khám bắt đầu lúc ${shiftStart ?? ''}. '
                        'Còn ~$waitMinutes phút phục vụ trước bạn.'
                  : 'Còn ~$waitMinutes phút (tham khảo)',
              textAlign: TextAlign.right,
              style: _font(11.5, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// ĐẾN TRỄ (trạng thái 7): thẻ số cũ bị gạch + không tính được số người trước
/// ---------------------------------------------------------------------------
class _LateTicketCard extends StatelessWidget {
  const _LateTicketCard({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: AppColors.late),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Số cũ - bị gạch ngang, màu nhạt
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lateBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.lateBorder),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'SỐ CỦA BẠN',
                                style: _font(
                                  10.5,
                                  weight: FontWeight.w800,
                                  color: AppColors.lateDark,
                                ).copyWith(letterSpacing: 0.8),
                              ),
                              Text(
                                number > 0 ? '$number' : '--',
                                style:
                                    _font(
                                      46,
                                      weight: FontWeight.w800,
                                      color: AppColors.late.withValues(
                                        alpha: 0.55,
                                      ),
                                      height: 1.1,
                                    ).copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.lateDark,
                                      decorationThickness: 2,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Còn phía trước',
                              style: _font(13, color: AppColors.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '—',
                              style: _font(
                                32,
                                weight: FontWeight.w800,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lateBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.lateBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: AppColors.late,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chưa xác định',
                                    style: _font(
                                      12.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.lateDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lateBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: AppColors.lateDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn đến trễ nên số thứ tự cũ đã được đưa ra khỏi '
                              'hàng chờ. Vui lòng gặp nhân viên hỗ trợ tại '
                              'phòng khám để được xếp lại.',
                              style: _font(
                                13,
                                weight: FontWeight.w600,
                                color: AppColors.lateDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

/// Các bước xử lý khi đến trễ (dạng timeline dọc)
class _LateSteps extends StatelessWidget {
  const _LateSteps();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.late,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Việc cần làm tiếp theo',
                style: _font(15, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _TimelineStep(
            state: _StepState.done,
            title: 'Đã ghi nhận bạn đến trễ',
            subtitle: 'Số thứ tự cũ được đưa ra khỏi hàng chờ.',
          ),
          const _TimelineStep(
            state: _StepState.current,
            title: 'Gặp nhân viên hỗ trợ',
            subtitle: 'Đến quầy hỗ trợ tại phòng khám và xuất trình mã QR.',
          ),
          const _TimelineStep(
            state: _StepState.upcoming,
            title: 'Được xếp lại vào hàng chờ',
            subtitle: 'Bạn sẽ nhận số mới và thông báo khi sắp đến lượt.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.state,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final _StepState state;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color bg;
    late final IconData icon;

    switch (state) {
      case _StepState.done:
        color = AppColors.teal;
        bg = AppColors.teal.withValues(alpha: 0.14);
        icon = Icons.check_rounded;
        break;
      case _StepState.current:
        color = AppColors.late;
        bg = AppColors.lateBg;
        icon = Icons.support_agent_rounded;
        break;
      case _StepState.upcoming:
        color = AppColors.muted;
        bg = AppColors.line.withValues(alpha: 0.5);
        icon = Icons.format_list_numbered_rounded;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: state == _StepState.current
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: state == _StepState.done
                          ? AppColors.teal.withValues(alpha: 0.4)
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _font(
                      14,
                      weight: FontWeight.w700,
                      color: state == _StepState.upcoming
                          ? AppColors.muted
                          : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _font(12.5, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dự kiến đến lượt: chưa xác định vì đang đến trễ
class _LateEstimateCard extends StatelessWidget {
  const _LateEstimateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lateBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lateBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.lateBorder.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.timer_off_outlined,
              color: AppColors.lateDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dự kiến đến lượt',
                  style: _font(12.5, color: AppColors.lateDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chưa xác định',
                  style: _font(
                    20,
                    weight: FontWeight.w800,
                    color: AppColors.lateDark,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              'Sẽ tự cập nhật sau khi nhân viên xếp lại số cho bạn.',
              textAlign: TextAlign.right,
              style: _font(11.5, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Đã hoàn thành khám
/// ---------------------------------------------------------------------------
class _CompletedCard extends StatelessWidget {
  const _CompletedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.08),
                ),
              ),
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.teal, AppColors.tealDark],
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Bạn đã hoàn thành lượt khám',
            style: _font(16.5, weight: FontWeight.w800, color: AppColors.teal),
          ),
          const SizedBox(height: 8),
          Text(
            'Cảm ơn bạn đã sử dụng dịch vụ. Chúc bạn nhiều sức khỏe!',
            textAlign: TextAlign.center,
            style: _font(14, color: AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Thẻ thông báo trạng thái chung (chờ duyệt / vắng mặt / đã hủy / ...)
/// ---------------------------------------------------------------------------
class _StatusMessageCard extends StatelessWidget {
  const _StatusMessageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _font(16.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: _font(14, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Chưa được cấp số
/// ---------------------------------------------------------------------------
class _NoTicketCard extends StatelessWidget {
  const _NoTicketCard({required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 34,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa được cấp số thứ tự',
            style: _font(16.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng có mặt tại bệnh viện trước $timeLabel để được nhân viên tiếp đón và cấp số.',
            textAlign: TextAlign.center,
            style: _font(14, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          // Các bước nhận số
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: _StepDot(
                  icon: Icons.local_hospital_rounded,
                  label: 'Đến\nbệnh viện',
                ),
              ),
              _StepArrow(),
              Expanded(
                child: _StepDot(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Quét mã QR\ncheck-in',
                ),
              ),
              _StepArrow(),
              Expanded(
                child: _StepDot(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Nhận số\nthứ tự',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 23, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: _font(11.5, weight: FontWeight.w600, height: 1.3),
        ),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 13),
      child: Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.line),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Chuẩn bị trước khi khám
/// ---------------------------------------------------------------------------
class _PrepareChecklist extends StatelessWidget {
  const _PrepareChecklist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Chuẩn bị trước khi khám',
                style: _font(15, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _CheckItem(
            icon: Icons.badge_rounded,
            text: 'Mang theo CCCD và thẻ BHYT (nếu có)',
          ),
          const _CheckItem(
            icon: Icons.qr_code_2_rounded,
            text: 'Chuẩn bị sẵn mã QR lịch khám để check-in',
          ),
          const _CheckItem(
            icon: Icons.notifications_active_rounded,
            text: 'Giữ điện thoại để nhận thông báo khi đến lượt',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: _font(13.5, weight: FontWeight.w500, height: 1.4),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Lưu ý quan trọng
/// ---------------------------------------------------------------------------
class _ImportantNotice extends StatelessWidget {
  const _ImportantNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warnBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warnBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warnBorder.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warnText,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lưu ý quan trọng',
                  style: _font(
                    15.5,
                    weight: FontWeight.w700,
                    color: AppColors.warnText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng có mặt trước giờ khám 15 phút để làm thủ tục. '
                  'Nếu quá giờ, số thứ tự của bạn có thể bị hủy.',
                  style: _font(13.5, color: AppColors.warnText, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueStatusCard extends StatelessWidget {
  const _QueueStatusCard({required this.loading, required this.message});

  final bool loading;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = loading ? AppColors.primary : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Icon(Icons.cloud_off_rounded, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: _font(14, weight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Style thẻ dùng chung
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF0B2A4A).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
);