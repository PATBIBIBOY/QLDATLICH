import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../support_doctor/auth_profile/doctor_initial_setup_screen.dart';
import '../../support_doctor/department_room_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF1E78E0);
  static const _danger = Color(0xFFE53935);
  static const _grey = Color(0xFF64748B);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _selectedRoleIndex = 0; // 0: Bệnh nhân, 1: Hỗ trợ bác sĩ, 2: Bệnh viện

  bool _obscure = true;

  final List<Map<String, dynamic>> _roles = [
    {'name': 'Bệnh nhân', 'icon': Icons.person_outline, 'code': 'benh_nhan'},
    {'name': 'Hỗ trợ bác sĩ', 'icon': Icons.medical_services_outlined, 'code': 'doctor_assistant'},
    {'name': 'Bệnh viện', 'icon': Icons.local_hospital, 'code': 'benh_vien'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin đăng nhập');
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. KIỂM TRA ĐĂNG NHẬP NHÂN VIÊN Y TẾ / HỖ TRỢ BÁC SĨ QUA FIRESTORE
      final isMedicalStaff = !email.contains('@') ||
          _selectedRoleIndex == 1 ||
          email.toLowerCase().contains('bs') ||
          email.toLowerCase().contains('htbs');

      if (isMedicalStaff) {
        Map<String, dynamic>? nhanVienData;

        // Tìm trong NhanVien/BV502/danh_sach hoặc collectionGroup 'danh_sach'
        QuerySnapshot snap = await firestore
            .collection('NhanVien')
            .doc('BV502')
            .collection('danh_sach')
            .where('ma_tai_khoan', isEqualTo: email)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          snap = await firestore
              .collection('NhanVien')
              .doc('BV502')
              .collection('danh_sach')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
        }

        if (snap.docs.isEmpty) {
          snap = await firestore
              .collectionGroup('danh_sach')
              .where('ma_tai_khoan', isEqualTo: email)
              .limit(1)
              .get();
        }

        if (snap.docs.isEmpty) {
          snap = await firestore
              .collectionGroup('danh_sach')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
        }

        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data() as Map<String, dynamic>;
          final realPass = (data['mat_khau'] ?? data['matKhau'] ?? '').toString();
          if (realPass.isNotEmpty && realPass != password) {
            _showError('Mật khẩu nhân viên không chính xác');
            return;
          }
          nhanVienData = data;
        }

        if (nhanVienData != null) {
          final bool daKichHoat = (nhanVienData['da_kich_hoat'] == true) ||
              (nhanVienData['trang_thai'] == 'dang_hoat_dong');
          final maNvThucTe = (nhanVienData['ma_nhan_vien'] ??
                  nhanVienData['ma_tai_khoan'] ??
                  email)
              .toString();

          if (!mounted) return;

          // Nếu chưa kích hoạt -> Màn hình thiết lập thông tin ban đầu
          if (!daKichHoat) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorInitialSetupScreen(
                  maNhanVienMacDinh: maNvThucTe,
                ),
              ),
            );
            return;
          }

          // Đã kích hoạt -> Vào thẳng màn hình chọn phòng khám & gọi số
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClinicRoomPickerScreen()),
          );
          return;
        }
      }

      // 2. NẾU ĐĂNG NHẬP QUA FIREBASE AUTH THƯỜNG (BỆNH NHÂN / BỆNH VIỆN)
      await auth.login(email: email, password: password);

      if (!mounted) return;
      final selectedRoleCode = _roles[_selectedRoleIndex]['code'];
      if (selectedRoleCode == 'benh_vien') {
        Navigator.pushReplacementNamed(context, AppRoutes.hospitalDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu không chính xác';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử thất bại. Vui lòng thử lại sau';
      default:
        return 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Hospital Logo / Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    size: 40,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'MEDICONNECT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hệ thống quản lý đặt lịch & khám bệnh',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: _grey),
              ),
              const SizedBox(height: 28),

              // Role Selector Chips (Bệnh nhân, Hỗ trợ bác sĩ, Bệnh viện)
              const Text(
                'VAI TRÒ ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_roles.length, (index) {
                  final isSelected = _selectedRoleIndex == index;
                  final role = _roles[index];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 4,
                        right: index == _roles.length - 1 ? 0 : 4,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRoleIndex = index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? _primary : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                role['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : _grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role['name'] as String,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Email / Account Input
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _selectedRoleIndex == 1
                      ? 'Mã nhân viên / Gmail bác sĩ'
                      : 'Email / Mã tài khoản',
                  hintText: _selectedRoleIndex == 1
                      ? 'VD: HTBS_01 hoặc bacsi@gmail.com'
                      : 'nhap_email@domain.com',
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: _grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: _grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: _grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Register Link
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(
                  'Chưa có tài khoản? Đăng ký ngay',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _danger),
                ),
              ),
              const SizedBox(height: 20),

              // Support Hotline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: _danger, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Hotline hỗ trợ 24/7: 1900 6868',
                      style: TextStyle(color: _danger, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
