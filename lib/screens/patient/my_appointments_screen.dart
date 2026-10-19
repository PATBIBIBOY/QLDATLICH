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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LichHenProvider>();
    final usePreview = widget.appointments != null;

    final items = usePreview
        ? widget.appointments!
        : provider.activeBookings.map(_toItem).toList();
    final historyCount =
        widget.historyCount ?? (usePreview ? 0 : provider.historyBookings.length);

    final loading = !usePreview && provider.isLoadingMyBookings;
    final error = usePreview ? null : provider.myBookingsError;
    final notLoggedIn = !usePreview && (_patientId == null || _patientId!.isEmpty);

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
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
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
        children.add(const _EmptyState());
      } else {
        for (final item in items) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AppointmentCard(item: item, onTap: () => _openDetail(item)),
            ),
          );
        }
      }
      children.add(_HistoryCard(count: historyCount, onTap: widget.onOpenHistory));
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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

class _AppointmentCard extends StatelessWidget {
  final MyAppointmentItem item;
  final VoidCallback? onTap;
  const _AppointmentCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApptCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.hospitalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ApptColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(item.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: ApptColors.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ngày khám: ${item.dateLabel}',
                style: const TextStyle(fontSize: 13, color: ApptColors.textGrey),
              ),
              const SizedBox(height: 12),
              const _LinkText('Xem chi tiết'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _HistoryCard({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ApptCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch sử',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ApptColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count lần khám',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ApptColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Xem lại các lịch khám đã hoàn tất',
                style: TextStyle(fontSize: 13, color: ApptColors.textGrey),
              ),
              const SizedBox(height: 12),
              const _LinkText('Xem lịch sử'),
            ],
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
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: ApptColors.link,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: ApptColors.link,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'Bạn chưa có lịch khám nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ApptColors.textGrey,
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
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: ApptColors.textGrey,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ],
      ),
    );
  }
}