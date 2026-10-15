import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_session.dart';
import 'chiTietKhoa_screem.dart';

Stream<QuerySnapshot<Map<String, dynamic>>> _khoaStream() => FirebaseFirestore
    .instance
    .collection('Khoa')
    .doc(AppSession.benhVienId)
    .collection('danh_sach')
    .orderBy('ngayTao', descending: true)
    .snapshots();

// ===================== THẺ "TỔNG SỐ KHOA KHÁM" =====================
// Dùng thay cho _StatCard đầu tiên ở màn Trang chủ: const TongSoKhoaCard()
class TongSoKhoaCard extends StatelessWidget {
  const TongSoKhoaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _khoaStream(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final dauThang = DateTime(DateTime.now().year, DateTime.now().month);
        final moi = docs.where((d) {
          final t = d.data()['ngayTao'];
          // ngayTao null = vừa tạo, server chưa kịp ghi giờ
          return t == null || (t as Timestamp).toDate().isAfter(dauThang);
        }).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E96D8), Color(0xFF1C88D9)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng số khoa khám',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${docs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+$moi khoa mới tháng này',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================== DANH SÁCH KHOA ĐIỀU TRỊ =====================
class ListKhoaDieuTri extends StatelessWidget {
  const ListKhoaDieuTri({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _khoaStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'Danh sách khoa điều trị',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TatCaKhoaScreen(),
                      ),
                    ),
                    child: Text(
                      'Xem tất cả (${docs.length})',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: docs.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có khoa nào. Bấm "Thêm Khoa Khám Mới".',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => KhoaCard(
                        data: docs[i].data(),
                        onTap: () => _moChiTiet(ctx, docs[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// Bấm vào thẻ khoa -> mở màn chi tiết (thông tin khoa + trạng thái phòng khám)
void _moChiTiet(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChiTietKhoaScreen(khoaId: doc.id, data: doc.data()),
    ),
  );
}

// trangThai -> (nhãn, màu nền, màu chữ)
(String, Color, Color) _trangThai(String? ma) {
  switch (ma) {
    case 'day_lich_sang':
      return (
        'Đầy lịch sáng',
        const Color(0xFFFFF3D8),
        const Color(0xFFB7791F),
      );
    case 'dong_cua':
      return ('Đóng cửa', const Color(0xFFFEE2E2), const Color(0xFFDC2626));
    default:
      return ('Đang mở', const Color(0xFFE8F9F2), const Color(0xFF16A34A));
  }
}

class KhoaCard extends StatelessWidget {
  const KhoaCard({super.key, required this.data, this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: _noiDung(context),
  );

  Widget _noiDung(BuildContext context) {
    final (nhan, nen, chu) = _trangThai(data['trangThai'] as String?);
    final soPhong = data['soPhong'] ?? 0;
    final phongDau = (data['phongDau'] ?? '') as String;
    final phuDe = phongDau.isEmpty
        ? '$soPhong phòng khám'
        : (soPhong > 1 ? '$phongDau (+${soPhong - 1} phòng)' : phongDau);
    final hinh = (data['hinhAnh'] ?? '') as String;
    final gioiHan = data['gioiHanBenhNhan'];
    const xam = TextStyle(
      color: Color(0xFF4B5563),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['tenKhoa'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phuDe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: nen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  nhan,
                  style: TextStyle(
                    color: chu,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hinh.isEmpty
                ? Container(
                    width: double.infinity,
                    height: 76,
                    color: const Color(0xFFE5E7EB),
                  )
                : Image.network(
                    hinh,
                    width: double.infinity,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Số ca: ${data['soCaMoiNgay'] ?? '-'} ca/ngày',
                  style: xam,
                ),
              ),
              Expanded(
                child: Text(
                  'Giới hạn: ${gioiHan ?? '-'} BN/buổi',
                  textAlign: TextAlign.right,
                  style: xam,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              data['lichLamViec'] ?? '',
              style: const TextStyle(
                color: Color(0xFF1D78D8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== MÀN HÌNH "XEM TẤT CẢ" =====================
class TatCaKhoaScreen extends StatefulWidget {
  /// laTab = true: hiển thị như tab "Khoa khám" (có thanh điều hướng dưới).
  /// laTab = false: trang "Xem tất cả" thông thường (có nút quay lại).
  final bool laTab;
  const TatCaKhoaScreen({super.key, this.laTab = false});

  @override
  State<TatCaKhoaScreen> createState() => _TatCaKhoaScreenState();
}

class _TatCaKhoaScreenState extends State<TatCaKhoaScreen> {
  String _tuKhoa = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.laTab,
        title: Text(
          widget.laTab ? 'Khoa khám' : 'Tất cả khoa khám',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
      ),
      bottomNavigationBar: widget.laTab ? const _ThanhDieuHuong() : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _tuKhoa = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm khoa khám...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _khoaStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs.where((d) {
                  final ten = (d.data()['tenKhoa'] ?? '').toString();
                  return ten.toLowerCase().contains(_tuKhoa);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có khoa nào phù hợp',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => KhoaCard(
                    data: docs[i].data(),
                    onTap: () => _moChiTiet(ctx, docs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== THANH ĐIỀU HƯỚNG CỦA TAB "KHOA KHÁM" =====================
class _ThanhDieuHuong extends StatelessWidget {
  const _ThanhDieuHuong();

  @override
  Widget build(BuildContext context) {
    Widget muc(
      IconData icon,
      String nhan, {
      bool active = false,
      VoidCallback? onTap,
    }) {
      final mau = active ? const Color(0xFF1D7BFF) : const Color(0xFF7A8196);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: mau, size: 22),
              const SizedBox(height: 4),
              Text(
                nhan,
                style: TextStyle(
                  color: mau,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Trang chủ nằm ngay bên dưới trong stack, nên chỉ cần quay lại
              muc(
                Icons.home_rounded,
                'Trang chủ',
                onTap: () => Navigator.of(context).pop(),
              ),
              muc(Icons.calendar_today_rounded, 'Khoa khám', active: true),
              muc(Icons.people_alt_rounded, 'Nhân viên'),
              muc(Icons.settings_rounded, 'Cài đặt'),
            ],
          ),
        ),
      ),
    );
  }
}
