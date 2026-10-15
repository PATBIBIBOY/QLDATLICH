// ============================================
// ENUM VAI TRÒ (ROLE)
// ============================================
enum Role {
  patient,
  receptionist,
  doctorAssistant,
  customerSupport,
  hospital,
  admin,
}

// ============================================
// ENUM TRẠNG THÁI (STATUS)
// ============================================
enum TrangThai {
  choDuyet, // Chờ duyệt (ID: 1)
  daXacNhan, // Đã xác nhận (ID: 2)
  chuaXacNhan, // Chưa xác nhận (ID: 3)
  huy, // Hủy (ID: 4)
  hoanThanh, // Hoàn thành (ID: 5)
  vangMat, // Vắng mặt (ID: 6)
  hoatDong, // Hoạt động (ID: 7)
  khongHoatDong, // Không hoạt động (ID: 8)
}

class TrangThaiId {
  static const int choDuyet = 1;
  static const int daXacNhan = 2;
  static const int chuaXacNhan = 3;
  static const int huy = 4;
  static const int hoanThanh = 5;
  static const int vangMat = 6;
  static const int hoatDong = 7;
  static const int khongHoatDong = 8;
}

// ============================================
// HELPER CLASS CHO TRẠNG THÁI
// ============================================
class TrangThaiHelper {
  // Map từ ID sang tên trạng thái
  static const Map<int, String> tenTrangThai = {
    TrangThaiId.choDuyet: 'Chờ duyệt',
    TrangThaiId.daXacNhan: 'Đã xác nhận',
    TrangThaiId.chuaXacNhan: 'Chưa xác nhận',
    TrangThaiId.huy: 'Hủy',
    TrangThaiId.hoanThanh: 'Hoàn thành',
    TrangThaiId.vangMat: 'Vắng mặt',
    TrangThaiId.hoatDong: 'Hoạt động',
    TrangThaiId.khongHoatDong: 'Không hoạt động',
  };

  // Map từ ID sang mã màu (ARGB)
  static const Map<int, int> mauTrangThai = {
    TrangThaiId.choDuyet: 0xFFFFA726, // Cam - Chờ duyệt
    TrangThaiId.daXacNhan: 0xFF66BB6A, // Xanh lá - Đã xác nhận
    TrangThaiId.chuaXacNhan: 0xFFEF5350, // Đỏ - Chưa xác nhận
    TrangThaiId.huy: 0xFFBDBDBD, // Xám - Hủy
    TrangThaiId.hoanThanh: 0xFF42A5F5, // Xanh dương - Hoàn thành
    TrangThaiId.vangMat: 0xFFAB47BC, // Tím - Vắng mặt
    TrangThaiId.hoatDong: 0xFF66BB6A, // Xanh lá - Hoạt động
    TrangThaiId.khongHoatDong: 0xFFEF5350, // Đỏ - Không hoạt động
  };

  // Map từ ID sang tên icon (Material Icons)
  static const Map<int, String> iconTrangThai = {
    TrangThaiId.choDuyet: 'hourglass_empty',
    TrangThaiId.daXacNhan: 'check_circle',
    TrangThaiId.chuaXacNhan: 'pending',
    TrangThaiId.huy: 'cancel',
    TrangThaiId.hoanThanh: 'done_all',
    TrangThaiId.vangMat: 'person_off',
    TrangThaiId.hoatDong: 'check_circle',
    TrangThaiId.khongHoatDong: 'block',
  };

  // Lấy tên trạng thái từ ID
  static String getTenTrangThai(int id) {
    return tenTrangThai[id] ?? 'Không xác định';
  }

  // Lấy màu trạng thái từ ID
  static int getMauTrangThai(int id) {
    return mauTrangThai[id] ?? 0xFF9E9E9E;
  }

  // Lấy tên icon từ ID
  static String getIconTrangThai(int id) {
    return iconTrangThai[id] ?? 'help_outline';
  }

  // Chuyển từ enum sang ID
  static int trangThaiToId(TrangThai trangThai) {
    switch (trangThai) {
      case TrangThai.choDuyet:
        return 1;
      case TrangThai.daXacNhan:
        return 2;
      case TrangThai.chuaXacNhan:
        return 3;
      case TrangThai.huy:
        return 4;
      case TrangThai.hoanThanh:
        return 5;
      case TrangThai.vangMat:
        return TrangThaiId.vangMat;
      case TrangThai.hoatDong:
        return TrangThaiId.hoatDong;
      case TrangThai.khongHoatDong:
        return TrangThaiId.khongHoatDong;
    }
  }

  // Chuyển từ ID sang enum
  static TrangThai idToTrangThai(int id) {
    switch (id) {
      case TrangThaiId.choDuyet:
        return TrangThai.choDuyet;
      case TrangThaiId.daXacNhan:
        return TrangThai.daXacNhan;
      case TrangThaiId.chuaXacNhan:
        return TrangThai.chuaXacNhan;
      case TrangThaiId.huy:
        return TrangThai.huy;
      case TrangThaiId.hoanThanh:
        return TrangThai.hoanThanh;
      case TrangThaiId.vangMat:
        return TrangThai.vangMat;
      case TrangThaiId.hoatDong:
        return TrangThai.hoatDong;
      case TrangThaiId.khongHoatDong:
        return TrangThai.khongHoatDong;
      default:
        return TrangThai.choDuyet;
    }
  }
}

// ============================================
// APP CONSTANTS
// ============================================
class AppConstants {
  // Collection names
  static const String patientsCollection = 'BenhNhan';
  static const String hospitalsCollection = 'BenhVien';
  static const String appointmentsCollection = 'appointments';
  static const String medicalRecordsCollection = 'medical_records';
  static const String doctorsCollection = 'doctors';
  static const String chatsCollection = 'chats';
  static const String rolesCollection = 'VaiTro';
  static const String statusCollection = 'TrangThai';

  // Role names mapping
  static const Map<Role, String> roleNames = {
    Role.patient: 'Bệnh nhân',
    Role.receptionist: 'Lễ tân',
    Role.doctorAssistant: 'Hỗ trợ bác sĩ',
    Role.customerSupport: 'CSKH',
    Role.hospital: 'Bệnh viện',
    Role.admin: 'Quản trị viên',
  };

  // Role codes (dùng để lưu vào Firestore)
  static const Map<Role, String> roleCodes = {
    Role.patient: 'benh_nhan',
    Role.receptionist: 'le_tan',
    Role.doctorAssistant: 'ho_tro_bac_si',
    Role.customerSupport: 'cham_soc_khach_hang',
    Role.hospital: 'benh_vien',
    Role.admin: 'admin',
  };

  // Helper: Lấy tên role từ enum
  static String getRoleName(Role role) {
    return roleNames[role] ?? 'Không xác định';
  }

  // Helper: Lấy code role từ enum
  static String getRoleCode(Role role) {
    return roleCodes[role] ?? 'unknown';
  }

  // Helper: Lấy enum Role từ code string
  static Role? getRoleFromCode(String code) {
    return roleCodes.entries
        .firstWhere(
          (entry) => entry.value == code,
          orElse: () => const MapEntry(Role.patient, 'benh_nhan'),
        )
        .key;
  }
}
