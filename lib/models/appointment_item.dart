// lib/models/appointment_item.dart

import 'package:flutter/material.dart';

enum AppointmentStatus {
  pending,    // Chờ duyệt
  approved,   // Đã xác nhận
  cancelled,  // Đã hủy
}

class MyAppointmentItem {
  final String id;
  final String hospitalName;
  final String subtitle;
  final AppointmentStatus status;
  final String departmentName;
  final String dateLabel;
  final String timeLabel;

  const MyAppointmentItem({
    required this.id,
    required this.hospitalName,
    required this.subtitle,
    required this.status,
    this.departmentName = 'Chuyên khoa',
    this.dateLabel = '—',
    this.timeLabel = '—',
  });
}

/// Map trangThaiId từ Firestore → AppointmentStatus
AppointmentStatus statusFromTrangThaiId(dynamic trangThaiId) {
  final id = int.tryParse(trangThaiId?.toString() ?? '') ?? 0;
  switch (id) {
    case 1:
      return AppointmentStatus.pending;
    case 2:
      return AppointmentStatus.approved;
    case 3:
    case 4:
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.pending;
  }
}

/// Extension để StatusChip dùng được .label / .background / ...
extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Chờ duyệt';
      case AppointmentStatus.approved:
        return 'Đã xác nhận';
      case AppointmentStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get background {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFF6DD);
      case AppointmentStatus.approved:
        return const Color(0xFFE8F5E9);
      case AppointmentStatus.cancelled:
        return const Color(0xFFFDECEC);
    }
  }

  Color get foreground {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFF59E0B);
      case AppointmentStatus.approved:
        return const Color(0xFF22C55E);
      case AppointmentStatus.cancelled:
        return const Color(0xFFE53935);
    }
  }

  Color get borderColor {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFE3A0);
      case AppointmentStatus.approved:
        return const Color(0xFFBBF7D0);
      case AppointmentStatus.cancelled:
        return const Color(0xFFF8CACA);
    }
  }
}