import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import '../../services/khoa_service.dart';
import 'addKhoaHospital_Screen.dart';
import 'chiTietKhoa_screem.dart';

String _getBenhVienId() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) return uid;
  return AppSession.benhVienId;
}

Stream<QuerySnapshot<Map<String, dynamic>>> _khoaStream() => FirebaseFirestore
    .instance
    .collection('Khoa')
    .doc(_getBenhVienId())
    .collection('danh_sach')
    .orderBy('ngayTao', descending: true)
    .snapshots();

// ===================== THẺ "TỔNG SỐ KHOA KHÁM" =====================
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
  final VoidCallback? onXemTatCa;
  const ListKhoaDieuTri({super.key, this.onXemTatCa});

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
                    onTap: () {
                      if (onXemTatCa != null) {
                        onXemTatCa!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TatCaKhoaScreen(),
                          ),
                        );
                      }
                    },
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
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => KhoaCard(
                        khoaId: docs[i].id,
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

// Xác nhận xóa khoa
Future<void> _xacNhanXoaKhoa(
  BuildContext context,
  String khoaId,
  String tenKhoa,
) async {
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
          child: const Text('Xóa Khoa',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  if (confirm != true || !context.mounted) return;

  try {
    await KhoaService().xoaKhoa(
      benhVienId: _getBenhVienId(),
      khoaId: khoaId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa thành công khoa "$tenKhoa"'),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi khi xóa khoa: $e'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }
}

// trangThai -> (nhãn, màu nền, màu chữ)
(String, Color, Color) _trangThai(String? ma) {
  switch (ma) {
    case 'day_lich_sang':
      return (
        'Đầy lịch sáng',
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      );
    case 'dong_cua':
      return ('Đóng cửa', const Color(0xFFFEE2E2), const Color(0xFFDC2626));
    default:
      return ('Đang mở', const Color(0xFFDCFCE7), const Color(0xFF16A34A));
  }
}

class KhoaCard extends StatelessWidget {
  const KhoaCard({
    super.key,
    this.khoaId,
    required this.data,
    this.onTap,
  });

  final String? khoaId;
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
    final gioiHan = data['gioiHanBenhNhan'];
    final lichLamViec = (data['lichLamViec'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['tenKhoa'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phuDe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: nen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      nhan,
                      style: TextStyle(
                        color: chu,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (khoaId != null && khoaId!.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Tùy chọn',
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ThemKhoaScreen(
                                benhVienId: _getBenhVienId(),
                                khoaId: khoaId,
                                duLieuKhoa: data,
                              ),
                            ),
                          );
                        } else if (val == 'delete') {
                          _xacNhanXoaKhoa(
                            context,
                            khoaId!,
                            (data['tenKhoa'] ?? 'khoa này').toString(),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF0284C7)),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text('Xóa khoa',
                                  style: TextStyle(color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: (constraints.maxWidth - 20)
                          .clamp(0.0, double.infinity),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Số ca: ',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: '${data['soCaMoiNgay'] ?? '-'} ca/ngày',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            text: 'Giới hạn: ',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: '${gioiHan ?? '-'} BN/buổi',
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lichLamViec.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            lichLamViec,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================== TAB "TẤT CẢ KHOA KHÁM" =====================
class TatCaKhoaTab extends StatefulWidget {
  const TatCaKhoaTab({super.key});

  @override
  State<TatCaKhoaTab> createState() => _TatCaKhoaTabState();
}

class _TatCaKhoaTabState extends State<TatCaKhoaTab> {
  String _tuKhoa = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh tìm kiếm + Nút Thêm Khoa
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _tuKhoa = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm khoa khám...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF0284C7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.addClinic);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),

        // Tiêu đề số lượng khoa
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _khoaStream(),
            builder: (context, snap) {
              final total = snap.data?.docs.length ?? 0;
              return Row(
                children: [
                  Text(
                    'Tất cả khoa khám ($total)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Danh sách khoa điều trị
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tuKhoa.isEmpty
                            ? 'Bệnh viện chưa có khoa khám nào.\nHãy nhấn "+" để thêm khoa mới.'
                            : 'Không tìm thấy khoa phù hợp với "$_tuKhoa"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => KhoaCard(
                  khoaId: docs[i].id,
                  data: docs[i].data(),
                  onTap: () => _moChiTiet(ctx, docs[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===================== MÀN HÌNH "XEM TẤT CẢ" =====================
class TatCaKhoaScreen extends StatelessWidget {
  final bool laTab;
  const TatCaKhoaScreen({super.key, this.laTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: !laTab,
        title: Text(
          laTab ? 'Khoa khám' : 'Tất cả khoa khám',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      bottomNavigationBar: laTab ? const _ThanhDieuHuong() : null,
      body: const TatCaKhoaTab(),
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
