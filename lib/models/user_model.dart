import '../config/constants.dart';

class UserModel {
  final String uid;
  final String? hoTen;           // họ_ten
  final String? email;
  final String? soDienThoai;     // so_dien_thoai
  final String? matKhau;         // mat_khau (hash)
  final String? googleId;        // google
  final DateTime? ngaySinh;      // ngay_sinh
  final String? gioiTinh;        // gioi_tinh
  final String? diaChi;          // dia_chi
  final int? trangThaiId;        // trang_thai_id (default: 1 = active)
  final DateTime? ngayTao;       // ngay_tao
  final String? role;            // 'Bệnh nhân' hoặc 'Bệnh viện'

  UserModel({
    required this.uid,
    this.hoTen,
    this.email,
    this.soDienThoai,
    this.matKhau,
    this.googleId,
    this.ngaySinh,
    this.gioiTinh,
    this.diaChi,
    this.trangThaiId = 1,
    DateTime? ngayTao,
    this.role = 'Bệnh nhân',
  }) : ngayTao = ngayTao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'ho_ten': hoTen,
      'email': email,
      'so_dien_thoai': soDienThoai,
      'mat_khau': matKhau,
      'google': googleId,
      'ngay_sinh': ngaySinh?.toIso8601String(),
      'gioi_tinh': gioiTinh,
      'dia_chi': diaChi,
      'trang_thai_id': trangThaiId,
      'ngay_tao': ngayTao?.toIso8601String(),
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      hoTen: map['ho_ten'],
      email: map['email'],
      soDienThoai: map['so_dien_thoai'],
      matKhau: map['mat_khau'],
      googleId: map['google'],
      ngaySinh: map['ngay_sinh'] != null 
          ? DateTime.parse(map['ngay_sinh']) 
          : null,
      gioiTinh: map['gioi_tinh'],
      diaChi: map['dia_chi'],
      trangThaiId: map['trang_thai_id'],
      ngayTao: map['ngay_tao'] != null 
          ? DateTime.parse(map['ngay_tao']) 
          : null,
      role: map['role'] ?? 'Bệnh nhân',
    );
  }

  // Helper để tạo user từ đăng ký email/mật khẩu
  factory UserModel.fromRegisterEmail({
    required String uid,
    required String hoTen,
    required String email,
    required String matKhau,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      hoTen: hoTen,
      email: email,
      matKhau: matKhau,
      trangThaiId: 1,
      ngayTao: DateTime.now(),
      role: role ?? 'Bệnh nhân',
      // Các trường khác để null
    );
  }

  // Helper để tạo user từ đăng ký số điện thoại
  factory UserModel.fromRegisterPhone({
    required String uid,
    required String hoTen,
    required String soDienThoai,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      hoTen: hoTen,
      soDienThoai: soDienThoai,
      trangThaiId: 1,
      ngayTao: DateTime.now(),
      role: role ?? 'Bệnh nhân',
      // Các trường khác để null
    );
  }

  // Helper để tạo user từ Google Sign-In
  factory UserModel.fromGoogle({
    required String uid,
    required String hoTen,
    required String email,
    required String googleId,
  }) {
    return UserModel(
      uid: uid,
      hoTen: hoTen,
      email: email,
      googleId: googleId,
      trangThaiId: 1,
      ngayTao: DateTime.now(),
      role: 'Bệnh nhân',
      // Các trường khác để null
    );
  }
}