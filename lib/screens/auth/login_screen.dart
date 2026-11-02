import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../support_doctor/department_room_picker.dart';

/// MÀN HÌNH ĐĂNG NHẬP MỚI CHO HỖ TRỢ BÁC SĨ (CHUẨN GIAO DIỆN Y TẾ C1)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taiKhoanCtrl = TextEditingController(text: 'HTBS_01');
  final _matKhauCtrl = TextEditingController(text: '123456');

  bool _anMatKhau = true;
  bool _dangXuLy = false;

  @override
  void dispose() {
    _taiKhoanCtrl.dispose();
    _matKhauCtrl.dispose();
    super.dispose();
  }

  Future<void> _xuLyDangNhap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangXuLy = true);

    final input = _taiKhoanCtrl.text.trim();
    final pass = _matKhauCtrl.text.trim();

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Tìm tài khoản trong Firestore
      QuerySnapshot snap = await firestore
          .collection('NhanVien')
          .doc('BV502')
          .collection('danh_sach')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collection('NhanVien')
            .doc('BV502')
            .collection('danh_sach')
            .where('ma_tai_khoan', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collection('NhanVien')
            .doc('BV502')
            .collection('danh_sach')
            .where('ma_nhan_vien', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collectionGroup('danh_sach')
            .where('email', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collectionGroup('danh_sach')
            .where('ma_tai_khoan', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data() as Map<String, dynamic>;
        final realPass = (data['mat_khau'] ?? data['matKhau'] ?? '').toString();

        if (realPass.isNotEmpty && realPass != pass) {
          throw Exception('Mật khẩu không chính xác!');
        }
      }

      if (!mounted) return;
      setState(() => _dangXuLy = false);

      // Chuyển thẳng vào màn hình chọn phòng khám của bên Hỗ trợ bác sĩ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClinicRoomPickerScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Y tế gradient
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'HỆ THỐNG Y TẾ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Đăng Nhập Hỗ Trợ Bác Sĩ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhập mã nhân viên hoặc Gmail để bắt đầu ca trực',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),

                  // Ô Tài khoản / Mã nhân viên
                  TextFormField(
                    controller: _taiKhoanCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tài khoản'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Tài khoản / Mã nhân viên / Gmail',
                      hintText: 'VD: HTBS_01 hoặc email@gmail.com',
                      prefixIcon: const Icon(Icons.person_outline,
                          size: 20, color: Color(0xFF0284C7)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ô Mật khẩu
                  TextFormField(
                    controller: _matKhauCtrl,
                    obscureText: _anMatKhau,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập mật khẩu'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 20, color: Color(0xFF0284C7)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _anMatKhau ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () =>
                            setState(() => _anMatKhau = !_anMatKhau),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _dangXuLy ? null : _xuLyDangNhap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        shadowColor:
                            const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                      child: _dangXuLy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
