import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../database_seeder.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException;
import '../../config/app_session.dart';
import '../../providers/auth_provider.dart';
import '../letan_c1/cskh_duyetdon_khoa_screen_c1.dart';
import '../letan_c1/letan_thietlap_thongtin_screen_c1.dart';
import '../letan_c1/letan_trangchu_screen_c1.dart';
import '../../support_doctor/department_room_picker.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';

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
  int _selectedRoleIndex = 0; // 0: Bệnh nhân, 1: Bệnh viện, 2: Admin

  bool _obscure = true;

  final List<Map<String, dynamic>> _roles = [
    {'name': 'Bệnh nhân', 'icon': Icons.person_outline, 'code': 'benh_nhan'},
    {'name': 'Bệnh viện', 'icon': Icons.local_hospital, 'code': 'benh_vien'},
    {'name': 'Admin', 'icon': Icons.admin_panel_settings, 'code': 'admin'},
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
      );
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final selectedRoleCode = _roles[_selectedRoleIndex]['code'] as String;

      // ✅ 1. Kiểm tra nếu người dùng đăng nhập bằng MÃ NHÂN VIÊN nội bộ (chưa có Gmail Auth)
      final input = email.trim();
      if (!input.contains('@') && selectedRoleCode != 'admin') {
        final firestore = FirebaseFirestore.instance;
        DocumentSnapshot<Map<String, dynamic>> nhanVienDoc =
            await firestore.collection('NhanVien').doc(input).get();

        if (!nhanVienDoc.exists) {
          final q = await firestore
              .collection('NhanVien')
              .where('ma_tai_khoan', isEqualTo: input)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) nhanVienDoc = q.docs.first;
        }

        // Tự động khởi tạo tài khoản ban đầu nếu chưa có trên Firestore
        if (!nhanVienDoc.exists && (input.toUpperCase() == 'LT_TM_01' || input.toUpperCase() == 'CSKH_01')) {
          if (password != '123456') {
            throw Exception('Mật khẩu cấp ban đầu không chính xác! (Mặc định: 123456)');
          }
          final isCskh = input.toUpperCase().contains('CSKH');
          final defaultUser = {
            'ma_tai_khoan': input.toUpperCase(),
            'ma_nhan_vien': input.toUpperCase(),
            'mat_khau': '123456',
            'ho_ten': isCskh ? 'Nhân Viên CSKH' : 'Đinh Hoàng Cước',
            'role': isCskh ? 'customerSupport' : 'receptionist',
            'khoa': 'KHOA TIM',
            'da_kich_hoat': false,
            'ngay_tao': FieldValue.serverTimestamp(),
          };
          await firestore.collection('NhanVien').doc(input.toUpperCase()).set(defaultUser);
          nhanVienDoc = await firestore.collection('NhanVien').doc(input.toUpperCase()).get();
        }

        if (nhanVienDoc.exists) {
          final nvData = nhanVienDoc.data()!;
          if (nvData['mat_khau'] != null && nvData['mat_khau'] != password) {
            throw Exception('Mật khẩu không chính xác!');
          }

          if (!mounted) return;
          final bool daKichHoat = nvData['da_kich_hoat'] ?? false;
          final role = (nvData['role'] ?? 'receptionist').toString();

          // Chưa kích hoạt -> Màn hình 3 thiết lập thông tin
          if (!daKichHoat) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LetanThietlapThongtinScreenC1(
                  maNhanVienMacDinh: input.toUpperCase(),
                ),
              ),
            );
            return;
          }

          // Đã kích hoạt -> Vào đúng Role
          final maNvThucTe = (nvData['ma_nhan_vien'] ?? nvData['ma_tai_khoan'] ?? input).toString();
          DuLieuProfileMauC1.thongTinHienTai = DuLieuProfileMauC1.thongTinHienTai.copyWith(
            maNhanVien: maNvThucTe,
            hoTen: (nvData['ho_ten'] ?? 'Nhân viên').toString(),
            chucVu: (nvData['chuc_vu'] ?? (role == 'le_tan' || role == 'receptionist' ? 'Lễ tân tiếp đón' : 'Chăm sóc khách hàng')).toString(),
            khoa: (nvData['khoa'] ?? 'Khoa Khám Bệnh').toString(),
            email: (nvData['email'] ?? '').toString(),
          );

          if (role == 'receptionist' || role == 'le_tan') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LeTanHomeScreenC1()));
            return;
          } else if (role == 'customerSupport' || role == 'cskh' || role == 'cham_soc_khach_hang') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CskhDuyetdonKhoaScreenC1()));
            return;
          } else if (role == 'doctorAssistant' || role == 'ho_tro_bac_si' || role == 'bac_si') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ClinicRoomPickerScreen()));
            return;
          }
        }
      }

      // ✅ 2. Xử lý đăng nhập bằng Gmail qua FirebaseAuth theo Role
      if (selectedRoleCode == 'admin') {
        await auth.loginAdmin(email: email, password: password);
        await DatabaseSeeder.seedAllData();
      } else {
        await auth.login(
          email: email,
          password: password,
          role: selectedRoleCode,
        );
      }

      if (!mounted) return;

      // ✅ 2. Điều hướng thông minh & Kiểm tra kích hoạt theo Role
      if (selectedRoleCode == 'admin' && auth.admin != null) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false);
        return;
      }
      
      if (selectedRoleCode == 'benh_vien' || auth.hospital != null) {
        AppSession.benhVienId = auth.hospital?.uid ??
            FirebaseAuth.instance.currentUser?.uid ??
            '';
        route = AppRoutes.hospitalDashboard;
      } 

      // Xử lý tài khoản người dùng / nhân viên
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        // Kiểm tra xem có phải tài khoản trong NhanVien hoặc users không
        final firestore = FirebaseFirestore.instance;
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await firestore.collection('NhanVien').doc(currentUid).get();

        // 1. Nếu doc(currentUid) có trường ma_nhan_vien, ưu tiên đọc bản ghi gốc theo mã nhân viên
        if (userDoc.exists) {
          final maNvGoc = userDoc.data()?['ma_nhan_vien'] ?? userDoc.data()?['ma_tai_khoan'];
          if (maNvGoc != null && maNvGoc.toString().isNotEmpty && maNvGoc.toString() != currentUid) {
            final docGoc = await firestore.collection('NhanVien').doc(maNvGoc.toString()).get();
            if (docGoc.exists) userDoc = docGoc;
          }
        }

        // 2. Thử tìm theo UID nếu doc ID là mã nhân viên
        if (!userDoc.exists || (userDoc.data()?['role'] == null)) {
          final qUid = await firestore
              .collection('NhanVien')
              .where('uid', isEqualTo: currentUid)
              .limit(1)
              .get();
          if (qUid.docs.isNotEmpty) userDoc = qUid.docs.first;
        }

        // 3. Thử tìm theo email nếu doc ID là mã nhân viên
        if (!userDoc.exists) {
          final q = await firestore
              .collection('NhanVien')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) userDoc = q.docs.first;
        }

        if (!userDoc.exists) {
          // Thử tìm trong bảng users chung
          userDoc = await firestore.collection('users').doc(currentUid).get();
        }

        if (userDoc.exists) {
          final data = userDoc.data() ?? {};
          final role = (data['role'] ?? 'patient').toString();
          final bool daKichHoat = data['da_kich_hoat'] ?? false;

          if (!mounted) return;

          // 1. NẾU CHƯA KÍCH HOẠT -> SANG MÀN HÌNH ĐIỀN THÔNG TIN LẦN ĐẦU (MÀN HÌNH 3)
          if (!daKichHoat) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LetanThietlapThongtinScreenC1(
                  maNhanVienMacDinh: (data['ma_nhan_vien'] ?? data['ma_tai_khoan'] ?? currentUid).toString(),
                ),
              ),
            );
            return;
          }

          // 2. NẾU ĐÃ KÍCH HOẠT -> VÀO ĐÚNG ROLE
          final maNvThucTe = (data['ma_nhan_vien'] ?? data['ma_tai_khoan'] ?? currentUid).toString();
          DuLieuProfileMauC1.thongTinHienTai = DuLieuProfileMauC1.thongTinHienTai.copyWith(
            maNhanVien: maNvThucTe,
            hoTen: (data['ho_ten'] ?? 'Nhân viên').toString(),
            chucVu: (data['chuc_vu'] ?? (role == 'le_tan' || role == 'receptionist' ? 'Lễ tân tiếp đón' : 'Chăm sóc khách hàng')).toString(),
            khoa: (data['khoa'] ?? 'Khoa Khám Bệnh').toString(),
            email: (data['email'] ?? email).toString(),
          );

          if (role == 'receptionist' || role == 'le_tan') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LeTanHomeScreenC1()),
            );
            return;
          } else if (role == 'customerSupport' || role == 'cskh' || role == 'cham_soc_khach_hang') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CskhDuyetdonKhoaScreenC1()),
            );
            return;
          } else if (role == 'doctorAssistant' || role == 'ho_tro_bac_si' || role == 'bac_si') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ClinicRoomPickerScreen()),
            );
            return;
          }
        }
      }

      if (!mounted) return;
      // Mặc định: Vào giao diện bệnh nhân
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.patientHome, (route) => false);

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = _loginErrorMessage(e);
      
      // ✅ 3. Xử lý riêng trường hợp chưa xác thực email (chỉ áp dụng cho BN/BV)
      if (errorMessage.contains('EMAIL_NOT_VERIFIED')) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.emailVerification,
          arguments: email,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: _danger),
      );
    }
  }

  String _loginErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
        case 'user-not-found':
          return 'Email không đúng hoặc chưa được đăng ký.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Mật khẩu không đúng.';
        case 'user-disabled':
          return 'Tài khoản này đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Bạn thử đăng nhập quá nhiều lần. Vui lòng thử lại sau.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy trạng thái loading từ Provider để đồng bộ UI
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo & Title
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MEDICONNECT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hệ thống Y tế & Đặt lịch khám thông minh\nhàng đầu Việt Nam',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: _grey, height: 1.4),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Role Selection Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_roles.length, (index) {
                    final isSelected = index == _selectedRoleIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRoleIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _roles[index]['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : _grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _roles[index]['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : _grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Google Login Button (Placeholder)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, color: _primary, size: 24),
                  label: const Text(
                    'Đăng nhập với Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Or divider
              Row(
                children: [
                  Expanded(child: Divider(color: _grey.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc đăng nhập bằng tài khoản nội bộ', style: TextStyle(fontSize: 13, color: _grey)),
                  ),
                  Expanded(child: Divider(color: _grey.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 24),

              // Email Input
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined, color: _grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: _border(const Color(0xFFE2E8F0)),
                  enabledBorder: _border(const Color(0xFFE2E8F0)),
                  focusedBorder: _border(_primary),
                ),
              ),
              const SizedBox(height: 16),

              // Password Input
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline, color: _grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: _grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: _border(const Color(0xFFE2E8F0)),
                  enabledBorder: _border(const Color(0xFFE2E8F0)),
                  focusedBorder: _border(_primary),
                ),
              ),
              
              // ✅ Quên mật khẩu (Đã chuyển xuống dưới ô mật khẩu cho đúng UX)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.forgotPassword,
                    arguments: _emailCtrl.text.trim(),
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
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
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Register Link
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text(
                  'Đăng ký tài khoản mới',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _danger),
                ),
              ),
              const SizedBox(height: 24),

              // Support Hotline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: _danger, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hotline hỗ trợ 24/7: 1900 6868',
                      style: TextStyle(color: _danger, fontWeight: FontWeight.w600, fontSize: 15),
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