import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../models/hospital_model.dart';
import '../models/patient_model.dart';

import 'hospital_sync_service.dart';

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
        return await _createHospitalModelWithRealtimeStatus(d);
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
    if (dataToSave['co_so'] == null) {
      dataToSave['co_so'] = 'Tu_nhan';
    }
    if (dataToSave['bhyt'] == null) {
      dataToSave['bhyt'] = 'Co_BHYT';
    }
    if (dataToSave['chuyen_khoa_ids'] == null) {
      dataToSave['chuyen_khoa_ids'] = <String>[];
    }

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

  static Map<String, dynamic> buildHospitalStatusFields(dynamic rawStatus) {
    return HospitalSyncService.buildStatusFields(rawStatus);
  }

  /// Chuẩn hóa các tài khoản bệnh viện đã đăng ký hợp tác trên Firestore
  /// (đảm bảo co_so, bhyt, chuyen_khoa_ids theo đúng collection Firebase CoSo & BHYT,
  /// TUYỆT ĐỐI KHÔNG tự ý ghi đè trạng thái hợp tác của bệnh viện)
  Future<void> chuanHoaBenhVienDaDangKyHopTac([String? specificMaBv]) async {
    try {
      // 0. Quét dọn các tài liệu có id là Auth UID trong YeuCauHopTac và di chuyển về BVxxx
      await HospitalSyncService.chuanHoaVaDonDepYeuCauHopTac();

      // 1. Chuẩn hóa cho bệnh viện cụ thể nếu có
      if (specificMaBv != null && specificMaBv.isNotEmpty) {
        final doc = await _firestore
            .collection(AppConstants.hospitalsCollection)
            .doc(specificMaBv)
            .get();
        if (doc.exists) {
          await _chuanHoaMotDocBenhVien(doc);
        }
      }

      // 3. Chuẩn hóa co_so, bhyt, chuyen_khoa_ids cho tất cả các viện đã gửi đơn
      final query = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('da_gui_don', isEqualTo: true)
          .get();
      for (final doc in query.docs) {
        await _chuanHoaMotDocBenhVien(doc);
      }
    } catch (e) {
      print('⚠️ [AuthService] Lỗi chuẩn hóa dữ liệu bệnh viện: $e');
    }
  }

  Future<void> _chuanHoaMotDocBenhVien(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    if (data == null) return;

    // Kiểm tra trạng thái từ YeuCauHopTac để đảm bảo luôn đồng nhất
    try {
      final yDoc = await _firestore.collection('YeuCauHopTac').doc(doc.id).get();
      if (yDoc.exists && yDoc.data()?['trang_thai_hop_tac_id'] != null) {
        final rawYcStatus = yDoc.data()!['trang_thai_hop_tac_id'];
        final int ycStatus = rawYcStatus is int
            ? rawYcStatus
            : int.tryParse(rawYcStatus.toString()) ?? 1;
        final statusFields = buildHospitalStatusFields(ycStatus);
        if (data['trang_thai_hop_tac_id'] != ycStatus ||
            data['trangThai'] != statusFields['trangThai'] ||
            data['trang_thai'] != statusFields['trang_thai']) {
          await doc.reference.set(statusFields, SetOptions(merge: true));
        }
      }
    } catch (_) {}

    final bool canCapNhat = data['bhyt'] == null ||
        data['co_so'] == null ||
        data['chuyen_khoa_ids'] == null;
    if (canCapNhat) {
      final updates = <String, dynamic>{};
      if (data['bhyt'] == null) {
        final coBhyt = data['co_bhyt'];
        updates['bhyt'] = (coBhyt == false) ? 'Khong_BHYT' : 'Co_BHYT';
      }
      if (data['co_so'] == null) {
        final loaiHinh = (data['loai_hinh'] ?? '').toString().toLowerCase();
        updates['co_so'] = (loaiHinh.contains('công') || loaiHinh.contains('cong'))
            ? 'Cong_lap'
            : 'Tu_nhan';
      }
      if (data['chuyen_khoa_ids'] == null) {
        updates['chuyen_khoa_ids'] = <String>[];
      }
      await doc.reference.update(updates);
      try {
        if (doc.id.startsWith('BV')) {
          final ycSnap = await _firestore.collection('YeuCauHopTac').doc(doc.id).get();
          if (ycSnap.exists) {
            await ycSnap.reference.set(updates, SetOptions(merge: true));
          }
        }
      } catch (_) {}
      print('✅ [AuthService] Đã chuẩn hóa co_so, bhyt, chuyen_khoa_ids cho bệnh viện: ${doc.id}');
    }
  }

  Future<HospitalModel> _createHospitalModelWithRealtimeStatus(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) async {
    _chuanHoaMotDocBenhVien(d);
    final mapData = Map<String, dynamic>.from(d.data() ?? {});
    try {
      final String ycKey = d.id.startsWith('BV')
          ? d.id
          : (mapData['ma_benh_vien']?.toString() ?? '');
      if (ycKey.isNotEmpty && ycKey.startsWith('BV')) {
        final yc = await _firestore.collection('YeuCauHopTac').doc(ycKey).get();
        if (yc.exists && yc.data()?['trang_thai_hop_tac_id'] != null) {
          final rawYcStatus = yc.data()!['trang_thai_hop_tac_id'];
          final int ycStatus = rawYcStatus is int
              ? rawYcStatus
              : int.tryParse(rawYcStatus.toString()) ?? 1;
          mapData['trang_thai_hop_tac_id'] = ycStatus;
          final statusFields = buildHospitalStatusFields(ycStatus);
          mapData['trangThai'] = statusFields['trangThai'];
          mapData['trang_thai'] = statusFields['trang_thai'];
        }
      }
    } catch (_) {}
    return HospitalModel.fromMap(mapData, d.id);
  }

  
   /// getHospitalFromFirestore: lấy hồ sơ bệnh viện theo uid (null nếu không có).
  Future<HospitalModel?> getHospitalFromFirestore(String uid) async {
    try {
      // 1. Nếu là mã BVxxx, tìm trực tiếp theo Doc ID
      if (uid.startsWith('BV')) {
        final doc = await _firestore
            .collection(AppConstants.hospitalsCollection)
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          return await _createHospitalModelWithRealtimeStatus(doc);
        }
      }

      // 2. Nếu là Auth UID hoặc không tìm thấy bằng Doc ID, tìm theo auth_uid
      final authQuery = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('auth_uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (authQuery.docs.isNotEmpty) {
        return await _createHospitalModelWithRealtimeStatus(authQuery.docs.first);
      }

      // 3. Tìm theo ma_benh_vien
      final maQuery = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .where('ma_benh_vien', isEqualTo: uid)
          .limit(1)
          .get();
      if (maQuery.docs.isNotEmpty) {
        return await _createHospitalModelWithRealtimeStatus(maQuery.docs.first);
      }

      // 4. Fallback tìm theo doc ID (kể cả không bắt đầu bằng BV)
      final doc = await _firestore
          .collection(AppConstants.hospitalsCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return await _createHospitalModelWithRealtimeStatus(doc);
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