import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../config/constants.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  PatientModel? _user;
  HospitalModel? _hospital;
  Map<String, dynamic>? _admin;
  String? _selectedRole;
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;
  String? _pendingPhone;

  PatientModel? get user => _user;
  HospitalModel? get hospital => _hospital;
  Map<String, dynamic>? get admin => _admin;
  String? get selectedRole => _selectedRole;
  List<Map<String, dynamic>> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get pendingPhone => _pendingPhone;

  Future<Map<String, dynamic>?> getAdminFromFirestore(String uid) async {
    return _authService.getAdminFromFirestore(uid);
  }

  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final adminData = await _authService.loginAdmin(
        email: email,
        password: password,
      );
      if (adminData == null) {
        throw Exception('Tài khoản này không có quyền quản trị viên.');
      }

      _user = null;
      _hospital = null;
      _admin = adminData;
      _selectedRole = 'admin';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentUser({String? preferredRole}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        if (preferredRole == 'benh_vien') {
          var hospital = await _authService.getHospitalFromFirestore(
            currentUser.uid,
          );
          hospital ??= await _authService.findHospitalByEmail(
            currentUser.email ?? '',
          );

          if (hospital == null) {
            final fallbackName =
                (currentUser.displayName?.trim().isNotEmpty ?? false)
                ? currentUser.displayName!
                : (currentUser.email?.split('@').first ?? 'Bệnh Viện Mới');
            final newHospital = HospitalModel(
              uid: currentUser.uid,
              tenBenhVien: fallbackName,
              email: currentUser.email,
              role: 'benh_vien',
              trangThaiHopTacId: TrangThaiId.choDuyet,
              daXacThucEmail: true,
            );
            try {
              await _authService.saveHospitalToFirestore(newHospital);
            } catch (e) {
              print('⚠️ Không thể lưu document BenhVien: $e');
            }
            hospital = newHospital;

            await FCMService().init();
          }

          _hospital = hospital;
          _user = null;
          AppSession.benhVienId = hospital.uid ?? currentUser.uid;
          _selectedRole = 'benh_vien';
          return;
        }

        final patientModel = await _authService.getPatientFromFirestore(
          currentUser.uid,
        );
        _user = patientModel;
        if (patientModel == null) {
          _hospital = await _authService.getHospitalFromFirestore(
            currentUser.uid,
          );
          _hospital ??= await _authService.findHospitalByEmail(
            currentUser.email ?? '',
          );
          if (_hospital != null) {
            AppSession.benhVienId = _hospital!.uid ?? currentUser.uid;
          }
        }
        _selectedRole = patientModel?.role ?? _hospital?.role;
      }
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin user hiện tại: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRoles() async {
    if (_roles.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      _roles = await _authService.getRoles();
      if (_roles.isNotEmpty && _selectedRole == null) {
        _selectedRole = _roles.first['ma_vai_tro'];
      }
    } catch (e) {
      print('❌ Lỗi khi load roles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedRole(String maVaiTro) {
    _selectedRole = maVaiTro;
    notifyListeners();
  }

  Map<String, dynamic>? get currentRoleInfo {
    if (_selectedRole == null || _roles.isEmpty) return null;
    return _roles.firstWhere(
      (role) => role['ma_vai_tro'] == _selectedRole,
      orElse: () => {},
    );
  }

  Future<void> login({
    required String email,
    required String password,
    String? role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _admin = null;
      await fetchCurrentUser(preferredRole: role);

      final isEmailUnverified =
          _user?.daXacThucEmail == false || _hospital?.daXacThucEmail == false;
      if (isEmailUnverified) {
        await _authService.signOut();
        _user = null;
        _hospital = null;
        notifyListeners();
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      await FCMService().init();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required PatientModel user,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.sendEmailVerification();

      final newUser = PatientModel.fromRegisterEmail(
        uid: credential.user!.uid,
        hoTen: user.hoTen!,
        email: email,
        role: user.role,
      ).copyWith(daXacThucEmail: false);

      await _authService.saveUserToFirestore(newUser);
      _user = newUser;
      _hospital = null;
      await FCMService().init();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _handleExistingEmail(email, password, user);
        return; // Thoát hàm an toàn, RegisterScreen sẽ tự động chuyển sang màn hình xác thực
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerHospitalWithEmail({
    required String email,
    required String password,
    required HospitalModel hospital,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.sendEmailVerification();

      final newHospital = HospitalModel.fromRegisterEmail(
        uid: credential.user!.uid,
        tenBenhVien: hospital.tenBenhVien!,
        email: email,
        diaChi: hospital.diaChi,
        role: hospital.role,
      ).copyWith(daXacThucEmail: false);

      await _authService.saveHospitalToFirestore(newHospital);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _handleExistingHospitalEmail(email, password, hospital);
        return;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleExistingHospitalEmail(
    String email,
    String password,
    HospitalModel hospital,
  ) async {
    final oldHospital = await _authService.findHospitalByEmail(email);
    if (oldHospital == null || oldHospital.daXacThucEmail) {
      throw Exception(
        'Email đã được sử dụng và xác thực. Vui lòng sử dụng tính năng Đăng nhập.',
      );
    }
    await _signInToReplaceUnverifiedAccount(email, password);
    await _authService.deleteUnverifiedHospital(oldHospital.uid!);

    final credential = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();

    final newHospital = HospitalModel.fromRegisterEmail(
      uid: credential.user!.uid,
      tenBenhVien: hospital.tenBenhVien!,
      email: email,
      diaChi: hospital.diaChi,
      role: hospital.role,
    ).copyWith(daXacThucEmail: false);
    await _authService.saveHospitalToFirestore(newHospital);
    _hospital = newHospital;
    _user = null;
  }

  Future<void> _signInToReplaceUnverifiedAccount(
    String email,
    String password,
  ) async {
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw Exception(
          'Email đã có tài khoản chưa xác thực nhưng mật khẩu không khớp. '
          'Vui lòng đăng nhập hoặc đặt lại mật khẩu.',
        );
      }
      rethrow;
    }
  }

  Future<void> _handleExistingEmail(
    String email,
    String password,
    PatientModel user,
  ) async {
    try {
      final oldUser = await _authService.findPatientByEmail(email);

      if (oldUser != null && oldUser.daXacThucEmail == false) {
        print('⚠️ Phát hiện tài khoản cũ chưa xác thực: ${oldUser.uid}');

        await _signInToReplaceUnverifiedAccount(email, password);

        // 3. Xóa tài khoản Auth và Firestore
        await _authService.deleteUnverifiedPatient(oldUser.uid);
        print('✅ Đã xóa sạch tài khoản cũ.');

        // 4. Đăng ký lại với thông tin mới của người dùng hiện tại
        final newCredential = await _authService.registerWithEmailAndPassword(
          email: email,
          password: password,
        );

        await newCredential.user?.sendEmailVerification();

        final newUser = PatientModel.fromRegisterEmail(
          uid: newCredential.user!.uid,
          hoTen: user.hoTen!,
          email: email,
          role: user.role,
        ).copyWith(daXacThucEmail: false);

        await _authService.saveUserToFirestore(newUser);
        _user = newUser;
        _hospital = null;
        print('✅ Đã tạo tài khoản mới thành công cho email: $email');
      } else {
        throw Exception(
          'Email đã được sử dụng và xác thực. Vui lòng sử dụng tính năng Đăng nhập.',
        );
      }
    } catch (e) {
      print('❌ Lỗi khi xử lý email tồn tại: $e');
      rethrow; // Ném lỗi để RegisterScreen bắt được và hiển thị cho người dùng
    }
  }

  Future<void> markEmailAsVerified() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserVerificationStatus(user.uid, true);
        _user = await _authService.getPatientFromFirestore(user.uid);
        _hospital = _user == null
            ? await _authService.getHospitalFromFirestore(user.uid)
            : null;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật trạng thái xác thực: $e');
      rethrow;
    }
  }

  // ... (Giữ nguyên các hàm sendOtp, verifyOtpAndRegister, logout như cũ) ...
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
    required PatientModel user,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_verificationId == null) throw Exception('Mã xác thực không hợp lệ');
      final credential = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final newUser = PatientModel.fromRegisterPhone(
        uid: credential.user!.uid,
        hoTen: user.hoTen!,
        soDienThoai: _pendingPhone!,
        role: user.role,
      );
      await _authService.saveUserToFirestore(newUser);
      _user = newUser;
      _hospital = null;
      await FCMService().init();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? hoTen,
    String? gioiTinh,
    DateTime? ngaySinh,
    String? diaChi,
    String? email,
    String? soDienThoai,
    String? cccd,
    String? soBhyt,
  }) async {
    if (_user == null) {
      throw Exception('Không tìm thấy thông tin người dùng để cập nhật.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Cập nhật lên Firestore
      await _authService.updateUserProfile(
        uid: _user!.uid,
        hoTen: hoTen,
        gioiTinh: gioiTinh,
        ngaySinh: ngaySinh,
        diaChi: diaChi,
        email: email,
        soDienThoai: soDienThoai,
        cccd: cccd,
        soBhyt: soBhyt,
      );

      // 2. Cập nhật lại state local để UI thay đổi ngay lập tức
      _user = _user!.copyWith(
        hoTen: hoTen ?? _user!.hoTen,
        gioiTinh: gioiTinh ?? _user!.gioiTinh,
        ngaySinh: ngaySinh ?? _user!.ngaySinh,
        diaChi: diaChi ?? _user!.diaChi,
        email: email ?? _user!.email,
        soDienThoai: soDienThoai ?? _user!.soDienThoai,
        cccd: cccd ?? _user!.cccd,
        soBhyt: soBhyt ?? _user!.soBhyt,
      );

      // 3. (Tùy chọn) Cập nhật email đăng nhập Firebase Auth nếu có thay đổi
      // Lưu ý: Firebase yêu cầu người dùng phải đăng nhập gần đây mới cho đổi email.
      if (email != null && email != _authService.currentUser?.email) {
        try {
          await _authService.currentUser?.updateEmail(email);
          print('✅ [DEBUG] Đã cập nhật email Firebase Auth.');
        } catch (e) {
          print(
            '⚠️ [DEBUG] Không thể cập nhật email Firebase Auth (yêu cầu xác thực lại): $e',
          );
          // Không throw lỗi ở đây để không làm hỏng luồng cập nhật Firestore
        }
      }
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi cập nhật hồ sơ: $e');
      rethrow; // Ném lỗi ra để EditProfileScreen bắt và hiển thị SnackBar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
      _hospital = null;
      _admin = null;
      _selectedRole = null;
      _verificationId = null;
      _resendToken = null;
      _pendingPhone = null;
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
