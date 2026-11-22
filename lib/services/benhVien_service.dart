import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/app_session.dart';

class BenhVienService {
  static final Map<String, String> _cache = {};

  /// _chuanHoa: chuẩn hóa tên field (chữ thường, bỏ dấu gạch dưới và khoảng trắng) để so khớp.
  static String _chuanHoa(String k) =>
      k.toLowerCase().replaceAll('_', '').replaceAll(' ', '');

  /// _timTen: tìm tên bệnh viện trong document, chấp nhận nhiều kiểu đặt tên field (ten_benh_vien, tenBenhVien, ten, name...).
  static String _timTen(Map<String, dynamic> data) {
    const uuTien = ['tenbenhvien', 'tenbv', 'ten', 'name', 'hospitalname'];
    final chuan = {for (final e in data.entries) _chuanHoa(e.key): e.value};
    for (final k in uuTien) {
      final v = chuan[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    for (final e in data.entries) {
      final v = e.value;
      if (_chuanHoa(e.key).startsWith('ten') &&
          v is String &&
          v.trim().isNotEmpty) {
        return v.trim();
      }
    }
    return '';
  }

  /// layTen: lấy tên bệnh viện theo ID (có cache); trả về chuỗi rỗng nếu không tìm thấy, ném lỗi nếu Firestore từ chối.
  /// Có AppSession.benhVienPath thì đọc thẳng document đó, không thì tìm trong 'BenhVien' rồi quét collection group 'danh_sach' (bỏ nhánh Khoa/).
  static Future<String> layTen(String benhVienId) async {
    if (_cache.containsKey(benhVienId)) return _cache[benhVienId]!;
    final db = FirebaseFirestore.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      final path = AppSession.benhVienPath;

      if (path != null) {
        doc = await db.doc(path).get();
        if (!doc.exists) doc = null;
      } else {
        // 1. Kiểm tra trực tiếp trong collection BenhVien/{benhVienId}
        final docDirect = await db.collection('BenhVien').doc(benhVienId).get();
        if (docDirect.exists) {
          doc = docDirect;
        } else {
          // 2. Dự phòng: quét collectionGroup danh_sach
          final all = await db.collectionGroup('danh_sach').get();
          for (final d in all.docs) {
            if (d.id == benhVienId && !d.reference.path.startsWith('Khoa/')) {
              doc = d;
              break;
            }
          }
          if (doc == null) {
            debugPrint(
              '[BenhVienService] Đã quét ${all.docs.length} document '
              'trong danh_sach nhưng không có ID "$benhVienId".',
            );
          }
        }
      }

      if (doc == null) return '';

      final data = doc.data() ?? {};
      debugPrint('[BenhVienService] Tìm thấy: ${doc.reference.path}');
      debugPrint('[BenhVienService] Các field: ${data.keys.toList()}');

      final ten = _timTen(data);
      if (ten.isEmpty) {
        debugPrint('[BenhVienService] Document có nhưng không thấy field tên.');
        return '';
      }
      _cache[benhVienId] = ten;
      return ten;
    } catch (e) {
      debugPrint('[BenhVienService] Lỗi đọc tên bệnh viện: $e');
      rethrow;
    }
  }

  /// homNay: trả về ngày hôm nay dạng "yyyy-MM-dd" (id document thống kê).
  static String homNay() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// thongKeHomNay: lắng nghe thống kê hôm nay (tongBenhNhan, dangKham) tại ThongKe/{benhVienId}/danh_sach/{yyyy-MM-dd}.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> thongKeHomNay(
    String benhVienId,
  ) => FirebaseFirestore.instance
      .collection('ThongKe')
      .doc(benhVienId)
      .collection('danh_sach')
      .doc(homNay())
      .snapshots();

  /// tangBenhNhan: cộng dồn số bệnh nhân hôm nay khi có người đăng ký hoặc bắt đầu khám (tự tạo document nếu chưa có).
  static Future<void> tangBenhNhan(
    String benhVienId, {
    int tong = 1,
    int dangKham = 0,
  }) {
    return FirebaseFirestore.instance
        .collection('ThongKe')
        .doc(benhVienId)
        .collection('danh_sach')
        .doc(homNay())
        .set({
          'tongBenhNhan': FieldValue.increment(tong),
          'dangKham': FieldValue.increment(dangKham),
        }, SetOptions(merge: true));
  }
}