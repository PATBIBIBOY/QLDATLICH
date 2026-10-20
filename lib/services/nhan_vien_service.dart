import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nhan_vien_model.dart';

class NhanVienService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _nhanVienCol =>
      _db.collection('NhanVien');

  /// Stream danh sách toàn bộ nhân viên theo thời gian thực (sắp xếp mới nhất lên đầu)
  Stream<List<NhanVienModel>> streamNhanVien() {
    return _nhanVienCol.snapshots().map((snap) {
      final list = snap.docs.map((d) => NhanVienModel.fromDoc(d)).toList();
      list.sort((a, b) {
        if (a.ngayTao == null && b.ngayTao == null) return 0;
        if (a.ngayTao == null) return 1;
        if (b.ngayTao == null) return -1;
        return b.ngayTao!.compareTo(a.ngayTao!);
      });
      return list;
    });
  }

  /// Lấy danh sách toàn bộ tài khoản cho màn hình xem danh sách tài khoản
  Future<List<TaiKhoanItem>> layDanhSachTaiKhoan() async {
    final snap = await _nhanVienCol.get();
    return snap.docs.map((d) {
      final data = d.data();
      final maTk = (data['ma_nhan_vien'] ??
              data['ma_tai_khoan'] ??
              d.id)
          .toString();
      final matKhau = (data['mat_khau'] ?? '123456').toString();
      final trangThaiRaw = (data['trang_thai'] ?? '').toString();
      final daKichHoat = data['da_kich_hoat'] ?? false;
      final trangThai = daKichHoat == true || trangThaiRaw == 'dang_hoat_dong'
          ? 'Đang hoạt động'
          : 'Chưa kích hoạt';

      return TaiKhoanItem(
        maTk: maTk,
        matKhau: matKhau,
        trangThai: trangThai,
      );
    }).toList();
  }

  /// Cấp mới danh sách tài khoản nhân viên và lưu đồng loạt bằng WriteBatch
  Future<DotCapTaiKhoan> taoVaLuuNhanVien({
    required String tenKhoa,
    required String deptCode,
    required String vaiTro,
    required String rolePrefix,
    required String roleCode,
    required int soLuong,
    String matKhau = '123456',
  }) async {
    final prefix = '${rolePrefix}_${deptCode}_';

    // 1. Tính toán startIndex để tự động tăng số thứ tự tránh trùng lặp
    int startIndex = 1;
    try {
      final existingQuery = await _nhanVienCol
          .where('ma_nhan_vien', isGreaterThanOrEqualTo: prefix)
          .where('ma_nhan_vien', isLessThan: '$prefix\uf8ff')
          .get();

      int maxIndex = 0;
      for (final doc in existingQuery.docs) {
        final ma = (doc.data()['ma_nhan_vien'] ?? doc.id).toString();
        final part = ma.replaceFirst(prefix, '');
        final parsed = int.tryParse(part);
        if (parsed != null && parsed > maxIndex) {
          maxIndex = parsed;
        }
      }
      startIndex = maxIndex + 1;
    } catch (_) {
      startIndex = 1;
    }

    final List<TaiKhoanItem> danhSach = [];
    final batch = _db.batch();

    for (int i = 0; i < soLuong; i++) {
      final currentNum = startIndex + i;
      final numStr = currentNum.toString().padLeft(2, '0');
      final maTk = '$prefix$numStr';

      danhSach.add(TaiKhoanItem(maTk: maTk, matKhau: matKhau));

      final docRef = _nhanVienCol.doc(maTk);
      batch.set(docRef, {
        'ma_nhan_vien': maTk,
        'ma_tai_khoan': maTk,
        'mat_khau': matKhau,
        'role': roleCode,
        'vai_tro': vaiTro,
        'khoa': tenKhoa,
        'da_kich_hoat': false,
        'trang_thai': 'chua_kich_hoat',
        'ngay_tao': FieldValue.serverTimestamp(),
        'ho_ten': '$vaiTro $numStr',
        'so_dien_thoai': '',
        'email': '${maTk.toLowerCase()}@benhvien.vn',
      });
    }

    // Ghi đồng loạt lên Firebase Firestore
    await batch.commit();

    return DotCapTaiKhoan(
      tenKhoa: tenKhoa,
      vaiTro: vaiTro,
      soLuong: soLuong,
      danhSachTaiKhoan: danhSach,
    );
  }

  /// Cập nhật trạng thái khóa / mở khóa tài khoản
  Future<void> capNhatTrangThai({
    required String nhanVienId,
    required bool dangHoatDong,
  }) async {
    await _nhanVienCol.doc(nhanVienId).update({
      'trang_thai': dangHoatDong ? 'dang_hoat_dong' : 'da_khoa',
      'da_kich_hoat': dangHoatDong,
    });
  }

  /// Xóa tài khoản nhân viên
  Future<void> xoaNhanVien(String nhanVienId) async {
    await _nhanVienCol.doc(nhanVienId).delete();
  }
}
