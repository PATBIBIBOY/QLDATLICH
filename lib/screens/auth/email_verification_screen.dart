import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_routes.dart'; // ✅ Import AppRoutes

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _primary = Color(0xFF1E78E0);
  static const _grey = Color(0xFF64748B);
  
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      
      // ⚠️ QUAN TRỌNG: Reload để Firebase cập nhật trạng thái emailVerified từ server
      await user?.reload();
      user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực email thành công! Bạn có thể đăng nhập.'), 
            backgroundColor: Colors.green,
          ),
        );
        
        // ✅ CHUYỂN VỀ MÀN HÌNH LOGIN VÀ XÓA SẠCH HISTORY
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.login, 
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email chưa được xác thực. Vui lòng kiểm tra hộp thư (bao gồm cả mục Spam).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      User? user = _auth.currentUser;
      await user?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại email xác thực!'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi lại: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAndLogout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pop(context); // Quay lại màn hình đăng ký
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 50, color: _primary),
              ),
              const SizedBox(height: 24),

              const Text(
                'Xác thực Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              Text(
                'Chúng tôi đã gửi một đường link xác thực đến:',
                style: TextStyle(fontSize: 15, color: _grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng mở ứng dụng Email, nhấp vào đường link để kích hoạt tài khoản. Sau đó quay lại đây và bấm "Đã xác thực".',
                style: TextStyle(fontSize: 14, color: _grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerificationStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Đã xác thực, Kiểm tra lại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _isLoading ? null : _resendVerificationEmail,
                child: const Text(
                  'Gửi lại email xác thực',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primary),
                ),
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: _isLoading ? null : _cancelAndLogout,
                child: const Text(
                  'Nhập sai email? Hủy và đăng ký lại',
                  style: TextStyle(fontSize: 14, color: _grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}