import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_session.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  @override
  void notifyListeners() {
    // Tránh lỗi FlutterError: setState() or markNeedsBuild() called during build
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          super.notifyListeners();
        }
      });
    } else {
      super.notifyListeners();
    }
  }

  AuthProvider() {
    _initAutoRestore();
  }

  void _initAutoRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cur = _authService.currentUser;
      if (cur != null) {
        fetchCurrentUser(preferredRole: 'benh_vien');
      }
    });
  }

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

  /// getAdminFromFirestore: lấy hồ sơ admin theo uid.
  Future<Map<String, dynamic>?> getAdminFromFirestore(String uid) async {
    return _authService.getAdminFromFirestore(uid);
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

  /// fetchCurrentUser: nạp hồ sơ của tài khoản đang đăng nhập theo vai trò đã chọn.
  /// Tab bệnh viện chỉ nhận tài khoản có hồ sơ bệnh viện và chưa có hồ sơ bệnh nhân;
  /// các tab còn lại ưu tiên hồ sơ bệnh nhân, không có mới thử hồ sơ bệnh viện.
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
          AppSession.benhVienId =
              hospital.maBenhVien ?? hospital.uid ?? currentUser.uid;
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

  /// currentRoleInfo: thông tin vai trò đang chọn (null nếu chưa chọn hoặc chưa tải).
  Map<String, dynamic>? get currentRoleInfo {
    if (_selectedRole == null || _roles.isEmpty) return null;
    return _roles.firstWhere(
      (role) => role['ma_vai_tro'] == _selectedRole,
      orElse: () => {},
    );
  }

  /// login: đăng nhập bằng email/mật khẩu, nạp hồ sơ, chặn tài khoản chưa xác thực email (ném 'EMAIL_NOT_VERIFIED').
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

      // 1. Đồng bộ trạng thái xác thực từ Firebase Auth sang Firestore
      final currentFbUser = _authService.currentUser;
      await currentFbUser?.reload();
      final freshFbUser = _authService.currentUser;
      final isAuthEmailVerified = freshFbUser?.emailVerified ?? false;

      if (freshFbUser != null && isAuthEmailVerified) {
        try {
          await _authService.updateUserVerificationStatus(
            freshFbUser.uid,
            true,
          );
        } catch (_) {}
      }

      await fetchCurrentUser(preferredRole: role);

      // 2. Kiểm tra xác thực email: nếu cả Firebase Auth lẫn Firestore đều chưa xác thực
      final isFirestoreEmailVerified = (_user?.daXacThucEmail ?? false) ||
          (_hospital?.daXacThucEmail ?? false);

      final isVerified = isAuthEmailVerified || isFirestoreEmailVerified;

      if (!isVerified) {
        // KHÔNG gọi signOut() tại đây để phiên làm việc còn giữ lại cho màn hình EmailVerificationScreen
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

  /// resetPassword: gửi email đặt lại mật khẩu.
  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  /// registerWithEmail: đăng ký bệnh nhân bằng email, gửi mail xác thực và lưu hồ sơ.
  /// Nếu email đã tồn tại thì chuyển sang xử lý tài khoản cũ chưa xác thực.
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

      // ✅ Tự động sinh ID bệnh viện tăng dần theo CSDL
      final idData = await _authService.generateHospitalId();
      final nextId = idData['id'] as int;
      final nextMaBv = idData['ma_benh_vien'] as String;

      final newHospital = HospitalModel.fromRegisterEmail(
        id: nextId,
        maBenhVien: nextMaBv,
        uid: nextMaBv,
        authUid: credential.user!.uid,
        tenBenhVien: hospital.tenBenhVien!,
        email: email,
        diaChi: hospital.diaChi,
        role: hospital.role,
      ).copyWith(daXacThucEmail: false);

      await _authService.saveHospitalToFirestore(newHospital);
      _hospital = newHospital;
      _user = null;
      AppSession.benhVienId = nextMaBv;
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

  /// _handleExistingHospitalEmail: email bệnh viện đã tồn tại; nếu chưa xác thực thì xóa tài khoản cũ và đăng ký lại.
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
    await _authService.deleteUnverifiedHospital(oldHospital.uid ?? oldHospital.authUid ?? '');

    final credential = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();

    final idData = await _authService.generateHospitalId();
    final nextId = oldHospital.id ?? (idData['id'] as int);
    final nextMaBv = oldHospital.maBenhVien ?? (idData['ma_benh_vien'] as String);

    final newHospital = HospitalModel.fromRegisterEmail(
      id: nextId,
      maBenhVien: nextMaBv,
      uid: nextMaBv,
      authUid: credential.user!.uid,
      tenBenhVien: hospital.tenBenhVien!,
      email: email,
      diaChi: hospital.diaChi,
      role: hospital.role,
    ).copyWith(daXacThucEmail: false);

    await _authService.saveHospitalToFirestore(newHospital);
    _hospital = newHospital;
    _user = null;
    AppSession.benhVienId = nextMaBv;
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

  /// _handleExistingEmail: email bệnh nhân đã tồn tại; nếu chưa xác thực thì xóa tài khoản cũ và đăng ký lại.
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
        if (_hospital != null) {
          AppSession.benhVienId = _hospital!.maBenhVien ?? _hospital!.uid ?? user.uid;
        }
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật trạng thái xác thực: $e');
      rethrow;
    }
  }

  /// sendOtp: gửi mã OTP tới số điện thoại (dùng cho cả đăng ký và đăng nhập), lưu verificationId và resendToken.
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

  /// verifyOtpAndRegister: xác thực OTP rồi tạo hồ sơ bệnh nhân.
  /// Nếu số điện thoại đã có hồ sơ thì đăng xuất và báo lỗi, tránh ghi đè dữ liệu cũ.
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
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// loginWithPhoneOtp: đăng nhập bệnh nhân bằng OTP đã gửi qua sendOtp.
  /// Số điện thoại chưa có hồ sơ bệnh nhân thì bị từ chối và dọn tài khoản Auth vừa tự tạo.
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
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> chuanHoaBenhVienDaDangKy([String? maBv]) async {
    try {
      await _authService.chuanHoaBenhVienDaDangKyHopTac(maBv);
    } catch (_) {}
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