import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Chuẩn hóa số điện thoại về định dạng E.164 (+84...)
  String _toE164(String phone) {
    String cleaned = phone.replaceAll(
      RegExp(r'\s+'),
      '',
    ); // Xóa khoảng trắng thừa
    if (cleaned.startsWith('0')) {
      return '+84${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+')) {
      return '+84$cleaned';
    }
    return cleaned;
  }

  Future<void> sendOtp({
    required String phone,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserCredential credential) onAutoVerified,
    required void Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _toE164(phone),
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (cred) async {
          final userCredential = await _auth.signInWithCredential(cred);
          onAutoVerified(userCredential);
        },
        verificationFailed: (e) => onError(_errorMessage(e)),
        codeSent: (id, token) => onCodeSent(id, token),
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      onError('Không thể gửi mã OTP: ${e.toString()}');
    }
  }

  // ✅ Lấy thông tin admin từ Firestore
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

  // ✅ Đăng nhập admin (kiểm tra trong collection admins)
  Future<Map<String, dynamic>?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Đăng nhập Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Kiểm tra xem UID này có trong collection 'admins' không
      final adminDoc = await _firestore.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        return adminDoc.data();
      }

      // Nếu không có trong collection admins → không phải admin
      await _auth.signOut();
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(cred);
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final snapshot = await _firestore.collection('VaiTro').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Lưu document ID
        return data;
      }).toList();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách vai trò: $e');
      return [];
    }
  }

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
      default:
        return e.message ?? 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<String> _generatePatientId() async {
    try {
      // Query hồ sơ bệnh nhân có mã lớn nhất để tạo mã tiếp theo.
      final snapshot = await _firestore
          .collection(AppConstants.patientsCollection)
          .where('ma_benh_nhan', isNotEqualTo: null)
          .orderBy(
            'ngay_tao',
            descending: true,
          ) // Sắp xếp giảm dần (mới nhất lên đầu)
          .limit(1) // Chỉ lấy đúng 1 người đầu tiên (người đăng ký cuối cùng)
          .get();

      int nextNumber = 1; // Mặc định nếu chưa có ai thì bắt đầu từ 1

      // 2. Nếu đã có người đăng ký trước đó và có mã
      if (snapshot.docs.isNotEmpty) {
        String? lastMaBN = snapshot.docs.first.data()['ma_benh_nhan'];

        if (lastMaBN != null && lastMaBN.isNotEmpty) {
          // Tách lấy phần số (loại bỏ chữ "BN" và các ký tự không phải số)
          String numberPart = lastMaBN.replaceAll(RegExp(r'[^0-9]'), '');

          // Chuyển thành số và cộng thêm 1
          if (numberPart.isNotEmpty) {
            nextNumber = int.parse(numberPart) + 1;
          }
        }
      }

      // 3. Format lại thành BN001, BN002, v.v.
      final newId = 'BN${nextNumber.toString().padLeft(3, '0')}';
      print('✅ [DEBUG] Mã bệnh nhân tiếp theo sẽ là: $newId');

      return newId;
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi query mã bệnh nhân: $e');
      rethrow;
    }
  }

  /// ✅ SINH ID BỆNH VIỆN TỰ ĐỘNG TĂNG DẦN THEO DATABASE
  /// CSDL gốc có 500 bệnh viện (BV001 - BV500).
  /// Mỗi khi tạo bệnh viện mới, ID tăng thêm 1 (501 -> BV501, 502 -> BV502,...).
  Future<Map<String, dynamic>> generateHospitalId() async {
    try {
      int maxFound = 500; // Mặc định cơ sở ban đầu có 500 bệnh viện

      // 1. Quét tìm tất cả document có id dạng BVxxx để tìm số lớn nhất
      try {
        final snap = await _firestore
            .collection(AppConstants.hospitalsCollection)
            .get();

        final regex = RegExp(r'^BV(\d+)$', caseSensitive: false);
        for (final doc in snap.docs) {
          final match = regex.firstMatch(doc.id);
          if (match != null) {
            final parsed = int.tryParse(match.group(1)!);
            if (parsed != null && parsed > maxFound) {
              maxFound = parsed;
            }
          }

          final ma = doc.data()['ma_benh_vien']?.toString() ?? '';
          final matchMa = regex.firstMatch(ma);
          if (matchMa != null) {
            final parsed = int.tryParse(matchMa.group(1)!);
            if (parsed != null && parsed > maxFound) {
              maxFound = parsed;
            }
          }

          final idVal = doc.data()['id'];
          if (idVal is num && idVal.toInt() > maxFound) {
            maxFound = idVal.toInt();
          }
        }
      } catch (e) {
        print('⚠️ [AuthService] Lỗi quét danh sách bệnh viện: $e');
      }

      final nextId = maxFound + 1;
      final nextMaBv = 'BV${nextId.toString().padLeft(3, '0')}';
      print('✅ [AuthService] Sinh ID bệnh viện tăng dần (+1): $nextMaBv (ID: $nextId)');

      return {
        'id': nextId,
        'ma_benh_vien': nextMaBv,
      };
    } catch (e) {
      print('❌ [DEBUG] Lỗi khi sinh ID bệnh viện: $e');
      return {
        'id': 503,
        'ma_benh_vien': 'BV503',
      };
    }
  }

  // ✅ HÀM MỚI 1: Tìm user theo email
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

  Future<void> deleteUnverifiedPatient(String uid) async {
    await _deleteUnverifiedAccount(uid, AppConstants.patientsCollection);
  }

  Future<void> deleteUnverifiedHospital(String uid) async {
    try {
      final hospital = await getHospitalFromFirestore(uid);
      final docId = hospital?.maBenhVien ?? uid;
      await _firestore
          .collection(AppConstants.hospitalsCollection)
          .doc(docId)
          .delete();
      await _auth.currentUser?.delete();
      print('✅ Đã xóa bệnh viện chưa xác thực: $docId');
    } catch (e) {
      print('❌ Lỗi khi xóa bệnh viện chưa xác thực: $e');
    }
  }

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
      final maBv = hospital.data()?['ma_benh_vien']?.toString();
      final authUid = hospital.data()?['auth_uid']?.toString();
      if (maBv != null && maBv != uid) {
        await _firestore
            .collection(AppConstants.hospitalsCollection)
            .doc(maBv)
            .update({'da_xac_thuc_email': isVerified});
      }
      if (authUid != null && authUid != uid) {
        await _firestore
            .collection(AppConstants.hospitalsCollection)
            .doc(authUid)
            .update({'da_xac_thuc_email': isVerified});
      }
      return;
    }

    // Tìm theo auth_uid
    final authQuery = await _firestore
        .collection(AppConstants.hospitalsCollection)
        .where('auth_uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (authQuery.docs.isNotEmpty) {
      await authQuery.docs.first.reference
          .update({'da_xac_thuc_email': isVerified});
      return;
    }

    // Tìm theo email hiện tại của Firebase Auth
    final currentEmail = _auth.currentUser?.email;
    if (currentEmail != null && currentEmail.isNotEmpty) {
      final emailQuery = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('email', isEqualTo: currentEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        await emailQuery.docs.first.reference
            .update({'da_xac_thuc_email': isVerified});
        return;
      }
    }
  }

  Future<void> saveUserToFirestore(PatientModel user) async {
    Map<String, dynamic> userData = user.toMap();

    if (user.role?.trim() == 'benh_nhan' &&
        (user.maBenhNhan == null || user.maBenhNhan!.isEmpty)) {
      try {
        final generatedId = await _generatePatientId();
        userData['ma_benh_nhan'] = generatedId;
        print('✅ [DEBUG] Đã sinh mã bệnh nhân thành công: $generatedId');
      } catch (e) {
        print('❌ [DEBUG] Lỗi khi sinh mã bệnh nhân: $e');
        rethrow;
      }
    } else {
      print(
        '⚠️ [DEBUG] Bỏ qua sinh mã. Role hiện tại: "${user.role}", maBenhNhan: "${user.maBenhNhan}"',
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

  /// ✅ LƯU BỆNH VIỆN VÀO FIRESTORE
  /// - Lưu document ID là `ma_benh_vien` (ví dụ `BV501`) để liên kết chuẩn khóa ngoại với Khoa, PhongKham, NhanVien
  /// - Nếu chưa có ID thì tự động gọi `generateHospitalId()`
  /// - Đồng thời liên kết `auth_uid` để tìm kiếm từ Firebase Auth UID
  Future<void> saveHospitalToFirestore(HospitalModel hospital) async {
    HospitalModel modelToSave = hospital;

    if (modelToSave.id == null ||
        modelToSave.maBenhVien == null ||
        modelToSave.maBenhVien!.isEmpty) {
      final generated = await generateHospitalId();
      final genId = generated['id'] as int;
      final genMa = generated['ma_benh_vien'] as String;

      modelToSave = modelToSave.copyWith(
        id: genId,
        maBenhVien: genMa,
        uid: genMa,
      );
    }

    final docId = modelToSave.maBenhVien ?? modelToSave.uid;
    if (docId == null || docId.isEmpty) {
      throw ArgumentError('Hospital ID/UID is required to save the account.');
    }

    final dataToSave = {
      ...modelToSave.toMap(),
      'mat_khau': FieldValue.delete(),
    };

    // CHỈ LƯU DUY NHẤT 1 TÀI LIỆU VỚI ID LÀ MÃ BỆNH VIỆN BVxxx (ví dụ: BV502)
    // TUYỆT ĐỐI KHÔNG TẠO DOCUMENT VỚI ID TỰ SINH / AUTH UID
    await _firestore
        .collection(AppConstants.hospitalsCollection)
        .doc(docId)
        .set(dataToSave, SetOptions(merge: true));

    print('✅ [AuthService] Đã lưu bệnh viện theo đúng định dạng mẫu: $docId');

    // Tự động dọn dẹp các document có id tự sinh (như UJqOeEvWBsY...) nếu có
    _donDepDocumentTuSinhBenhVien();
  }

  /// Dọn dẹp các document có ID tự sinh (không phải dạng BVxxx) trong collection BenhVien
  Future<void> _donDepDocumentTuSinhBenhVien() async {
    try {
      final snap = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .get();
      for (final doc in snap.docs) {
        if (!doc.id.startsWith('BV')) {
          print('🧹 [AuthService] Đang xóa document ID tự sinh trong BenhVien: ${doc.id}');
          await doc.reference.delete();
        }
      }
    } catch (_) {}
  }

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

  Future<HospitalModel?> getHospitalFromFirestore(String uid) async {
    try {
      // 1. Thử lấy trực tiếp theo Document ID (mã BVxxx hoặc Auth UID)
      final doc = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return HospitalModel.fromMap(doc.data()!, doc.id);
      }

      // 2. Tìm theo auth_uid
      final authQuery = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('auth_uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (authQuery.docs.isNotEmpty) {
        final d = authQuery.docs.first;
        return HospitalModel.fromMap(d.data(), d.id);
      }

      // 3. Tìm theo ma_benh_vien
      final maQuery = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('ma_benh_vien', isEqualTo: uid)
          .limit(1)
          .get();
      if (maQuery.docs.isNotEmpty) {
        final d = maQuery.docs.first;
        return HospitalModel.fromMap(d.data(), d.id);
      }

      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin bệnh viện từ Firestore: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
