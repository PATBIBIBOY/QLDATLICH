import '../config/constants.dart';

class HospitalModel {
  final int? id;
  final String? uid;
  final String? tenBenhVien;
  final String? diaChi;
  final String? moTa;
  final String? hinhAnh;
  final int? trangThaiHopTacId;
  final double? diemDanhGiaTb;
  final int? tongSoDanhGia;
  final DateTime? ngayHopTac;
  final DateTime? ngayTao;
  final String? coSo;
  final String? bhyt;
  final String? email;
  final String? role;
  final bool daXacThucEmail;

  HospitalModel({
    this.id,
    this.uid,
    this.tenBenhVien,
    this.diaChi,
    this.moTa,
    this.hinhAnh,
    this.trangThaiHopTacId = TrangThaiId.choDuyet,
    this.diemDanhGiaTb = 0.0,
    this.tongSoDanhGia = 0,
    this.ngayHopTac,
    DateTime? ngayTao,
    this.coSo,
    this.bhyt,
    this.email,
    this.role = 'benh_vien',
    this.daXacThucEmail = false,
  }) : ngayTao = ngayTao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'ten_benh_vien': tenBenhVien,
      'dia_chi': diaChi,
      'mo_ta': moTa,
      'hinh_anh': hinhAnh,
      'trang_thai_hop_tac_id': trangThaiHopTacId,
      'diem_danh_gia_tb': diemDanhGiaTb,
      'tong_so_danh_gia': tongSoDanhGia,
      'ngay_hop_tac': ngayHopTac?.toIso8601String(),
      'ngay_tao': ngayTao?.toIso8601String(),
      'co_so': coSo,
      'bhyt': bhyt,
      'email': email,
      'role': role,
      'da_xac_thuc_email': daXacThucEmail,
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawUid = (map['uid'] ?? map['benh_vien_id'] ?? docId)?.toString();
    final rawTen = (map['ten_benh_vien'] ?? map['tenBenhVien'] ?? map['ten'] ?? '').toString();
    return HospitalModel(
      id: map['id'] is int ? map['id'] : (map['id'] as num?)?.toInt(),
      uid: rawUid,
      tenBenhVien: rawTen.isNotEmpty ? rawTen : null,
      diaChi: map['dia_chi'] ?? map['diaChi'],
      moTa: map['mo_ta'] ?? map['moTa'],
      hinhAnh: map['hinh_anh'] ?? map['hinhAnh'],
      trangThaiHopTacId: map['trang_thai_hop_tac_id'] ?? TrangThaiId.choDuyet,
      diemDanhGiaTb: (map['diem_danh_gia_tb'] as num?)?.toDouble() ?? 0.0,
      tongSoDanhGia: map['tong_so_danh_gia'] ?? 0,
      ngayHopTac: map['ngay_hop_tac'] != null
          ? DateTime.parse(map['ngay_hop_tac'])
          : null,
      ngayTao: map['ngay_tao'] != null ? DateTime.parse(map['ngay_tao']) : null,
      coSo: map['co_so'] ?? map['coSo'],
      bhyt: map['bhyt']?.toString(),
      email: map['email'],
      role: map['role'] ?? 'benh_vien',
      daXacThucEmail: map['da_xac_thuc_email'] ?? false,
    );
  }

  HospitalModel copyWith({
    int? id,
    String? uid,
    String? tenBenhVien,
    String? diaChi,
    String? moTa,
    String? hinhAnh,
    int? trangThaiHopTacId,
    double? diemDanhGiaTb,
    int? tongSoDanhGia,
    DateTime? ngayHopTac,
    DateTime? ngayTao,
    String? coSo,
    String? bhyt,
    String? email,
    String? role,
    bool? daXacThucEmail,
  }) {
    return HospitalModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      tenBenhVien: tenBenhVien ?? this.tenBenhVien,
      diaChi: diaChi ?? this.diaChi,
      moTa: moTa ?? this.moTa,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      trangThaiHopTacId: trangThaiHopTacId ?? this.trangThaiHopTacId,
      diemDanhGiaTb: diemDanhGiaTb ?? this.diemDanhGiaTb,
      tongSoDanhGia: tongSoDanhGia ?? this.tongSoDanhGia,
      ngayHopTac: ngayHopTac ?? this.ngayHopTac,
      ngayTao: ngayTao ?? this.ngayTao,
      coSo: coSo ?? this.coSo,
      bhyt: bhyt ?? this.bhyt,
      email: email ?? this.email,
      role: role ?? this.role,
      daXacThucEmail: daXacThucEmail ?? this.daXacThucEmail,
    );
  }

  factory HospitalModel.fromRegisterEmail({
    required String uid,
    required String tenBenhVien,
    required String email,
    String? diaChi,
    String? role,
  }) {
    return HospitalModel(
      uid: uid,
      tenBenhVien: tenBenhVien,
      email: email,
      diaChi: diaChi,
      trangThaiHopTacId: TrangThaiId.choDuyet,
      ngayTao: DateTime.now(),
      role: role ?? 'benh_vien',
      daXacThucEmail: false,
    );
  }
}