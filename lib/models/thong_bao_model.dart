import 'package:cloud_firestore/cloud_firestore.dart';

import 'nhan_vien_model.dart';

/// Model dữ liệu Thông báo trong hệ thống Bệnh viện
class ThongBaoModel {
  final String id;
  final String tieuDe;
  final String noiDungNgan;
  final String noiDungChiTiet;
  final DateTime thoiGian;
  final String loai; // 'kich_hoat_tai_khoan', 'he_thong', 'lich_hen',...
  final bool daDoc;
  final String? benhVienId;
  final String? maNhanVien;
  final String? tenNhanVien;
  final String? khoa;
  final String? vaiTro;
  final Map<String, dynamic>? metadata;

  const ThongBaoModel({
    required this.id,
    required this.tieuDe,
    required this.noiDungNgan,
    required this.noiDungChiTiet,
    required this.thoiGian,
    this.loai = 'kich_hoat_tai_khoan',
    this.daDoc = false,
    this.benhVienId,
    this.maNhanVien,
    this.tenNhanVien,
    this.khoa,
    this.vaiTro,
    this.metadata,
  });

  ThongBaoModel copyWith({bool? daDoc}) {
    return ThongBaoModel(
      id: id,
      tieuDe: tieuDe,
      noiDungNgan: noiDungNgan,
      noiDungChiTiet: noiDungChiTiet,
      thoiGian: thoiGian,
      loai: loai,
      daDoc: daDoc ?? this.daDoc,
      benhVienId: benhVienId,
      maNhanVien: maNhanVien,
      tenNhanVien: tenNhanVien,
      khoa: khoa,
      vaiTro: vaiTro,
      metadata: metadata,
    );
  }

  /// Tạo thông báo từ đối tượng NhanVienModel đã kích hoạt
  factory ThongBaoModel.fromNhanVienKichHoat({
    required NhanVienModel nv,
    required bool daDoc,
    DateTime? thoiGianKichHoat,
  }) {
    final tenKhoa = nv.khoa.isNotEmpty ? nv.khoa : 'Chuyên khoa';
    final vaiTro = nv.vaiTro.isNotEmpty
        ? nv.vaiTro
        : (nv.role.isNotEmpty ? nv.role : 'Nhân viên');
    final tg = thoiGianKichHoat ?? nv.ngayTao ?? DateTime.now();

    return ThongBaoModel(
      id: 'tb_kich_hoat_${nv.maNv}',
      tieuDe: 'Tài khoản nhân sự đã được kích hoạt',
      noiDungNgan:
          'Nhân viên ${nv.hoTen} ($vaiTro - ${nv.maNv}) thuộc $tenKhoa đã được kích hoạt tài khoản thành công.',
      noiDungChiTiet:
          'Tài khoản nhân sự đã được kích hoạt thành công trên hệ thống:\n\n'
          '• Họ và tên: ${nv.hoTen}\n'
          '• Mã nhân sự: ${nv.maNv}\n'
          '• Chuyên khoa: $tenKhoa\n'
          '• Vai trò: $vaiTro\n'
          '• Số điện thoại: ${nv.soDienThoai.isNotEmpty ? nv.soDienThoai : "Chưa cập nhật"}\n'
          '• Email: ${nv.email.isNotEmpty ? nv.email : "Chưa cập nhật"}\n'
          '• Trạng thái nhân sự: Đã kích hoạt (Đang hoạt động)\n'
          '• Trạng thái nhận việc: Chờ (15) - Chờ nhận lịch làm\n\n'
          'Nhân sự hiện đã sẵn sàng và đủ điều kiện để được phân công ca trực theo ngày trong mục Phân Công Trực.',
      thoiGian: tg,
      loai: 'kich_hoat_tai_khoan',
      daDoc: daDoc,
      benhVienId: nv.benhVienId,
      maNhanVien: nv.maNv,
      tenNhanVien: nv.hoTen,
      khoa: tenKhoa,
      vaiTro: vaiTro,
    );
  }

  /// Tạo thông báo từ Document Firestore (nếu có trong ThongBaoHeThong hoặc ThongBao)
  factory ThongBaoModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool daDoc = false,
  }) {
    final data = doc.data() ?? {};
    DateTime tg = DateTime.now();
    final rawTg = data['thoi_gian'] ?? data['ngay_tao'] ?? data['createdAt'];
    if (rawTg is Timestamp) {
      tg = rawTg.toDate();
    }

    return ThongBaoModel(
      id: doc.id,
      tieuDe: (data['tieu_de'] ?? data['ten_loai'] ?? 'Thông báo').toString(),
      noiDungNgan: (data['noi_dung_ngan'] ?? data['mo_ta'] ?? '').toString(),
      noiDungChiTiet:
          (data['noi_dung_chi_tiet'] ?? data['noi_dung'] ?? data['mo_ta'] ?? '')
              .toString(),
      thoiGian: tg,
      loai: (data['loai'] ?? data['id_loai'] ?? 'he_thong').toString(),
      daDoc: (data['da_doc'] == true) || daDoc,
      benhVienId: data['benh_vien_id']?.toString(),
      maNhanVien: data['ma_nhan_vien']?.toString(),
      tenNhanVien: data['ten_nhan_vien']?.toString(),
      khoa: data['khoa']?.toString(),
      vaiTro: data['vai_tro']?.toString(),
      metadata: data,
    );
  }

  /// Định dạng thời gian hiển thị thân thiện (Vừa xong, hôm nay, ngày tháng...)
  String get thoiGianHienThi {
    final now = DateTime.now();
    final diff = now.difference(thoiGian);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24 && now.day == thoiGian.day) {
      final h = thoiGian.hour.toString().padLeft(2, '0');
      final m = thoiGian.minute.toString().padLeft(2, '0');
      return '$h:$m Hôm nay';
    } else {
      final d = thoiGian.day.toString().padLeft(2, '0');
      final m = thoiGian.month.toString().padLeft(2, '0');
      final y = thoiGian.year;
      final h = thoiGian.hour.toString().padLeft(2, '0');
      final min = thoiGian.minute.toString().padLeft(2, '0');
      return '$h:$min $d/$m/$y';
    }
  }
}
