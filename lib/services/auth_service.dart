import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// currentUser: trả về tài khoản Firebase đang đăng nhập (null nếu chưa đăng nhập).
  User? get currentUser => _auth.currentUser;

  /// _toE164: chuẩn hóa số điện thoại Việt Nam về dạng +84xxxxxxxxx.
  String _toE164(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('0')) {
      return '+84${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+')) {
      return '+84$cleaned';
    }
    return cleaned;
  }

  /// sendOtp: gửi mã OTP qua SMS tới số điện thoại.
  /// Gọi onCodeSent khi gửi thành công (kèm verificationId để xác thực), onError khi thất bại.
  /// Không tự đăng nhập khi Android tự đọc SMS; người dùng luôn nhập mã thủ công.
  Future<void> sendOtp({
    required String phone,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _toE164(phone),
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (_) {},
        verificationFailed: (e) => onError(_errorMessage(e)),
        codeSent: (id, token) => onCodeSent(id, token),
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      onError('Không thể gửi mã OTP: ${e.toString()}');
    }
  }

  /// verifyOtp: đối chiếu mã OTP người dùng nhập với verificationId và đăng nhập Firebase bằng số điện thoại.
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// getAdminFromFirestore: lấy hồ sơ admin theo uid từ collection 'admins' (null nếu không có).
  Future<Map<String, dynamic>?> getAdminFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin admin: $e');
      return null;
    }
  }

  /// loginAdmin: đăng nhập email/mật khẩu rồi kiểm tra uid có trong 'admins'; không phải admin thì đăng xuất.
  Future<Map<String, dynamic>?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        return adminDoc.data();
      }

      await _auth.signOut();
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  /// getRoles: lấy danh sách vai trò từ collection 'VaiTro'.
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final snapshot = await _firestore.collection('VaiTro').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách vai trò: $e');
      return [];
    }
  }

  /// getRoleByMaVaiTro: lấy một vai trò theo mã vai trò.
  Future<Map<String, dynamic>?> getRoleByMaVaiTro(String maVaiTro) async {
    try {
      final doc = await _firestore.collection('VaiTro').doc(maVaiTro).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print(' Lỗi khi lấy vai trò: $e');
      return null;
    }
  }

  /// _errorMessage: đổi mã lỗi FirebaseAuth sang thông báo tiếng Việt.
  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần, vui lòng thử lại sau';
      case 'invalid-verification-code':
        return 'Mã OTP không đúng';
      case 'session-expired':
        return 'Mã OTP đã hết hạn, vui lòng gửi lại';
      case 'quota-exceeded':
        return 'Hệ thống đã hết lượt gửi SMS, vui lòng thử lại sau';
      default:
        return e.message ?? 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }

  /// signInWithEmailAndPassword: đăng nhập Firebase bằng email và mật khẩu.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// registerWithEmailAndPassword: tạo tài khoản Firebase bằng email và mật khẩu.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// _generatePatientId: sinh mã bệnh nhân kế tiếp (BN001, BN002...) dựa trên hồ sơ tạo gần nhất.
  Future<String> _generatePatientId() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('uid', isNotEqualTo: null)
          .orderBy('ngay_tao', descending: true)
          .limit(1)
          .get();

      int nextNumber = 1;

      if (snapshot.docs.isNotEmpty) {
        final String? lastUid = snapshot.docs.first.data()['uid'];

        if (lastUid != null && lastUid.isNotEmpty) {
          final numberPart = lastUid.replaceAll(RegExp(r'[^0-9]'), '');
          if (numberPart.isNotEmpty) {
            nextNumber = int.parse(numberPart) + 1;
          }
        }
      }

      final newId = 'BN${nextNumber.toString().padLeft(3, '0')}';
      print('✅ [DEBUG] Mã bệnh nhân tiếp theo sẽ là: $newId');

      return newId;
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi query mã bệnh nhân: $e');
      rethrow;
    }
  }

  /// findPatientByEmail: tìm hồ sơ bệnh nhân theo email (null nếu không có).
  Future<PatientModel?> findPatientByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PatientModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi tìm user theo email: $e');
      return null;
    }
  }

  /// findHospitalByEmail: tìm hồ sơ bệnh viện theo email (null nếu không có).
  Future<HospitalModel?> findHospitalByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final d = snapshot.docs.first;
        return HospitalModel.fromMap(d.data(), d.id);
      }
      return null;
    } catch (e) {
      print('Lỗi khi tìm bệnh viện theo email: $e');
      return null;
    }
  }

  /// deleteUnverifiedPatient: xóa hồ sơ bệnh nhân chưa xác thực email cùng tài khoản Auth hiện tại.
  Future<void> deleteUnverifiedPatient(String uid) async {
    await _deleteUnverifiedAccount(uid, AppConstants.patientsCollection);
  }

  /// deleteUnverifiedHospital: xóa hồ sơ bệnh viện chưa xác thực email cùng tài khoản Auth hiện tại.
  Future<void> deleteUnverifiedHospital(String uid) async {
    await _deleteUnverifiedAccount(uid, AppConstants.hospitalsCollection);
  }

  /// _deleteUnverifiedAccount: xóa document trong collection chỉ định và xóa tài khoản Auth đang đăng nhập.
  Future<void> _deleteUnverifiedAccount(String uid, String collection) async {
    try {
      await _firestore.collection(collection).doc(uid).delete();
      print('✅ Đã xóa document Firestore: $uid');

      await _auth.currentUser?.delete();
      print('✅ Đã xóa tài khoản Auth: $uid');
    } catch (e) {
      print('❌ Lỗi khi xóa user: $e');
      rethrow;
    }
  }

  /// updateUserVerificationStatus: cập nhật cờ đã xác thực email cho hồ sơ bệnh nhân hoặc bệnh viện.
  Future<void> updateUserVerificationStatus(String uid, bool isVerified) async {
    final patientRef = _firestore
        .collection(AppConstants.patientsCollection)
        .doc(uid);
    final patient = await patientRef.get();
    if (patient.exists) {
      await patientRef.update({
        'da_xac_thuc_email': isVerified,
        'trang_thai_id': isVerified
            ? TrangThaiId.hoatDong
            : TrangThaiId.khongHoatDong,
      });
      return;
    }

    final hospitalRef = _firestore
        .collection(AppConstants.hospitalsCollection)
        .doc(uid);
    final hospital = await hospitalRef.get();
    if (hospital.exists) {
      await hospitalRef.update({'da_xac_thuc_email': isVerified});
      return;
    }

    throw StateError('Không tìm thấy hồ sơ bệnh nhân hoặc bệnh viện: $uid');
  }

  /// saveUserToFirestore: lưu hồ sơ bệnh nhân (merge) và sinh mã BNxxx nếu role là bệnh nhân và chưa có uid.
  Future<void> saveUserToFirestore(PatientModel user) async {
    final Map<String, dynamic> userData = user.toMap();

    if (user.role?.trim() == 'benh_nhan' &&
        (user.uid == null || user.uid!.isEmpty)) {
      try {
        final generatedId = await _generatePatientId();
        userData['uid'] = generatedId;
        print('✅ [DEBUG] Đã sinh mã bệnh nhân thành công: $generatedId');
      } catch (e) {
        print('❌ [DEBUG] Lỗi khi sinh mã bệnh nhân: $e');
        rethrow;
      }
    } else {
      print(
        '⚠️ [DEBUG] Bỏ qua sinh mã. Role hiện tại: "${user.role}", uid: "${user.uid}"',
      );
    }

    await _firestore
        .collection(AppConstants.patientsCollection)
        .doc(user.uid)
        .set({
          ...userData,
          'mat_khau': FieldValue.delete(),
        }, SetOptions(merge: true));

    print('✅ [DEBUG] Đã lưu user vào Firestore với UID: ${user.uid}');
  }

  /// saveHospitalToFirestore: lưu hồ sơ bệnh viện (merge), bắt buộc có uid.
  Future<void> saveHospitalToFirestore(HospitalModel hospital) async {
    final uid = hospital.uid;
    if (uid == null || uid.isEmpty) {
      throw ArgumentError('Hospital UID is required to save the account.');
    }

    await _firestore.collection(AppConstants.hospitalsCollection).doc(uid).set({
      ...hospital.toMap(),
      'mat_khau': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// getPatientFromFirestore: lấy hồ sơ bệnh nhân theo uid (null nếu không có).
  Future<PatientModel?> getPatientFromFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return PatientModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin user từ Firestore: $e');
      return null;
    }
  }

  /// getHospitalFromFirestore: lấy hồ sơ bệnh viện theo uid (null nếu không có).
  Future<HospitalModel?> getHospitalFromFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return HospitalModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin bệnh viện từ Firestore: $e');
      return null;
    }
  }

  /// updateUserProfile: cập nhật các trường hồ sơ bệnh nhân khác null lên Firestore.
  Future<void> updateUserProfile({
    required String uid,
    String? hoTen,
    String? gioiTinh,
    DateTime? ngaySinh,
    String? diaChi,
    String? email,
    String? soDienThoai,
    String? cccd,
    String? soBhyt,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (hoTen != null) updateData['ho_ten'] = hoTen;
      if (gioiTinh != null) updateData['gioi_tinh'] = gioiTinh;
      if (ngaySinh != null) updateData['ngay_sinh'] = ngaySinh.toIso8601String();
      if (diaChi != null) updateData['dia_chi'] = diaChi;
      if (email != null) updateData['email'] = email;
      if (soDienThoai != null) updateData['so_dien_thoai'] = soDienThoai;
      if (cccd != null) updateData['cccd'] = cccd;
      if (soBhyt != null) updateData['so_bhyt'] = soBhyt;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(AppConstants.patientsCollection)
            .doc(uid)
            .update(updateData);

        print('✅ [DEBUG] Đã cập nhật thông tin người dùng thành công.');
      }
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi cập nhật thông tin người dùng: $e');
      rethrow;
    }
  }

  /// signOut: đăng xuất khỏi Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// resetPassword: gửi email đặt lại mật khẩu.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}