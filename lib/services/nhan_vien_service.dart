import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../models/nhan_vien_model.dart';

class NhanVienService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _nhanVienCol =>
      _db.collection('NhanVien');

  /// Stream danh sách nhân viên theo thời gian thực (chỉ của bệnh viện hiện tại & chỉ hiển thị nhân viên đã kích hoạt)
  Stream<List<NhanVienModel>> streamNhanVien({
    String? benhVienId,
    bool chiLayDaKichHoat = true,
  }) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    Query<Map<String, dynamic>> query = _nhanVienCol;
    if (bvid.isNotEmpty) {
      query = query.where('benh_vien_id', isEqualTo: bvid);
    }

    return query.snapshots().map((snap) {
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

  /// Lấy danh sách tài khoản vừa tạo đang ở trạng thái đợi kích hoạt (chỉ của bệnh viện này)
  Future<List<TaiKhoanItem>> layDanhSachTaiKhoanChuaKichHoat([String? benhVienId]) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    Query<Map<String, dynamic>> query = _nhanVienCol;
    if (bvid.isNotEmpty) {
      query = query.where('benh_vien_id', isEqualTo: bvid);
    }

    final snap = await query.get();
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
        id: d.id,
        benhVienId: (data['benh_vien_id'] ?? bvid).toString(),
        maTk: maTk,
        matKhau: matKhau,
        trangThai: 'Đợi kích hoạt',
      ));
    }
    return list;
  }

  /// Tương thích ngược: Lấy danh sách tài khoản đợi kích hoạt
  Future<List<TaiKhoanItem>> layDanhSachTaiKhoan([String? benhVienId]) =>
      layDanhSachTaiKhoanChuaKichHoat(benhVienId);

  /// Cấp mới danh sách tài khoản nhân viên và lưu đồng loạt bằng WriteBatch
  /// - ID trong Firebase là ID tự sinh của Firebase (doc().id), không lấy mã tài khoản làm id
  /// - Gắn benh_vien_id để chỉ hiển thị trong đúng tài khoản bệnh viện tạo ra
  /// - Mã tài khoản được tạo ngẫu nhiên và đảm bảo không trùng lặp
  /// - Mật khẩu là duy nhất cho tất cả các tài khoản
  Future<DotCapTaiKhoan> taoVaLuuNhanVien({
    String? benhVienId,
    required String tenKhoa,
    required String deptCode,
    required String vaiTro,
    required String rolePrefix,
    required String roleCode,
    required int soLuong,
    String matKhau = '123456',
  }) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

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

      // ✅ TỰ SINH ID TỪ FIREBASE THAY VÌ LẤY maTk LÀM ID
      final docRef = _nhanVienCol.doc();

      danhSach.add(TaiKhoanItem(
        id: docRef.id,
        benhVienId: bvid,
        maTk: maTk,
        matKhau: commonPassword,
        trangThai: 'Đợi kích hoạt',
      ));

      final staffData = {
        'id': docRef.id,
        'benh_vien_id': bvid,
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
      };

      batch.set(docRef, staffData);

      // Lưu đồng bộ vào subcollection BenhVien/{bvid}/NhanVien/{docRef.id}
      if (bvid.isNotEmpty) {
        final subDocRef = _db
            .collection('BenhVien')
            .doc(bvid)
            .collection('NhanVien')
            .doc(docRef.id);
        batch.set(subDocRef, staffData);
      }
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
  Future<void> kichHoatTaiKhoan(String nhanVienId, [String? benhVienId]) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    // 1. Tìm theo docId trực tiếp
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
      final hId = docSnap.data()?['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(nhanVienId)
              .update({
            'da_kich_hoat': true,
            'trang_thai': 'dang_hoat_dong',
          });
        } catch (_) {}
      }
      return;
    }

    // 2. Tìm theo ma_nhan_vien
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      await d.reference.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .update({
            'da_kich_hoat': true,
            'trang_thai': 'dang_hoat_dong',
          });
        } catch (_) {}
      }
    }

    // 3. Tìm theo ma_tai_khoan
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      await d.reference.update({
        'da_kich_hoat': true,
        'trang_thai': 'dang_hoat_dong',
      });
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .update({
            'da_kich_hoat': true,
            'trang_thai': 'dang_hoat_dong',
          });
        } catch (_) {}
      }
    }
  }

  /// Cập nhật trạng thái khóa / mở khóa tài khoản
  Future<void> capNhatTrangThai({
    required String nhanVienId,
    required bool dangHoatDong,
    String? benhVienId,
  }) async {
    final statusStr = dangHoatDong ? 'dang_hoat_dong' : 'da_khoa';
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    // 1. Tìm theo docId trực tiếp
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
      final hId = docSnap.data()?['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(nhanVienId)
              .update({
            'trang_thai': statusStr,
            'da_kich_hoat': true,
          });
        } catch (_) {}
      }
      return;
    }

    // 2. Tìm theo ma_nhan_vien
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      await d.reference.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .update({
            'trang_thai': statusStr,
            'da_kich_hoat': true,
          });
        } catch (_) {}
      }
    }

    // 3. Tìm theo ma_tai_khoan
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      await d.reference.update({
        'trang_thai': statusStr,
        'da_kich_hoat': true,
      });
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .update({
            'trang_thai': statusStr,
            'da_kich_hoat': true,
          });
        } catch (_) {}
      }
    }
  }

  /// Xóa tài khoản nhân viên (xóa cả trên collection NhanVien và subcollection BenhVien/{bvid}/NhanVien)
  Future<void> xoaNhanVien(String nhanVienId, [String? benhVienId]) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty)
        ? benhVienId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? AppSession.benhVienId);

    // 1. Thử xóa theo docId trực tiếp
    final docRef = _nhanVienCol.doc(nhanVienId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final hId = docSnap.data()?['benh_vien_id']?.toString() ?? bvid;
      await docRef.delete();
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(nhanVienId)
              .delete();
        } catch (_) {}
      }
      return;
    }

    // 2. Tìm và xóa theo ma_nhan_vien
    final q1 = await _nhanVienCol
        .where('ma_nhan_vien', isEqualTo: nhanVienId)
        .get();
    for (final d in q1.docs) {
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      await d.reference.delete();
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .delete();
        } catch (_) {}
      }
    }

    // 3. Tìm và xóa theo ma_tai_khoan
    final q2 = await _nhanVienCol
        .where('ma_tai_khoan', isEqualTo: nhanVienId)
        .get();
    for (final d in q2.docs) {
      final hId = d.data()['benh_vien_id']?.toString() ?? bvid;
      await d.reference.delete();
      if (hId.isNotEmpty) {
        try {
          await _db
              .collection('BenhVien')
              .doc(hId)
              .collection('NhanVien')
              .doc(d.id)
              .delete();
        } catch (_) {}
      }
    }
  }
}
