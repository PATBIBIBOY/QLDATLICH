import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gửi và ghi log email thông báo từ chối / hủy hợp tác đến email người đăng ký
  static Future<bool> guiEmailTuChoiHopTac({
    required String emailNguoiNhan,
    required String tenBenhVien,
    required String maBenhVien,
    String? lyDo,
  }) async {
    final cleanEmail = emailNguoiNhan.trim();
    if (cleanEmail.isEmpty) {
      debugPrint('⚠️ [EmailService] Không có email người nhận để gửi thông báo.');
      return false;
    }

    try {
      final String tieuDe =
          '[MediConnect] Thông báo về yêu cầu hợp tác - $tenBenhVien';
      final String lyDoChiTiet = (lyDo != null && lyDo.trim().isNotEmpty)
          ? lyDo.trim()
          : 'Hồ sơ pháp lý chưa đầy đủ hoặc không phù hợp với quy chế hợp tác hiện hành của hệ thống.';

      final String noiDungText = '''
Kính gửi đại diện $tenBenhVien,

Ban Quản Trị hệ thống MediConnect xin trân trọng thông báo:
Yêu cầu hợp tác của quý Bệnh viện (Mã: $maBenhVien) đã bị TỪ CHỐI / HỦY HỢP TÁC trên hệ thống.

- Lý do: $lyDoChiTiet
- Trạng thái hệ thống: 9 (Hủy Hợp Tác)
- Thời gian xử lý: ${DateTime.now().toString()}

Quý Bệnh viện vui lòng mở ứng dụng MediConnect để kiểm tra lại thông tin, hoàn thiện hồ sơ và thực hiện gửi lại yêu cầu hợp tác mới từ đầu.

Trân trọng,
Ban Quản Trị Hệ Thống MediConnect
''';

      final String noiDungHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333333; background-color: #f4f6f8; margin: 0; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #EF4444, #DC2626); padding: 28px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 700; }
    .content { padding: 30px 24px; }
    .status-badge { display: inline-block; background-color: #FEE2E2; color: #DC2626; padding: 6px 14px; border-radius: 20px; font-weight: 700; font-size: 14px; margin-bottom: 20px; }
    .info-box { background-color: #F8FAFC; border-left: 4px solid #EF4444; padding: 16px; border-radius: 6px; margin: 20px 0; }
    .footer { background-color: #F8FAFC; padding: 20px 24px; text-align: center; font-size: 13px; color: #64748B; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HỆ THỐNG Y TẾ MEDICONNECT</h1>
      <p style="margin: 6px 0 0 0; opacity: 0.9; font-size: 14px;">Thông báo về yêu cầu hợp tác</p>
    </div>
    <div class="content">
      <div class="status-badge">Trạng thái: Hủy / Từ Chối Hợp Tác (Mã 9)</div>
      <p>Kính gửi Quý đại diện <strong>$tenBenhVien</strong>,</p>
      <p>Ban Quản Trị MediConnect xin thông báo yêu cầu đăng ký hợp tác của cơ sở y tế đã được xử lý với kết quả <strong>KHÔNG ĐƯỢC CHẤP THUẬN HOẶC ĐÃ HỦY HỢP TÁC</strong>.</p>
      
      <div class="info-box">
        <p style="margin: 0 0 8px 0;"><strong>Mã Bệnh Viện:</strong> $maBenhVien</p>
        <p style="margin: 0 0 8px 0;"><strong>Tên Cơ Sở:</strong> $tenBenhVien</p>
        <p style="margin: 0;"><strong>Lý do:</strong> $lyDoChiTiet</p>
      </div>

      <p>Quý cơ sở y tế có thể mở ứng dụng MediConnect để bổ sung, điều chỉnh thông tin và <strong>gửi lại đơn yêu cầu hợp tác mới từ đầu</strong>.</p>
      
      <p>Trân trọng cảm ơn sự quan tâm của Quý viện đối với hệ thống của chúng tôi.</p>
    </div>
    <div class="footer">
      <p style="margin: 0;">Email tự động gửi từ Hệ thống MediConnect • Vui lòng không trả lời trực tiếp email này nếu không cần thiết.</p>
    </div>
  </div>
</body>
</html>
''';

      // 1. Ghi vào collection EmailLog trên Firebase (đúng cấu trúc collection EmailLog của hệ thống)
      final emailLogDoc = _firestore.collection('EmailLog').doc();
      await emailLogDoc.set({
        'id': emailLogDoc.id,
        'to': [cleanEmail],
        'email': cleanEmail,
        'email_nguoi_nhan': cleanEmail,
        'message': {
          'subject': tieuDe,
          'text': noiDungText,
          'html': noiDungHtml,
        },
        'tieu_de': tieuDe,
        'noi_dung': noiDungText,
        'html': noiDungHtml,
        'ten_benh_vien': tenBenhVien,
        'ma_benh_vien': maBenhVien,
        'benh_vien_id': maBenhVien,
        'ly_do': lyDoChiTiet,
        'trang_thai_id': TrangThaiId.huyHopTac, // 9: Hủy hợp tác
        'loai': 'tu_choi_hop_tac',
        'trang_thai': 'sent',
        'thoi_gian_gui': FieldValue.serverTimestamp(),
        'ngay_tao_str': DateTime.now().toIso8601String(),
      });

      // 2. Ghi thêm vào collection ThongBao
      try {
        await _firestore.collection('ThongBao').add({
          'benh_vien_id': maBenhVien,
          'ma_benh_vien': maBenhVien,
          'tieu_de': 'Yêu cầu hợp tác bị từ chối / hủy',
          'noi_dung':
              'Hồ sơ hợp tác của $tenBenhVien đã bị từ chối/hủy. Vui lòng kiểm tra email $cleanEmail và gửi lại hồ sơ.',
          'loai': 'hop_tac',
          'trang_thai_id': TrangThaiId.huyHopTac,
          'da_doc': false,
          'thoi_gian': FieldValue.serverTimestamp(),
          'ngay_tao_str': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      debugPrint(
        '✅ [EmailService] Đã ghi nhận EmailLog gửi thông báo hủy/từ chối tới: $cleanEmail',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [EmailService] Lỗi khi gửi email thông báo: $e');
      return false;
    }
  }

  /// Thực hiện từ chối / hủy hợp tác:
  /// - Chuyển trang_thai_hop_tac_id sang 9 ở cả BenhVien và YeuCauHopTac
  /// - Đặt da_gui_don = false (để màn hình chính quay về phần gửi lại từ đầu)
  /// - Gửi email thông báo và lưu EmailLog
  static Future<void> tuChoiHoacHuyHopTac({
    required String benhVienId,
    required String tenBenhVien,
    required String email,
    String? lyDo,
  }) async {
    final updateData = <String, dynamic>{
      'trang_thai_hop_tac_id': TrangThaiId.huyHopTac, // 9
      'da_gui_don': false, // Màn hình chính sẽ hiển thị gửi hợp tác lại từ đầu
      'da_bi_tu_choi': true,
      'ly_do_tu_choi': lyDo ?? 'Hồ sơ chưa đạt yêu cầu / Hủy hợp tác',
      'thoi_gian_tu_choi': FieldValue.serverTimestamp(),
      'da_gui_mail_tu_choi': true,
    };

    // 1. Cập nhật collection BenhVien
    await _firestore
        .collection('BenhVien')
        .doc(benhVienId)
        .set(updateData, SetOptions(merge: true));

    // 2. Cập nhật collection YeuCauHopTac
    try {
      await _firestore
          .collection('YeuCauHopTac')
          .doc(benhVienId)
          .set(updateData, SetOptions(merge: true));
    } catch (_) {}

    // 3. Gửi email thông báo
    await guiEmailTuChoiHopTac(
      emailNguoiNhan: email,
      tenBenhVien: tenBenhVien,
      maBenhVien: benhVienId,
      lyDo: lyDo,
    );
  }
}
