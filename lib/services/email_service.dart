import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static final EmailService instance = EmailService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EmailService._();

  /// Gửi email thông báo KHÓA TÀI KHOẢN
  Future<void> sendAccountBlockedEmail({
    required String toEmail,
    required String recipientName,
    required String reason,
    bool isHospital = false,
  }) async {
    final entityType = isHospital ? 'Bệnh viện / Cơ sở Y tế' : 'Bệnh nhân';
    final subject = '[MediConnect] Thông báo tạm khóa tài khoản $entityType';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #1D4ED8, #3B82F6); padding: 30px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 800; letter-spacing: 0.5px; }
    .header p { margin: 6px 0 0; font-size: 13px; opacity: 0.9; }
    .body { padding: 28px 24px; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #0F172A; }
    .alert-box { background: #FEE2E2; border-left: 4px solid #DC2626; padding: 14px 18px; border-radius: 8px; margin: 18px 0; }
    .alert-box strong { color: #DC2626; font-size: 14px; }
    .reason-text { margin-top: 6px; font-size: 13.5px; color: #7F1D1D; }
    .footer { background: #F1F5F9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
    .footer a { color: #1D4ED8; text-decoration: none; font-weight: 600; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>CỔNG QUẢN TRỊ Y TẾ MEDICONNECT</h1>
      <p>Thông báo quan trọng về trạng thái tài khoản</p>
    </div>
    <div class="body">
      <div class="greeting">Kính gửi: $recipientName,</div>
      <p>Hệ thống Quản trị Y tế MediConnect xin thông báo tài khoản <strong>$entityType</strong> liên kết với email này đã bị <strong>tạm khóa / chặn đăng nhập</strong> bởi Quản trị viên.</p>
      
      <div class="alert-box">
        <strong>LÝ DO TẠM KHÓA:</strong>
        <div class="reason-text">$reason</div>
      </div>

      <p>Trong thời gian tài khoản bị tạm khóa, bạn sẽ tạm thời không thể đăng nhập hoặc thực hiện các thao tác trên nền tảng.</p>
      <p>Nếu bạn cho rằng đây là một sự nhầm lẫn hoặc cần giải trình để mở lại tài khoản, vui lòng liên hệ ngay với Bộ phận Hỗ trợ Quản trị qua email <strong>hotro@mediconnect.vn</strong> hoặc Hotline <strong>1900 8888</strong>.</p>
    </div>
    <div class="footer">
      <p>Email này được gửi tự động từ Hệ thống Quản trị Y tế MediConnect.</p>
      <p>© 2026 MediConnect Healthcare System. Mọi quyền được bảo lưu.</p>
    </div>
  </div>
</body>
</html>
''';

    await _queueEmail(
      toEmail: toEmail,
      recipientName: recipientName,
      subject: subject,
      htmlContent: htmlContent,
      type: 'ACCOUNT_BLOCKED',
    );
  }

  /// Gửi email thông báo MỞ KHÓA TÀI KHOẢN
  Future<void> sendAccountUnblockedEmail({
    required String toEmail,
    required String recipientName,
    bool isHospital = false,
  }) async {
    final entityType = isHospital ? 'Bệnh viện / Cơ sở Y tế' : 'Bệnh nhân';
    final subject = '[MediConnect] Tài khoản $entityType của bạn đã được kích hoạt lại';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #059669, #10B981); padding: 30px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
    .body { padding: 28px 24px; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #0F172A; }
    .success-box { background: #D1FAE5; border-left: 4px solid #059669; padding: 14px 18px; border-radius: 8px; margin: 18px 0; color: #065F46; }
    .footer { background: #F1F5F9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>MEDICONNECT HEALTHCARE</h1>
      <p>Tài khoản đã sẵn sàng hoạt động</p>
    </div>
    <div class="body">
      <div class="greeting">Kính gửi: $recipientName,</div>
      <div class="success-box">
        <strong>Tài khoản đã mở khóa thành công!</strong>
        <p style="margin: 4px 0 0; font-size: 13.5px;">Quản trị viên đã kiểm tra và kích hoạt lại tài khoản $entityType của bạn.</p>
      </div>
      <p>Hiện tại bạn đã có thể đăng nhập vào ứng dụng và sử dụng đầy đủ các dịch vụ bình thường.</p>
      <p>Cảm ơn bạn đã luôn đồng hành cùng hệ sinh thái Y tế MediConnect.</p>
    </div>
    <div class="footer">
      <p>© 2026 MediConnect Healthcare System. Hotline hỗ trợ: 1900 8888</p>
    </div>
  </div>
</body>
</html>
''';

    await _queueEmail(
      toEmail: toEmail,
      recipientName: recipientName,
      subject: subject,
      htmlContent: htmlContent,
      type: 'ACCOUNT_UNBLOCKED',
    );
  }

  /// Gửi email thông báo XÓA TÀI KHOẢN
  Future<void> sendAccountDeletedEmail({
    required String toEmail,
    required String recipientName,
    bool isHospital = false,
  }) async {
    final entityType = isHospital ? 'Bệnh viện / Cơ sở Y tế' : 'Bệnh nhân';
    final subject = '[MediConnect] Thông báo xóa tài khoản $entityType';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #475569, #0F172A); padding: 30px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
    .body { padding: 28px 24px; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #0F172A; }
    .info-box { background: #F1F5F9; border-left: 4px solid #64748B; padding: 14px 18px; border-radius: 8px; margin: 18px 0; color: #334155; }
    .footer { background: #F1F5F9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HỆ THỐNG Y TẾ MEDICONNECT</h1>
      <p>Thông báo xóa tài khoản</p>
    </div>
    <div class="body">
      <div class="greeting">Kính gửi: $recipientName,</div>
      <div class="info-box">
        Hồ sơ tài khoản $entityType liên kết với email này đã được Quản trị viên xóa khỏi cơ sở dữ liệu hệ thống theo quy định quản lý.
      </div>
      <p>Toàn bộ thông tin phiên làm việc liên kết đã được thu hồi an toàn. Nếu bạn có bất kỳ thắc mắc hoặc khiếu nại, vui lòng liên hệ <strong>hotro@mediconnect.vn</strong>.</p>
    </div>
    <div class="footer">
      <p>© 2026 MediConnect Healthcare System.</p>
    </div>
  </div>
</body>
</html>
''';

    await _queueEmail(
      toEmail: toEmail,
      recipientName: recipientName,
      subject: subject,
      htmlContent: htmlContent,
      type: 'ACCOUNT_DELETED',
    );
  }

  /// Gửi email thông báo HỦY HỢP TÁC BỆNH VIỆN
  Future<void> sendPartnershipCancelledEmail({
    required String toEmail,
    required String hospitalName,
    required String reason,
  }) async {
    final subject = '[MediConnect] Thông báo chấm dứt hợp tác cơ sở y tế';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #DC2626, #EA580C); padding: 30px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 20px; font-weight: 800; }
    .body { padding: 28px 24px; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #0F172A; }
    .alert-box { background: #FEF2F2; border-left: 4px solid #DC2626; padding: 14px 18px; border-radius: 8px; margin: 18px 0; }
    .footer { background: #F1F5F9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HỆ THỐNG Y TẾ MEDICONNECT</h1>
      <p>Thông báo ngừng hợp tác cơ sở y tế</p>
    </div>
    <div class="body">
      <div class="greeting">Kính gửi Ban Giám đốc: $hospitalName,</div>
      <p>Ban Quản trị Nền tảng MediConnect xin trân trọng thông báo quyết định <strong>chấm dứt quan hệ hợp tác</strong> đối với cơ sở y tế.</p>
      
      <div class="alert-box">
        <strong>LÝ DO CHẤM DỨT HỢP TÁC:</strong>
        <div style="margin-top: 6px; color: #991B1B;">$reason</div>
      </div>

      <p>Cơ sở y tế sẽ ngừng xuất hiện trên cổng đặt lịch của bệnh nhân. Trân trọng cảm ơn sự đồng hành của quý cơ sở trong thời gian qua.</p>
    </div>
    <div class="footer">
      <p>© 2026 MediConnect Healthcare System. Email liên hệ pháp chế: phapche@mediconnect.vn</p>
    </div>
  </div>
</body>
</html>
''';

    await _queueEmail(
      toEmail: toEmail,
      recipientName: hospitalName,
      subject: subject,
      htmlContent: htmlContent,
      type: 'PARTNERSHIP_CANCELLED',
    );
  }

  /// Gửi email thông báo KHÔI PHỤC HỢP TÁC BỆNH VIỆN
  Future<void> sendPartnershipRestoredEmail({
    required String toEmail,
    required String hospitalName,
  }) async {
    final subject = '[MediConnect] Thông báo khôi phục quan hệ hợp tác cơ sở y tế';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; color: #1E293B; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; }
    .header { background: linear-gradient(135deg, #059669, #10B981); padding: 30px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 20px; font-weight: 800; }
    .body { padding: 28px 24px; line-height: 1.6; }
    .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #0F172A; }
    .success-box { background: #D1FAE5; border-left: 4px solid #059669; padding: 14px 18px; border-radius: 8px; margin: 18px 0; color: #065F46; }
    .footer { background: #F1F5F9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HỆ THỐNG Y TẾ MEDICONNECT</h1>
      <p>Chúc mừng tái ký kết hợp tác y tế</p>
    </div>
    <div class="body">
      <div class="greeting">Kính gửi Ban Giám đốc: $hospitalName,</div>
      <div class="success-box">
        <strong>HỒ SƠ HỢP TÁC ĐÃ ĐƯỢC KHÔI PHỤC THÀNH CÔNG!</strong>
        <p style="margin: 4px 0 0; font-size: 13.5px;">Quản trị viên đã kiểm tra và chấp thuận khôi phục thỏa thuận hợp tác y tế với cơ sở.</p>
      </div>
      <p>Cơ sở y tế đã được mở khóa đăng nhập và hiển thị trở lại trên cổng đặt lịch khám bệnh nhân của hệ thống MediConnect.</p>
      <p>Chúc quý cơ sở y tế hoạt động hiệu quả và phục vụ người bệnh ngày một tốt hơn.</p>
    </div>
    <div class="footer">
      <p>© 2026 MediConnect Healthcare System. Hotline: 1900 8888</p>
    </div>
  </div>
</body>
</html>
''';

    await _queueEmail(
      toEmail: toEmail,
      recipientName: hospitalName,
      subject: subject,
      htmlContent: htmlContent,
      type: 'PARTNERSHIP_RESTORED',
    );
  }

  /// GHI VÀO FIRESTORE (Chuẩn Firebase Trigger Email Extension & EmailLog)
  Future<void> _queueEmail({
    required String toEmail,
    required String recipientName,
    required String subject,
    required String htmlContent,
    required String type,
  }) async {
    if (toEmail.trim().isEmpty || !toEmail.contains('@')) {
      debugPrint('⚠️ Email không hợp lệ để gửi thông báo: "$toEmail"');
      return;
    }

    try {
      // 1. Ghi vào collection 'mail' (Chuẩn Firebase Trigger Email Extension)
      await _firestore.collection('mail').add({
        'to': [toEmail.trim()],
        'message': {
          'subject': subject,
          'html': htmlContent,
        },
        'status': 'PENDING',
        'ngay_tao': FieldValue.serverTimestamp(),
        'loai': type,
        'nguoi_nhan': recipientName,
      });

      // 2. Ghi lịch sử vào collection 'EmailLog' để quản trị viên dễ dàng theo dõi
      await _firestore.collection('EmailLog').add({
        'to': toEmail.trim(),
        'recipient_name': recipientName,
        'subject': subject,
        'type': type,
        'sent_at': FieldValue.serverTimestamp(),
        'status': 'QUEUED_FOR_DELIVERY',
      });

      debugPrint('📧 Đã tạo lệnh gửi email thông báo tới: $toEmail ($subject)');
    } catch (e) {
      debugPrint('❌ Lỗi khi xếp hàng gửi email trên Firebase: $e');
    }
  }
}
