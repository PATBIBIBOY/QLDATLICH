import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_session.dart';
import '../../services/khoa_service.dart';
import 'addKhoaHospital_Screen.dart';

// Trạng thái phòng khám: mã lưu trong Firestore -> (nhãn, màu nền, màu chữ)
const Map<String, String> _dsTrangThai = {
  'san_sang': 'Sẵn sàng',
  'dang_kham': 'Đang khám',
  'tam_dong': 'Tạm đóng',
};

(String, Color, Color) _trangThaiPhong(String? ma) {
  switch (ma) {
    case 'dang_kham':
      return ('Đang khám', const Color(0xFFE9F2FF), const Color(0xFF1D78D8));
    case 'tam_dong':
      return ('Tạm đóng', const Color(0xFFFEE2E2), const Color(0xFFDC2626));
    default: // san_sang, hoặc phòng cũ chưa có field trangThai
      return ('Sẵn sàng', const Color(0xFFE8F9F2), const Color(0xFF16A34A));
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
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
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
            child:
                const Text('Xóa Khoa', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await KhoaService().xoaKhoa(
        benhVienId: _bvid,
        khoaId: widget.khoaId,
      );
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
    final (nhan, nen, chu) = _trangThaiPhong(p['trangThai'] as String?);
    final ten = (p['tenPhong'] ?? p['ten_phong'] ?? p['id'] ?? '').toString();
    final gio = (p['gioMoCua'] != null && p['gioDongCua'] != null)
        ? '${p['gioMoCua']} - ${p['gioDongCua']}'
        : (p['gio_mo_cua'] != null && p['gio_dong_cua'] != null)
            ? '${p['gio_mo_cua']} - ${p['gio_dong_cua']}'
            : '-';

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
                  'Giờ khám: $gio  •  Tối đa ${p['soBenhNhanToiDa'] ?? '-'} BN/ca',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Đổi trạng thái',
            onSelected: (ma) async {
              try {
                await d.reference.update({'trangThai': ma});
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không đổi được trạng thái: $e')),
                );
              }
            },
            itemBuilder: (_) => [
              for (final e in _dsTrangThai.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
            child: _chip(nhan, nen, chu, mui: true),
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
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFDC2626)),
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
              final dau =
                  phong.isEmpty ? <String, dynamic>{} : phong.first.data();

              // Khoa tạo từ bản cũ chưa có khungGio/gioiHan -> lấy từ phòng đầu tiên
              final khungGio = currentData['khungGio'] ?? dau['khungGio'];
              final gioiHan =
                  currentData['gioiHanBenhNhan'] ?? dau['soBenhNhanToiDa'];

              // Đếm số phòng theo từng trạng thái
              final dem = {for (final k in _dsTrangThai.keys) k: 0};
              for (final d in phong) {
                final ma = d.data()['trangThai'] as String?;
                final k = dem.containsKey(ma) ? ma! : 'san_sang';
                dem[k] = dem[k]! + 1;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  _thongTinCard(currentData,
                      khungGio: khungGio, gioiHan: gioiHan),
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
                      for (final e in dem.entries)
                        () {
                          final (nhan, nen, chu) = _trangThaiPhong(e.key);
                          return _chip('$nhan: ${e.value}', nen, chu);
                        }(),
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
