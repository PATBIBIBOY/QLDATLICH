import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_routes.dart';
import '../config/constants.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _securityWatcherSub;

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

  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final patientModel = await _authService.getPatientFromFirestore(
          currentUser.uid,
        );
        _user = patientModel;
        if (patientModel == null) {
          _hospital = await _authService.getHospitalFromFirestore(
            currentUser.uid,
          );
        }
        _selectedRole = patientModel?.role ?? _hospital?.role;

        // Kiểm tra nếu tài khoản đang bị khóa trong phiên đăng nhập
        if (_user != null) {
          final bool isBlocked = _user!.isBlocked ||
              _user!.chanDangNhap ||
              _user!.trangThaiId == TrangThaiId.khongHoatDong;
          if (isBlocked) {
            final reason = _user!.lyDoKhoa ?? 'Tài khoản bệnh nhân đã bị khóa';
            await forceSignOut(reason: reason);
            return;
          }
        } else if (_hospital != null) {
          final bool isBlocked = _hospital!.isBlocked ||
              _hospital!.chanDangNhap ||
              _hospital!.trangThaiHopTacId != 10;
          if (isBlocked) {
            final reason = _hospital!.lyDoKhoa ?? 'Cơ sở y tế đã ngừng hợp tác hoặc bị chặn truy cập';
            await forceSignOut(reason: reason);
            return;
          }
        }

        // Bắt đầu lắng nghe thời gian thực để đá văng ra ngay khi bị Admin khóa
        _startSecurityWatcher(currentUser.uid, isHospital: _hospital != null);
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

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _admin = null;
      await fetchCurrentUser();

      // ✅ 1. Kiểm tra nếu đăng nhập thành công nhưng chưa xác thực email
      final isEmailUnverified =
          _user?.daXacThucEmail == false || _hospital?.daXacThucEmail == false;
      if (isEmailUnverified) {
        await _authService.signOut();
        _user = null;
        _hospital = null;
        notifyListeners();
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      // ✅ 2. Kiểm tra nếu tài khoản bệnh nhân bị khóa
      if (_user != null) {
        final bool isBlocked = _user!.isBlocked ||
            _user!.chanDangNhap ||
            _user!.trangThaiId == TrangThaiId.khongHoatDong;
        if (isBlocked) {
          final reason = _user!.lyDoKhoa ?? 'Tài khoản đã bị quản trị viên khóa';
          await _authService.signOut();
          _user = null;
          notifyListeners();
          throw Exception('ACCOUNT_BLOCKED: $reason');
        }
      }

      // ✅ 3. Kiểm tra nếu tài khoản bệnh viện bị ngừng hợp tác / khóa
      if (_hospital != null) {
        final bool isBlocked = _hospital!.isBlocked ||
            _hospital!.chanDangNhap ||
            _hospital!.trangThaiHopTacId != 10;
        if (isBlocked) {
          final reason = _hospital!.lyDoKhoa ?? 'Cơ sở y tế đã ngừng hợp tác hoặc bị chặn truy cập';
          await _authService.signOut();
          _hospital = null;
          notifyListeners();
          throw Exception('HOSPITAL_BLOCKED: $reason');
        }
      }

      // ✅ 4. Kích hoạt Security Watcher
      final curUid = _authService.currentUser?.uid;
      if (curUid != null) {
        _startSecurityWatcher(curUid, isHospital: _hospital != null);
      }
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

  // ✅ ĐÃ TỐI ƯU: Thêm kiểm tra an toàn cho mật khẩu
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
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      _securityWatcherSub?.cancel();
      _securityWatcherSub = null;
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

  // =========================================================================
  // BẢO MẬT THỜI GIAN THỰC (REALTIME SECURITY WATCHER)
  // Tự động kiểm tra và ĐÁ VĂNG (Kick out) người dùng ngay lập tức khi bị Admin khóa
  // =========================================================================
  void _startSecurityWatcher(String uid, {required bool isHospital}) {
    _securityWatcherSub?.cancel();
    final collection = isHospital
        ? AppConstants.hospitalsCollection
        : AppConstants.patientsCollection;

    _securityWatcherSub = FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        await forceSignOut(reason: 'Tài khoản của bạn đã bị xóa khỏi hệ thống.');
        return;
      }

      final data = snapshot.data();
      if (data == null) return;

      bool shouldKick = false;
      String kickReason = '';

      if (isHospital) {
        final statusId = (data['trang_thai_hop_tac_id'] as num?)?.toInt() ?? 1;
        final chanDangNhap = data['chan_dang_nhap'] == true || data['is_blocked'] == true;
        final isHuy = data['trang_thai'] == 'huy_hop_tac' || data['trangThai'] == 'HUY_HOP_TAC';
        if (chanDangNhap || statusId != 10 || isHuy) {
          shouldKick = true;
          kickReason = data['ly_do_huy']?.toString() ??
              data['ly_do_khoa']?.toString() ??
              'Cơ sở y tế đã bị ngừng hợp tác hoặc khóa truy cập bởi Quản trị viên.';
        }
      } else {
        // Bệnh nhân
        final rawStatus = data['trang_thai_id'];
        int statusId = TrangThaiId.hoatDong;
        if (rawStatus is int) {
          statusId = rawStatus;
        } else if (rawStatus is num) {
          statusId = rawStatus.toInt();
        } else if (rawStatus is String) {
          statusId = int.tryParse(rawStatus) ?? TrangThaiId.hoatDong;
        }
        final chanDangNhap = data['chan_dang_nhap'] == true || data['is_blocked'] == true;
        final trangThaiStr = data['trang_thai']?.toString().toLowerCase() ?? '';
        final isKhoa = statusId == TrangThaiId.khongHoatDong ||
            trangThaiStr == 'khoa' ||
            trangThaiStr == 'chan_dang_nhap';
        if (chanDangNhap || isKhoa) {
          shouldKick = true;
          kickReason = data['ly_do_khoa']?.toString() ??
              data['ly_do_chan']?.toString() ??
              'Tài khoản của bạn đã bị quản trị viên khóa.';
        }
      }

      if (shouldKick) {
        await forceSignOut(reason: kickReason);
      }
    });
  }

  /// Buộc đăng xuất ngay lập tức, chuyển về màn hình đăng nhập và cảnh báo
  Future<void> forceSignOut({String? reason}) async {
    _securityWatcherSub?.cancel();
    _securityWatcherSub = null;
    try {
      await _authService.signOut();
    } catch (_) {}

    _user = null;
    _hospital = null;
    _admin = null;
    _selectedRole = null;
    notifyListeners();

    // Chuyển hướng người dùng về màn hình đăng nhập
    final nav = AppRoutes.navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
    }

    // Hiển thị hộp thoại cảnh báo tài khoản bị khóa
    final ctx = AppRoutes.navigatorKey.currentContext;
    if (ctx != null) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_person_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                'Tài khoản bị khóa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            reason ?? 'Tài khoản của bạn đã bị khóa hoặc ngừng hợp tác bởi Quản trị viên. Phiên làm việc đã bị kết thúc.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _securityWatcherSub?.cancel();
    super.dispose();
  }
}
