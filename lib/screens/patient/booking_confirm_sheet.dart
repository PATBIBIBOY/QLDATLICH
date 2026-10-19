import 'package:flutter/material.dart';

// Giả sử bạn có file màu riêng, nếu không hãy thay ApptColors bằng mã màu của bạn
class ApptColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color green = Color(0xFF5B8C3E);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color link = Color(0xFF1976D2);
}

// Widget nút bấm giả lập (thay bằng widget nút bấm thực tế của bạn)
class ApptButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color background;
  final VoidCallback onPressed;

  const ApptButton({
    super.key,
    required this.text,
    required this.icon,
    this.background = const Color(0xFF2196F3),
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<bool?> showBookingConfirmSheet(
  BuildContext context, {
  required String hospitalName,
  required List<Map<String, String>> bookingDetails, // Danh sách chi tiết từng khoa
  required String dateLabel,
  required String address,
  required String bhytNote,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookingConfirmSheet(
      hospitalName: hospitalName,
      bookingDetails: bookingDetails,
      dateLabel: dateLabel,
      address: address,
      bhytNote: bhytNote,
    ),
  );
}

class BookingConfirmSheet extends StatelessWidget {
  final String hospitalName;
  final List<Map<String, String>> bookingDetails;
  final String dateLabel;
  final String address;
  final String bhytNote;

  const BookingConfirmSheet({
    super.key,
    required this.hospitalName,
    required this.bookingDetails,
    required this.dateLabel,
    required this.address,
    required this.bhytNote,
  });

  Widget _block({
    required IconData icon,
    required String caption,
    required List<Widget> lines,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ApptColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: ApptColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ApptColors.textGrey,
                ),
              ),
              const SizedBox(height: 3),
              ...lines,
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gộp thông tin các khoa lại để hiển thị
    final departmentsText = bookingDetails.map((e) => e['departmentName'] ?? '').join(', ');
    final shiftsText = bookingDetails.map((e) => e['shiftLabel'] ?? '').join('; ');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ApptColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded, size: 32, color: ApptColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Xác nhận đặt lịch khám',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ApptColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kiểm tra thông tin trước khi gửi yêu cầu',
              style: TextStyle(fontSize: 13, color: ApptColors.textGrey),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: ApptColors.border),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _block(
                    icon: Icons.apartment_rounded,
                    caption: 'BỆNH VIỆN',
                    lines: [
                      Text(hospitalName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ApptColors.textDark)),
                      const SizedBox(height: 2),
                      Text(departmentsText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ApptColors.green)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _block(
                    icon: Icons.schedule_rounded,
                    caption: 'THỜI GIAN KHÁM',
                    lines: [
                      Text(shiftsText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ApptColors.textDark)),
                      const SizedBox(height: 2),
                      Text(dateLabel, style: const TextStyle(fontSize: 13, color: ApptColors.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _block(
                    icon: Icons.location_on_rounded,
                    caption: 'ĐỊA CHỈ CƠ SỞ',
                    lines: [
                      Text(address, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ApptColors.textDark)),
                      const SizedBox(height: 3),
                      Text(bhytNote, style: const TextStyle(fontSize: 13, color: ApptColors.link)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      'Sau khi xác nhận, đơn khám sẽ được chuyển để bệnh viện xét duyệt lịch hẹn.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF8A5B00)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ApptButton(
                    text: 'Hủy',
                    icon: Icons.close_rounded,
                    background: const Color(0xFFE53935),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ApptButton(
                    text: 'Xác nhận',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
            // Chừa khoảng trống cho bàn phím hoặc safe area
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}