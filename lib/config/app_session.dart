/// Lưu ID bệnh viện đang quản lý (document trong collection `benhVien`).
/// Sau này khi làm đăng nhập, thay bằng ID lấy theo tài khoản.

class AppSession {
  static const String benhVienId = 'dFmZHBjFNUT1eRzJjXp5';

  /// (Tùy chọn) Đường dẫn đầy đủ tới document bệnh viện, ví dụ:
  /// 'BenhVien/xxx/co_so/yyy/bhyt/zzz/danh_sach/dFmZHBjFNUT1eRzJjXp5'
  /// Điền vào sẽ đọc tên nhanh hơn; để null thì app tự tìm theo ID.
  static const String? benhVienPath = null;
}
