import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1. QUẢN LÝ BỆNH VIỆN / CƠ SỞ Y TẾ
  // ---------------------------------------------------------------------------

  /// Lấy danh sách tất cả bệnh viện (Realtime Stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getHospitalsStream({String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db.collection('BenhVien');
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('trangThai', isEqualTo: statusFilter);
    }
    return query.orderBy('ngayTao', descending: true).snapshots();
  }

  /// Duyệt bệnh viện mới đăng ký
  Future<void> approveHospital(String hospitalId) async {
    await _db.collection('BenhVien').doc(hospitalId).update({
      'trangThai': 'DA_DUYET', // Hoặc mã ID trạng thái tương ứng
      'ngayDuyet': FieldValue.serverTimestamp(),
    });
  }

  /// Từ chối hoặc Khóa bệnh viện vi phạm
  Future<void> updateHospitalStatus(String hospitalId, String status, {String? reason}) async {
    await _db.collection('BenhVien').doc(hospitalId).update({
      'trangThai': status, // 'TU_CHOI', 'DA_KHOA', 'HOAT_DONG'
      if (reason != null) 'lyDoKhoa': reason,
      'capNhatLaoCuoi': FieldValue.serverTimestamp(),
    });
  }

  /// Thêm bệnh viện mới trực tiếp từ Admin
  Future<DocumentReference> addHospital(Map<String, dynamic> hospitalData) async {
    hospitalData['ngayTao'] = FieldValue.serverTimestamp();
    hospitalData['trangThai'] = 'DA_DUYET';
    return await _db.collection('BenhVien').add(hospitalData);
  }

  // ---------------------------------------------------------------------------
  // 2. QUẢN LÝ TÀI KHOẢN & PHÂN QUYỀN (NhanVien / BenhNhan)
  // ---------------------------------------------------------------------------

  /// Lấy danh sách nhân viên theo bệnh viện hoặc toàn hệ thống
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream({String? roleId}) {
    Query<Map<String, dynamic>> query = _db.collection('NhanVien');
    if (roleId != null && roleId.isNotEmpty) {
      query = query.where('vaiTroId', isEqualTo: roleId);
    }
    return query.snapshots();
  }

  /// Cấp vai trò hoặc cập nhật trạng thái tài khoản
  Future<void> updateUserRoleAndStatus({
    required String userId,
    required String roleId,
    required bool isActive,
  }) async {
    await _db.collection('NhanVien').doc(userId).update({
      'vaiTroId': roleId,
      'trangThaiHoatDong': isActive,
      'capNhatLaoCuoi': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // 3. QUẢN LÝ BÁO CÁO LỖI (BaoCaoLoi)
  // ---------------------------------------------------------------------------

  /// Lấy danh sách báo cáo lỗi từ người dùng (Realtime)
  Stream<QuerySnapshot<Map<String, dynamic>>> getBugReportsStream({String? status}) {
    Query<Map<String, dynamic>> query = _db.collection('BaoCaoLoi');
    if (status != null && status.isNotEmpty) {
      query = query.where('trangThaiXuly', isEqualTo: status);
    }
    return query.orderBy('ngayTao', descending: true).snapshots();
  }

  /// Cập nhật tiến độ xử lý báo cáo lỗi
  Future<void> updateBugReportStatus({
    required String reportId,
    required String status, // 'DANG_XU_LY', 'DA_GIAI_QUYET', 'TU_CHOI'
    String? adminNote,
  }) async {
    await _db.collection('BaoCaoLoi').doc(reportId).update({
      'trangThaiXuly': status,
      if (adminNote != null) 'ghiChuAdmin': adminNote,
      'ngayCapNhat': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // 4. THỐNG KÊ TỔNG QUAN HỆ THỐNG
  // ---------------------------------------------------------------------------

  /// Lấy các chỉ số tổng quan cho Dashboard Admin
  Future<Map<String, int>> getAdminDashboardStats() async {
    final hospitals = await _db.collection('BenhVien').count().get();
    final pendingHospitals = await _db
        .collection('BenhVien')
        .where('trangThai', isEqualTo: 'CHO_DUYET')
        .count()
        .get();
    final patients = await _db.collection('BenhNhan').count().get();
    final openReports = await _db
        .collection('BaoCaoLoi')
        .where('trangThaiXuly', isEqualTo: 'CHO_XU_LY')
        .count()
        .get();

    return {
      'totalHospitals': hospitals.count ?? 0,
      'pendingHospitals': pendingHospitals.count ?? 0,
      'totalPatients': patients.count ?? 0,
      'openReports': openReports.count ?? 0,
    };
  }
}