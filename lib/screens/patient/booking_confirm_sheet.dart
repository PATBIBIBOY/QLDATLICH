import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const green = Color(0xFF5B8C3E);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF757575);
  static const border = Color(0xFFE6E9F0);
}

Future<bool?> showBookingConfirmSheet(
  BuildContext context, {
  required String hospitalName,
  required List<Map<String, String>> bookingDetails,
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

  /// Một dòng thông tin nhỏ: icon + chữ.
  Widget _metaRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: color ?? _C.textGrey),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: color ?? _C.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ của từng khoa đã chọn.
  Widget _departmentTile(int index, Map<String, String> detail) {
    final department = detail['departmentName'] ?? '';
    final room = detail['roomName'] ?? '';
    final shift = detail['shiftLabel'] ?? '';
    final date = (detail['dateLabel'] ?? '').isNotEmpty
        ? detail['dateLabel']!
        : dateLabel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Số thứ tự của khoa
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primary, _C.primaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department.isEmpty ? 'Chuyên khoa' : department,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.green,
                  ),
                ),
                if (room.isNotEmpty)
                  _metaRow(Icons.meeting_room_outlined, room),
                if (shift.isNotEmpty)
                  _metaRow(
                    Icons.schedule_rounded,
                    shift,
                    color: _C.textDark,
                  ),
                if (date.isNotEmpty)
                  _metaRow(Icons.calendar_today_rounded, date),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Thanh kéo ──
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // ── Tiêu đề ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.primary, _C.primaryDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Xác nhận đặt lịch khám',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _C.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kiểm tra thông tin trước khi gửi yêu cầu',
                  style: TextStyle(fontSize: 13, color: _C.textGrey),
                ),
              ],
            ),
          ),

          // ── Nội dung (cuộn được khi chọn nhiều khoa) ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thẻ bệnh viện
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _C.primary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                size: 24,
                                color: _C.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BỆNH VIỆN',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: _C.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hospitalName,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                      color: _C.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty)
                          _metaRow(Icons.location_on_rounded, address),
                        if (bhytNote.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 15,
                                  color: _C.primaryDark,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    bhytNote,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _C.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tiêu đề danh sách khoa + số lượng
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lịch khám đã chọn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${bookingDetails.length} chuyên khoa',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _C.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mỗi khoa 1 thẻ
                  ...List.generate(
                    bookingDetails.length,
                    (i) => Padding(
                      padding: EdgeInsets.only(
                        bottom: i == bookingDetails.length - 1 ? 0 : 10,
                      ),
                      child: _departmentTile(i, bookingDetails[i]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Lưu ý
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6DD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE3A0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sau khi xác nhận, đơn khám sẽ được chuyển để bệnh viện '
                            'xét duyệt lịch hẹn.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Color(0xFF8A5B00),
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

          // ── Nút hành động (luôn nằm dưới cùng, không bị cuộn mất) ──
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _SheetButton(
                    text: 'Hủy',
                    icon: Icons.close_rounded,
                    filled: false,
                    color: const Color(0xFFE53935),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _SheetButton(
                    text: 'Xác nhận đặt lịch',
                    icon: Icons.check_rounded,
                    filled: true,
                    color: _C.primary,
                    onPressed: () => Navigator.pop(context, true),
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

/// Nút của hộp thoại: [filled] = nền đặc (Xác nhận), false = viền (Hủy).
class _SheetButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback onPressed;

  const _SheetButton({
    required this.text,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: filled ? Colors.white : color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color,
            ),
          ),
        ),
      ],
    );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(colors: [_C.primary, _C.primaryDark])
            : null,
        color: filled ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: filled ? null : Border.all(color: color.withOpacity(0.5)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: _C.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(child: content),
        ),
      ),
    );
  }
}