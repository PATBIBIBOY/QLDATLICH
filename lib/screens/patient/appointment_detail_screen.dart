import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';
import '../../widgets/appointment_card.dart';

/// Chi tiết 1 lịch khám. Nhận [MyAppointmentItem] làm argument.
class AppointmentDetailScreen extends StatelessWidget {
  final MyAppointmentItem appointment;
  final String? currentQueue;
  final String? estimatedMinutes;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.currentQueue,
    this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final isCancelled = status == AppointmentStatus.cancelled;
    final isPending = status == AppointmentStatus.pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: const Text(
                'Chi tiết lịch khám',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  children: [
                    ApptCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên bệnh viện + trạng thái
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appointment.hospitalName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusChip(status),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Chuyên khoa
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.medical_services_outlined,
                                  size: 15,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment.departmentName,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF757575),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 6),

                          DetailRow(label: 'Mã lịch hẹn', value: appointment.id),
                          DetailRow(label: 'Ngày khám', value: appointment.dateLabel),
                          DetailRow(label: 'Khung giờ', value: appointment.timeLabel),

                          // ── Chờ duyệt ──
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6DD),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFFE3A0)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lịch khám đang chờ bệnh viện xác nhận. Bạn có thể hủy nếu có thay đổi.',
                                      style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF8A5B00)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showCancelDialog(context),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Hủy lịch khám này', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],

                          // ── Đã duyệt ──
                          if (status == AppointmentStatus.approved) ...[
                            const SizedBox(height: 6),
                            const Divider(height: 1, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 6),
                            if (currentQueue != null)
                              DetailRow(
                                label: 'Số TT khám hiện tại',
                                value: currentQueue!,
                                valueColor: const Color(0xFF1976D2),
                                labelWidth: 150,
                              ),
                            if (estimatedMinutes != null)
                              DetailRow(
                                label: 'Thời gian chờ ước tính',
                                value: estimatedMinutes!,
                                valueColor: const Color(0xFFF59E0B),
                                labelWidth: 150,
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đang cập nhật số thứ tự...')),
                                  );
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Làm mới trạng thái', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],

                          // ── Đã hủy ──
                          if (isCancelled) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF8CACA)),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin lỗi quý khách',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Lịch khám của bạn đã bị hủy do phòng khám đã đủ số lượng bệnh nhân hoặc bác sĩ có lịch đột xuất.',
                                    style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1A1A1A)),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Chúng tôi rất tiếc về sự bất tiện này.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Gợi ý giải quyết',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            ),
                            const SizedBox(height: 10),
                            _SuggestionTile(
                              background: const Color(0xFFE8F5E9),
                              leading: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                              ),
                              title: 'Đặt lịch ca khác',
                              subtitle: 'Xem các khung giờ còn trống trong ngày',
                              onTap: () => _goToBooking(context),
                            ),
                            const SizedBox(height: 10),
                            _SuggestionTile(
                              background: const Color(0xFFEEF1F6),
                              leading: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle),
                                child: const Text('2', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                              title: 'Chọn ngày khác',
                              subtitle: 'Xem lịch trống các ngày tới',
                              onTap: () => _goToBooking(context),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Nút dưới thẻ khi đã hủy
                    if (isCancelled) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _goToBooking(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Đặt lịch ca khác ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.patientMain,
                            (route) => route.isFirst,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1A1A),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Về trang chủ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
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

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy lịch'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch khám này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Gọi API cập nhật trạng thái thành cancelled
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi yêu cầu hủy lịch khám'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Đồng ý hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _goToBooking(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientMain,
      (route) => route.isFirst,
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final Color background;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.background,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF757575)),
          ],
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
          const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
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