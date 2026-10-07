import '../../models/letan_c1/letan_model_c1.dart';

// Du lieu mau chay offline cho Le tan C1
class DuLieuMauLeTanC1 {
  static const String tenKhoaMacDinh = 'Khoa Tim Mạch';
  static const String tenLeTan = 'Đinh Hoàng Cước';

  static const ThongKeLeTanC1 thongKe = ThongKeLeTanC1(
    daTiepNhan: 47,
    dangCho: 12,
    daKham: 35,
  );

  static const List<BenhNhanChoKhamC1> danhSachCho = [
    BenhNhanChoKhamC1(
      id: 'BN01',
      ten: 'Nguyễn Văn An',
      khoa: 'Khoa Tim mạch',
      gioKham: '08:30',
      trangThai: 'Tiếp theo',
      avatarInitials: 'NA',
    ),
    BenhNhanChoKhamC1(
      id: 'BN02',
      ten: 'Trần Thị Hoa',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:00',
      trangThai: 'Đang chờ',
      avatarInitials: 'TH',
    ),
    BenhNhanChoKhamC1(
      id: 'BN03',
      ten: 'Lê Minh',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:15',
      trangThai: 'Chưa đến',
      avatarInitials: 'LM',
    ),
    BenhNhanChoKhamC1(
      id: 'BN04',
      ten: 'Phạm Hồng Nhung',
      khoa: 'Khoa Tim mạch',
      gioKham: '09:30',
      trangThai: 'Đang chờ',
      avatarInitials: 'HN',
    ),
  ];
}
