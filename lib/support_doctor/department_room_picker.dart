import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import 'queue_screen.dart';
import 'room_session_store.dart';

// -----------------------------------------------------------------------------
// Ten route dung NOI BO trong file nay.
//
// Dart KHONG import bac cau: `import 'login_screen.dart'` chi mang vao day
// LoginScreen / RegisterScreen / goToLoginScreen; no KHONG mang theo AppRoutes
// neu class do nam o library khac (vd config/app_routes.dart). Do do khai bao
// thang 3 hang so o day de file tu chua, tranh loi "Undefined name 'AppRoutes'".
//
// Neu du an cua ban dat ten route khac, sua 3 hang so nay cho khop.
// -----------------------------------------------------------------------------
const String _kRouteLogin = '/login';
const String _kRouteRegister = '/register';
const String _kRoutePatientHome = '/patient-home';

/// Dua nguoi dung ve [LoginScreen] va xoa SACH stack dieu huong,
/// de khong the bam Back quay lai man hinh vua dang xuat.
///
/// Dat ngay trong file nay (thay vi goi tu login_screen.dart) de file chi
/// can biet duy nhat widget `LoginScreen` — tranh loi
/// "Undefined name 'goToLoginScreen'" khi ban dung file login_screen rieng.
Future<void> _goToLoginScreen(NavigatorState navigator) async {
  await navigator.pushAndRemoveUntil<void>(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// A reusable screen for choosing a department and then a clinic room.
///
/// This widget is generic so it can use the `RoomInfo` model from an existing
/// app without declaring that model again. See the usage example at the bottom
/// of this file.
class DepartmentRoomPicker<T> extends StatefulWidget {
  const DepartmentRoomPicker({
    super.key,
    required this.rooms,
    required this.departmentOf,
    required this.hospitalIdOf,
    required this.departmentIdOf,
    required this.roomIdOf,
    required this.roomNameOf,
    required this.statusLabelOf,
    required this.isOpen,
    required this.isPaused,
    required this.isClosed,
    required this.currentNumberOf,
    required this.waitingCountOf,
    required this.examinedCountOf,
    required this.onRoomSelected,
    this.initialDepartment,
    this.hospitalName = 'Bệnh viện',
    this.title = 'Chọn phòng khám',
    this.onLogout,
    this.logoutLabel = 'Đăng xuất',
    this.confirmLogout = true,
  });

  /// Room data supplied by the app.
  final List<T> rooms;

  /// Adapters that read the required values from the app's room model.
  final String Function(T room) departmentOf;
  final String Function(T room) hospitalIdOf;
  final String Function(T room) departmentIdOf;
  final String Function(T room) roomIdOf;
  final String Function(T room) roomNameOf;
  final String Function(T room) statusLabelOf;
  final bool Function(T room) isOpen;
  final bool Function(T room) isPaused;
  final bool Function(T room) isClosed;
  final int? Function(T room) currentNumberOf;
  final int Function(T room) waitingCountOf;
  final int Function(T room) examinedCountOf;

  /// Called when the user taps an available room.
  final ValueChanged<T> onRoomSelected;

  /// Khoa mặc định (giữ lại để tương thích với mã gọi cũ). Trang chọn nay
  /// luôn mở ở bước chọn khoa nên giá trị này không còn tự đưa người dùng
  /// vào thẳng danh sách phòng.
  final String? initialDepartment;
  final String hospitalName;
  final String title;

  /// Xử lý đăng xuất (xoá token/phiên đăng nhập, đóng socket…).
  ///
  /// Widget LUÔN tự chuyển về [LoginScreen] sau khi callback này chạy xong,
  /// nên callback chỉ cần dọn dữ liệu — không cần tự gọi Navigator.
  /// Để `null` thì nút đăng xuất vẫn chuyển thẳng về [LoginScreen].
  final Future<void> Function()? onLogout;

  /// Nhãn của nút đăng xuất (ẩn nhãn khi màn hình hẹp).
  final String logoutLabel;

  /// Có hỏi xác nhận trước khi đăng xuất hay không.
  final bool confirmLogout;

  @override
  State<DepartmentRoomPicker<T>> createState() =>
      _DepartmentRoomPickerState<T>();
}

class _DepartmentRoomPickerState<T> extends State<DepartmentRoomPicker<T>> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _departmentSearchController =
      TextEditingController();
  String? _selectedDepartment;
  _RoomFilter _filter = _RoomFilter.all;
  bool _loggingOut = false;

  List<String> get _departments {
    final values = widget.rooms
        .map((room) => widget.departmentOf(room).trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  /// Danh sách khoa sau khi lọc theo ô tìm khoa ở bước chọn khoa
  /// (tìm theo tên khoa và mã khoa).
  List<String> get _visibleDepartments {
    final query = _departmentSearchController.text.trim().toLowerCase();
    final departments = _departments;
    if (query.isEmpty) return departments;
    return departments.where((department) {
      final roomsInDepartment = _roomsOfDepartment(department);
      final departmentId = roomsInDepartment.isEmpty
          ? ''
          : widget.departmentIdOf(roomsInDepartment.first);
      final searchable = ('$department $departmentId').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  /// Các phòng của một khoa (so theo tên khoa đã cắt khoảng trắng).
  List<T> _roomsOfDepartment(String department) => widget.rooms
      .where((room) => widget.departmentOf(room).trim() == department)
      .toList();

  List<T> get _departmentRooms {
    final selected = _selectedDepartment;
    return selected == null
        ? widget.rooms.toList()
        : _roomsOfDepartment(selected);
  }

  /// Đang ở bước 1 (chọn khoa): chưa chọn khoa và dữ liệu có ít nhất một
  /// khoa. Khi dữ liệu không có khoa nào, hiển thị thẳng bước chọn phòng
  /// với toàn bộ phòng như trước đây.
  bool get _choosingDepartment =>
      _selectedDepartment == null && _departments.isNotEmpty;

  void _chooseDepartment(String department) {
    setState(() {
      _selectedDepartment = department;
      _filter = _RoomFilter.all;
      _searchController.clear();
    });
  }

  void _backToDepartments() {
    setState(() {
      _selectedDepartment = null;
      _filter = _RoomFilter.all;
      _searchController.clear();
    });
  }

  List<T> get _visibleRooms {
    final query = _searchController.text.trim().toLowerCase();
    return _departmentRooms.where((room) {
      final matchesStatus = switch (_filter) {
        _RoomFilter.all => true,
        _RoomFilter.open => widget.isOpen(room),
        _RoomFilter.paused => widget.isPaused(room),
        _RoomFilter.closed => widget.isClosed(room),
      };
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      // Chỉ tìm theo phòng (tên phòng và mã phòng), không tìm theo khoa.
      final searchable = ('${widget.roomNameOf(room)} ${widget.roomIdOf(room)}')
          .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  void didUpdateWidget(covariant DepartmentRoomPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khoa đang xem không còn phòng nào -> quay về bước chọn khoa.
    final selected = _selectedDepartment;
    if (selected != null && !_departments.contains(selected)) {
      _selectedDepartment = null;
      _filter = _RoomFilter.all;
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _departmentSearchController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _PickerUi.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        ),
      );
  }

  /// Hỏi xác nhận (nếu bật), dọn phiên rồi chuyển về màn hình đăng nhập.
  Future<void> _handleLogout() async {
    if (_loggingOut) return;

    if (widget.confirmLogout) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x14E94B45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Color(0xFFE94B45),
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Đăng xuất?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _PickerUi.text,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn sẽ thoát khỏi ${widget.hospitalName}. '
            'Các phòng đang khám vẫn tiếp tục chạy trên hệ thống.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _PickerUi.secondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Huỷ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _PickerUi.secondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE94B45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
              ),
              child: Text(
                widget.logoutLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }

    // Lay Navigator TRUOC cac await de khong dung BuildContext qua async gap.
    final navigator = Navigator.of(context);
    setState(() => _loggingOut = true);
    try {
      final onLogout = widget.onLogout;
      if (onLogout != null) {
        // Callback chi don token/phien; viec doi man hinh do widget dam nhiem.
        await onLogout();
      }
      if (mounted) _showMessage('Đã đăng xuất.');
      // LUON ve LoginScreen, xoa sach stack (khong cho bam Back quay lai).
      await _goToLoginScreen(navigator);
    } catch (_) {
      if (mounted) {
        _showMessage('Đăng xuất thất bại. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _visibleRooms;
    final departments = _departments;
    final visibleDepartments = _visibleDepartments;
    // Tablet (chiều rộng màn hình từ 600dp): bỏ trần 620dp để giao diện
    // dàn full màn hình thay vì bó thành một cột hẹp ở giữa.
    final useFullWidth = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_PickerUi.bgTop, _PickerUi.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: useFullWidth ? double.infinity : 620,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final tablet = constraints.maxWidth >= 768;
                  final horizontalPadding = compact
                      ? 16.0
                      : tablet
                      ? 28.0
                      : 22.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      tablet ? 24 : 20,
                      horizontalPadding,
                      tablet ? 36 : 30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: compact
                                          ? 21
                                          : tablet
                                          ? 28
                                          : 24,
                                      fontWeight: FontWeight.w800,
                                      color: _PickerUi.text,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const _PickerPulseDot(),
                                      const SizedBox(width: 7),
                                      Flexible(
                                        child: Text(
                                          _selectedDepartment == null
                                              ? widget.hospitalName
                                              : '${_selectedDepartment!} · ${widget.hospitalName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _PickerUi.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _PickerLogoutButton(
                              compact: compact,
                              label: widget.logoutLabel,
                              busy: _loggingOut,
                              onTap: _loggingOut ? null : _handleLogout,
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        if (_choosingDepartment) ...[
                          const Text(
                            'CHỌN KHOA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                              color: _PickerUi.faint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSearchBox(
                            controller: _departmentSearchController,
                            hintText: 'Tìm khoa…',
                          ),
                          const SizedBox(height: 12),
                          if (visibleDepartments.isEmpty)
                            _buildEmptyState('Không tìm thấy khoa phù hợp.')
                          else
                            for (
                              var index = 0;
                              index < visibleDepartments.length;
                              index++
                            )
                              Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 12,
                                ),
                                child: _buildDepartmentCard(
                                  visibleDepartments[index],
                                  compact,
                                ),
                              ),
                        ] else ...[
                          if (departments.isNotEmpty) ...[
                            _buildBackToDepartmentsButton(),
                            const SizedBox(height: 12),
                          ],
                          _buildSearchBox(
                            controller: _searchController,
                            hintText: 'Tìm phòng…',
                          ),
                          const SizedBox(height: 12),
                          _buildStatusFilters(),
                          const SizedBox(height: 16),
                          if (rooms.isEmpty)
                            _buildEmptyState()
                          else
                            for (var index = 0; index < rooms.length; index++)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 12,
                                ),
                                child: _buildRoomCard(rooms[index], compact),
                              ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ô tìm kiếm dùng chung cho cả hai bước (tìm khoa / tìm phòng).
  Widget _buildSearchBox({
    required TextEditingController controller,
    required String hintText,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PickerUi.border),
      boxShadow: _PickerUi.quietShadow,
    ),
    child: TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _PickerUi.text,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFFB6BCC9),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: _PickerUi.faint,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _PickerUi.faint,
                ),
              ),
        isDense: true,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
  );

  Widget _buildStatusFilters() {
    final filters = <(_RoomFilter, String, int)>[
      (_RoomFilter.all, 'Tất cả', _departmentRooms.length),
      (
        _RoomFilter.open,
        'Đang khám',
        _departmentRooms.where(widget.isOpen).length,
      ),
      (
        _RoomFilter.paused,
        'Tạm dừng',
        _departmentRooms.where(widget.isPaused).length,
      ),
      (
        _RoomFilter.closed,
        'Chưa mở',
        _departmentRooms.where(widget.isClosed).length,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _PickerFilterChip(
              label: filters[index].$2,
              count: filters[index].$3,
              selected: _filter == filters[index].$1,
              onTap: () => setState(() => _filter = filters[index].$1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState([String? message]) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _PickerUi.border),
      boxShadow: _PickerUi.cardShadow,
    ),
    child: Row(
      children: [
        const Icon(Icons.search_off_rounded, color: _PickerUi.faint),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message ??
                (widget.rooms.isEmpty
                    ? 'Chưa có phòng khám.'
                    : 'Không tìm thấy phòng phù hợp.'),
            style: const TextStyle(fontSize: 13, color: _PickerUi.secondary),
          ),
        ),
      ],
    ),
  );

  /// Nút quay lại bước chọn khoa (hiện ở đầu bước chọn phòng).
  Widget _buildBackToDepartmentsButton() => Align(
    alignment: Alignment.centerLeft,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: _backToDepartments,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _PickerUi.border),
            boxShadow: _PickerUi.quietShadow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 17,
                color: _PickerUi.secondary,
              ),
              SizedBox(width: 7),
              Text(
                'Đổi khoa',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _PickerUi.text,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Thẻ khoa ở bước 1: bấm để sang bước chọn phòng của khoa đó. Dáng thẻ
  /// giống thẻ phòng: ô mã khoa, tên khoa, số phòng/đang khám và mũi tên.
  Widget _buildDepartmentCard(String department, bool compact) {
    final roomsInDepartment = _roomsOfDepartment(department);
    final openCount = roomsInDepartment.where(widget.isOpen).length;
    final pausedCount = roomsInDepartment.where(widget.isPaused).length;
    final departmentId = roomsInDepartment.isEmpty
        ? ''
        : widget.departmentIdOf(roomsInDepartment.first).trim();
    final hospitalId = roomsInDepartment.isEmpty
        ? ''
        : widget.hospitalIdOf(roomsInDepartment.first).trim();
    final codeLine = [
      if (hospitalId.isNotEmpty) 'BV $hospitalId',
      if (departmentId.isNotEmpty) 'Khoa $departmentId',
    ].join('  ·  ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PickerUi.border),
        boxShadow: _PickerUi.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _chooseDepartment(department),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Row(
              children: [
                Container(
                  width: compact ? 52 : 58,
                  height: compact ? 52 : 58,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3D9BF0), Color(0xFF0F6CD6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: departmentId.isEmpty
                      ? const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 26,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            departmentId,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              department,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w800,
                                color: _PickerUi.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PickerRoomStatus(
                            label: '${roomsInDepartment.length} phòng',
                            foreground: const Color(0xFF107FE8),
                            background: const Color(0x14107FE8),
                          ),
                        ],
                      ),
                      if (codeLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          codeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _PickerUi.faint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 11,
                        runSpacing: 6,
                        children: [
                          _PickerMeta(
                            icon: Icons.meeting_room_rounded,
                            text: '${roomsInDepartment.length} phòng khám',
                          ),
                          _PickerMeta(
                            icon: Icons.check_circle_rounded,
                            text: '$openCount đang khám',
                          ),
                          if (pausedCount > 0)
                            _PickerMeta(
                              icon: Icons.pause_circle_rounded,
                              text: '$pausedCount tạm dừng',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0x14107FE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF107FE8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(T room, bool compact) {
    final closed = widget.isClosed(room);
    final paused = widget.isPaused(room);
    final open = widget.isOpen(room);
    final statusColor = open
        ? const Color(0xFF1E8E43)
        : paused
        ? const Color(0xFFB47A00)
        : const Color(0xFF8B90A0);
    final statusBackground = open
        ? const Color(0x1F2AC653)
        : paused
        ? const Color(0x24F5A623)
        : const Color(0x14101828);
    final badgeGradient = open
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF41D366), Color(0xFF1FA24C)],
          )
        : paused
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD54A), Color(0xFFFF9000)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9DDE8), Color(0xFFB7BDCC)],
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PickerUi.border),
        boxShadow: _PickerUi.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: closed
              ? () => _showMessage('${widget.roomNameOf(room)} chưa mở.')
              : () => widget.onRoomSelected(room),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Row(
              children: [
                Container(
                  width: compact ? 52 : 58,
                  height: compact ? 52 : 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: badgeGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    widget.roomIdOf(room),
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: paused ? const Color(0xFF3A2A00) : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.roomNameOf(room),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w800,
                                color: _PickerUi.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PickerRoomStatus(
                            label: widget.statusLabelOf(room),
                            foreground: statusColor,
                            background: statusBackground,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BV ${widget.hospitalIdOf(room)}  ·  '
                        'Khoa ${widget.departmentIdOf(room)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _PickerUi.faint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 11,
                        runSpacing: 6,
                        children: [
                          _PickerMeta(
                            icon: Icons.person_rounded,
                            text: widget.currentNumberOf(room) == null
                                ? 'Chưa gọi số'
                                : 'Số ${widget.currentNumberOf(room)}',
                          ),
                          _PickerMeta(
                            icon: Icons.groups_rounded,
                            text: '${widget.waitingCountOf(room)} đang đợi',
                          ),
                          _PickerMeta(
                            icon: Icons.task_alt_rounded,
                            text: '${widget.examinedCountOf(room)} đã khám',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: closed
                        ? const Color(0xFFF2F4F8)
                        : const Color(0x14107FE8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    closed
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                    color: closed ? _PickerUi.faint : const Color(0xFF107FE8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _PickerUi {
  static const Color bgTop = Color(0xFFF9FAFE);
  static const Color bgBottom = Color(0xFFEBEFF8);
  static const Color border = Color(0xFFEEF0F7);
  static const Color text = Color(0xFF191C26);
  static const Color secondary = Color(0xFF8B90A0);
  static const Color faint = Color(0xFFAAB0BE);

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x12101828), blurRadius: 22, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> quietShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F101828), blurRadius: 12, offset: Offset(0, 6)),
  ];
}

enum _RoomFilter { all, open, paused, closed }

class _PickerPulseDot extends StatelessWidget {
  const _PickerPulseDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: Color(0xFF35C95B),
      shape: BoxShape.circle,
    ),
  );
}

/// Nút đăng xuất ở góc phải phần tiêu đề. Ẩn nhãn chữ khi màn hình hẹp,
/// hiện vòng xoay khi đang xử lý đăng xuất.
class _PickerLogoutButton extends StatelessWidget {
  const _PickerLogoutButton({
    required this.compact,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final bool compact;
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: onTap == null ? 0.65 : 1,
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _PickerUi.border),
              boxShadow: _PickerUi.quietShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE94B45),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: Color(0xFFE94B45),
                  ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE94B45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return compact ? Tooltip(message: label, child: button) : button;
  }
}

class _PickerFilterChip extends StatelessWidget {
  const _PickerFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _PickerUi.text : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _PickerUi.text : _PickerUi.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _PickerUi.secondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x33FFFFFF)
                    : const Color(0xFFF1F3F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _PickerUi.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerRoomStatus extends StatelessWidget {
  const _PickerRoomStatus({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
    ),
  );
}

class _PickerMeta extends StatelessWidget {
  const _PickerMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: _PickerUi.faint),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _PickerUi.secondary,
        ),
      ),
    ],
  );
}

/// Trạng thái phòng khám dùng cho màn hình chọn khoa/phòng.
enum ClinicRoomStatus { open, paused, closed }

extension ClinicRoomStatusLabel on ClinicRoomStatus {
  String get label => switch (this) {
    ClinicRoomStatus.open => 'Đang khám',
    ClinicRoomStatus.paused => 'Tạm dừng',
    ClinicRoomStatus.closed => 'Chưa mở',
  };
}

/// Thông tin một phòng trong màn hình chọn khoa/phòng.
class ClinicRoomData {
  const ClinicRoomData({
    required this.hospitalId,
    required this.departmentId,
    required this.id,
    required this.name,
    required this.department,
    required this.staffId,
    required this.status,
    this.currentNumber,
    this.waitingCount = 0,
    this.examinedCount = 0,
  });

  /// ID bệnh viện (`id_benhvien`).
  final String hospitalId;

  /// ID khoa (`id_khoa`) của phòng khám.
  final String departmentId;

  /// ID phòng khám (`id_phongkham`).
  final String id;
  final String name;
  final String department;
  final String staffId;
  final ClinicRoomStatus status;
  final int? currentNumber;
  final int waitingCount;
  final int examinedCount;

  /// Bản sao có cập nhật trạng thái/số liệu theo thời gian chạy.
  ClinicRoomData copyWith({
    ClinicRoomStatus? status,
    int? currentNumber,
    int? waitingCount,
    int? examinedCount,
  }) => ClinicRoomData(
    hospitalId: hospitalId,
    departmentId: departmentId,
    id: id,
    name: name,
    department: department,
    staffId: staffId,
    status: status ?? this.status,
    currentNumber: currentNumber ?? this.currentNumber,
    waitingCount: waitingCount ?? this.waitingCount,
    examinedCount: examinedCount ?? this.examinedCount,
  );

  String sessionIdForToday() {
    final now = DateTime.now();
    final date =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return '$hospitalId-$departmentId-$id-$date-01';
  }
}

/// Dữ liệu mẫu trong bộ nhớ, khai báo dạng cây KHOA → PHÒNG ở
/// [demoDepartments]: khoa gồm id + tên khoa, phòng là con của khoa gồm
/// id phòng + tên phòng. Khi nối dữ liệu thật, truyền `rooms:` cho
/// [ClinicRoomPickerScreen]/[ClinicRoomPickerApp], hoặc dùng sẵn đường
/// nối Cloud Firestore ở clinic_firestore_service.dart (hướng dẫn trong
/// FIREBASE_SETUP.md) — cấu trúc cây trên Firestore giống hệt danh sách
/// mẫu này.
///
/// Tất cả phòng đều BẮT ĐẦU Ở SỐ 1: `currentNumber = 1`, chưa có ai đang
/// đợi và chưa khám ai. Khi mở một phòng, màn hình hàng chờ sẽ hiển thị
/// SỐ HIỆN TẠI = 1, SỐ TIẾP THEO = 2, và hàng chờ bắt đầu từ số 3.
///
/// Mọi phòng đều ở trạng thái “Đang khám”. Trạng thái “Tạm dừng” CHỈ xuất
/// hiện sau khi bác sĩ nhấn nút “Tạm dừng khám” ở màn hình hàng chờ (xem
/// [RoomSessionStore]) — không gán cứng ở đây.
const int demoStartingNumber = 1;

/// Id bệnh viện của dữ liệu mẫu (mọi khoa/phòng mẫu đều thuộc bệnh viện
/// này).
const String demoHospitalId = '10';

/// Một khoa trong dữ liệu mẫu: mã khoa ([id]), tên khoa ([name]) và danh
/// sách phòng trực thuộc ([rooms]). Muốn thêm khoa mới, cứ thêm một phần
/// tử vào [demoDepartments].
class DemoDepartment {
  const DemoDepartment({
    required this.id,
    required this.name,
    this.rooms = const <DemoRoom>[],
  });

  /// Mã khoa (ví dụ 'K001').
  final String id;

  /// Tên khoa (ví dụ 'Khoa Tim').
  final String name;

  /// Các phòng khám là "con" của khoa này.
  final List<DemoRoom> rooms;
}

/// Một phòng khám trong dữ liệu mẫu, là "con" của [DemoDepartment].
///
/// Chỉ bắt buộc mã phòng ([id]) và tên phòng ([name]). Các thông tin còn
/// lại đều không bắt buộc và có sẵn giá trị mặc định: chưa gán nhân viên,
/// trạng thái “Đang khám”, bắt đầu ở [demoStartingNumber].
class DemoRoom {
  const DemoRoom({
    required this.id,
    required this.name,
    this.staffId = '',
    this.status = ClinicRoomStatus.open,
    this.currentNumber = demoStartingNumber,
  });

  /// Mã phòng (ví dụ 'PK1').
  final String id;

  /// Tên phòng (ví dụ 'Phòng khám 1').
  final String name;

  /// Mã nhân viên phụ trách (không bắt buộc).
  final String staffId;

  /// Trạng thái mẫu của phòng (mặc định đang khám).
  final ClinicRoomStatus status;

  /// Số đang khám mẫu (mặc định bắt đầu ở số [demoStartingNumber]).
  final int? currentNumber;
}

/// Dữ liệu mẫu dạng cây KHOA → PHÒNG: mỗi khoa gồm id + tên khoa, bên
/// trong là các phòng con gồm id phòng + tên phòng. Thêm khoa/phòng bằng
/// cách sửa trực tiếp danh sách này; màn hình chọn khoa/phòng dùng
/// [demoClinicRooms] (được trải phẳng từ đây) nên sẽ tự cập nhật.
const List<DemoDepartment> demoDepartments = <DemoDepartment>[
  DemoDepartment(
    id: 'K001',
    name: 'Khoa Tim',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK1', name: 'Phòng khám 1', staffId: 'NV-LAN'),
      DemoRoom(id: 'PK4', name: 'Phòng khám 4', staffId: 'NV-MAI'),
    ],
  ),
  DemoDepartment(
    id: 'K002',
    name: 'Khoa Hô hấp',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK2', name: 'Phòng khám 2', staffId: 'NV-HUNG'),
      DemoRoom(id: 'PK6', name: 'Phòng khám 6', staffId: 'NV-HUY'),
    ],
  ),
  DemoDepartment(
    id: 'K003',
    name: 'Khoa Nhi',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK3', name: 'Phòng khám 3', staffId: 'NV-VNT'),
      DemoRoom(id: 'PK5', name: 'Phòng khám 5', staffId: 'NV-DUNG'),
    ],
  ),
  DemoDepartment(
    id: 'K004',
    name: 'Khoa Nội',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK7', name: 'Phòng khám 7', staffId: 'NV-BINH'),
      DemoRoom(id: 'PK8', name: 'Phòng khám 8', staffId: 'NV-HA'),
    ],
  ),
  DemoDepartment(
    id: 'K005',
    name: 'Khoa Ngoại',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK9', name: 'Phòng khám 9', staffId: 'NV-MTUAN'),
      DemoRoom(id: 'PK10', name: 'Phòng khám 10', staffId: 'NV-LINH'),
    ],
  ),
  DemoDepartment(
    id: 'K006',
    name: 'Khoa Sản',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK11', name: 'Phòng khám 11', staffId: 'NV-TRAM'),
      DemoRoom(id: 'PK12', name: 'Phòng khám 12', staffId: 'NV-VAN'),
      DemoRoom(id: 'PK13', name: 'Phòng khám 13', staffId: 'NV-PHUONG'),
    ],
  ),
  DemoDepartment(
    id: 'K007',
    name: 'Khoa Mắt',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK14', name: 'Phòng khám 14', staffId: 'NV-THANG'),
      DemoRoom(id: 'PK15', name: 'Phòng khám 15', staffId: 'NV-GIANG'),
    ],
  ),
  DemoDepartment(
    id: 'K008',
    name: 'Khoa Tai Mũi Họng',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK16', name: 'Phòng khám 16', staffId: 'NV-DUC'),
      DemoRoom(id: 'PK17', name: 'Phòng khám 17', staffId: 'NV-LY'),
    ],
  ),
  DemoDepartment(
    id: 'K009',
    name: 'Khoa Răng Hàm Mặt',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK18', name: 'Phòng khám 18', staffId: 'NV-TANH'),
      DemoRoom(id: 'PK19', name: 'Phòng khám 19', staffId: 'NV-NGOC'),
    ],
  ),
  DemoDepartment(
    id: 'K010',
    name: 'Khoa Thần Kinh',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK20', name: 'Phòng khám 20', staffId: 'NV-CONG'),
      DemoRoom(id: 'PK21', name: 'Phòng khám 21', staffId: 'NV-CHAU'),
    ],
  ),
  DemoDepartment(
    id: 'K011',
    name: 'Khoa Tiêu Hoá',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK22', name: 'Phòng khám 22', staffId: 'NV-NGHIA'),
      DemoRoom(id: 'PK23', name: 'Phòng khám 23', staffId: 'NV-LTA'),
    ],
  ),
  DemoDepartment(
    id: 'K012',
    name: 'Khoa Da Liễu',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK24', name: 'Phòng khám 24', staffId: 'NV-THAO'),
    ],
  ),
  DemoDepartment(
    id: 'K013',
    name: 'Khoa Chấn Thương Chỉnh Hình',
    rooms: <DemoRoom>[
      DemoRoom(id: 'PK25', name: 'Phòng khám 25', staffId: 'NV-TUNG'),
      DemoRoom(id: 'PK26', name: 'Phòng khám 26', staffId: 'NV-NAM'),
    ],
  ),
];

/// Toàn bộ phòng mẫu ở dạng danh sách phẳng mà màn hình chọn khoa/phòng
/// sử dụng: gộp các phòng con của mọi khoa trong [demoDepartments], gắn
/// thêm mã/tên khoa của khoa chứa nó và bệnh viện [demoHospitalId].
final List<ClinicRoomData> demoClinicRooms = <ClinicRoomData>[
  for (final department in demoDepartments)
    for (final room in department.rooms)
      ClinicRoomData(
        hospitalId: demoHospitalId,
        departmentId: department.id,
        id: room.id,
        name: room.name,
        department: department.name,
        staffId: room.staffId,
        status: room.status,
        currentNumber: room.currentNumber,
        waitingCount: 0,
        examinedCount: 0,
      ),
];

/// Màn hình chọn khoa/phòng đã kết nối với QueueScreen trong queue_screen.dart.
/// Dữ liệu phòng lấy trực tiếp từ danh sách [rooms] (mặc định là dữ liệu mẫu
/// trong bộ nhớ). Muốn lấy từ Cloud Firestore theo thời gian thực, dùng
/// FirestoreClinicRoomPickerScreen trong clinic_firestore_service.dart.
class ClinicRoomPickerScreen extends StatelessWidget {
  const ClinicRoomPickerScreen({
    super.key,
    this.rooms,
    this.initialDepartment = 'Khoa Tim',
    this.hospitalName = 'Bệnh viện Bạch Mai',
    this.onLogout,
  });

  final List<ClinicRoomData>? rooms;
  final String initialDepartment;
  final String hospitalName;

  /// Xử lý đăng xuất thật của app (chỉ cần dọn dữ liệu). Ví dụ:
  ///
  /// ```dart
  /// ClinicRoomPickerScreen(
  ///   onLogout: () async {
  ///     await AuthStore.instance.logout();      // xoá token/phiên đăng nhập
  ///     RoomSessionStore.instance.resetAll();   // (tuỳ chọn) dọn phiên phòng
  ///   },
  /// )
  /// ```
  ///
  /// Sau khi callback chạy xong, widget tự chuyển về [LoginScreen] và xoá
  /// toàn bộ stack điều hướng — không cần gọi Navigator trong callback.
  /// Để `null` thì nút đăng xuất vẫn chuyển về [LoginScreen].
  final Future<void> Function()? onLogout;

  /// Danh sách phòng kèm trạng thái/số liệu thật lấy từ [RoomSessionStore]
  /// (phòng chưa mở lần nào thì giữ nguyên dữ liệu ban đầu).
  List<ClinicRoomData> _liveRooms() => <ClinicRoomData>[
    for (final room in rooms ?? demoClinicRooms)
      if (RoomSessionStore.instance.sessionOf(room.id) case final snapshot
          when snapshot.started)
        room.copyWith(
          status: switch (snapshot.status) {
            RoomRuntimeStatus.open => ClinicRoomStatus.open,
            RoomRuntimeStatus.paused => ClinicRoomStatus.paused,
            RoomRuntimeStatus.closed => ClinicRoomStatus.closed,
          },
          currentNumber: snapshot.currentNumber,
          waitingCount: snapshot.waitingCount,
          examinedCount: snapshot.examinedCount,
        )
      else
        room,
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: RoomSessionStore.instance,
    builder: (context, _) => _buildPicker(context, _liveRooms()),
  );

  Widget _buildPicker(BuildContext context, List<ClinicRoomData> liveRooms) =>
      DepartmentRoomPicker<ClinicRoomData>(
        rooms: liveRooms,
        initialDepartment: initialDepartment,
        hospitalName: hospitalName,
        onLogout: onLogout,
        departmentOf: (room) => room.department,
        hospitalIdOf: (room) => room.hospitalId,
        departmentIdOf: (room) => room.departmentId,
        roomIdOf: (room) => room.id,
        roomNameOf: (room) => room.name,
        statusLabelOf: (room) => room.status.label,
        isOpen: (room) => room.status == ClinicRoomStatus.open,
        isPaused: (room) => room.status == ClinicRoomStatus.paused,
        isClosed: (room) => room.status == ClinicRoomStatus.closed,
        currentNumberOf: (room) => room.currentNumber,
        waitingCountOf: (room) => room.waitingCount,
        examinedCountOf: (room) => room.examinedCount,
        onRoomSelected: (room) {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => QueueScreen(
                sessionId: room.sessionIdForToday(),
                roomId: room.id,
                staffId: room.staffId,
                roomName: room.name,
                departmentName: room.department,
                hospitalName: hospitalName,
                initialCurrent: room.currentNumber ?? demoStartingNumber,
                // Nút “Đặt lại số” trong màn hình hàng chờ đưa phòng về số này.
                startingNumber: demoStartingNumber,
              ),
            ),
          );
        },
      );
}

/// Điểm vào mẫu – chạy được ngay, không cần Firebase hay cấu hình CSDL nào.
void main() => runApp(const ClinicRoomPickerApp());

class ClinicRoomPickerApp extends StatelessWidget {
  const ClinicRoomPickerApp({
    super.key,
    this.rooms,
    this.hospitalName = 'Bệnh viện Bạch Mai',
    this.onLogout,
  });

  /// Danh sách phòng do app cung cấp; để trống (null) thì dùng dữ liệu
  /// mẫu [demoDepartments].
  final List<ClinicRoomData>? rooms;
  final String hospitalName;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _pickerScreen(),
    routes: <String, WidgetBuilder>{
      _kRouteLogin: (_) => const LoginScreen(),
      _kRouteRegister: (_) => const RegisterScreen(),
      _kRoutePatientHome: (_) => _pickerScreen(),
    },
    // Du phong: neu AppRoutes trong du an ban dat ten route khac
    // (vd '/patientHome', '/home'), route do van duoc xu ly thay vi bao loi
    // "Could not find a generator for route".
    onGenerateRoute: (RouteSettings settings) {
      final name = (settings.name ?? '').toLowerCase();
      final Widget page;
      if (name.contains('login')) {
        page = const LoginScreen();
      } else if (name.contains('register') || name.contains('signup')) {
        page = const RegisterScreen();
      } else {
        page = _pickerScreen();
      }
      return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
    },
  );

  /// Man hinh chon khoa/phong, dung cho ca `home` va cac route.
  Widget _pickerScreen() => ClinicRoomPickerScreen(
    rooms: rooms,
    hospitalName: hospitalName,
    onLogout: onLogout,
  );
}
