import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../models/lichhen_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lich_hen_provider.dart';
import '../../models/appointment_item.dart';

const _primary = Color(0xFF1E78E0);
const _bg = Color(0xFFF5F7FA);
const _textDark = Color(0xFF0F172A);
const _textGrey = Color(0xFF64748B);
const _danger = Color(0xFFEF4444);

// ───────────────────────── Màn hình trang chủ ─────────────────────────

// Trang chủ bệnh nhân: lịch khám sắp tới, chức năng nhanh, thông báo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: lấy số thông báo chưa đọc thật.
  static const _unreadCount = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBookings();
    });
  }

  // Tải lịch hẹn của bệnh nhân đang đăng nhập.
  Future<void> _loadBookings() async {
    final id = FirebaseAuth.instance.currentUser?.uid;
    if (id == null) return;
    await context.read<LichHenProvider>().loadMyBookings(id);
  }

  // Tìm lịch đã xác nhận (trạng thái '2') từ hôm nay trở đi, gần nhất trước.
  LichHenModel? _findUpcoming(List<LichHenModel> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming =
        bookings
            .where(
              (b) =>
                  b.trangThaiId == '2' &&
                  b.ngayDat != null &&
                  !b.ngayDat!.isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.ngayDat!.compareTo(b.ngayDat!));

    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Hàm chuyển đổi từ LichHenModel (dữ liệu Firestore) sang MyAppointmentItem (dữ liệu UI)
  MyAppointmentItem _convertToAppointmentItem(LichHenModel model) {
    // 1. Format ngày tháng
    String dateStr = '—';
    if (model.ngayDat != null) {
      dateStr = '${model.ngayDat!.day.toString().padLeft(2, '0')}/'
          '${model.ngayDat!.month.toString().padLeft(2, '0')}/'
          '${model.ngayDat!.year}';
    }

    // 2. Format giờ giấc
    String timeStr = '—';
    if (model.gioBatDau != null && model.gioKetThuc != null) {
      timeStr = '${model.gioBatDau} - ${model.gioKetThuc}';
    } else if (model.gioDuKien.isNotEmpty) {
      timeStr = model.gioDuKien;
    }

    final deptName = model.tenKhoa ?? 'Chuyên khoa';
    final hospName = model.tenBenhVien ?? 'Bệnh viện';

    // 3. Trả về đối tượng MyAppointmentItem
    return MyAppointmentItem(
      id: model.id,
      hospitalName: hospName,
      subtitle: '$deptName · $timeStr',
      status: statusFromTrangThaiId(model.trangThaiId),
      departmentName: deptName,
      dateLabel: dateStr,
      timeLabel: timeStr,
    );
  }
  
  // Mở màn hình tìm bệnh viện để đặt lịch.
  void _openBooking() => Navigator.pushNamed(context, AppRoutes.hospitalFilter);

  void _openAppointmentDetail(MyAppointmentItem appointment) {
    Navigator.pushNamed(
      context,
      AppRoutes.appointmentDetail,
      arguments: appointment,
    );
  }

  // TODO: mở mã QR của tôi.
  void _openQr() {}

  // TODO: mở danh sách thông báo.
  void _openNotifications() {}

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().user?.hoTen ?? 'Nguyễn Văn An';

    final LichHenModel? upcomingLichHen = _findUpcoming(
      context.watch<LichHenProvider>().activeBookings,
    );

    // 2. ✅ CHUYỂN ĐỔI sang MyAppointmentItem để dùng cho UI
    final MyAppointmentItem? upcomingItem = upcomingLichHen != null 
        ? _convertToAppointmentItem(upcomingLichHen) 
        : null;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBookings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  userName: userName,
                  unreadCount: _unreadCount,
                  onBellTap: _openNotifications,
                ),
                const SizedBox(height: 24),

               upcomingLichHen == null
                    ? _EmptyUpcomingCard(onBook: _openBooking)
                    : _UpcomingCard(
                        appointment: upcomingLichHen, 
                        onTap: () {
                          if (upcomingItem != null) {
                            _openAppointmentDetail(upcomingItem); 
                          }
                        },
                      ),
                const SizedBox(height: 28),

                const _SectionTitle('Chức năng nhanh'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.add_rounded,
                        color: _primary,
                        background: const Color(0xFFDBEAFE),
                        title: 'Đặt lịch khám',
                        subtitle: 'Chọn khoa & giờ',
                        onTap: _openBooking,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.qr_code_2_rounded,
                        color: const Color(0xFF10B981),
                        background: const Color(0xFFD1FAE5),
                        title: 'Mã QR của tôi',
                        subtitle: 'Xuất trình khi đến',
                        onTap: _openQr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _SectionTitle(
                  'Thông báo gần đây',
                  actionText: 'Xem tất cả',
                  onAction: _openNotifications,
                ),
                const SizedBox(height: 14),
                for (final notice in _sampleNotices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NoticeTile(notice),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hàm định dạng ─────────────────────────

// Định dạng ngày: dd/MM/yyyy.
String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// Nhãn đếm ngược: Hôm nay / Ngày mai / Còn n ngày.
String _countdownLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(today).inDays;
  if (days <= 0) return 'Hôm nay';
  if (days == 1) return 'Ngày mai';
  return 'Còn $days ngày';
}

// Lời chào theo giờ trong ngày.
String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Chào buổi sáng';
  if (hour < 14) return 'Chào buổi trưa';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

// ───────────────────────── Đầu trang ─────────────────────────

// Đầu trang: ảnh đại diện, lời chào, nút thông báo có số chưa đọc.
class _HomeHeader extends StatelessWidget {
  final String userName;
  final int unreadCount;
  final VoidCallback onBellTap;

  const _HomeHeader({
    required this.userName,
    required this.unreadCount,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final words = userName.trim().split(RegExp(r'\s+'));
    final initial = words.last.isNotEmpty ? words.last[0].toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primary.withOpacity(0.65)],
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()} 👋',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _BellButton(count: unreadCount, onTap: onBellTap),
      ],
    );
  }
}

// Nút chuông thông báo, góc trên phải có huy hiệu số chưa đọc.
class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _primary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _danger,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Lịch khám sắp tới ─────────────────────────

// Thẻ lịch khám sắp tới: khoa, bệnh viện, ngày giờ, số thứ tự, đếm ngược.
class _UpcomingCard extends StatelessWidget {
  final LichHenModel appointment;
  final VoidCallback onTap;

  const _UpcomingCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final date = a.ngayDat;
    final hospital = a.tenBenhVien;

    final timeText = (a.gioBatDau != null && a.gioKetThuc != null)
        ? '${a.gioBatDau} – ${a.gioKetThuc}'
        : (a.gioDuKien.isNotEmpty ? a.gioDuKien : 'Đang cập nhật giờ khám');
    final queueText = a.soThuTu > 0 ? '#${a.soThuTu}' : 'Đang cập nhật';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                const Positioned(
                  top: -35,
                  right: -25,
                  child: _Bubble(130, 0.10),
                ),
                const Positioned(
                  bottom: -50,
                  left: -30,
                  child: _Bubble(150, 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nhãn "Lịch khám sắp tới" + đếm ngược
                      Row(
                        children: [
                          const _GlassChip(
                            icon: Icons.event_available_rounded,
                            text: 'Lịch khám sắp tới',
                            small: true,
                          ),
                          const Spacer(),
                          if (date != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _countdownLabel(date),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Khoa + bệnh viện
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.tenKhoa ?? 'Khoa chưa cập nhật',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                if (hospital != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    hospital,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ngày + giờ khám
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _GlassChip(
                            icon: Icons.calendar_today_rounded,
                            text: date != null
                                ? _formatDate(date)
                                : 'Chưa cập nhật ngày',
                          ),
                          _GlassChip(
                            icon: Icons.access_time_rounded,
                            text: timeText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.white.withOpacity(0.25)),
                      const SizedBox(height: 12),

                      // Số thứ tự + trạng thái
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SỐ THỨ TỰ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  queueText,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _GlassChip(
                            icon: Icons.check_circle_rounded,
                            text: 'Đã xác nhận',
                            small: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Thẻ rỗng khi chưa có lịch sắp tới, kèm nút đặt lịch.
class _EmptyUpcomingCard extends StatelessWidget {
  final VoidCallback onBook;
  const _EmptyUpcomingCard({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 32,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có lịch khám sắp tới',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đặt lịch khám để được chăm sóc sức khỏe\nvà nhận số thứ tự sớm nhất.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: _textGrey),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onBook,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Đặt lịch ngay',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Vòng tròn trang trí mờ ở nền thẻ.
class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

// Nhãn nền kính mờ (icon + chữ) dùng trong thẻ lịch khám.
class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool small;

  const _GlassChip({
    required this.icon,
    required this.text,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: small ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(small ? 0.20 : 0.18),
        borderRadius: BorderRadius.circular(small ? 20 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 15 : 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: small ? 12.5 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Chức năng nhanh ─────────────────────────

// Tiêu đề từng mục, có thể kèm chữ bấm bên phải.
class _SectionTitle extends StatelessWidget {
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle(this.text, {this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
      ],
    );
  }
}

// Ô chức năng nhanh dạng dọc: icon trên, tiêu đề và mô tả dưới.
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        background,
                        Color.lerp(background, Colors.white, 0.45)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: _textGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Thông báo ─────────────────────────

// Dữ liệu một thông báo.
class _Notice {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;

  const _Notice({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });
}

// TODO: thay bằng thông báo thật từ Firestore. Hiện là dữ liệu mẫu.
const _sampleNotices = [
  _Notice(
    icon: Icons.priority_high_rounded,
    color: Color(0xFFF59E0B),
    background: Color(0xFFFEF3C7),
    title: 'Nhắc lịch khám ngày mai',
    subtitle: 'Khoa Tim mạch · 08:00',
  ),
  _Notice(
    icon: Icons.check_rounded,
    color: Color(0xFF10B981),
    background: Color(0xFFD1FAE5),
    title: 'Lịch khám đã được xác nhận',
    subtitle: '24/09/2026 · Số #12',
  ),
  _Notice(
    icon: Icons.info_outline_rounded,
    color: Color(0xFF8B5CF6),
    background: Color(0xFFEDE9FE),
    title: 'Hướng dẫn chuẩn bị khám',
    subtitle: 'Nhịn ăn 6 tiếng trước khi khám',
  ),
];

// Một dòng thông báo: icon, tiêu đề, mô tả, mũi tên.
class _NoticeTile extends StatelessWidget {
  final _Notice notice;
  const _NoticeTile(this.notice);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notice.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notice.icon, size: 23, color: notice.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notice.subtitle,
                  style: const TextStyle(fontSize: 12.5, color: _textGrey),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}
