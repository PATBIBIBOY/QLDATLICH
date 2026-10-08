import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  Role? _selectedRole;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;
  String? _pendingPhone;

  UserModel? get user => _user;
  Role? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;

  void setSelectedRole(Role role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required UserModel user,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --- THÊM ĐOẠN CODE NÀY ---
      // Gửi email chứa link xác thực tài khoản
      await credential.user?.sendEmailVerification();
      // -------------------------

      final newUser = UserModel.fromRegisterEmail(
        uid: credential.user!.uid,
        hoTen: user.hoTen!,
        email: email,
        matKhau: password, 
        role: user.role,
      );

      await _authService.saveUserToFirestore(newUser);
      _user = newUser;
    } catch (e) {
      rethrow; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp({
    required String phone,
    required VoidCallback onCodeSent,
    required void Function(String message) onError,
  }) async {
    _isLoading = true;
    notifyListeners();
    _pendingPhone = phone;

    await _authService.sendOtp(
      phone: phone,
      resendToken: _resendToken,
      onCodeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
        _isLoading = false;
        notifyListeners();
        onCodeSent();
      },
      onAutoVerified: (credential) async {
        // Xử lý nếu Firebase tự động xác thực (ví dụ: số điện thoại thử nghiệm)
        _isLoading = false;
        notifyListeners();
      },
      onError: (message) {
        _isLoading = false;
        notifyListeners();
        onError(message);
      },
    );
  }

  Future<void> verifyOtpAndRegister({
    required String smsCode,
    required UserModel user,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_verificationId == null) throw Exception('Mã xác thực không hợp lệ');

      final credential = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final newUser = UserModel.fromRegisterPhone(
        uid: credential.user!.uid,
        hoTen: user.hoTen!,
        soDienThoai: _pendingPhone!,
        role: user.role,
      );

      await _authService.saveUserToFirestore(newUser);
      _user = newUser;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _selectedRole = null;
    notifyListeners();
  }
}
