import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_admin_credentials.dart';

class FirebaseAdminAuthService {
  static final FirebaseAdminAuthService instance = FirebaseAdminAuthService._();
  FirebaseAdminAuthService._();

  static const _scopes = [
    'https://www.googleapis.com/auth/identitytoolkit',
    'https://www.googleapis.com/auth/firebase',
  ];

  AccessCredentials? _credentials;

  /// Lấy Google OAuth2 Access Token từ Service Account Key
  Future<String?> _getAccessToken() async {
    try {
      if (_credentials != null &&
          _credentials!.accessToken.data.isNotEmpty &&
          _credentials!.accessToken.expiry.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
        return _credentials!.accessToken.data;
      }

      final accountCredentials = ServiceAccountCredentials.fromJson({
        'type': 'service_account',
        'project_id': FirebaseAdminConfig.projectId,
        'client_email': FirebaseAdminConfig.clientEmail,
        'private_key': FirebaseAdminConfig.privateKey,
      });

      final client = http.Client();
      try {
        _credentials = await obtainAccessCredentialsViaServiceAccount(
          accountCredentials,
          _scopes,
          client,
        );
        return _credentials?.accessToken.data;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ Lỗi lấy Access Token từ Service Account: $e');
      return null;
    }
  }

  /// Tìm Firebase Auth UID dựa vào Email
  Future<String?> getUidByEmail(String email) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/projects/${FirebaseAdminConfig.projectId}/accounts:lookup',
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': [email],
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final users = data['users'] as List?;
        if (users != null && users.isNotEmpty) {
          return users[0]['localId']?.toString();
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi tra cứu UID bằng email trên Firebase Auth: $e');
    }
    return null;
  }

  /// Vô hiệu hóa tài khoản và thu hồi toàn bộ phiên đăng nhập (Đá văng ngay lập tức)
  Future<bool> disableAndRevokeUser({required String uid, String? email}) async {
    final token = await _getAccessToken();
    if (token == null) return false;

    // Nếu UID truyền vào không phải là Auth UID gốc (ví dụ UID ngẫu nhiên từ Firestore), thử tra bằng email
    String targetUid = uid;
    if (email != null && email.isNotEmpty) {
      final lookupUid = await getUidByEmail(email);
      if (lookupUid != null && lookupUid.isNotEmpty) {
        targetUid = lookupUid;
      }
    }

    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/projects/${FirebaseAdminConfig.projectId}/accounts:update',
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'localId': targetUid,
          'disableUser': true,
          // Gắn validSince = thời điểm hiện tại để thu hồi toàn bộ Refresh Token của các thiết bị đang đăng nhập
          'validSince': (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString(),
        }),
      );

      if (res.statusCode == 200) {
        debugPrint('✅ Đã khóa tài khoản gốc và thu hồi token thành công cho Auth UID: $targetUid');
        return true;
      } else {
        debugPrint('⚠️ Firebase Auth trả về mã lỗi ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi gọi disableUser trên Firebase Auth: $e');
    }
    return false;
  }

  /// Kích hoạt lại tài khoản trên Firebase Auth (Mở khóa)
  Future<bool> enableUser({required String uid, String? email}) async {
    final token = await _getAccessToken();
    if (token == null) return false;

    String targetUid = uid;
    if (email != null && email.isNotEmpty) {
      final lookupUid = await getUidByEmail(email);
      if (lookupUid != null && lookupUid.isNotEmpty) {
        targetUid = lookupUid;
      }
    }

    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/projects/${FirebaseAdminConfig.projectId}/accounts:update',
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'localId': targetUid,
          'disableUser': false,
        }),
      );

      if (res.statusCode == 200) {
        debugPrint('✅ Đã mở khóa tài khoản gốc thành công cho Auth UID: $targetUid');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Lỗi mở khóa tài khoản trên Firebase Auth: $e');
    }
    return false;
  }
}
