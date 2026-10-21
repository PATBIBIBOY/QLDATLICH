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
  
  // ✅ THÊM 2 TRƯỜNG TỌA ĐỘ
  final double? viDo;  // Latitude
  final double? kinhDo; // Longitude

  // ✅ THÊM 2 TRƯỜNG DANH SÁCH CHUYÊN KHOA
  final List<String>? chuyenKhoaIds; // Ví dụ: ['CK01', 'CK04'] -> Dùng để query filter
  final List<String>? tenCacKhoa;    // Ví dụ: ['Khoa Tim mạch', 'Khoa Hô hấp'] -> Dùng để hiển thị UI nhanh

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
    this.viDo,    
    this.kinhDo,  
    this.chuyenKhoaIds, // ✅ Thêm
    this.tenCacKhoa,    // ✅ Thêm
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
      'vi_do': viDo,    
      'kinh_do': kinhDo, 
      'chuyen_khoa_ids': chuyenKhoaIds, // ✅ Thêm
      'ten_cac_khoa': tenCacKhoa,       // ✅ Thêm
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      id: map['id'] is int ? map['id'] : (map['id'] as num?)?.toInt(),
      uid: map['uid'],
      tenBenhVien: map['ten_benh_vien'],
      diaChi: map['dia_chi'],
      moTa: map['mo_ta'],
      hinhAnh: map['hinh_anh'],
      trangThaiHopTacId: map['trang_thai_hop_tac_id'] ?? TrangThaiId.choDuyet,
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
      viDo: (map['vi_do'] as num?)?.toDouble(),    
      kinhDo: (map['kinh_do'] as num?)?.toDouble(), 
      
      // ✅ Xử lý an toàn cho List<String> từ Firestore
      chuyenKhoaIds: map['chuyen_khoa_ids'] != null
          ? List<String>.from(map['chuyen_khoa_ids'])
          : null,
      tenCacKhoa: map['ten_cac_khoa'] != null
          ? List<String>.from(map['ten_cac_khoa'])
          : null,
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
    double? viDo,    
    double? kinhDo,  
    List<String>? chuyenKhoaIds, // ✅ Thêm
    List<String>? tenCacKhoa,    // ✅ Thêm
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
      viDo: viDo ?? this.viDo,    
      kinhDo: kinhDo ?? this.kinhDo, 
      chuyenKhoaIds: chuyenKhoaIds ?? this.chuyenKhoaIds, // ✅ Thêm
      tenCacKhoa: tenCacKhoa ?? this.tenCacKhoa,          // ✅ Thêm
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
      // Các trường chuyên khoa sẽ để null khi mới đăng ký
    );
  }
}