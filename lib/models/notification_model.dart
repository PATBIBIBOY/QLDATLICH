import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Loại thông báo.
enum NotificationType {
  appointmentConfirmed, // Xác nhận lịch
  appointmentReminder,  // Nhắc lịch (trễ giờ, v.v.)
  appointmentCompleted, // Hoàn thành & đánh giá
  appointmentCancelled, // Hủy lịch
  system,               // Hệ thống
}

/// Trạng thái đọc.
enum NotificationStatus { unread, read }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final String? hospitalName;
  final String? departmentName;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? queueNumber;
  
  // ✅ THÊM 3 TRƯỜNG MỚI ĐỂ TRUYỀN DỮ LIỆU CHO DIALOG ĐÁNH GIÁ
  final String? lichHenId;
  final String? benhVienId;
  final String? khoaId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    this.hospitalName,
    this.departmentName,
    this.appointmentDate,
    this.appointmentTime,
    this.queueNumber,
    this.lichHenId,       // ✅
    this.benhVienId,      // ✅
    this.khoaId,          // ✅
  });

  // ───────────── Đọc từ Firestore ─────────────
  static String? _str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }

  static DateTime _date(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
    }
    return DateTime.now();
  }

  static NotificationType _typeFrom(String? raw) {
    if (raw == null) return NotificationType.system;
    final v = raw.toLowerCase().trim();

    if (v == 'benh_vien_xac_nhan' || v.contains('xac_nhan') || v.contains('confirm')) {
      return NotificationType.appointmentConfirmed;
    }
    if (v == 'benh_vien_huy_lich' || v.contains('huy') || v.contains('cancel')) {
      return NotificationType.appointmentCancelled;
    }
    if (v == 'benh_vien_nhan_nho' || v.contains('nhac') || v.contains('remind')) {
      return NotificationType.appointmentReminder;
    }
    if (v == 'benh_vien_thong_bao' || v.contains('hoan_thanh') || v.contains('complete')) {
      return NotificationType.appointmentCompleted;
    }
    if (v == 'he_thong' || v.contains('system')) {
      return NotificationType.system;
    }

    return NotificationType.system; // Fallback mặc định
  }

  static NotificationStatus _statusFrom(Map<String, dynamic> m) {
    final daDoc = m['da_doc'] ?? m['isRead'] ?? m['is_read'];
    if (daDoc is bool) {
      return daDoc ? NotificationStatus.read : NotificationStatus.unread;
    }
    if (daDoc is int) {
      return daDoc == 1 ? NotificationStatus.read : NotificationStatus.unread;
    }
    final s = (m['status'] ?? m['trang_thai'] ?? '').toString().toLowerCase();
    if (s == 'read' || s == 'da_doc') return NotificationStatus.read;
    return NotificationStatus.unread;
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: _str(map, ['tieu_de', 'title']) ?? 'Thông báo',
      message: _str(map, ['noi_dung', 'message', 'body']) ?? '',
      type: _typeFrom(_str(map, ['loai_thong_bao', 'loai', 'type'])),
      status: _statusFrom(map),
      createdAt: _date(map, ['ngay_tao', 'createdAt', 'created_at']),
      hospitalName: _str(map, ['ten_benh_vien', 'hospitalName']),
      departmentName: _str(map, ['ten_khoa', 'departmentName']),
      appointmentDate: _str(map, ['ngay_kham', 'appointmentDate']),
      appointmentTime: _str(map, ['gio_kham', 'appointmentTime']),
      queueNumber: _str(map, ['so_thu_tu', 'queueNumber']),
      lichHenId: _str(map, ['lich_hen_id']),
      benhVienId: _str(map, ['benh_vien_id']),
      khoaId: _str(map, ['khoa_id']),
    );
  }

  /// Ghi lên Firestore.
  Map<String, dynamic> toMap() => {
    'tieu_de': title,
    'noi_dung': message,
    'loai_thong_bao': type.name, 
    'da_doc': status == NotificationStatus.read ? 1 : 0, 
    'ngay_tao': Timestamp.fromDate(createdAt),
    if (hospitalName != null) 'ten_benh_vien': hospitalName,
    if (departmentName != null) 'ten_khoa': departmentName,
    if (appointmentDate != null) 'ngay_kham': appointmentDate,
    if (appointmentTime != null) 'gio_kham': appointmentTime,
    if (queueNumber != null) 'so_thu_tu': queueNumber,
    if (lichHenId != null) 'lich_hen_id': lichHenId,
    if (benhVienId != null) 'benh_vien_id': benhVienId,
    if (khoaId != null) 'khoa_id': khoaId,
  };

  NotificationModel copyWith({
    NotificationStatus? status,
    String? lichHenId,
    String? benhVienId,
    String? khoaId,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      hospitalName: hospitalName,
      departmentName: departmentName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      queueNumber: queueNumber,
      lichHenId: lichHenId ?? this.lichHenId,       
      benhVienId: benhVienId ?? this.benhVienId,    
      khoaId: khoaId ?? this.khoaId,                
    );
  }
}