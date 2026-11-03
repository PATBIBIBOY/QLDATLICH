import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';
import '../../widgets/appointment_card.dart'; // Đảm bảo file này chứa StatusChip
import '../../utils/app_snackbar.dart';

/// Chỉnh độ trong suốt an toàn cho mọi phiên bản Flutter (thay withOpacity).
extension _ColorX on Color {
  Color o(double opacity) => withAlpha((opacity * 255).round().clamp(0, 255));
}

// ───────────────────────── CONSTANTS ─────────────────────────
const Color _primary = Color(0xFF0B63CE);
const Color _primaryDark = Color(0xFF084A9E);
const Color _primarySoft = Color(0xFFE8F1FC);
const Color _green = Color(0xFF15935F);
const Color _greenSoft = Color(0xFFE3F6EE);
const Color _red = Color(0xFFDC2626);
const Color _amber = Color(0xFFD97706);
const Color _amberSoft = Color(0xFFFEF3C7);
const Color _dark = Color(0xFF0B1F3A);
const Color _grey = Color(0xFF5B6B80);
const Color _border = Color(0xFFE3EAF2);

// ───────────────────────── WIDGETS ─────────────────────────

class AppointmentDetailHeader extends StatelessWidget {
  const AppointmentDetailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Material(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: _primary,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Chi tiết lịch khám',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Thông tin & trạng thái',
                  style: TextStyle(fontSize: 11.5, color: _grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class AppointmentStatusHero extends StatelessWidget {
  final bool isPending;
  final bool isApproved;
  final bool isCancelled;

  const AppointmentStatusHero({
    super.key,
    required this.isPending,
    required this.isApproved,
    required this.isCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String message;
    final List<Color> colors;

    if (isCancelled) {
      icon = Icons.event_busy_rounded;
      title = 'Lịch khám đã bị hủy';
      message = 'Rất tiếc, lịch khám này không còn hiệu lực.';
      colors = const [Color(0xFFEF4444), Color(0xFFB91C1C)];
    } else if (isApproved) {
      icon = Icons.verified_rounded;
      title = 'Lịch khám đã được duyệt';
      message = 'Vui lòng đến đúng ngày và khung giờ đã đặt.';
      colors = const [Color(0xFF1FB57A), Color(0xFF0E7A52)];
    } else if (isPending) {
      icon = Icons.hourglass_top_rounded;
      title = 'Đang chờ bệnh viện xác nhận';
      message = 'Chúng tôi sẽ thông báo ngay khi lịch khám được duyệt.';
      colors = const [Color(0xFFF59E0B), Color(0xFFC2650A)];
    } else {
      icon = Icons.event_note_rounded;
      title = 'Thông tin lịch khám';
      message = 'Chi tiết lịch khám của bạn.';
      colors = const [Color(0xFF1F8FE8), _primaryDark];
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.last.o(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.o(0.09),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -46,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.o(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.o(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.o(0.3)),
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
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.white.o(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isPending || isApproved) ...[
                  const SizedBox(height: 20),
                  AppointmentStatusSteps(
                    completed: isApproved ? 3 : 1,
                    current: isApproved ? null : 1,
                    accent: colors.last,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentStatusSteps extends StatelessWidget {
  final int completed;
  final int? current;
  final Color accent;

  const AppointmentStatusSteps({
    super.key,
    required this.completed,
    required this.current,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Đã gửi', 'Chờ duyệt', 'Đã duyệt'];

    Widget circle(int step) {
      final done = step < completed;
      final isCurrent = step == current;
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? Colors.white : Colors.white.o(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.o(done || isCurrent ? 1 : 0.45),
            width: 2,
          ),
        ),
        child: done
            ? Icon(Icons.check_rounded, size: 16, color: accent)
            : isCurrent
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
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
                  color: Colors.white.o(lineDone ? 1 : 0.35),
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
                color: Colors.white.o(highlighted ? 1 : 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class AppointmentInfoCard extends StatelessWidget {
  final MyAppointmentItem appointment;
  final AppointmentStatus status;

  const AppointmentInfoCard({
    super.key,
    required this.appointment,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.o(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Đầu thẻ: bệnh viện + trạng thái
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 26,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.hospitalName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 13,
                              color: _primary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                appointment.departmentName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
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
          ),

          // Đường cắt kiểu vé: hai nửa tròn hai bên
          Row(
            children: [
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
              ),
              const Expanded(child: _DashedLine()),
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Column(
              children: [
                AppointmentInfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Mã lịch hẹn',
                  value: appointment.id,
                  trailing: Material(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: appointment.id),
                        );
                        if (!context.mounted) return;
                        context.showAppSnackBar(
                          title: 'Sao chép thành công',
                          message: 'Đã sao chép mã lịch hẹn',
                          type: SnackBarType.success,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: const Tooltip(
                        message: 'Sao chép mã',
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.copy_rounded,
                            size: 17,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEF2F7)),
                AppointmentInfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Ngày khám',
                  value: appointment.dateLabel,
                ),
                const Divider(height: 1, color: Color(0xFFEEF2F7)),
                AppointmentInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Khung giờ',
                  value: appointment.timeLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Đường nét đứt dùng cho đường cắt của thẻ.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final count = (c.maxWidth / 9).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: 5, height: 1.5, color: _border),
          ),
        );
      },
    );
  }
}

class AppointmentInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const AppointmentInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: _primary),
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppointmentPendingSection extends StatelessWidget {
  final VoidCallback onCancel;

  const AppointmentPendingSection({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _amberSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCD98A)),
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
                    color: Color(0xFF7A4A07),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded, size: 19),
          label: const Text(
            'Hủy lịch khám này',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _red,
            backgroundColor: Colors.white,
            side: BorderSide(color: _red.o(0.45), width: 1.3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class AppointmentApprovedSection extends StatelessWidget {
  final Future<Map<String, dynamic>?> Function() fetchDetails;
  final VoidCallback onRefresh;
  final VoidCallback onTrack;

  const AppointmentApprovedSection({
    super.key,
    required this.fetchDetails,
    required this.onRefresh,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(child: _statSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _statSkeleton()),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _greenSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _green.o(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: _green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Không thể tải thông tin số thứ tự. Vui lòng thử lại sau.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF0E6B47),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppointmentStatTile(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Số thứ tự của bạn',
                    value: soThuTu,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppointmentStatTile(
                    icon: Icons.timer_outlined,
                    label: 'Thời gian chờ ước tính',
                    value: thoiGianCho,
                    color: _amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text(
                'Làm mới trạng thái',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
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
              onPressed: onTrack,
              icon: const Icon(Icons.track_changes_rounded, size: 19),
              label: const Text(
                'Bấm Vào Đây để theo dõi trực tiếp',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                backgroundColor: Colors.white,
                side: BorderSide(color: _primary.o(0.45), width: 1.3),
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

  /// Ô giả khi đang tải số thứ tự (nhẹ nhàng hơn vòng xoay).
  Widget _statSkeleton() {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3, color: _primary),
        ),
      ),
    );
  }
}

class AppointmentStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const AppointmentStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: color.o(0.09),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.o(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
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
}

class AppointmentCancelledSection extends StatelessWidget {
  final VoidCallback onGoToBooking;
  final VoidCallback onDelete;

  const AppointmentCancelledSection({
    super.key,
    required this.onGoToBooking,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: _primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gợi ý cho bạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SuggestionTile(
          background: _greenSoft,
          accent: _green,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.access_time_filled_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          title: 'Đặt lịch ca khác',
          subtitle: 'Xem các khung giờ còn trống trong ngày',
          onTap: onGoToBooking,
        ),
        const SizedBox(height: 10),
        SuggestionTile(
          background: _primarySoft,
          accent: _primary,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          title: 'Chọn ngày khác',
          subtitle: 'Xem lịch trống các ngày tới',
          onTap: onGoToBooking,
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: onGoToBooking,
          icon: const Icon(Icons.event_available_rounded, size: 20),
          label: const Text(
            'Đặt lịch khám mới',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
          label: const Text(
            'Xóa lịch khám này',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

class AppointmentDialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;

  const AppointmentDialogInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primarySoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _primary),
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
}

class SuggestionTile extends StatelessWidget {
  final Color background;
  final Color accent;
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SuggestionTile({
    super.key,
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
            border: Border.all(color: accent.o(0.2)),
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
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _grey),
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
              style: const TextStyle(fontSize: 13, color: _grey),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13, color: _grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}