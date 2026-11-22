import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../../config/staff_session.dart';

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

  /// currentRoleInfo: trả về thông tin vai trò đang chọn (null nếu chưa chọn hoặc chưa tải).
  Map<String, dynamic>? get currentRoleInfo {
    if (_selectedRole == null || _roles.isEmpty) return null;
    return _roles.firstWhere(
      (role) => role['ma_vai_tro'] == _selectedRole,
      orElse: () => {},
    );
  }

  /// getAdminFromFirestore: lấy hồ sơ admin theo uid.
  Future<Map<String, dynamic>?> getAdminFromFirestore(String uid) {
    return _authService.getAdminFromFirestore(uid);
  }

  /// loadRoles: tải danh sách vai trò một lần và chọn vai trò đầu tiên nếu chưa chọn.
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

  /// setSelectedRole: đổi vai trò đang chọn.
  void setSelectedRole(String maVaiTro) {
    _selectedRole = maVaiTro;
    notifyListeners();
  }

  /// fetchCurrentUser: nạp hồ sơ tài khoản đang đăng nhập theo vai trò ưu tiên.
  /// Vai trò bệnh viện chỉ nhận tài khoản có hồ sơ bệnh viện và chưa có hồ sơ bệnh nhân;
  /// các vai trò khác ưu tiên hồ sơ bệnh nhân, không có mới thử hồ sơ bệnh viện.
  Future<void> fetchCurrentUser({String? preferredRole}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      if (preferredRole == 'benh_vien') {
        var hospital = await _authService.getHospitalFromFirestore(
          currentUser.uid,
        );
        hospital ??= await _authService.findHospitalByEmail(
          currentUser.email ?? '',
        );

        final patient = await _authService.getPatientFromFirestore(
          currentUser.uid,
        );
        if (patient != null) hospital = null;

        _hospital = hospital;
        _user = null;
        _selectedRole = hospital != null ? 'benh_vien' : null;
        if (hospital != null) {
          AppSession.benhVienId = hospital.uid ?? currentUser.uid;
        }
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
      } else {
        _hospital = null;
      }
      _selectedRole = patientModel?.role ?? _hospital?.role;
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin user hiện tại: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// restoreSession: khôi phục phiên Firebase còn lưu khi mở app.
  /// Trả về 'admin' | 'hospital' | 'patient' | 'login' (cần đăng nhập lại hoặc là nhân viên).
  Future<String> restoreSession() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return 'login';

    final admin = await _authService.getAdminFromFirestore(firebaseUser.uid);
    if (admin != null) {
      _admin = admin;
      _user = null;
      _hospital = null;
      _selectedRole = 'admin';
      notifyListeners();
      return 'admin';
    }

    await fetchCurrentUser();

    final hasEmail = (firebaseUser.email ?? '').isNotEmpty;
    final isEmailUnverified =
        hasEmail &&
        (_user?.daXacThucEmail == false || _hospital?.daXacThucEmail == false);
    if (isEmailUnverified) {
      await _authService.signOut();
      _user = null;
      _hospital = null;
      notifyListeners();
      return 'login';
    }

    if (_user != null) {
      await FCMService().init();
      return 'patient';
    }
    if (_hospital != null) {
      await FCMService().init();
      return 'hospital';
    }
    return 'login';
  }

  /// loginAdmin: đăng nhập admin bằng email/mật khẩu và lưu hồ sơ admin vào state.
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

  /// login: đăng nhập bằng email/mật khẩu, nạp hồ sơ và chặn tài khoản chưa xác thực email (ném 'EMAIL_NOT_VERIFIED').
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// sendOtp: gửi mã OTP tới số điện thoại và lưu verificationId, resendToken.
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
      onError: (message) {
        _isLoading = false;
        notifyListeners();
        onError(message);
      },
    );
  }

  /// loginWithPhoneOtp: đăng nhập bệnh nhân bằng OTP đã gửi qua sendOtp.
  /// Số điện thoại chưa có hồ sơ bệnh nhân sẽ bị từ chối và dọn tài khoản Auth vừa tự tạo.
  Future<void> loginWithPhoneOtp({required String smsCode}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_verificationId == null) throw Exception('Mã xác thực không hợp lệ');
      await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      _admin = null;

      await fetchCurrentUser(preferredRole: 'benh_nhan');

      if (_user == null) {
        final hasAnyProfile = _hospital != null;
        _hospital = null;
        if (hasAnyProfile) {
          await _authService.signOut();
        } else {
          try {
            await _authService.currentUser?.delete();
          } catch (_) {
            await _authService.signOut();
          }
        }

        throw Exception(
          'Số điện thoại này chưa đăng ký tài khoản bệnh nhân. Vui lòng đăng ký trước.',
        );
      }

      await FCMService().init();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// registerWithEmail: đăng ký bệnh nhân bằng email, gửi mail xác thực và lưu hồ sơ.
  /// Email đã tồn tại thì chuyển sang xử lý tài khoản cũ chưa xác thực.
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
        return;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// registerHospitalWithEmail: đăng ký bệnh viện bằng email, gửi mail xác thực và lưu hồ sơ.
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

  /// verifyOtpAndRegister: xác thực OTP rồi tạo hồ sơ bệnh nhân.
  /// Số điện thoại đã có hồ sơ thì đăng xuất và báo lỗi, tránh ghi đè dữ liệu cũ.
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

      final existing = await _authService.getPatientFromFirestore(
        credential.user!.uid,
      );
      if (existing != null) {
        await _authService.signOut();

        throw Exception(
          'Số điện thoại này đã được đăng ký. Vui lòng đăng nhập bằng mã OTP.',
        );
      }

      final newUser = PatientModel.fromRegisterPhone(
        uid: credential.user!.uid,
        hoTen: user.hoTen!,
        soDienThoai: _pendingPhone!,
        role: user.role,
      );
      await _authService.saveUserToFirestore(newUser);
      _user = newUser;
      _hospital = null;
      _selectedRole = newUser.role;

      await FCMService().init();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// _handleExistingEmail: xử lý email bệnh nhân đã tồn tại; nếu chưa xác thực thì xóa tài khoản cũ và đăng ký lại.
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
        await _authService.deleteUnverifiedPatient(oldUser.uid);
        print('✅ Đã xóa sạch tài khoản cũ.');

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
      rethrow;
    }
  }

  /// _handleExistingHospitalEmail: xử lý email bệnh viện đã tồn tại; nếu chưa xác thực thì xóa tài khoản cũ và đăng ký lại.
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

  /// _signInToReplaceUnverifiedAccount: đăng nhập vào tài khoản cũ chưa xác thực để có quyền xóa nó.
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

  /// resetPassword: gửi email đặt lại mật khẩu.
  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  /// markEmailAsVerified: đánh dấu đã xác thực email và nạp lại hồ sơ.
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

  /// updateUserProfile: cập nhật hồ sơ lên Firestore, cập nhật state cục bộ và thử đổi email đăng nhập Firebase.
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

      if (email != null && email != _authService.currentUser?.email) {
        try {
          await _authService.currentUser?.updateEmail(email);
          print('✅ [DEBUG] Đã cập nhật email Firebase Auth.');
        } catch (e) {
          print(
            '⚠️ [DEBUG] Không thể cập nhật email Firebase Auth (yêu cầu xác thực lại): $e',
          );
        }
      }
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi cập nhật hồ sơ: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// logout: đăng xuất và xóa toàn bộ state phiên, kể cả thông tin OTP đang chờ.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      await StaffSession.clear();
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