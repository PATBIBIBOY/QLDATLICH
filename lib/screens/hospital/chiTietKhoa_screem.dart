import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_session.dart';
import '../../services/khoa_service.dart';
import 'addKhoaHospital_Screen.dart';

/// Model trạng thái phòng khám đồng bộ 100% với collection `TrangThai` trên Firebase Firestore:
/// - 11: Sẵn sàng (Phòng khám sẵn sàng tiếp nhận khám)
/// - 12: Tạm dừng (Phòng đang trong trạng thái tạm dừng khám)
/// - 13: Đang khám (Phòng khám đang trong trạng thái khám)
/// - 14: Đóng (Phòng khám đang đóng cửa)
class TrangThaiPhongModel {
  final int id;
  final String ma;
  final String tenTrangThai;
  final String moTa;
  final Color mauNen;
  final Color mauChu;

  const TrangThaiPhongModel({
    required this.id,
    required this.ma,
    required this.tenTrangThai,
    required this.moTa,
    required this.mauNen,
    required this.mauChu,
  });

  Map<String, dynamic> toFirestoreData() => {
    'id_trang_thai': id,
    'trang_thai_id': id,
    'trangThaiId': id,
    'trang_thai': ma,
    'trangThai': ma,
    'ten_trang_thai': tenTrangThai,
    'mo_ta_trang_thai': moTa,
  };
}

class DanhSachTrangThaiPhong {
  // static const sanSang = TrangThaiPhongModel(
  //   id: 15,
  //   ma: 'san_sang',
  //   tenTrangThai: 'Sẵn sàng',
  //   moTa: 'Phòng khám đang trong trạng thái sẵn sàng tiếp nhận khám',
  //   mauNen: Color(0xFFE8F9F2),
  //   mauChu: Color(0xFF16A34A),
  // );

  static const tamDung = TrangThaiPhongModel(
    id: 12,
    ma: 'tam_dung',
    tenTrangThai: 'Tạm dừng',
    moTa: 'Phòng đang trong trạng thái tạm dừng khám',
    mauNen: Color(0xFFFEF3C7),
    mauChu: Color(0xFFD97706),
  );

  static const dangKham = TrangThaiPhongModel(
    id: 13,
    ma: 'dang_kham',
    tenTrangThai: 'Đang khám',
    moTa: 'Phòng khám đang trong trạng thái khám',
    mauNen: Color(0xFFE9F2FF),
    mauChu: Color(0xFF1D78D8),
  );

  static const dong = TrangThaiPhongModel(
    id: 14,
    ma: 'dong',
    tenTrangThai: 'Đóng',
    moTa: 'Phòng khám đang đóng cửa',
    mauNen: Color(0xFFFEE2E2),
    mauChu: Color(0xFFDC2626),
  );

  static const List<TrangThaiPhongModel> danhSach = [
    // sanSang,
    dangKham,
    tamDung,
    dong,
  ];

  static TrangThaiPhongModel parse(dynamic rawValue) {
    // if (rawValue == null) return sanSang;
    if (rawValue == null) return tamDung;
    if (rawValue is int) {
      if (rawValue == 12) return tamDung;
      if (rawValue == 13) return dangKham;
      if (rawValue == 14) return dong;
      return tamDung;
    }
    final s = rawValue.toString().trim().toLowerCase();
    // if (s == '12' || s == 'tam_dung' || s == 'tam_dong' || s.contains('tạm')) {
    //   return tamDung;
    // }
    if (s == '13' || s == 'dang_kham' || s.contains('đang khám')) {
      return dangKham;
    }
    if (s == '14' || s == 'dong' || s == 'dong_cua' || s.contains('đóng')) {
      return dong;
    }
    return tamDung;
  }
}

/// [{batDau:'07:30', ketThuc:'11:30'}, ...] -> "07:30 - 11:30 | 13:30 - 17:00"
String _gioText(dynamic kg) {
  if (kg is! List || kg.isEmpty) return '-';
  return kg.map((e) => '${e['batDau']} - ${e['ketThuc']}').join(' | ');
}

String _getHospitalId() {
  if (AppSession.benhVienId.isNotEmpty) {
    return AppSession.benhVienId;
  }
  return FirebaseAuth.instance.currentUser?.uid ?? '';
}

class ChiTietKhoaScreen extends StatefulWidget {
  final String khoaId;
  final Map<String, dynamic> data;
  const ChiTietKhoaScreen({
    super.key,
    required this.khoaId,
    required this.data,
  });

  @override
  State<ChiTietKhoaScreen> createState() => _ChiTietKhoaScreenState();
}

class _ChiTietKhoaScreenState extends State<ChiTietKhoaScreen> {
  String get _bvid => _getHospitalId();

  DocumentReference<Map<String, dynamic>> get _khoaDocRef => FirebaseFirestore
      .instance
      .collection('Khoa')
      .doc(_bvid)
      .collection('danh_sach')
      .doc(widget.khoaId);

  CollectionReference<Map<String, dynamic>> get _phongRef =>
      _khoaDocRef.collection('phongKham');

  Future<void> _xacNhanXoaKhoa(String tenKhoa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận xóa khoa?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa khoa "$tenKhoa" cùng toàn bộ phòng khám liên quan không? Thao tác này không thể hoàn tác.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa Khoa',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await KhoaService().xoaKhoa(benhVienId: _bvid, khoaId: widget.khoaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa thành công khoa "$tenKhoa"'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa khoa: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _dong(String nhan, Widget giaTri) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nhan,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: giaTri),
        ),
      ],
    ),
  );

  Widget _chip(String nhan, Color nen, Color chu, {bool mui = false}) =>
      Container(
        padding: EdgeInsets.fromLTRB(10, 5, mui ? 4 : 10, 5),
        decoration: BoxDecoration(
          color: nen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nhan,
              style: TextStyle(
                color: chu,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (mui) Icon(Icons.arrow_drop_down, size: 18, color: chu),
          ],
        ),
      );

  Widget _thongTinCard(
    Map<String, dynamic> data, {
    required dynamic khungGio,
    required dynamic gioiHan,
  }) {
    const dam = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    final lich = (data['lichLamViec'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (data['tenKhoa'] ?? data['ten_khoa'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const Divider(height: 16),
          _dong(
            'Số ca khám:',
            Text('${data['soCaMoiNgay'] ?? '-'} ca / ngày', style: dam),
          ),
          _dong(
            'Số lượng BN tối đa:',
            Text('${gioiHan ?? '-'} bệnh nhân / ca', style: dam),
          ),
          _dong(
            'Thời gian:',
            Text(_gioText(khungGio), textAlign: TextAlign.right, style: dam),
          ),
          _dong(
            'Lịch khám:',
            lich.isEmpty
                ? const Text('-', style: dam)
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEFB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lich,
                      style: const TextStyle(
                        color: Color(0xFF0B5CAD),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _phongTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final p = d.data();
    final tt = DanhSachTrangThaiPhong.parse(
      p['trang_thai_id'] ??
          p['id_trang_thai'] ??
          p['trangThaiId'] ??
          p['trang_thai'] ??
          p['trangThai'],
    );
    final ten = (p['tenPhong'] ?? p['ten_phong'] ?? p['id'] ?? '').toString();
    final gio = (p['gioMoCua'] != null && p['gioDongCua'] != null)
        ? '${p['gioMoCua']} - ${p['gioDongCua']}'
        : (p['gio_mo_cua'] != null && p['gio_dong_cua'] != null)
        ? '${p['gio_mo_cua']} - ${p['gio_dong_cua']}'
        : '-';
    final soBn = p['soBenhNhanToiDa'] ?? p['so_benh_nhan_toi_da'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ten.isEmpty ? 'Phòng khám' : ten,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Giờ khám: $gio  •  Tối đa $soBn BN/ca',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<TrangThaiPhongModel>(
            tooltip: 'Đổi trạng thái phòng khám',
            onSelected: (ttMoi) async {
              try {
                final updateData = ttMoi.toFirestoreData();
                updateData['thoi_gian_cap_nhat'] = FieldValue.serverTimestamp();
                updateData['thoiGianCapNhat'] = FieldValue.serverTimestamp();

                final pkDocId = (p['id'] ?? '${_bvid}_${widget.khoaId}_$ten')
                    .toString();

                final batch = FirebaseFirestore.instance.batch();

                // 1. Cập nhật subcollection Khoa/.../phongKham
                batch.set(d.reference, updateData, SetOptions(merge: true));

                // 2. Cập nhật root collection PhongKham/{pkDocId} (hình 5 Firestore)
                final rootRef = FirebaseFirestore.instance
                    .collection('PhongKham')
                    .doc(pkDocId);
                batch.set(rootRef, updateData, SetOptions(merge: true));

                // 3. Cập nhật nested subcollection PhongKham/{bvId}/danh_sach/{khoaId}/danh_sach/{pkDocId}
                final treeRef = FirebaseFirestore.instance
                    .collection('PhongKham')
                    .doc(_bvid)
                    .collection('danh_sach')
                    .doc(widget.khoaId)
                    .collection('danh_sach')
                    .doc(pkDocId);
                batch.set(treeRef, updateData, SetOptions(merge: true));

                await batch.commit();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã cập nhật $ten sang "${ttMoi.tenTrangThai}"',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi đổi trạng thái: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              for (final item in DanhSachTrangThaiPhong.danhSach)
                PopupMenuItem<TrangThaiPhongModel>(
                  value: item,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.mauChu,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.tenTrangThai,
                        style: TextStyle(
                          fontWeight: item.id == tt.id
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
            ],
            child: _chip(tt.tenTrangThai, tt.mauNen, tt.mauChu, mui: true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _khoaDocRef.snapshots(),
      builder: (context, khoaSnap) {
        final currentData = khoaSnap.data?.data() ?? widget.data;
        final tenKhoa = (currentData['tenKhoa'] ?? 'Khoa khám').toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            title: Text(
              tenKhoa,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFFF5F7FB),
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Sửa khoa',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThemKhoaScreen(
                        benhVienId: _bvid,
                        khoaId: widget.khoaId,
                        duLieuKhoa: currentData,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Xóa khoa',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                ),
                onPressed: () => _xacNhanXoaKhoa(tenKhoa),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _phongRef.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final phong = [...snap.data!.docs]
                ..sort(
                  (a, b) => (a.data()['tenPhong'] ?? '').toString().compareTo(
                    (b.data()['tenPhong'] ?? '').toString(),
                  ),
                );
              final dau = phong.isEmpty
                  ? <String, dynamic>{}
                  : phong.first.data();

              // Khoa tạo từ bản cũ chưa có khungGio/gioiHan -> lấy từ phòng đầu tiên
              final khungGio = currentData['khungGio'] ?? dau['khungGio'];
              final gioiHan =
                  currentData['gioiHanBenhNhan'] ?? dau['soBenhNhanToiDa'];

              // Đếm số phòng theo từng trạng thái chuẩn Firestore TrangThai (11, 13, 12, 14)
              final dem = {
                for (final item in DanhSachTrangThaiPhong.danhSach) item.id: 0,
              };
              for (final d in phong) {
                final pData = d.data();
                final tt = DanhSachTrangThaiPhong.parse(
                  pData['trang_thai_id'] ??
                      pData['id_trang_thai'] ??
                      pData['trangThaiId'] ??
                      pData['trang_thai'] ??
                      pData['trangThai'],
                );
                dem[tt.id] = (dem[tt.id] ?? 0) + 1;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  _thongTinCard(
                    currentData,
                    khungGio: khungGio,
                    gioiHan: gioiHan,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        'Trạng thái phòng khám (${phong.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final item in DanhSachTrangThaiPhong.danhSach)
                        _chip(
                          '${item.tenTrangThai}: ${dem[item.id] ?? 0}',
                          item.mauNen,
                          item.mauChu,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (phong.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Khoa chưa có phòng khám',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    for (final d in phong) _phongTile(context, d),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
