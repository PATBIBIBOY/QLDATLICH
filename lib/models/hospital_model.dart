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
  final bool isBlocked;
  final bool chanDangNhap;
  final String? lyDoKhoa;

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
    this.isBlocked = false,
    this.chanDangNhap = false,
    this.lyDoKhoa,
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
      'is_blocked': isBlocked,
      'chan_dang_nhap': chanDangNhap,
      'ly_do_khoa': lyDoKhoa,
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    final statusId = (map['trang_thai_hop_tac_id'] as num?)?.toInt() ?? TrangThaiId.choDuyet;
    final chan = map['chan_dang_nhap'] == true;
    final blocked = map['is_blocked'] == true ||
        chan ||
        statusId != 10 ||
        map['trang_thai'] == 'huy_hop_tac';

    return HospitalModel(
      id: map['id'] is int ? map['id'] : (map['id'] as num?)?.toInt(),
      uid: map['uid'],
      tenBenhVien: map['ten_benh_vien'],
      diaChi: map['dia_chi'],
      moTa: map['mo_ta'],
      hinhAnh: map['hinh_anh'],
      trangThaiHopTacId: statusId,
      diemDanhGiaTb: (map['diem_danh_gia_tb'] as num?)?.toDouble() ?? 0.0,
      tongSoDanhGia: map['tong_so_danh_gia'] ?? 0,
      ngayHopTac: map['ngay_hop_tac'] != null
          ? DateTime.parse(map['ngay_hop_tac'])
          : null,
      ngayTao: map['ngay_tao'] != null ? DateTime.parse(map['ngay_tao']) : null,
      coSo: map['co_so'],
      bhyt: map['bhyt'],
      email: map['email'],
      role: map['role'] ?? 'benh_vien',
      daXacThucEmail: map['da_xac_thuc_email'] ?? false,
      isBlocked: blocked,
      chanDangNhap: chan,
      lyDoKhoa: map['ly_do_khoa']?.toString() ??
          map['ly_do_huy']?.toString() ??
          map['ly_do_chan']?.toString(),
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
    bool? isBlocked,
    bool? chanDangNhap,
    String? lyDoKhoa,
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
      isBlocked: isBlocked ?? this.isBlocked,
      chanDangNhap: chanDangNhap ?? this.chanDangNhap,
      lyDoKhoa: lyDoKhoa ?? this.lyDoKhoa,
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
