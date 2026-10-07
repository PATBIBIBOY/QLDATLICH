import 'package:flutter/material.dart';

class LetanQuenmatkhauScreenC1 extends StatefulWidget {
  final String emailMacDinh;

  const LetanQuenmatkhauScreenC1({
    super.key,
    this.emailMacDinh = '',
  });

  @override
  State<LetanQuenmatkhauScreenC1> createState() => _LetanQuenmatkhauScreenC1State();
}

class _LetanQuenmatkhauScreenC1State extends State<LetanQuenmatkhauScreenC1> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  bool _daGuiYeuCau = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailMacDinh);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _guiYeuCauReset() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _daGuiYeuCau = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi liên kết / mã xác thực đặt lại mật khẩu đến ${_emailController.text.trim()} qua Firebase!',
          ),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quên Mật Khẩu',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Khung minh họa icon thư
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Color(0xFFFF9500),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'Khôi Phục Mật Khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhập địa chỉ Gmail tài khoản của bạn. Hệ thống Firebase sẽ gửi liên kết xác thực đặt lại mật khẩu mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Ô nhập Gmail
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ Gmail tài khoản',
                        style: TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập Gmail';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Địa chỉ email không đúng định dạng';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'vidu@gmail.com',
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                          prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF8E8E93), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Thông báo khi đã gửi
                if (_daGuiYeuCau) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Đã gửi thư xác thực đến ${_emailController.text.trim()}! Vui lòng kiểm tra hộp thư đến hoặc mục Spam.',
                            style: const TextStyle(
                              color: Color(0xFF065F46),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Nút Gửi mã xác nhận
                ElevatedButton(
                  onPressed: _guiYeuCauReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _daGuiYeuCau ? 'Gửi Lại Thư Xác Thực' : 'Gửi Thư Đặt Lại Mật Khẩu',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Quay lại
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8E8E93),
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: Color(0xFFE5E5EA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Quay Lại',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
