class PhongKhamModel {
  final String id;
  final String hospitalId;
  final String khoaId;
  final String tenPhong;
  final String soPhong;
  final String gioMoCua;
  final String gioDongCua;
  final int thoiGianKham; // Tính bằng phút
  final int soBenhNhanToiDa;
  final String? nhanVienId;

  PhongKhamModel({
    required this.id,
    required this.hospitalId,
    required this.khoaId,
    required this.tenPhong,
    required this.soPhong,
    required this.gioMoCua,
    required this.gioDongCua,
    required this.thoiGianKham,
    required this.soBenhNhanToiDa,
    this.nhanVienId,
  });

  factory PhongKhamModel.fromMap(Map<String, dynamic> map, String docId) {
    return PhongKhamModel(
      id: docId,
      hospitalId: map['hospital_id'] ?? '',
      khoaId: map['khoa_id'] ?? '',
      tenPhong: map['ten_phong'] ?? '',
      soPhong: map['so_phong'] ?? '',
      gioMoCua: map['gio_mo_cua'] ?? '',
      gioDongCua: map['gio_dong_cua'] ?? '',
      thoiGianKham: (map['thoi_gian_kham'] as num?)?.toInt() ?? 0,
      soBenhNhanToiDa: (map['so_benh_nhan_toi_da'] as num?)?.toInt() ?? 0,
      nhanVienId: map['nhan_vien_id'],
    );
  }
}