import 'package:flutter/material.dart';

import 'Queue_screen.dart';
import 'room_session_store.dart';

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
    required this.doctorNameOf,
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
  final String Function(T room) doctorNameOf;
  final String Function(T room) statusLabelOf;
  final bool Function(T room) isOpen;
  final bool Function(T room) isPaused;
  final bool Function(T room) isClosed;
  final int? Function(T room) currentNumberOf;
  final int Function(T room) waitingCountOf;
  final int Function(T room) examinedCountOf;

  /// Called when the user taps an available room.
  final ValueChanged<T> onRoomSelected;

  /// The initial department. If it is not in [rooms], the first department is
  /// selected automatically.
  final String? initialDepartment;
  final String hospitalName;
  final String title;

  /// Xử lý đăng xuất (xoá token/phiên đăng nhập, đóng socket, điều hướng về
  /// màn hình đăng nhập…). Nếu để `null`, nút đăng xuất vẫn hiển thị và chỉ
  /// đưa người dùng về route đầu tiên trong stack.
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

  List<T> get _departmentRooms => widget.rooms.where((room) {
    final selected = _selectedDepartment;
    return selected == null || widget.departmentOf(room).trim() == selected;
  }).toList();

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

      final searchable =
          ('${widget.hospitalIdOf(room)} '
                  '${widget.departmentIdOf(room)} '
                  '${widget.roomIdOf(room)} '
                  '${widget.departmentOf(room)} '
                  '${widget.roomNameOf(room)} '
                  '${widget.doctorNameOf(room)}')
              .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  int get _openCount =>
      _departmentRooms.where((room) => widget.isOpen(room)).length;

  int get _waitingTotal => _departmentRooms.fold<int>(
    0,
    (total, room) => total + widget.waitingCountOf(room),
  );

  int get _examinedTotal => _departmentRooms.fold<int>(
    0,
    (total, room) => total + widget.examinedCountOf(room),
  );

  @override
  void initState() {
    super.initState();
    final departments = _departments;
    final preferred = widget.initialDepartment?.trim();
    if (preferred != null && departments.contains(preferred)) {
      _selectedDepartment = preferred;
    } else if (departments.isNotEmpty) {
      _selectedDepartment = departments.first;
    }
  }

  @override
  void didUpdateWidget(covariant DepartmentRoomPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final departments = _departments;
    if (_selectedDepartment == null ||
        !departments.contains(_selectedDepartment)) {
      final preferred = widget.initialDepartment?.trim();
      _selectedDepartment = preferred != null && departments.contains(preferred)
          ? preferred
          : (departments.isEmpty ? null : departments.first);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  /// Hỏi xác nhận (nếu bật) rồi gọi [DepartmentRoomPicker.onLogout].
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

    setState(() => _loggingOut = true);
    try {
      final onLogout = widget.onLogout;
      if (onLogout != null) {
        await onLogout();
      } else {
        // Mặc định: về route đầu tiên (thường là màn hình đăng nhập).
        Navigator.of(context).popUntil((route) => route.isFirst);
        if (mounted) _showMessage('Đã đăng xuất.');
      }
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
              constraints: const BoxConstraints(maxWidth: 620),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final horizontalPadding = compact ? 16.0 : 22.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      30,
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
                                      fontSize: compact ? 21 : 24,
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
                                          '${_selectedDepartment ?? 'Tất cả khoa'} · '
                                          '${widget.hospitalName}',
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
                        if (_departments.isNotEmpty) ...[
                          _buildDepartmentSelector(),
                          const SizedBox(height: 12),
                        ],
                        _buildStatsCard(compact),
                        const SizedBox(height: 14),
                        _buildSearchBox(),
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

  Widget _buildDepartmentSelector() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PickerUi.border),
      boxShadow: _PickerUi.quietShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0x14107FE8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Color(0xFF107FE8),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CHỌN KHOA',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: _PickerUi.faint,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _PickerUi.secondary,
                  ),
                  items: _departments
                      .map(
                        (department) => DropdownMenuItem<String>(
                          value: department,
                          child: Text(
                            department,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _PickerUi.text,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (department) =>
                      setState(() => _selectedDepartment = department),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStatsCard(bool compact) => Container(
    padding: EdgeInsets.symmetric(vertical: 16, horizontal: compact ? 6 : 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _PickerUi.border),
      boxShadow: _PickerUi.cardShadow,
    ),
    child: Row(
      children: [
        Expanded(
          child: _PickerStat(
            icon: Icons.meeting_room_rounded,
            value: '$_openCount',
            label: 'ĐANG KHÁM',
            color: const Color(0xFF35B85A),
          ),
        ),
        const _PickerStatDivider(),
        Expanded(
          child: _PickerStat(
            icon: Icons.groups_rounded,
            value: '$_waitingTotal',
            label: 'ĐANG ĐỢI',
            color: const Color(0xFFE94B45),
          ),
        ),
        const _PickerStatDivider(),
        Expanded(
          child: _PickerStat(
            icon: Icons.task_alt_rounded,
            value: '$_examinedTotal',
            label: 'ĐÃ KHÁM',
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    ),
  );

  Widget _buildSearchBox() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PickerUi.border),
      boxShadow: _PickerUi.quietShadow,
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _PickerUi.text,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm phòng hoặc bác sĩ…',
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
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
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

  Widget _buildEmptyState() => Container(
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
            widget.rooms.isEmpty
                ? 'Chưa có phòng khám.'
                : 'Không tìm thấy phòng phù hợp.',
            style: const TextStyle(fontSize: 13, color: _PickerUi.secondary),
          ),
        ),
      ],
    ),
  );

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
                        widget.doctorNameOf(room),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _PickerUi.secondary,
                          fontWeight: FontWeight.w500,
                        ),
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

class _PickerStat extends StatelessWidget {
  const _PickerStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
          color: _PickerUi.faint,
        ),
      ),
    ],
  );
}

class _PickerStatDivider extends StatelessWidget {
  const _PickerStatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: _PickerUi.border);
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
    required this.doctorName,
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
  final String doctorName;
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
    doctorName: doctorName,
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

/// Dữ liệu demo trong bộ nhớ. Thay danh sách này bằng dữ liệu do app của bạn
/// cung cấp (API nội bộ, mock, file JSON…). Không cần cơ sở dữ liệu/Firebase.
///
/// Tất cả phòng đều BẮT ĐẦU Ở SỐ 1: `currentNumber = 1`, chưa có ai đang đợi
/// và chưa khám ai. Khi mở một phòng, màn hình hàng chờ sẽ hiển thị
/// SỐ HIỆN TẠI = 1, SỐ TIẾP THEO = 2, và hàng chờ bắt đầu từ số 3.
///
/// Mọi phòng đều ở trạng thái "Đang khám". Trạng thái "Tạm dừng" CHỈ xuất hiện
/// sau khi bác sĩ nhấn nút "Tạm dừng khám" ở màn hình hàng chờ (xem
/// [RoomSessionStore]) — không gán cứng ở đây.
const int demoStartingNumber = 1;

const List<ClinicRoomData> demoClinicRooms = <ClinicRoomData>[
  ClinicRoomData(
    hospitalId: '10',
    departmentId: 'K001',
    id: 'PK1',
    name: 'Phòng khám 1',
    department: 'Khoa Tim',
    staffId: 'NV-LAN',
    doctorName: 'BS. Nguyễn Thị Lan',
    status: ClinicRoomStatus.open,
    currentNumber: demoStartingNumber,
    waitingCount: 0,
    examinedCount: 0,
  ),
  ClinicRoomData(
    hospitalId: '10',
    departmentId: 'K002',
    id: 'PK2',
    name: 'Phòng khám 2',
    department: 'Khoa Hô hấp',
    staffId: 'NV-HUNG',
    doctorName: 'BS. Trần Quốc Hưng',
    status: ClinicRoomStatus.open,
    currentNumber: demoStartingNumber,
    waitingCount: 0,
    examinedCount: 0,
  ),
  ClinicRoomData(
    hospitalId: '10',
    departmentId: 'K003',
    id: 'PK3',
    name: 'Phòng khám 3',
    department: 'Khoa Nhi',
    staffId: 'NV-VNT',
    doctorName: 'BS. Vũ Nam Tuấn',
    status: ClinicRoomStatus.open,
    currentNumber: demoStartingNumber,
    waitingCount: 0,
    examinedCount: 0,
  ),
  ClinicRoomData(
    hospitalId: '10',
    departmentId: 'K001',
    id: 'PK4',
    name: 'Phòng khám 4',
    department: 'Khoa Tim',
    staffId: 'NV-MAI',
    doctorName: 'BS. Lê Thanh Mai',
    status: ClinicRoomStatus.open,
    currentNumber: demoStartingNumber,
    waitingCount: 0,
    examinedCount: 0,
  ),
  ClinicRoomData(
    hospitalId: '10',
    departmentId: 'K003',
    id: 'PK5',
    name: 'Phòng khám 5',
    department: 'Khoa Nhi',
    staffId: 'NV-DUNG',
    doctorName: 'BS. Phạm Anh Dũng',
    status: ClinicRoomStatus.open,
    currentNumber: demoStartingNumber,
    waitingCount: 0,
    examinedCount: 0,
  ),
];

/// Màn hình chọn khoa/phòng đã kết nối với QueueScreen trong Queue_screen.dart.
/// Dữ liệu phòng lấy trực tiếp từ danh sách [rooms] (mặc định là dữ liệu demo
/// trong bộ nhớ), không đọc/ghi Firestore hay SQLite.
class ClinicRoomPickerScreen extends StatelessWidget {
  const ClinicRoomPickerScreen({
    super.key,
    this.rooms = demoClinicRooms,
    this.initialDepartment = 'Khoa Tim',
    this.hospitalName = 'Bệnh viện Bạch Mai',
    this.onLogout,
  });

  final List<ClinicRoomData> rooms;
  final String initialDepartment;
  final String hospitalName;

  /// Xử lý đăng xuất thật của app. Ví dụ:
  ///
  /// ```dart
  /// ClinicRoomPickerScreen(
  ///   onLogout: () async {
  ///     await AuthStore.instance.logout();      // xoá token/phiên đăng nhập
  ///     RoomSessionStore.instance.resetAll();   // (tuỳ chọn) dọn phiên phòng
  ///     if (!context.mounted) return;
  ///     Navigator.of(context).pushNamedAndRemoveUntil(
  ///       '/login',
  ///       (route) => false,
  ///     );
  ///   },
  /// )
  /// ```
  ///
  /// Để `null` thì nút đăng xuất chỉ đưa người dùng về route đầu tiên.
  final Future<void> Function()? onLogout;

  /// Danh sách phòng kèm trạng thái/số liệu thật lấy từ [RoomSessionStore]
  /// (phòng chưa mở lần nào thì giữ nguyên dữ liệu ban đầu).
  List<ClinicRoomData> _liveRooms() => <ClinicRoomData>[
    for (final room in rooms)
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
        doctorNameOf: (room) => room.doctorName,
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
                doctorName: room.doctorName,
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
    this.rooms = demoClinicRooms,
    this.hospitalName = 'Bệnh viện Bạch Mai',
    this.onLogout,
  });

  /// Danh sách phòng do app cung cấp (mặc định: dữ liệu demo trong bộ nhớ).
  final List<ClinicRoomData> rooms;
  final String hospitalName;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ClinicRoomPickerScreen(
      rooms: rooms,
      hospitalName: hospitalName,
      onLogout: onLogout,
    ),
  );
}
