// Model du lieu cho Le tan C1
class BenhNhanChoKhamC1 {
  final String id;
  final String ten;
  final String khoa;
  final String gioKham;
  final String trangThai; // "Tiếp theo", "Đang chờ", "Chưa đến"
  final String avatarInitials;

  const BenhNhanChoKhamC1({
    required this.id,
    required this.ten,
    required this.khoa,
    required this.gioKham,
    required this.trangThai,
    required this.avatarInitials,
  });
}

class ThongKeLeTanC1 {
  final int daTiepNhan;
  final int dangCho;
  final int daKham;

  const ThongKeLeTanC1({
    required this.daTiepNhan,
    required this.dangCho,
    required this.daKham,
  });
}
