import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../models/lichhen_model.dart';
import '../../providers/lich_hen_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../models/appointment_item.dart';

/// Màn hình "Lịch khám của tôi": lấy lịch hẹn của bệnh nhân từ collection LichHen.
class MyAppointmentsScreen extends StatefulWidget {
  /// Mã bệnh nhân. Không truyền thì dùng uid của tài khoản đang đăng nhập
  /// (phải cùng giá trị với benhNhanId bạn truyền vào saveBooking).
  final String? benhNhanId;

  /// Truyền danh sách để xem thử giao diện (không đọc Firestore). Bình thường để null.
  final List<MyAppointmentItem>? appointments;
  final int? historyCount;

  final ValueChanged<MyAppointmentItem>? onOpenDetail;
  final VoidCallback? onOpenHistory;
  final ValueChanged<int>? onNavTap;
  final bool showBottomNavBar;

  const MyAppointmentsScreen({
    super.key,
    this.benhNhanId,
    this.appointments,
    this.historyCount,
    this.onOpenDetail,
    this.onOpenHistory,
    this.onNavTap,
    this.showBottomNavBar = true,
  });

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  String? get _patientId =>
      widget.benhNhanId ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.appointments == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final id = _patientId;
    if (id == null || id.isEmpty) return;
    await context.read<LichHenProvider>().loadMyBookings(id);
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Lịch hẹn trong Firestore -> dòng hiển thị.
  MyAppointmentItem _toItem(LichHenModel b) {
    final khoa = b.tenKhoa ?? 'Chuyên khoa';
    final hasHours = b.gioBatDau != null && b.gioKetThuc != null;
    final hours = hasHours ? '${b.gioBatDau} - ${b.gioKetThuc}' : '';

    return MyAppointmentItem(
      id: b.id,
      hospitalName: b.tenBenhVien ?? 'Bệnh viện ${b.benhVienId}',
      subtitle: hasHours ? '$khoa • Giờ khám: $hours' : khoa,
      status: statusFromTrangThaiId(b.trangThaiId),
      departmentName: khoa,
      dateLabel: _formatDate(b.ngayDat),
      timeLabel: hasHours ? hours : '—',
    );
  }

  void _openDetail(MyAppointmentItem item) {
    if (widget.onOpenDetail != null) {
      widget.onOpenDetail!(item);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.appointmentDetail,
        arguments: item,
      );
    }
  }

  /// Về trang chủ (tab đầu tiên) để đặt lịch khám.
  void _goBookNow() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientMain,
      (_) => false,
      arguments: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LichHenProvider>();
    final usePreview = widget.appointments != null;

    final items = usePreview
        ? widget.appointments!
        : provider.activeBookings.map(_toItem).toList();
    final historyCount =
        widget.historyCount ??
        (usePreview ? 0 : provider.historyBookings.length);

    final loading = !usePreview && provider.isLoadingMyBookings;
    final error = usePreview ? null : provider.myBookingsError;
    final notLoggedIn =
        !usePreview && (_patientId == null || _patientId!.isEmpty);

    // Nội dung danh sách
    final children = <Widget>[];
    if (notLoggedIn) {
      children.add(
        const _MessageState(
          icon: Icons.lock_outline_rounded,
          text: 'Vui lòng đăng nhập để xem lịch khám của bạn.',
        ),
      );
    } else if (loading && items.isEmpty) {
      // Khung xương khi đang tải (đẹp hơn vòng xoay trống)
      children.addAll(const [
        _SkeletonBanner(),
        SizedBox(height: 18),
        _SkeletonCard(),
        SizedBox(height: 14),
        _SkeletonCard(),
        SizedBox(height: 14),
        _SkeletonCard(),
      ]);
    } else if (error != null && items.isEmpty) {
      children.add(
        _MessageState(
          icon: Icons.error_outline_rounded,
          text: error,
          color: Colors.redAccent,
          onRetry: _load,
        ),
      );
    } else {
      if (items.isEmpty) {
        children.add(_EmptyState(onBookNow: _goBookNow));
      } else {
        children.add(_SummaryBanner(count: items.length));
        children.add(const SizedBox(height: 20));
        children.add(
          _SectionTitle(title: 'Lịch sắp tới', badge: '${items.length}'),
        );
        children.add(const SizedBox(height: 12));
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          children.add(
            _FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AppointmentCard(
                  item: item,
                  onTap: () => _openDetail(item),
                ),
              ),
            ),
          );
        }
      }
      children.add(const SizedBox(height: 6));
      children.add(
        _FadeSlideIn(
          index: items.length,
          child: _HistoryCard(count: historyCount, onTap: widget.onOpenHistory),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ApptColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ApptHeader(title: 'Lịch khám của tôi'),
            Expanded(
              // Kéo xuống để tải lại
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavBar
          ? CustomBottomNavBar(
              currentIndex: 1,
              onTap:
                  widget.onNavTap ??
                  (index) => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.patientMain,
                    (_) => false,
                    arguments: index,
                  ),
            )
          : null,
    );
  }
}

// ───────────────────────── MÀU RIÊNG CỦA MÀN HÌNH ─────────────────────────

const Color _kBlue = Color(0xFF2196F3);
const Color _kBlueDark = Color(0xFF1565C0);
const Color _kAmber = Color(0xFFF59E0B);

// ───────────────────────── HIỆU ỨNG XUẤT HIỆN ─────────────────────────

/// Mờ dần + trượt nhẹ từ dưới lên; các thẻ phía sau xuất hiện trễ hơn một chút.
class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeSlideIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delayStep = index > 6 ? 6 : index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayStep * 80),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

// ───────────────────────── BANNER TÓM TẮT ─────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int count;
  const _SummaryBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlue, _kBlueDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có $count lịch khám',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kéo xuống để cập nhật trạng thái mới nhất',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? badge;
  const _SectionTitle({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ApptColors.textDark,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _kBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── THẺ LỊCH KHÁM ─────────────────────────

class _AppointmentCard extends StatelessWidget {
  final MyAppointmentItem item;
  final VoidCallback? onTap;
  const _AppointmentCard({required this.item, this.onTap});

  /// Tách "dd/MM/yyyy" thành [ngày, tháng]; không đúng định dạng thì trả về null.
  List<String>? _splitDate(String label) {
    final parts = label.split('/');
    if (parts.length < 2) return null;
    final day = parts[0].trim();
    final month = parts[1].trim();
    if (day.isEmpty || month.isEmpty) return null;
    return [day, month];
  }

  /// 6 ký tự cuối của mã lịch, in hoa (mã Firestore rất dài nên chỉ hiện gọn).
  String _shortId(String id) {
    final clean = id.replaceAll('#', '').trim();
    if (clean.isEmpty) return '—';
    return clean.length > 6
        ? clean.substring(clean.length - 6).toUpperCase()
        : clean.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == AppointmentStatus.pending;
    final accent = isPending ? _kAmber : _kBlue;
    final date = _splitDate(item.dateLabel);
    final hasTime = item.timeLabel.trim().isNotEmpty && item.timeLabel != '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dải màu bên trái theo trạng thái
                  Container(width: 5, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ô ngày kiểu tờ lịch
                              _DateBadge(date: date, accent: accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.hospitalName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w800,
                                        color: ApptColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StatusChip(item.status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Thông tin chi tiết
                          _InfoRow(
                            icon: Icons.medical_services_outlined,
                            text: item.departmentName,
                            color: accent,
                          ),
                          if (hasTime) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              text: item.timeLabel,
                              color: accent,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            text: 'Ngày khám: ${item.dateLabel}',
                            color: accent,
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 10),

                          // Chân thẻ: mã lịch + xem chi tiết
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Mã ${_shortId(item.id)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: ApptColors.textGrey,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const _LinkText('Xem chi tiết'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô ngày kiểu tờ lịch: số ngày lớn, tháng nhỏ phía trên.
class _DateBadge extends StatelessWidget {
  final List<String>? date; // [ngày, tháng]
  final Color accent;
  const _DateBadge({required this.date, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withOpacity(0.16), accent.withOpacity(0.07)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: date == null
          ? Icon(Icons.event_rounded, size: 28, color: accent)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'THG ${date![1]}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date![0],
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: ApptColors.textDark,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Một dòng thông tin có biểu tượng tròn nhỏ.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: ApptColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── THẺ LỊCH SỬ ─────────────────────────

class _HistoryCard extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _HistoryCard({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FB)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 26,
                    color: ApptColors.textGrey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Lịch sử',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: ApptColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE3E8F0),
                              ),
                            ),
                            child: Text(
                              '$count lần khám',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ApptColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Xem lại các lịch khám đã hoàn tất',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ApptColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: ApptColors.link,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chữ liên kết xanh kèm mũi tên: "Xem chi tiết >"
class _LinkText extends StatelessWidget {
  final String text;
  const _LinkText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: ApptColors.link,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: ApptColors.link,
        ),
      ],
    );
  }
}

// ───────────────────────── TRẠNG THÁI TRỐNG / LỖI / ĐANG TẢI ─────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onBookNow;
  const _EmptyState({required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 36, 12, 24),
      child: Column(
        children: [
          // Hình minh hoạ: vòng tròn lồng nhau
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kBlue.withOpacity(0.06),
            ),
            child: Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlue.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 46,
                  color: _kBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bạn chưa có lịch khám nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ApptColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đặt lịch khám ngay để được bác sĩ\nchăm sóc sức khỏe cho bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: ApptColors.textGrey,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onBookNow,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Đặt lịch ngay',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thông báo giữa màn hình (chưa đăng nhập / lỗi), có nút "Thử lại" tuỳ chọn.
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.text,
    this.color = ApptColors.textGrey,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.10),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: ApptColors.textGrey,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBlue,
                side: const BorderSide(color: _kBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── KHUNG XƯƠNG KHI ĐANG TẢI ─────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _SkeletonBox({this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonBanner extends StatelessWidget {
  const _SkeletonBanner();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonBox(height: 86, radius: 22);
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _SkeletonBox(width: 54, height: 62, radius: 16),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(height: 16),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 90, height: 20, radius: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SkeletonBox(height: 14),
          const SizedBox(height: 10),
          const _SkeletonBox(width: 160, height: 14),
          const SizedBox(height: 10),
          const _SkeletonBox(width: 120, height: 14),
        ],
      ),
    );
  }
}