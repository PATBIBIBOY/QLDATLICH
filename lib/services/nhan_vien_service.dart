import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../models/nhan_vien_model.dart';

class NhanVienService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _nhanVienCol =>
      _db.collection('NhanVien');

  /// Stream danh sách toàn bộ nhân viên theo thời gian thực (chỉ hiển thị nhân viên đã kích hoạt)
  Stream<List<NhanVienModel>> streamNhanVien({bool chiLayDaKichHoat = true}) {
    return _nhanVienCol.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => NhanVienModel.fromDoc(d))
          .where((nv) => !chiLayDaKichHoat || nv.daKichHoat)
          .toList();
      list.sort((a, b) {
        if (a.ngayTao == null && b.ngayTao == null) return 0;
        if (a.ngayTao == null) return 1;
        if (b.ngayTao == null) return -1;
        return b.ngayTao!.compareTo(a.ngayTao!);
      });
      return list;
    });
  }

  /// Lấy danh sách tên các khoa đã được tạo thực tế trong Firestore (hoàn toàn không hardcode)
  Future<List<String>> layDanhSachKhoaDaTao([String? benhVienId]) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    final Set<String> names = {};

    // 1. Đọc từ đường dẫn chuẩn của bệnh viện: Khoa/{benhVienId}/danh_sach
    try {
      final snap = await _db
          .collection('Khoa')
          .doc(bvid)
          .collection('danh_sach')
          .get();
      for (final doc in snap.docs) {
        final ten = (doc.data()['tenKhoa'] ?? doc.data()['ten_khoa'] ?? '')
            .toString()
            .trim();
        if (ten.isNotEmpty) names.add(ten);
      }
    } catch (_) {}

    // 2. Nếu chưa có hoặc dùng ID khác, thử quét collectionGroup 'danh_sach'
    if (names.isEmpty) {
      try {
        final groupSnap = await _db.collectionGroup('danh_sach').get();
        for (final doc in groupSnap.docs) {
          final data = doc.data();
          if (data.containsKey('tenKhoa') || data.containsKey('ten_khoa')) {
            final ten = (data['tenKhoa'] ?? data['ten_khoa'] ?? '')
                .toString()
                .trim();
            if (ten.isNotEmpty) names.add(ten);
          }
        }
      } catch (_) {}
    }

    // 3. Quét collection 'Khoa' cấp cao nhất nếu có tài liệu lưu trực tiếp
    if (names.isEmpty) {
      try {
        final snapTop = await _db.collection('Khoa').get();
        for (final doc in snapTop.docs) {
          final data = doc.data();
          final ten = (data['tenKhoa'] ?? data['ten_khoa'] ?? '')
              .toString()
              .trim();
          if (ten.isNotEmpty) names.add(ten);
        }
      } catch (_) {}
    }

    final sorted = names.toList()..sort();
    return sorted;
  }

  /// Lấy danh sách tài khoản vừa tạo đang ở trạng thái đợi kích hoạt
  Future<List<TaiKhoanItem>> layDanhSachTaiKhoanChuaKichHoat() async {
    final snap = await _nhanVienCol.get();
    final list = <TaiKhoanItem>[];
    for (final d in snap.docs) {
      final data = d.data();
      final daKichHoat = data['da_kich_hoat'] ?? false;
      final trangThaiRaw = (data['trang_thai'] ?? '').toString();

      // Bỏ qua các tài khoản đã kích hoạt hoặc đang hoạt động / đã khóa
      if (daKichHoat == true ||
          trangThaiRaw == 'dang_hoat_dong' ||
          trangThaiRaw == 'da_khoa') {
        continue;
      }

      final maTk = (data['ma_nhan_vien'] ??
              data['ma_tai_khoan'] ??
              d.id)
          .toString();
      final matKhau = (data['mat_khau'] ?? '123456').toString();

      list.add(TaiKhoanItem(
        maTk: maTk,
        matKhau: matKhau,
        trangThai: 'Đợi kích hoạt',
      ));
    }
    return list;
  }

  /// Tương thích ngược: Lấy danh sách tài khoản đợi kích hoạt
  Future<List<TaiKhoanItem>> layDanhSachTaiKhoan() =>
      layDanhSachTaiKhoanChuaKichHoat();

  /// Cấp mới danh sách tài khoản nhân viên và lưu đồng loạt bằng WriteBatch
  /// Mã tài khoản được tạo ngẫu nhiên và đảm bảo không trùng lặp
  /// Mật khẩu là duy nhất cho tất cả các tài khoản
  Future<DotCapTaiKhoan> taoVaLuuNhanVien({
    required String tenKhoa,
    required String deptCode,
    required String vaiTro,
    required String rolePrefix,
    required String roleCode,
    required int soLuong,
    String matKhau = '123456',
  }) async {
    final prefix = deptCode.trim().isNotEmpty
        ? '${rolePrefix}_${deptCode}_'
        : '${rolePrefix}_';

    // Quét toàn bộ mã tài khoản hiện có để đối soát không trùng lặp
    final Set<String> existingCodes = {};
    try {
      final snap = await _nhanVienCol.get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final ma = (data['ma_nhan_vien'] ?? data['ma_tai_khoan'] ?? doc.id)
            .toString()
            .trim();
        if (ma.isNotEmpty) existingCodes.add(ma);
      }
    } catch (_) {}

    final random = Random();
    final List<TaiKhoanItem> danhSach = [];
    final batch = _db.batch();

    // Mật khẩu duy nhất cho tất cả tài khoản
    final String commonPassword =
        matKhau.trim().isNotEmpty ? matKhau.trim() : '123456';

    for (int i = 0; i < soLuong; i++) {
      String maTk;
      // Sinh mã ngẫu nhiên và kiểm tra tránh trùng lặp tuyệt đối
      do {
        final randomNum = 100000 + random.nextInt(900000); // 6 số ngẫu nhiên: 100000..999999
        maTk = '$prefix$randomNum';
      } while (existingCodes.contains(maTk));

      existingCodes.add(maTk);

      danhSach.add(TaiKhoanItem(
        maTk: maTk,
        matKhau: commonPassword,
        trangThai: 'Đợi kích hoạt',
      ));

      final docRef = _nhanVienCol.doc(maTk);
      batch.set(docRef, {
        'ma_nhan_vien': maTk,
        'ma_tai_khoan': maTk,
        'mat_khau': commonPassword,
        'role': roleCode,
        'vai_tro': vaiTro,
        'khoa': tenKhoa,
        'da_kich_hoat': false,
        'trang_thai': 'doi_kich_hoat',
        'ngay_tao': FieldValue.serverTimestamp(),
        'ho_ten': '$vaiTro ${maTk.split('_').last}',
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

  /// Kích hoạt tài khoản nhân viên
  Future<void> kichHoatTaiKhoan(String nhanVienId) async {
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
      return;
    }
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      await d.reference.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
    }
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      await d.reference.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
    }
  }

  /// Cập nhật trạng thái khóa / mở khóa tài khoản
  Future<void> capNhatTrangThai({
    required String nhanVienId,
    required bool dangHoatDong,
  }) async {
    final statusStr = dangHoatDong ? 'dang_hoat_dong' : 'da_khoa';
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
      return;
    }
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      await d.reference.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
    }
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      await d.reference.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
    }
  }

  /// Xóa tài khoản nhân viên
  Future<void> xoaNhanVien(String nhanVienId) async {
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.delete();
      return;
    }
    // Nếu document ID khác ma_nhan_vien, tìm và xóa theo ma_nhan_vien / ma_tai_khoan
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      await d.reference.delete();
    }
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      await d.reference.delete();
    }
  }
}
