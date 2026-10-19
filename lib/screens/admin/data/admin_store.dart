import 'package:flutter/material.dart';
import 'mock_data.dart';

// ===================================================
// KHO DỮ LIỆU DÙNG CHUNG — mọi thao tác duyệt / từ chối /
// xóa / sửa / xử lý lỗi đều đổi dữ liệu thật tại đây
// ===================================================
class ErrorReport {
  final String id;
  final String kind; // 'qr' hoặc 'booking'
  final String badge;
  final String title;
  final String sender;
  final String time;
  final String? desc;
  const ErrorReport({
    required this.id,
    required this.kind,
    required this.badge,
    required this.title,
    required this.sender,
    required this.time,
    this.desc,
  });
}

class AdminStore extends ChangeNotifier {
  AdminStore._();
  static final AdminStore instance = AdminStore._();

  List<Hospital> hospitals = List.of(verifiedHospitals);
  List<Map<String, String>> pending =
      pendingHospitals.map((e) => Map<String, String>.of(e)).toList();
  List<Map<String, String>> violations = [
    {
      'name': 'Phòng khám Đa Khoa An Khang',
      'match': 'PK Đa khoa An Khang',
      'complaints': '3 Khiếu nại',
      'location': '📍 Cầu Giấy, Hà Nội · Mã: PK-4912',
      'reason':
          'Lý do: Giấy phép hoạt động hết hạn, chưa hoàn tất kiểm định BYT.',
    },
  ];
  List<ErrorReport> reports = [
    ErrorReport(
      id: 'qr1',
      kind: 'qr',
      badge: 'Lỗi Check-in QR',
      title: 'Quét QR không auto điền form tiếp nhận',
      sender: 'Người gửi: BV Tâm Anh (Quầy lễ tân)',
      time: '10 phút trước',
      desc:
          'Mô tả: Camera quét mở của bệnh nhận Nguyễn Văn A báo mã hợp lệ nhưng không tự load thông tin khám.',
    ),
    ErrorReport(
      id: 'bk1',
      kind: 'booking',
      badge: 'Lỗi Đặt Lịch',
      title: 'Trùng ca khám buổi sáng',
      sender: 'Người gửi: Bệnh nhân Trần Mai Lan',
      time: '1 giờ trước',
    ),
  ];

  int get totalBV => hospitals.length;
  int pendingTotal = 5;
  int errorTotal = 12;

  String get totalBVText => totalBV.toString().padLeft(2, '0');
  String get pendingText => pendingTotal.toString().padLeft(2, '0');
  String get errorText => reports.length.toString().padLeft(2, '0');

  static const List<List<Color>> _avatarPalette = [
    [Color(0xFFDBEAFE), Color(0xFF2563EB)],
    [Color(0xFFFFEDD5), Color(0xFFD97706)],
    [Color(0xFFDCFCE7), Color(0xFF16A34A)],
    [Color(0xFFF3E8FF), Color(0xFF9333EA)],
  ];

  // DUYỆT: chuyển từ chờ duyệt sang đã xác nhận
  void approveHospital(Map<String, String> h) {
    pending.removeWhere((e) => e['code'] == h['code']);
    pendingTotal = (pendingTotal - 1).clamp(0, 999);
    if (pending.isEmpty) pendingTotal = 0;
    final palette = _avatarPalette[hospitals.length % _avatarPalette.length];
    final bsRaw = h['bs'] ?? '0';
    final doctors = int.tryParse(bsRaw.split(' ').first) ?? 0;
    hospitals.add(Hospital(
      initials: h['tag'] ?? 'BV',
      name: h['name'] ?? 'Bệnh viện',
      type: h['type'] ?? 'Tư nhân',
      rating: 5.0,
      doctors: doctors,
      avatarBg: palette[0],
      avatarText: palette[1],
      address: 'Đang cập nhật địa chỉ',
      code: h['code'],
    ));
    violations.removeWhere((v) => v['match'] == h['name']);
    notifyListeners();
  }

  // TỪ CHỐI: xóa khỏi danh sách chờ
  void rejectHospital(Map<String, String> h) {
    pending.removeWhere((e) => e['code'] == h['code']);
    pendingTotal = (pendingTotal - 1).clamp(0, 999);
    if (pending.isEmpty) pendingTotal = 0;
    violations.removeWhere((v) => v['match'] == h['name']);
    notifyListeners();
  }

  // XÓA cơ sở vi phạm
  void deleteViolation(Map<String, String> v) {
    violations.remove(v);
    final matched =
        pending.where((e) => e['name'] == v['match']).toList();
    for (final m in matched) {
      pending.remove(m);
      pendingTotal = (pendingTotal - 1).clamp(0, 999);
    }
    if (pending.isEmpty) pendingTotal = 0;
    notifyListeners();
  }

  // XÓA HỢP TÁC với bệnh viện đã xác nhận
  void unpartnerHospital(Hospital h) {
    hospitals.remove(h);
    notifyListeners();
  }

  // SỬA thông tin bệnh viện
  void updateHospital(Hospital h,
      {String? name, String? type, String? address, int? doctors}) {
    if (name != null && name.isNotEmpty) h.name = name;
    if (type != null && type.isNotEmpty) h.type = type;
    if (address != null && address.isNotEmpty) h.address = address;
    if (doctors != null) h.doctors = doctors;
    notifyListeners();
  }

  // XỬ LÝ xong một báo cáo lỗi
  void resolveReport(String id) {
    reports.removeWhere((r) => r.id == id);
    errorTotal = (errorTotal - 1).clamp(0, 999);
    if (reports.isEmpty) errorTotal = 0;
    notifyListeners();
  }

  // Lọc báo cáo theo chip: 0 = tất cả, 1 = đặt lịch, 2 = QR
  List<ErrorReport> filteredReports(int filter) {
    if (filter == 1) {
      return reports.where((r) => r.kind == 'booking').toList();
    }
    if (filter == 2) return reports.where((r) => r.kind == 'qr').toList();
    return List.of(reports);
  }
}
