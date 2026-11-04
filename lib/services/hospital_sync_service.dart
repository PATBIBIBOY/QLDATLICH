import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

/// Dịch vụ quản lý đồng bộ 2 chiều trạng thái giữa [BenhVien] và [YeuCauHopTac],
/// đồng thời chuẩn hóa dữ liệu cần thiết (bhyt, co_so, chuyen_khoa_ids).
class HospitalSyncService {
  static bool _isSyncing = false;

  /// Xây dựng đầy đủ các trường trạng thái đồng bộ cho cả BenhVien và YeuCauHopTac:
  /// - trang_thai_hop_tac_id: 1, 9, 10
  /// - trangThai: "CHO_DUYET", "HUY_HOP_TAC", "HOP_TAC"
  /// - trang_thai: "cho_duyet", "huy_hop_tac", "hop_tac"
  /// - da_gui_don, da_bi_tu_choi, da_xac_thuc
  static Map<String, dynamic> buildStatusFields(dynamic rawStatus) {
    final int statusId = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus?.toString() ?? '') ?? TrangThaiId.choDuyet;

    final String trangThaiUpper;
    final String trangThaiLower;
    final bool daGuiDon;
    final bool daBiTuChoi;
    final bool daXacThuc;

    switch (statusId) {
      case TrangThaiId.hopTac: // 10
        trangThaiUpper = 'HOP_TAC';
        trangThaiLower = 'hop_tac';
        daGuiDon = true;
        daBiTuChoi = false;
        daXacThuc = true;
        break;
      case TrangThaiId.huyHopTac: // 9
        trangThaiUpper = 'HUY_HOP_TAC';
        trangThaiLower = 'huy_hop_tac';
        daGuiDon = false;
        daBiTuChoi = true;
        daXacThuc = false;
        break;
      case TrangThaiId.choDuyet: // 1
      default:
        trangThaiUpper = 'CHO_DUYET';
        trangThaiLower = 'cho_duyet';
        daGuiDon = true;
        daBiTuChoi = false;
        daXacThuc = false;
        break;
    }

    return {
      'trang_thai_hop_tac_id': statusId,
      'trangThai': trangThaiUpper,
      'trang_thai': trangThaiLower,
      'da_gui_don': daGuiDon,
      'da_bi_tu_choi': daBiTuChoi,
      'da_xac_thuc': daXacThuc,
    };
  }

  /// Đồng bộ dữ liệu trạng thái từ YeuCauHopTac sang BenhVien
  static Future<void> dongBoSangBenhVien(
    String bvid,
    int newStatus, [
    Map<String, dynamic>? sourceData,
  ]) async {
    if (_isSyncing || bvid.isEmpty) return;
    try {
      _isSyncing = true;
      final bvRef = FirebaseFirestore.instance.collection('BenhVien').doc(bvid);
      final bvSnap = await bvRef.get();
      final currentBvData = bvSnap.data();

      final currentBvRawStatus = currentBvData?['trang_thai_hop_tac_id'];
      final currentBvStatus = currentBvRawStatus is int
          ? currentBvRawStatus
          : int.tryParse(currentBvRawStatus?.toString() ?? '');

      final currentUpper = currentBvData?['trangThai'];
      final currentLower = currentBvData?['trang_thai'];

      final statusFields = buildStatusFields(newStatus);

      // Cập nhật nếu trạng thái ID khác nhau hoặc thiếu chuỗi trạng thái
      if (currentBvStatus != newStatus ||
          currentUpper != statusFields['trangThai'] ||
          currentLower != statusFields['trang_thai'] ||
          !bvSnap.exists) {
        debugPrint('🔄 [SYNC 2 CHIỀU] Đồng bộ YeuCauHopTac ($newStatus) -> BenhVien/$bvid');
        await bvRef.set(statusFields, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('⚠️ [SYNC] Lỗi đồng bộ sang BenhVien: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Đồng bộ dữ liệu trạng thái từ BenhVien sang YeuCauHopTac
  static Future<void> dongBoSangYeuCauHopTac(
    String bvid,
    int newStatus, [
    Map<String, dynamic>? sourceData,
  ]) async {
    if (_isSyncing || bvid.isEmpty) return;
    try {
      _isSyncing = true;
      final ycRef = FirebaseFirestore.instance.collection('YeuCauHopTac').doc(bvid);
      final ycSnap = await ycRef.get();
      if (!ycSnap.exists) return; // Nếu chưa từng gửi đơn thì không tự ý tạo mới

      final currentYcData = ycSnap.data();
      final currentYcRawStatus = currentYcData?['trang_thai_hop_tac_id'];
      final currentYcStatus = currentYcRawStatus is int
          ? currentYcRawStatus
          : int.tryParse(currentYcRawStatus?.toString() ?? '');

      final currentUpper = currentYcData?['trangThai'];
      final currentLower = currentYcData?['trang_thai'];

      final statusFields = buildStatusFields(newStatus);

      if (currentYcStatus != newStatus ||
          currentUpper != statusFields['trangThai'] ||
          currentLower != statusFields['trang_thai']) {
        debugPrint('🔄 [SYNC 2 CHIỀU] Đồng bộ BenhVien ($newStatus) -> YeuCauHopTac/$bvid');
        await ycRef.set(statusFields, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('⚠️ [SYNC] Lỗi đồng bộ sang YeuCauHopTac: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Quét định kỳ / khi khởi chạy để đồng bộ 2 chiều và chuẩn hóa dữ liệu
  static Future<void> quetVaChuanHoaBenhVienDaGuiDon() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Quét từ YeuCauHopTac -> đồng bộ sang BenhVien
      final snapYeuCau = await firestore.collection('YeuCauHopTac').get();
      for (final doc in snapYeuCau.docs) {
        final data = doc.data();
        final rawStatus = data['trang_thai_hop_tac_id'];
        if (rawStatus != null) {
          final int statusId = rawStatus is int
              ? rawStatus
              : int.tryParse(rawStatus.toString()) ?? 1;

          final targetId = doc.id;
          final bvDocRef = firestore.collection('BenhVien').doc(targetId);
          final bvSnap = await bvDocRef.get();
          if (bvSnap.exists) {
            final bvData = bvSnap.data();
            final currentBvRaw = bvData?['trang_thai_hop_tac_id'];
            final currentBvStatus = currentBvRaw is int
                ? currentBvRaw
                : int.tryParse(currentBvRaw?.toString() ?? '');

            final expectedFields = buildStatusFields(statusId);
            if (currentBvStatus != statusId ||
                bvData?['trangThai'] != expectedFields['trangThai'] ||
                bvData?['trang_thai'] != expectedFields['trang_thai']) {
              await bvDocRef.set(expectedFields, SetOptions(merge: true));
            }
          }
        }
      }

      // 2. Quét từ BenhVien -> YeuCauHopTac nếu có tài liệu bị lệch
      final snapBvAll = await firestore.collection('BenhVien').get();
      for (final doc in snapBvAll.docs) {
        final data = doc.data();
        final rawStatus = data['trang_thai_hop_tac_id'];
        if (rawStatus != null) {
          final int statusId = rawStatus is int
              ? rawStatus
              : int.tryParse(rawStatus.toString()) ?? 1;

          final ycDocRef = firestore.collection('YeuCauHopTac').doc(doc.id);
          final ycSnap = await ycDocRef.get();
          if (ycSnap.exists) {
            final ycData = ycSnap.data();
            final currentYcRaw = ycData?['trang_thai_hop_tac_id'];
            final currentYcStatus = currentYcRaw is int
                ? currentYcRaw
                : int.tryParse(currentYcRaw?.toString() ?? '');

            final expectedFields = buildStatusFields(statusId);
            if (currentYcStatus != statusId ||
                ycData?['trangThai'] != expectedFields['trangThai'] ||
                ycData?['trang_thai'] != expectedFields['trang_thai']) {
              await ycDocRef.set(expectedFields, SetOptions(merge: true));
            }
          }
        }
      }

      // 3. Chuẩn hóa co_so, bhyt, chuyen_khoa_ids
      final snapBv = await firestore
          .collection('BenhVien')
          .where('da_gui_don', isEqualTo: true)
          .get();
      for (final doc in snapBv.docs) {
        chuanHoaDuLieuFirebaseNeuThieu(doc);
      }
    } catch (e) {
      debugPrint('⚠️ [HospitalSyncService] Lỗi quét chuẩn hóa dữ liệu: $e');
    }
  }

  /// Bổ sung co_so, bhyt, chuyen_khoa_ids nếu còn thiếu
  static void chuanHoaDuLieuFirebaseNeuThieu(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return;
    final bool canCapNhat = data['bhyt'] == null ||
        data['co_so'] == null ||
        data['chuyen_khoa_ids'] == null;
    if (canCapNhat) {
      final updates = <String, dynamic>{};
      if (data['bhyt'] == null) {
        final coBhyt = data['co_bhyt'];
        updates['bhyt'] = (coBhyt == false) ? 'Khong_BHYT' : 'Co_BHYT';
      }
      if (data['co_so'] == null) {
        final loaiHinh = (data['loai_hinh'] ?? '').toString().toLowerCase();
        updates['co_so'] =
            (loaiHinh.contains('công') || loaiHinh.contains('cong'))
                ? 'Cong_lap'
                : 'Tu_nhan';
      }
      if (data['chuyen_khoa_ids'] == null) {
        updates['chuyen_khoa_ids'] = <String>[];
      }
      doc.reference.update(updates).catchError((_) {});
      try {
        FirebaseFirestore.instance
            .collection('YeuCauHopTac')
            .doc(doc.id)
            .set(updates, SetOptions(merge: true))
            .catchError((_) {});
      } catch (_) {}
    }
  }
}
