import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';

/// Module Chat CSKH thời gian thực (C1)
class LetanChatServiceC1 {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream danh sách các cuộc hội thoại CSKH realtime
  static Stream<List<Map<String, dynamic>>> streamDanhSachHoiThoaiCskh([String? benhVienId]) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    return _firestore
        .collection('Chat_CSKH')
        .where('benh_vien_id', isEqualTo: bvid)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];

      final list = snap.docs.map((doc) {
        final d = doc.data();
        final rawTs = d['thoi_gian_cuoi'] ?? d['updated_at'] ?? d['timestamp'];
        DateTime time;
        if (rawTs is Timestamp) {
          time = rawTs.toDate();
        } else {
          time = DateTime.now();
        }

        return {
          'id': doc.id,
          'docPath': doc.reference.path,
          'hoTen': d['ho_ten'] ?? d['hoTen'] ?? 'Bệnh nhân',
          'tinNhanCuoi': d['tin_nhan_cuoi'] ?? d['noi_dung'] ?? '...',
          'thoiGian': time,
          'soChuaDoc': (d['so_chua_doc'] as num?)?.toInt() ?? 0,
          'anhDaiDien': d['anh_dai_dien'] ?? '',
          'sdt': d['sdt'] ?? '',
          'benhNhanId': d['benh_nhan_id'] ?? '',
        };
      }).toList();

      list.sort((a, b) => (b['thoiGian'] as DateTime).compareTo(a['thoiGian'] as DateTime));
      return list;
    });
  }

  /// Stream tin nhắn trong 1 hội thoại cụ thể
  static Stream<List<Map<String, dynamic>>> streamTinNhanCskh({
    required String hoiThoaiId,
    String? docPath,
  }) {
    CollectionReference<Map<String, dynamic>> ref;
    if (docPath != null && docPath.isNotEmpty) {
      ref = _firestore.doc(docPath).collection('tin_nhan');
    } else {
      ref = _firestore.collection('Chat_CSKH').doc(hoiThoaiId).collection('tin_nhan');
    }

    return ref.orderBy('timestamp', descending: false).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        final rawTs = data['timestamp'];
        DateTime time;
        if (rawTs is Timestamp) {
          time = rawTs.toDate();
        } else {
          time = DateTime.now();
        }

        return {
          'id': d.id,
          'noiDung': data['noi_dung'] ?? '',
          'laCskh': data['la_cskh'] ?? false,
          'nguoiGui': data['nguoi_gui'] ?? '',
          'thoiGian': time,
        };
      }).toList();
    });
  }

  /// Gửi tin nhắn từ phía CSKH
  static Future<void> guiTinNhanCskh({
    required String hoiThoaiId,
    String? docPath,
    required String noiDung,
    required String maNv,
    required String tenNv,
  }) async {
    if (noiDung.trim().isEmpty) return;

    DocumentReference<Map<String, dynamic>> parentRef;
    if (docPath != null && docPath.isNotEmpty) {
      parentRef = _firestore.doc(docPath);
    } else {
      parentRef = _firestore.collection('Chat_CSKH').doc(hoiThoaiId);
    }

    // 1. Thêm vào subcollection tin_nhan
    await parentRef.collection('tin_nhan').add({
      'noi_dung': noiDung.trim(),
      'la_cskh': true,
      'nguoi_gui': '$tenNv ($maNv)',
      'ma_nhan_vien': maNv,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật tin nhắn cuối trên doc cha
    await parentRef.set({
      'tin_nhan_cuoi': noiDung.trim(),
      'thoi_gian_cuoi': FieldValue.serverTimestamp(),
      'so_chua_doc': 0,
    }, SetOptions(merge: true));
  }
}
