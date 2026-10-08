import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Chuẩn hóa số điện thoại về định dạng E.164 (+84...)
  String _toE164(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+'), ''); // Xóa khoảng trắng thừa
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
        phoneNumber: _toE164(phone), // Đã sửa lỗi gọi hàm private
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (cred) async {
          // Tự động xác thực (thường gặp trên Android hoặc số điện thoại thử nghiệm)
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

  Future<void> saveUserToFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true), // Merge true giúp an toàn hơn khi cập nhật dữ liệu
    );
  }

  // Hàm mới: Lấy thông tin user từ Firestore (Dùng khi mở app, user đã đăng nhập sẵn)
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin user từ Firestore: $e');
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