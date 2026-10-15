import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../utils/validators.dart';

class HospitalRegisterScreen extends StatefulWidget {
  const HospitalRegisterScreen({super.key});

  @override
  State<HospitalRegisterScreen> createState() => _HospitalRegisterScreenState();
}

class _HospitalRegisterScreenState extends State<HospitalRegisterScreen> {
  static const _blue = Color(0xFF078ACB);
  static const _ink = Color(0xFF172033);
  static const _muted = Color(0xFF718096);
  static const _line = Color(0xFFE0E7F0);

  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _hospitalController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản sử dụng.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng ký bệnh viện chưa được kết nối với dịch vụ tạo tài khoản.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 15, 12, 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 23,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 12),
                          _buildAccountTypeSelector(),
                          const SizedBox(height: 14),
                          _buildField(
                            label: 'Tên bệnh viện / Cơ sở y tế',
                            hint: 'Bệnh viện Đa Khoa An Bình',
                            icon: Icons.business_outlined,
                            controller: _hospitalController,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập tên bệnh viện';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            label: 'Email đại diện bệnh viện',
                            hint: 'admin@bv-anbinh.vn',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            label: 'Số điện thoại liên hệ',
                            hint: '028 3899 9999',
                            icon: Icons.call_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                validatePhone(value?.replaceAll(' ', '')),
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            label: 'Mật khẩu',
                            hint: '••••••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: validatePassword,
                          ),
                          const SizedBox(height: 8),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 10),
                          _buildSubmitButton(),
                          const Spacer(),
                          const SizedBox(height: 30),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_box_outlined,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'ĐĂNG KÝ TÀI KHOẢN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Chọn đối tượng để tạo tài khoản mới',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildAccountTypeSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _accountTypeButton(
              label: 'Bệnh nhân',
              icon: Icons.person_outline_rounded,
              selected: false,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.register),
            ),
          ),
          Expanded(
            child: _accountTypeButton(
              label: 'Bệnh viện',
              icon: Icons.local_hospital_outlined,
              selected: true,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTypeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? _blue : _muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? _blue : _muted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF435168),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFE04444),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: const TextStyle(color: _ink, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _ink, fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF9AAAC0), size: 17),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 38,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE04444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE04444),
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return InkWell(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 18,
            child: Checkbox(
              value: _acceptedTerms,
              onChanged: (value) =>
                  setState(() => _acceptedTerms = value ?? false),
              activeColor: _blue,
              side: const BorderSide(color: Color(0xFF9AAAC0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Wrap(
              children: [
                const Text(
                  'Đồng ý với ',
                  style: TextStyle(color: _muted, fontSize: 9.5),
                ),
                GestureDetector(
                  onTap: () => _showTerms('Điều khoản & chính sách'),
                  child: const Text(
                    'Điều khoản & chính sách',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Text(
                  ' cơ sở y tế.',
                  style: TextStyle(color: _muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTerms(String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Vui lòng đọc và đồng ý với các điều khoản sử dụng dành cho cơ sở y tế.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: _blue.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đăng Ký Tài Khoản Bệnh Viện',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Đã có tài khoản? ',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(
                color: _blue,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
