import 'dart:convert'; // ✅ Thêm import này để dùng jsonEncode
import 'lichhen_model.dart';

/// Dữ liệu hiển thị trên vé (lấy từ lịch hẹn hoặc từ tham số màn hình).
class TicketData {
  final String bookingCode;
  final String qrData;
  final String queueNumber;
  final String patientName;
  final String hospitalName;
  final String? roomName;
  final String? departmentName;
  final String timeLabel;
  final String dateLabel;
  final String statusLabel;
  final bool confirmed;

  const TicketData({
    required this.bookingCode,
    required this.qrData,
    required this.queueNumber,
    required this.patientName,
    required this.hospitalName,
    required this.roomName,
    required this.departmentName,
    required this.timeLabel,
    required this.dateLabel,
    required this.statusLabel,
    required this.confirmed,
  });

  /// Tạo dữ liệu vé từ một lịch hẹn trong Firestore.
  factory TicketData.fromBooking(LichHenModel b, {String? patientName}) {
    final status = b.trangThaiId.toString();
    final hasHours = b.gioBatDau != null && b.gioKetThuc != null;
    final caName = b.tenCa ?? 'Ca khám';
    final time = hasHours
        ? '$caName (${b.gioBatDau} - ${b.gioKetThuc})'
        : (b.gioDuKien.isNotEmpty ? b.gioDuKien : caName);
    final date = b.ngayDat;

    return TicketData(
      bookingCode: '#${b.id}',
      // ✅ Ưu tiên dùng ma_qr có sẵn trong DB, nếu chưa có thì tự sinh bằng hàm mới
      qrData: b.maQr ?? buildQrPayload(b), 
      queueNumber: b.soThuTu > 0 ? b.soThuTu.toString().padLeft(2, '0') : '--',
      patientName: patientName ?? 'Bệnh nhân',
      hospitalName: b.tenBenhVien ?? 'Bệnh viện ${b.benhVienId}',
      roomName: b.tenPhongKham ?? (b.phongKhamId.isNotEmpty ? b.phongKhamId : null),
      departmentName: b.tenKhoa,
      timeLabel: time,
      dateLabel: date == null ? 'Chưa cập nhật ngày' : formatDateFull(date),
      statusLabel: statusLabelOf(status),
      confirmed: status == '2', // '2' là Đã xác nhận
    );
  }

  /// ✅ HÀM MỚI: Tạo nội dung mã QR dưới dạng JSON chuẩn
  /// Giúp máy quét của bệnh viện đọc được chính xác từng trường dữ liệu
  static String buildQrPayload(LichHenModel b) {
    final d = b.ngayDat;
    final dateStr = d == null
        ? ''
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Đóng gói tất cả thông tin quan trọng của lịch hẹn ĐÃ DUYỆT vào một Map
    final Map<String, dynamic> qrDataMap = {
      'type': 'appointment_checkin',      // Định danh đây là mã check-in lịch hẹn
      'lich_hen_id': b.id,                // ID quan trọng nhất để tra cứu
      'benh_nhan_id': b.benhNhanId,
      'benh_vien_id': b.benhVienId,
      'khoa_id': b.khoaId,
      'phong_kham_id': b.phongKhamId,
      'ca_id': b.caId,
      'ngay_dat': dateStr,
      'trang_thai': b.trangThaiId.toString(), // Quan trọng: '2' báo hiệu đã được duyệt
      'so_thu_tu': b.soThuTu > 0 ? b.soThuTu.toString() : '',
    };

    // Chuyển Map thành chuỗi JSON để đưa vào QR
    return jsonEncode(qrDataMap);
  }

  /// Định dạng ngày đầy đủ: "Thứ 3, 10/09/2026".
  static String formatDateFull(DateTime d) {
    const weekdays = [
      'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật',
    ];
    return '${weekdays[d.weekday - 1]}, '
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Tên trạng thái theo mã trong bảng TrangThai.
  static String statusLabelOf(String id) {
    switch (id) {
      case '2': return 'Đã xác nhận';
      case '4': return 'Đã hủy';
      case '5': return 'Hoàn thành';
      case '6': return 'Vắng mặt';
      default: return 'Chờ duyệt';
    }
  }
}