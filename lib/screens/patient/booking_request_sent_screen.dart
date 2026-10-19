import 'package:flutter/material.dart';
import '../../widgets/appointment_card.dart';
import '../../models/appointment_item.dart';

class BookingRequestSentScreen extends StatelessWidget {
  final String? requestCode;
  final String? hospitalName;
  final String? departmentName;
  final String? dateLabel;
  final String? shiftLabel;
  final VoidCallback? onViewStatus;
  final VoidCallback? onGoHome;

  const BookingRequestSentScreen({
    super.key,
    this.requestCode,
    this.hospitalName,
    this.departmentName,
    this.dateLabel,
    this.shiftLabel,
    this.onViewStatus,
    this.onGoHome,
  });

  /// Đọc 1 giá trị từ arguments của route: Map thì lấy theo [mapKey],
  /// còn lại (MyAppointmentItem...) thì đọc bằng [fromObject]. Không có -> null.
  static String? _arg(
    Object? args,
    String mapKey,
    dynamic Function(dynamic a) fromObject,
  ) {
    if (args == null) return null;
    dynamic value;
    if (args is Map) {
      value = args[mapKey];
    } else {
      try {
        value = fromObject(args);
      } catch (_) {
        value = null;
      }
    }
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFF8A5B00);
    const empty = '—';

    final args = ModalRoute.of(context)?.settings.arguments;
    final code =
        requestCode ?? _arg(args, 'requestCode', (a) => a.id) ?? empty;
    final hospital =
        hospitalName ??
        _arg(args, 'hospitalName', (a) => a.hospitalName) ??
        empty;
    final department =
        departmentName ??
        _arg(args, 'departmentName', (a) => a.departmentName) ??
        empty;
    final date =
        dateLabel ?? _arg(args, 'dateLabel', (a) => a.dateLabel) ?? empty;
    final shift =
        shiftLabel ?? _arg(args, 'shiftLabel', (a) => a.timeLabel) ?? empty;

    return Scaffold(
      backgroundColor: ApptColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          child: Column(
            children: [
              // ── Biểu tượng đồng hồ cát ──
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: Color(0xFFB7791F),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Đã gửi yêu cầu đặt lịch',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: gold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bệnh viện đang xét duyệt dựa trên số bác sĩ\nkhám ngày hôm đó',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: ApptColors.textGrey,
                ),
              ),
              const SizedBox(height: 22),

              // ── Thẻ thông tin yêu cầu ──
              ApptCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÃ YÊU CẦU',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: ApptColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Mã dài thì tự thu nhỏ cho vừa khung
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: ApptColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusChip(AppointmentStatus.pending),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: ApptColors.border),
                    const SizedBox(height: 6),
                    DetailRow(
                      label: 'Bệnh viện',
                      value: hospital,
                      alignValueEnd: true,
                    ),
                    DetailRow(
                      label: 'Chuyên khoa',
                      value: department,
                      alignValueEnd: true,
                    ),
                    DetailRow(
                      label: 'Ngày khám',
                      value: date,
                      alignValueEnd: true,
                    ),
                    DetailRow(label: 'Ca', value: shift, alignValueEnd: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Thông báo ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: ApptColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn sẽ nhận thông báo ngay khi bệnh viện xác nhận, '
                        'kèm số thứ tự và giờ khám chính thức.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: ApptColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Nút hành động ──
              ApptButton(
                text: 'Xem trạng thái đặt lịch',
                onPressed: onViewStatus,
              ),
              const SizedBox(height: 12),
              ApptButton(
                text: 'Về trang chủ',
                background: Colors.white,
                foreground: ApptColors.textDark,
                borderColor: ApptColors.border,
                // Mặc định quay về màn hình đầu tiên của ứng dụng
                onPressed:
                    onGoHome ??
                    () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}