import 'package:flutter/foundation.dart';

/// Trạng thái phòng hiển thị ở màn hình chọn khoa/phòng (trang chính).
enum RoomRuntimeStatus { open, paused, closed }

/// Ảnh chụp phiên hàng chờ của MỘT phòng, lưu trong bộ nhớ.
///
/// Không dùng cơ sở dữ liệu/Firebase: dữ liệu chỉ sống trong lúc app đang chạy.
class RoomSessionSnapshot {
  /// Phòng đã được mở màn hình hàng chờ lần nào chưa.
  /// Khi chưa mở, trang chính hiển thị đúng dữ liệu phòng ban đầu.
  bool started = false;

  /// Số hiện tại và số kế tiếp đang hiển thị ở màn hình hàng chờ.
  int current = 1;
  int next = 2;

  /// Các số đang đợi (đúng thứ tự sẽ gọi).
  List<int> waiting = <int>[];

  /// Số lớn nhất đã phát ra.
  int lastIssued = 0;

  /// Các số đã bấm "Đợi" (đang chờ chèn lại).
  List<int> deferredNumbers = <int>[];

  /// Các số đã khám xong (dùng cho "Gọi lại").
  List<int> examinedNumbers = <int>[];

  /// Bác sĩ đang tạm dừng khám.
  bool paused = false;

  /// Trạng thái phòng: chỉ "Tạm dừng" khi bác sĩ đã nhấn nút "Tạm dừng khám".
  RoomRuntimeStatus get status =>
      paused ? RoomRuntimeStatus.paused : RoomRuntimeStatus.open;

  /// Số bệnh nhân đang đợi (bằng độ dài hàng chờ).
  int get waitingCount => waiting.length;

  /// Số bệnh nhân đã khám xong.
  int get examinedCount => examinedNumbers.length;

  /// Số hiện tại đang khám (1 nếu phòng chưa mở lần nào).
  int get currentNumber => current;
}

/// Kho trạng thái dùng chung giữa màn hình chọn khoa/phòng và màn hình hàng chờ.
///
/// Nhờ lớp này, khi bác sĩ nhấn "Tạm dừng khám" / "Tiếp tục khám" ở màn hình
/// hàng chờ thì trang chính hiển thị đúng trạng thái mới ngay khi quay lại,
/// kèm số hiện tại – số đang đợi – số đã khám của phòng đó.
class RoomSessionStore extends ChangeNotifier {
  RoomSessionStore._();

  /// Singleton dùng chung cho toàn app (dữ liệu trong bộ nhớ).
  static final RoomSessionStore instance = RoomSessionStore._();

  final Map<String, RoomSessionSnapshot> _sessions =
      <String, RoomSessionSnapshot>{};

  /// Lấy (hoặc tạo) trạng thái của một phòng theo [roomId].
  RoomSessionSnapshot sessionOf(String roomId) =>
      _sessions.putIfAbsent(roomId, RoomSessionSnapshot.new);

  /// Báo cho các màn hình đang lắng nghe vẽ lại.
  void refresh() => notifyListeners();
}
