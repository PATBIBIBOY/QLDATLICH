class KetQuaQuetQrC1 {
  final bool thanhCong;
  final String thongBao;
  final String chiTietLoi;
  final int? soThuTu;
  final String? gioKhamDuKien;
  final String? hoTen;
  final String? maBenhNhan;
  final String? namSinhGioiTinh;
  final String? cccd;
  final String? bhyt;
  final String? khoaKham;
  final String? phongKham;
  final String? bacSi;

  const KetQuaQuetQrC1({
    required this.thanhCong,
    required this.thongBao,
    this.chiTietLoi = '',
    this.soThuTu,
    this.gioKhamDuKien,
    this.hoTen,
    this.maBenhNhan,
    this.namSinhGioiTinh,
    this.cccd,
    this.bhyt,
    this.khoaKham,
    this.phongKham,
    this.bacSi,
  });
}
