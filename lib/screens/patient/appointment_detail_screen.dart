import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';
import '../../providers/lich_hen_provider.dart';
import '../../widgets/appointment_card.dart';

/// Chi tiết 1 lịch khám.
class AppointmentDetailScreen extends StatefulWidget {
  final MyAppointmentItem appointment;
  final String?
  currentQueue; // Giữ lại để tương thích ngược, nhưng ưu tiên lấy từ Firebase
  final String? estimatedMinutes;
  final String? benhNhanId;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.currentQueue,
    this.estimatedMinutes,
    this.benhNhanId,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  String get _benhNhanId =>
      widget.benhNhanId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  // Bảng màu
  static const Color _bg = Color(0xFFF7F7F8);
  static const Color _blue = Color(0xFF2196F3);
  static const Color _blueDark = Color(0xFF1976D2);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFE53935);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _grey = Color(0xFF757575);
  static const Color _border = Color(0xFFE0E0E0);


  /// Hàm lấy chi tiết lịch hẹn mới nhất từ Firebase dựa trên ID
  Future<Map<String, dynamic>?> _fetchAppointmentDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('lich_hen')
          .where('id', isEqualTo: widget.appointment.id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi lấy chi tiết lịch hẹn: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.appointment.status;
    final isCancelled = status == AppointmentStatus.cancelled;
    final isPending = status == AppointmentStatus.pending;
    final isApproved = status == AppointmentStatus.approved;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusHero(isPending, isApproved, isCancelled),
                    const SizedBox(height: 14),
                    _buildInfoCard(context, status),
                    if (isPending) ...[
                      const SizedBox(height: 14),
                      _buildPendingSection(context),
                    ],
                    if (isApproved) ...[
                      const SizedBox(height: 14),
                      _buildApprovedSection(
                        context,
                      ), // Đã cập nhật để lấy data real-time
                    ],
                    if (isCancelled) ...[
                      const SizedBox(height: 14),
                      _buildCancelledSection(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── HEADER ─────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.grey.shade100,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: _dark),
              ),
            ),
          ),
          const Text(
            'Chi tiết lịch khám',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _dark,
            ),
          ),
          const SizedBox(width: 36), // Cân bằng layout
        ],
      ),
    );
  }

  // ───────────────────────── BANNER TRẠNG THÁI ─────────────────────────
  Widget _buildStatusHero(bool isPending, bool isApproved, bool isCancelled) {
    final IconData icon;
    final String title;
    final String message;
    final List<Color> colors;

    if (isCancelled) {
      icon = Icons.event_busy_rounded;
      title = 'Lịch khám đã bị hủy';
      message = 'Rất tiếc, lịch khám này không còn hiệu lực.';
      colors = const [Color(0xFFEF5350), Color(0xFFD32F2F)];
    } else if (isApproved) {
      icon = Icons.verified_rounded;
      title = 'Lịch khám đã được duyệt';
      message = 'Vui lòng đến đúng ngày và khung giờ đã đặt.';
      colors = const [Color(0xFF66BB6A), Color(0xFF2E7D32)];
    } else if (isPending) {
      icon = Icons.hourglass_top_rounded;
      title = 'Đang chờ bệnh viện xác nhận';
      message = 'Chúng tôi sẽ thông báo ngay khi lịch khám được duyệt.';
      colors = const [Color(0xFFFFB74D), Color(0xFFF57C00)];
    } else {
      icon = Icons.event_note_rounded;
      title = 'Thông tin lịch khám';
      message = 'Chi tiết lịch khám của bạn.';
      colors = const [Color(0xFF42A5F5), Color(0xFF1976D2)];
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPending || isApproved) ...[
            const SizedBox(height: 18),
            _buildSteps(
              completed: isApproved ? 3 : 1,
              current: isApproved ? null : 1,
              accent: colors.last,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSteps({
    required int completed,
    required int? current,
    required Color accent,
  }) {
    const labels = ['Đã gửi', 'Chờ duyệt', 'Đã duyệt'];

    Widget circle(int step) {
      final done = step < completed;
      final isCurrent = step == current;
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? Colors.white : Colors.white.withOpacity(0.20),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(done || isCurrent ? 1 : 0.45),
            width: 2,
          ),
        ),
        child: done
            ? Icon(Icons.check_rounded, size: 16, color: accent)
            : isCurrent
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (i) {
        if (i.isOdd) {
          final lineDone = (i ~/ 2) + 1 < completed;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 6, right: 6),
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(lineDone ? 1 : 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }
        final step = i ~/ 2;
        final highlighted = step < completed || step == current;
        return Column(
          children: [
            circle(step),
            const SizedBox(height: 5),
            Text(
              labels[step],
              style: TextStyle(
                fontSize: 11,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white.withOpacity(highlighted ? 1 : 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ───────────────────────── THÔNG TIN LỊCH KHÁM ─────────────────────────
  Widget _buildInfoCard(BuildContext context, AppointmentStatus status) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_blue.withOpacity(0.18), _blue.withOpacity(0.07)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 25,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment.hospitalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 13,
                            color: _blue,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              widget.appointment.departmentName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _border),
          _infoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Mã lịch hẹn',
            value: widget.appointment.id,
            trailing: IconButton(
              tooltip: 'Sao chép mã',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 18, color: _blue),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: widget.appointment.id),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mã lịch hẹn'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Ngày khám',
            value: widget.appointment.dateLabel,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _infoRow(
            icon: Icons.schedule_rounded,
            label: 'Khung giờ',
            value: widget.appointment.timeLabel,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ───────────────────────── CHỜ DUYỆT ─────────────────────────
  Widget _buildPendingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6DD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE3A0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: _amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lịch khám đang chờ bệnh viện xác nhận. Bạn có thể hủy nếu có thay đổi.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFF8A5B00),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _showCancelDialog(context),
          icon: const Icon(Icons.close_rounded, size: 19),
          label: const Text(
            'Hủy lịch khám này',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            backgroundColor: Colors.white,
            side: BorderSide(color: _red.withOpacity(0.5), width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── ĐÃ DUYỆT (CÓ FETCH DATA REAL-TIME) ─────────────────────────
  Widget _buildApprovedSection(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchAppointmentDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // ✅ Đã sửa ở đây (nếu có)
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Không thể tải thông tin số thứ tự. Vui lòng thử lại sau.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final soThuTu = data['so_thu_tu']?.toString() ?? 'Chưa có';
        final thoiGianCho =
            data['thoi_gian_cho_uoc_tinh']?.toString() ?? '~15 phút';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ SỬA LỖI Ở ĐÂY: Đổi thành CrossAxisAlignment.start hoặc xóa dòng này đi (mặc định là start)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _statTile(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Số TT của bạn',
                    value: soThuTu,
                    color: _blueDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statTile(
                    icon: Icons.timer_outlined,
                    label: 'Thời gian chờ ước tính',
                    value: thoiGianCho,
                    color: _amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Force rebuild to fetch data again
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang cập nhật số thứ tự mới nhất...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text(
                'Làm mới trạng thái',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blueDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.myAppointments,
                  arguments: widget.appointment,
                );
              },
              icon: const Icon(Icons.track_changes_rounded, size: 19),
              label: const Text(
                'Theo dõi lịch khám chi tiết',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blueDark,
                side: BorderSide(color: _blueDark.withOpacity(0.5), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: _grey,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── ĐÃ HỦY ─────────────────────────
  Widget _buildCancelledSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: _blue,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gợi ý giải quyết',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SuggestionTile(
          background: const Color(0xFFE8F5E9),
          accent: _green,
          leading: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          title: 'Đặt lịch ca khác',
          subtitle: 'Xem các khung giờ còn trống trong ngày',
          onTap: () => _goToBooking(context),
        ),
        const SizedBox(height: 10),
        _SuggestionTile(
          background: const Color(0xFFE8F1FB),
          accent: _blueDark,
          leading: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _blueDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          title: 'Chọn ngày khác',
          subtitle: 'Xem lịch trống các ngày tới',
          onTap: () => _goToBooking(context),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _goToBooking(context),
          icon: const Icon(Icons.event_available_rounded, size: 20),
          label: const Text(
            'Đặt lịch ca khác ngay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _blueDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.patientMain,
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.home_rounded, size: 20),
          label: const Text(
            'Về trang chủ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _dark,
            backgroundColor: Colors.white,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showDeleteDialog(context),
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          label: const Text(
            'Xóa lịch khám này',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            backgroundColor: Colors.white,
            side: BorderSide(color: _red.withOpacity(0.5), width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── HÀNH ĐỘNG ─────────────────────────
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _red.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hủy lịch khám?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có chắc chắn muốn hủy lịch khám này không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.45, color: _grey),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogInfoRow(
                        Icons.local_hospital_rounded,
                        widget.appointment.hospitalName,
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.calendar_month_rounded,
                        widget.appointment.dateLabel,
                      ),
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.schedule_rounded,
                        widget.appointment.timeLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: _red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hành động này không thể hoàn tác.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _dark,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Giữ lịch',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _cancelAppointment(context);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text(
                          'Hủy lịch',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context) async {
    final provider = context.read<LichHenProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.huyLichHen(
        benhNhanId: _benhNhanId,
        lichHenId: widget.appointment.id,
      );

      if (!navigator.canPop()) return; // Safety check
      navigator.pop(); // Đóng vòng quay

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu hủy lịch khám'),
          backgroundColor: _green,
        ),
      );
      navigator.pop(); // Quay lại danh sách
    } catch (e) {
      if (!navigator.canPop()) return;
      navigator.pop(); // Đóng vòng quay

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _red,
        ),
      );
    }
  }

  Widget _dialogInfoRow(IconData icon, String text, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: _dark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goToBooking(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientMain,
      (route) => route.isFirst,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Biểu tượng thùng rác (nảy nhẹ khi mở)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _red.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Xóa lịch khám?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lịch khám đã hủy này sẽ bị xóa khỏi danh sách của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.45, color: _grey),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogInfoRow(
                        Icons.local_hospital_rounded,
                        widget.appointment.hospitalName,
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.calendar_month_rounded,
                        widget.appointment.dateLabel,
                      ),
                      const SizedBox(height: 10),
                      _dialogInfoRow(
                        Icons.schedule_rounded,
                        widget.appointment.timeLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: _red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dữ liệu bị xóa vĩnh viễn và không thể khôi phục.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _dark,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Giữ lại',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // đóng hộp thoại xác nhận
                          _deleteAppointment(context);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  /// Xóa hẳn lịch hẹn đã hủy khỏi Firebase rồi quay lại danh sách.
  Future<void> _deleteAppointment(BuildContext context) async {
    final provider = context.read<LichHenProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
 
    // Vòng quay chờ (chặn bấm lần nữa)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
 
    try {
      await provider.xoaLichHen(
        benhNhanId: _benhNhanId,
        lichHenId: widget.appointment.id,
      );
 
      navigator.pop(); // đóng vòng quay
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã xóa lịch khám'),
          backgroundColor: _green,
        ),
      );
      navigator.pop(); // quay lại danh sách lịch hẹn
    } catch (e) {
      navigator.pop(); // đóng vòng quay, ở lại màn hình chi tiết
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _red,
        ),
      );
    }
  }

}

// ───────────────────────── WIDGET CON ─────────────────────────

class _SuggestionTile extends StatelessWidget {
  final Color background;
  final Color accent;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.background,
    required this.accent,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double? labelWidth;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth ?? 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
