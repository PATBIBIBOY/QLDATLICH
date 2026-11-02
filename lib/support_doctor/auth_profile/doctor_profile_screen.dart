import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String? tenKhoa;

  const DoctorProfileScreen({super.key, this.tenKhoa});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String _hoTen = 'Bác Sĩ / Trợ Lý';
  String _maNhanVien = 'HTBS_01';
  String _email = 'bacsi@gmail.com';
  String _chucVu = 'Hỗ Trợ Bác Sĩ';
  String _khoa = 'Khoa Khám Bệnh';
  String _tenBenhVien = 'Bệnh viện Đa khoa Quốc tế';

  @override
  void initState() {
    super.initState();
    if (widget.tenKhoa != null && widget.tenKhoa!.isNotEmpty) {
      _khoa = widget.tenKhoa!;
    }
  }

  void _moDoiMatKhau() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi Mật Khẩu'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.trim().length >= 6) {
                final snap = await FirebaseFirestore.instance
                    .collectionGroup('danh_sach')
                    .where('ma_tai_khoan', isEqualTo: _maNhanVien)
                    .limit(1)
                    .get();
                if (snap.docs.isNotEmpty) {
                  await snap.docs.first.reference.update({
                    'mat_khau': passCtrl.text.trim(),
                    'ngay_cap_nhat': FieldValue.serverTimestamp(),
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Đổi mật khẩu thành công!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _moChinhSuaThongTin() {
    final tenCtrl = TextEditingController(text: _hoTen);
    final emailCtrl = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh Sửa Thông Tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tenCtrl, decoration: const InputDecoration(labelText: 'Họ và tên')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Gmail liên kết')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final snap = await FirebaseFirestore.instance
                  .collectionGroup('danh_sach')
                  .where('ma_tai_khoan', isEqualTo: _maNhanVien)
                  .limit(1)
                  .get();
              if (snap.docs.isNotEmpty) {
                await snap.docs.first.reference.update({
                  'ho_ten': tenCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'ngay_cap_nhat': FieldValue.serverTimestamp(),
                });
              }
              setState(() {
                _hoTen = tenCtrl.text.trim();
                _email = emailCtrl.text.trim();
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Cập nhật thông tin thành công!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hồ Sơ Hỗ Trợ Bác Sĩ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + Tên
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.person, size: 40, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hoTen,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _chucVu,
                      style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Thông tin chi tiết
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _itemRow('Mã nhân viên:', _maNhanVien),
                  const Divider(height: 20),
                  _itemRow('Gmail:', _email),
                  const Divider(height: 20),
                  _itemRow('Khoa:', _khoa),
                  const Divider(height: 20),
                  _itemRow('Bệnh viện:', _tenBenhVien),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Các nút thao tác: Sửa thông tin & Đổi mật khẩu
            _buttonOption(
              icon: Icons.edit_note_rounded,
              title: 'Chỉnh sửa thông tin / Gmail',
              onTap: _moChinhSuaThongTin,
            ),
            const SizedBox(height: 10),
            _buttonOption(
              icon: Icons.lock_reset_rounded,
              title: 'Đổi mật khẩu tài khoản',
              onTap: _moDoiMatKhau,
            ),
            const SizedBox(height: 24),

            // Nút Đăng xuất
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Đăng xuất?'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất ca trực?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Đăng Xuất Ca Trực', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buttonOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0284C7), size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
