import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';
import '../../providers/lich_hen_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/patient_widget/appointment_detail_widget.dart';

class AppTheme {
  // Constructor private để ngăn chặn việc khởi tạo class này
  AppTheme._();

  // --- Màu sắc ---
  static const Color _bg = Color(0xFFF7F7F8);
  static const Color _blue = Color(0xFF2196F3);
  static const Color _blueDark = Color(0xFF1976D2);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFE53935);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _grey = Color(0xFF757575);
  static const Color _border = Color(0xFFE0E0E0);
}

class AppointmentDetailScreen extends StatefulWidget {
  final MyAppointmentItem appointment;
  final String? currentQueue;
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

  /// Hàm lấy chi tiết lịch hẹn mới nhất từ Firebase dựa trên ID
  Future<Map<String, dynamic>?> _fetchAppointmentDetails() async {
    try {
      final cleanId = widget.appointment.id
          .replaceFirst('#', '')
          .split(' ')
          .first;

      final snapshot = await FirebaseFirestore.instance
          .collection('LichHen')
          .where('id', isEqualTo: cleanId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return snapshot.docs.first.data();

      final docSnapshot = await FirebaseFirestore.instance
          .collection('LichHen')
          .doc(cleanId)
          .get();
      if (docSnapshot.exists) return docSnapshot.data();

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
      backgroundColor: AppTheme._bg,
      body: SafeArea(
        child: Column(
          children: [
            const AppointmentDetailHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppointmentStatusHero(
                      isPending: isPending,
                      isApproved: isApproved,
                      isCancelled: isCancelled,
                    ),
                    const SizedBox(height: 14),
                    AppointmentInfoCard(
                      appointment: widget.appointment,
                      status: status,
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 14),
                      AppointmentPendingSection(
                        onCancel: () => _showCancelDialog(context),
                      ),
                    ],
                    if (isApproved) ...[
                      const SizedBox(height: 14),
                      AppointmentApprovedSection(
                        fetchDetails: _fetchAppointmentDetails,
                        onRefresh: () {
                          setState(() {});
                          context.showAppSnackBar(
                            title: 'Đang cập nhật lịch hẹn',
                            message: 'Đang cập nhật số thứ tự mới nhất...',
                            duration: const Duration(seconds: 1),
                          );
                        },
                        onTrack: () => Navigator.pushNamed(
                          context,
                          AppRoutes.appointmentTracking,
                          arguments: widget.appointment,
                        ),
                      ),
                    ],
                    if (isCancelled) ...[
                      const SizedBox(height: 14),
                      AppointmentCancelledSection(
                        onGoToBooking: _goToBooking,
                        onDelete: () => _showDeleteDialog(context),
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

  // ───────────────────────── LOGIC & ACTIONS ─────────────────────────

  void _goToBooking() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientMain,
      (route) => route.isFirst,
    );
  }

  Future<void> _cancelAppointment(BuildContext context) async {
    final provider = context.read<LichHenProvider>();
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

      if (!navigator.canPop()) return;
      navigator.pop(); 

      if (!context.mounted) return;

      context.showAppSnackBar(
        title: 'Hủy lịch thành công',
        message: 'Đã hủy lịch khám thành công',
        type: SnackBarType.success,
      );

      if (navigator.canPop()) {
        navigator.pop(true); 
      }
    } catch (e) {
      if (!navigator.canPop()) return;
      navigator.pop(); // Đóng vòng quay

      if (!context.mounted) return;
      context.showAppSnackBar(
        title: 'Hủy lịch thất bại',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _deleteAppointment(BuildContext context) async {
    final provider = context.read<LichHenProvider>();
    final navigator = Navigator.of(context);

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
      context.showAppSnackBar(
        title: 'Xóa lịch thành công',
        message: 'Đã xóa lịch khám',
        type: SnackBarType.success,
      );
      navigator.pop(); // quay lại danh sách lịch hẹn
    } catch (e) {
      navigator.pop(); // đóng vòng quay, ở lại màn hình chi tiết
      context.showAppSnackBar(
        title: 'Xóa lịch thất bại',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: SnackBarType.error,
      );
    }
  }

  // ───────────────────────── DIALOGS ─────────────────────────

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
                          color: AppTheme._red.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppTheme._red.withOpacity(0.12),
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
                              color: AppTheme._red.withOpacity(0.35),
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
                    color: AppTheme._dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có chắc chắn muốn hủy lịch khám này không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme._grey,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme._border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppointmentDialogInfoRow(
                        icon: Icons.local_hospital_rounded,
                        text: widget.appointment.hospitalName,
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      AppointmentDialogInfoRow(
                        icon: Icons.calendar_month_rounded,
                        text: widget.appointment.dateLabel,
                      ),
                      const SizedBox(height: 10),
                      AppointmentDialogInfoRow(
                        icon: Icons.schedule_rounded,
                        text: widget.appointment.timeLabel,
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
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppTheme._red,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hành động này không thể hoàn tác.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme._red,
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
                          foregroundColor: AppTheme._dark,
                          side: const BorderSide(color: AppTheme._border),
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
                          backgroundColor: AppTheme._red,
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
                          color: AppTheme._red.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppTheme._red.withOpacity(0.12),
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
                              color: AppTheme._red.withOpacity(0.35),
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
                    color: AppTheme._dark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lịch khám đã hủy này sẽ bị xóa khỏi danh sách của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme._grey,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme._border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppointmentDialogInfoRow(
                        icon: Icons.local_hospital_rounded, // ✅ Thêm "icon:"
                        text: widget.appointment.hospitalName, // ✅ Thêm "text:"
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      AppointmentDialogInfoRow(
                        icon: Icons.calendar_month_rounded,
                        text: widget.appointment.dateLabel,
                      ),
                      const SizedBox(height: 10),
                      AppointmentDialogInfoRow(
                        icon: Icons.schedule_rounded,
                        text: widget.appointment.timeLabel,
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
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppTheme._red,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dữ liệu bị xóa vĩnh viễn và không thể khôi phục.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme._red,
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
                          foregroundColor: AppTheme._dark,
                          side: const BorderSide(color: AppTheme._border),
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
                          Navigator.of(ctx).pop();
                          _deleteAppointment(context);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme._red,
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
}
