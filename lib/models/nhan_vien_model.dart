import 'package:cloud_firestore/cloud_firestore.dart';

class TaiKhoanItem {
  final String? id;
  final String? benhVienId;
  final String maTk;
  final String matKhau;
  final String trangThai;

  const TaiKhoanItem({
    this.id,
    this.benhVienId,
    required this.maTk,
    required this.matKhau,
    this.trangThai = 'Đợi kích hoạt',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'benh_vien_id': benhVienId,
    'maTk': maTk,
    'matKhau': matKhau,
    'trangThai': trangThai,
  };

  factory TaiKhoanItem.fromMap(Map<String, dynamic> map) => TaiKhoanItem(
    id: map['id']?.toString(),
    benhVienId: (map['benh_vien_id'] ?? map['benhVienId'])?.toString(),
    maTk: (map['maTk'] ?? map['ma_nhan_vien'] ?? map['ma_tai_khoan'] ?? '').toString(),
    matKhau: (map['matKhau'] ?? map['mat_khau'] ?? '123456').toString(),
    trangThai: (map['trangThai'] ?? map['trang_thai'] ?? 'Đợi kích hoạt').toString(),
  );
}

class DotCapTaiKhoan {
  final String id;
  final String tenKhoa;
  final String vaiTro;
  final int soLuong;
  final List<TaiKhoanItem> danhSachTaiKhoan;
  final DateTime thoiGian;

  DotCapTaiKhoan({
    String? id,
    required this.tenKhoa,
    required this.vaiTro,
    required this.soLuong,
    required this.danhSachTaiKhoan,
    DateTime? thoiGian,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        thoiGian = thoiGian ?? DateTime.now();
}

class NhanVienModel {
  final String id;
  final String benhVienId;
  final String hoTen;
  final String maNv;
  final String vaiTro;
  final String role;
  final String khoa;
  final String soDienThoai;
  final String email;
  final String matKhau;
  final bool daKichHoat;
  final bool dangHoatDong;
  final String trangThai;
  final DateTime? ngayTao;

  const NhanVienModel({
    required this.id,
    this.benhVienId = '',
    required this.hoTen,
    required this.maNv,
    required this.vaiTro,
    this.role = '',
    required this.khoa,
    required this.soDienThoai,
    required this.email,
    this.matKhau = '123456',
    this.daKichHoat = true,
    this.dangHoatDong = true,
    this.trangThai = 'dang_hoat_dong',
    this.ngayTao,
  });

  factory NhanVienModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final benhVienId =
        (data['benh_vien_id'] ?? data['benhVienId'] ?? '').toString();
    final maNv = (data['ma_nhan_vien'] ??
            data['maNv'] ??
            data['ma_tai_khoan'] ??
            doc.id)
        .toString();
    final vaiTro = (data['vai_tro'] ?? data['vaiTro'] ?? 'Lễ tân').toString();
    final hoTen =
        (data['ho_ten'] ?? data['hoTen'] ?? 'Nhân viên $maNv').toString();
    final khoa = (data['khoa'] ?? '').toString();
    final sdt =
        (data['so_dien_thoai'] ?? data['soDienThoai'] ?? '').toString();
    final email =
        (data['email'] ?? '${maNv.toLowerCase()}@benhvien.vn').toString();
    final matKhau =
        (data['mat_khau'] ?? data['matKhau'] ?? '123456').toString();
    final trangThai = (data['trang_thai'] ?? '').toString();

    final bool daKichHoat;
    if (data.containsKey('da_kich_hoat')) {
      daKichHoat = data['da_kich_hoat'] == true;
    } else {
      daKichHoat = (trangThai == 'dang_hoat_dong' || trangThai == 'da_khoa') &&
          trangThai != 'doi_kich_hoat' &&
          trangThai != 'chua_kich_hoat';
    }

    final dangHoatDong = trangThai != 'da_khoa';

    DateTime? dt;
    final nt = data['ngay_tao'] ?? data['ngayTao'];
    if (nt is Timestamp) {
      dt = nt.toDate();
    }

    return NhanVienModel(
      id: doc.id,
      benhVienId: benhVienId,
      hoTen: hoTen,
      maNv: maNv,
      vaiTro: vaiTro,
      role: (data['role'] ?? '').toString(),
      khoa: khoa,
      soDienThoai: sdt,
      email: email,
      matKhau: matKhau,
      daKichHoat: daKichHoat,
      dangHoatDong: dangHoatDong,
      trangThai: trangThai,
      ngayTao: dt,
    );
  }
}
