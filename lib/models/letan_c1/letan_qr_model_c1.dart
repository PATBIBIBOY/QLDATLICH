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

class DuLieuQuetQrMauC1 {
  // Truong hop 1: Thanh cong theo dung mockup
  static const KetQuaQuetQrC1 thanhCongMockup = KetQuaQuetQrC1(
    thanhCong: true,
    thongBao: 'Xác thực QR thành công',
    chiTietLoi: 'Mã phiếu hợp lệ - Đã ghi nhận tiếp đón',
    soThuTu: 14,
    gioKhamDuKien: '08:35 - 08:50',
    hoTen: 'NGUYỄN VĂN AN',
    maBenhNhan: 'BN-2026-8891',
    namSinhGioiTinh: '1992 (34 tuổi) - Nam',
    cccd: '001092008892',
    bhyt: 'BHYT 100%',
    khoaKham: 'Khoa Tim Mạch',
    phongKham: 'Phòng 204 - Tầng 2 Khu A',
    bacSi: 'BS. CKII Lê Hoàng Nam',
  );

  // Truong hop 2a: Ma QR da duoc xac thuc truoc do
  static const KetQuaQuetQrC1 daXacThucTruocDo = KetQuaQuetQrC1(
    thanhCong: false,
    thongBao: 'Phiếu đã được tiếp đón trước đó!',
    chiTietLoi: 'Mã QR này đã thực hiện check-in vào lúc 08:15 hôm nay.',
    hoTen: 'TRẦN THỊ HOA',
    maBenhNhan: 'BN-2026-5542',
    khoaKham: 'Khoa Tim Mạch',
  );

  // Truong hop 2b: Ma QR khong hop le / sai khoa
  static const KetQuaQuetQrC1 maKhongHopLe = KetQuaQuetQrC1(
    thanhCong: false,
    thongBao: 'Mã QR không hợp lệ hoặc sai khoa!',
    chiTietLoi: 'Không tìm thấy phiếu hẹn hoặc lịch khám thuộc cơ sở khác.',
  );
}
