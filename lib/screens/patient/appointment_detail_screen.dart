import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';
import '../../providers/lich_hen_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/patient_widget/appointment_detail_widget.dart';
import '../../widgets/patient_widget/appointment_ticket_widget.dart';
import '../../widgets/patient_widget/book_appointment_widget.dart'
    show AppTheme;

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

  /// _fetchAppointmentDetails: lấy chi tiết lịch hẹn mới nhất từ Firestore theo mã lịch.
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

  /// _openTicket: dựng vé khám điện tử từ dữ liệu lịch hẹn rồi mở bảng xem trước và chia sẻ.
  void _openTicket(Map<String, dynamic> data) {
    final appointment = widget.appointment;
    final id = appointment.id.replaceFirst('#', '').split(' ').first;
    final queue = int.tryParse(data['so_thu_tu']?.toString() ?? '') ?? 0;
    final patient = (data['ten_nguoi_kham'] ?? data['tenNguoiKham'] ?? '')
        .toString();
    final qr = (data['ma_qr'] ?? data['maQr'] ?? '').toString();

    showAppointmentTicketSheet(
      context,
      hospitalName: appointment.hospitalName,
      patientName: patient.isEmpty ? 'Người bệnh' : patient,
      departmentName: appointment.departmentName,
      dateLabel: appointment.dateLabel,
      timeLabel: appointment.timeLabel,
      appointmentId: id,
      qrData: qr.isEmpty ? id : qr,
      queueNumber: queue,
    );
  }

  /// _goToBooking: quay về trang chính để đặt lịch mới.
  void _goToBooking() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.patientMain,
      (route) => route.isFirst,
    );
  }

  /// _cancelAppointment: hủy lịch hẹn, báo kết quả rồi quay lại màn hình trước.
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

      if (navigator.canPop()) navigator.pop(true);
    } catch (e) {
      if (!navigator.canPop()) return;
      navigator.pop();

      if (!context.mounted) return;
      context.showAppSnackBar(
        title: 'Hủy lịch thất bại',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: SnackBarType.error,
      );
    }
  }

  /// _deleteAppointment: xóa lịch đã hủy khỏi danh sách rồi quay lại màn hình trước.
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
      navigator.pop();
      if (!context.mounted) return;
      context.showAppSnackBar(
        title: 'Xóa lịch thành công',
        message: 'Đã xóa lịch khám',
        type: SnackBarType.success,
      );
      navigator.pop();
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      context.showAppSnackBar(
        title: 'Xóa lịch thất bại',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: SnackBarType.error,
      );
    }
  }

  /// _showCancelDialog: hiện hộp thoại xác nhận hủy lịch khám.
  void _showCancelDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmActionDialog(
        icon: Icons.event_busy_rounded,
        title: 'Hủy lịch khám?',
        message: 'Bạn có chắc chắn muốn hủy lịch khám này không?',
        warning: 'Hành động này không thể hoàn tác.',
        keepLabel: 'Giữ lịch',
        confirmLabel: 'Hủy lịch',
        confirmIcon: Icons.close_rounded,
        appointment: widget.appointment,
        onConfirm: () => _cancelAppointment(context),
      ),
    );
  }

  /// _showDeleteDialog: hiện hộp thoại xác nhận xóa lịch khám đã hủy.
  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmActionDialog(
        icon: Icons.delete_forever_rounded,
        title: 'Xóa lịch khám?',
        message: 'Lịch khám đã hủy này sẽ bị xóa khỏi danh sách của bạn.',
        warning: 'Dữ liệu bị xóa vĩnh viễn và không thể khôi phục.',
        keepLabel: 'Giữ lại',
        confirmLabel: 'Xóa',
        confirmIcon: Icons.delete_outline_rounded,
        appointment: widget.appointment,
        onConfirm: () => _deleteAppointment(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.appointment.status;
    final isCancelled = status == AppointmentStatus.cancelled;
    final isPending = status == AppointmentStatus.pending;
    final isApproved = status == AppointmentStatus.approved;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppointmentDetailHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                        onShareTicket: _openTicket,
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
}