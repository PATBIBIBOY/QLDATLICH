import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/app_routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _primary = Color(0xFF1E78E0);
  static const _danger = Color(0xFFE53935);
  static const _grey = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  
  // Controllers cho Bệnh nhân
  final _patientNameCtrl = TextEditingController();
  final _patientIdCtrl = TextEditingController();
  final _patientPassCtrl = TextEditingController();
  final _patientConfirmCtrl = TextEditingController();
  
  // Controllers cho Bệnh viện
  final _hospitalNameCtrl = TextEditingController();
  final _hospitalEmailCtrl = TextEditingController();
  final _hospitalPhoneCtrl = TextEditingController();
  final _hospitalPassCtrl = TextEditingController();
  final _hospitalConfirmCtrl = TextEditingController();
  
  final _roles = ['Bệnh nhân', 'Bệnh viện'];
  int _roleIndex = 0;
  
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreed = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.selectedRole != null) {
      setState(() {
        _roleIndex = auth.selectedRole == Role.hospital ? 1 : 0;
      });
    }
  }

  @override
  void dispose() {
    // Dispose tất cả controllers
    _patientNameCtrl.dispose();
    _patientIdCtrl.dispose();
    _patientPassCtrl.dispose();
    _patientConfirmCtrl.dispose();
    _hospitalNameCtrl.dispose();
    _hospitalEmailCtrl.dispose();
    _hospitalPhoneCtrl.dispose();
    _hospitalPassCtrl.dispose();
    _hospitalConfirmCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    setState(() {
      _roleIndex = index;
      _obscure = true;
      _obscureConfirm = true;
    });
    final auth = context.read<AuthProvider>();
    auth.setSelectedRole(index == 1 ? Role.hospital : Role.patient);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với Điều khoản & chính sách')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    UserModel user;
    String emailOrPhone = '';
    String password = '';

    if (_roleIndex == 0) {
      // --- Đăng ký Bệnh nhân ---
      final id = _patientIdCtrl.text.trim();
      emailOrPhone = id;
      password = _patientPassCtrl.text;
      
      user = UserModel(
        uid: '', 
        hoTen: _patientNameCtrl.text.trim(),
        email: id.contains('@') ? id : null,
        soDienThoai: !id.contains('@') ? id : null,
        role: 'Bệnh nhân',
      );
    } else {
      // --- Đăng ký Bệnh viện ---
      emailOrPhone = _hospitalEmailCtrl.text.trim();
      password = _hospitalPassCtrl.text;
      
      user = UserModel(
        uid: '', 
        hoTen: _hospitalNameCtrl.text.trim(),
        email: _hospitalEmailCtrl.text.trim(),
        soDienThoai: _hospitalPhoneCtrl.text.trim().isEmpty ? null : _hospitalPhoneCtrl.text.trim(),
        role: 'Bệnh viện',
      );
    }

    if (emailOrPhone.contains('@')) {
      // --- Nhánh EMAIL + mật khẩu ---
      try {
        await auth.registerWithEmail(
          email: emailOrPhone,
          password: password,
          user: user,
        );
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.emailVerification,
          arguments: emailOrPhone,
        );

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } else {
      // --- Nhánh SỐ ĐIỆN THOẠI + OTP (chỉ cho Bệnh nhân) ---
      await auth.sendOtp(
        phone: emailOrPhone,
        onCodeSent: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phone: emailOrPhone,
                onVerify: (code) async {
                  try {
                    await auth.verifyOtpAndRegister(smsCode: code, user: user);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đăng ký thành công!')),
                    );
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                },
                onResend: () => auth.sendOtp(
                  phone: emailOrPhone,
                  onCodeSent: () {},
                  onError: (msg) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
              ),
            ),
          );
        },
        onError: (msg) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    }
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c),
  );

  InputDecoration _decoration(IconData icon, String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: _grey),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
    border: _border(const Color(0xFFE2E8F0)),
    enabledBorder: _border(const Color(0xFFE2E8F0)),
    focusedBorder: _border(_primary),
    errorBorder: _border(_danger),
    focusedErrorBorder: _border(_danger),
  );

  Widget _label(String text, {bool required = false, String? note}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
        children: [
          if (required) const TextSpan(text: '  *', style: TextStyle(color: _danger)),
          if (note != null) TextSpan(text: ' $note', style: const TextStyle(fontWeight: FontWeight.w400, color: _grey)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roles[_roleIndex];
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(20)),
                        child: Icon(
                          _roleIndex == 0 ? Icons.local_hospital : Icons.local_hospital,
                          color: Colors.white, size: 44,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('MEDICONNECT', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _primary)),
                      Text('Đăng ký tài khoản $roleLabel', style: const TextStyle(fontSize: 15, color: _grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tabs vai trò
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: List.generate(_roles.length, (i) {
                      final active = i == _roleIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleChanged(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active ? _primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_roles[i], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: active ? Colors.white : _grey)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ✅ CÁC Ô NHẬP LIỆU THAY ĐỔI THEO TAB
                if (_roleIndex == 0) ...[
                  // === FORM BỆNH NHÂN ===
                  _label('Họ và Tên', required: true),
                  TextFormField(
                    controller: _patientNameCtrl,
                    decoration: _decoration(Icons.person_outline, 'Nguyễn Văn An'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Email hoặc số điện thoại', required: true),
                  TextFormField(
                    controller: _patientIdCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(Icons.mail_outline, 'an.nguyen@gmail.com / 0912 345 678'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Vui lòng nhập email hoặc số điện thoại';
                      if (value.contains('@')) {
                        return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value) ? null : 'Email không hợp lệ';
                      }
                      return RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$').hasMatch(value.replaceAll(' ', '')) ? null : 'Số điện thoại không hợp lệ';
                    },
                  ),
                  const SizedBox(height: 16),

                  _label('Mật khẩu', required: true),
                  TextFormField(
                    controller: _patientPassCtrl,
                    obscureText: _obscure,
                    decoration: _decoration(
                      Icons.lock_outline, 'Nhập mật khẩu',
                      suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: _grey), onPressed: () => setState(() => _obscure = !_obscure)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Nhập lại mật khẩu', required: true),
                  TextFormField(
                    controller: _patientConfirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: _decoration(
                      Icons.lock_outline, 'Nhập lại mật khẩu',
                      suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _grey), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    ),
                    validator: (v) => (v == null || v != _patientPassCtrl.text) ? 'Mật khẩu nhập lại không khớp' : null,
                  ),
                ] else ...[
                  // === FORM BỆNH VIỆN ===
                  _label('Tên bệnh viện / Cơ sở y tế', required: true),
                  TextFormField(
                    controller: _hospitalNameCtrl,
                    decoration: _decoration(Icons.business_outlined, 'Bệnh viện Đa Khoa An Bình'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên bệnh viện' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Email đại diện bệnh viện', required: true),
                  TextFormField(
                    controller: _hospitalEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(Icons.mail_outline, 'admin@benhvien.vn'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Vui lòng nhập email';
                      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value) ? null : 'Email không hợp lệ';
                    },
                  ),
                  const SizedBox(height: 16),

                  _label('Số điện thoại liên hệ', note: '(Không bắt buộc)'),
                  TextFormField(
                    controller: _hospitalPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _decoration(Icons.phone_outlined, '028 3899 9999'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return null;
                      return RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$').hasMatch(value.replaceAll(' ', '')) ? null : 'Số điện thoại không hợp lệ';
                    },
                  ),
                  const SizedBox(height: 16),

                  _label('Mật khẩu', required: true),
                  TextFormField(
                    controller: _hospitalPassCtrl,
                    obscureText: _obscure,
                    decoration: _decoration(
                      Icons.lock_outline, 'Nhập mật khẩu',
                      suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: _grey), onPressed: () => setState(() => _obscure = !_obscure)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('Nhập lại mật khẩu', required: true),
                  TextFormField(
                    controller: _hospitalConfirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: _decoration(
                      Icons.lock_outline, 'Nhập lại mật khẩu',
                      suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _grey), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập lại mật khẩu';
                      return (v != _hospitalPassCtrl.text) ? 'Mật khẩu nhập lại không khớp' : null;
                    },
                  ),
                ],
                const SizedBox(height: 12),

                // Điều khoản
                Row(
                  children: [
                    Checkbox(value: _agreed, activeColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onChanged: (v) => setState(() => _agreed = v ?? false)),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Đồng ý với ', style: TextStyle(color: _grey, fontSize: 14),
                          children: [
                            TextSpan(text: 'Điều khoản & chính sách', style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
                            TextSpan(text: _roleIndex == 0 ? ' người dùng.' : ' cơ sở y tế.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nút đăng ký
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Đăng Ký Tài Khoản $roleLabel', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 22),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Đã có tài khoản? ', style: TextStyle(color: _grey, fontSize: 15),
                        children: [TextSpan(text: 'Đăng nhập ngay', style: TextStyle(color: _primary, fontWeight: FontWeight.w700))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}