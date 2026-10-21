import 'package:flutter/material.dart';

import 'room_session_store.dart';

/// Một lượt đã qua: số thứ tự + có phải bệnh nhân xin đợi hay không.
typedef PassedEntry = ({int number, bool deferred});

/// Kết quả trả về từ màn hình chèn: số cần chèn + vị trí mới trong hàng chờ.
typedef InsertResult = ({int number, int targetIndex});

/// Lựa chọn trong bảng "Đợi / Gọi lại": số được chọn + hành động áp dụng.
/// hold = true  -> cho số đó qua lượt (đợi), hold = false -> gọi lại số đã khám.
typedef QueueAction = ({int number, bool hold});

/// Bộ màu & hiệu ứng dùng chung cho toàn giao diện.
abstract final class _Ui {
  static const Color bgTop = Color(0xFFF9FAFE);
  static const Color bgBottom = Color(0xFFEBEFF8);
  static const Color cardBorder = Color(0xFFEEF0F7);
  static const Color divider = Color(0xFFEFF1F7);
  static const Color textPrimary = Color(0xFF191C26);
  static const Color textSecondary = Color(0xFF8B90A0);
  static const Color textFaint = Color(0xFFAAB0BE);
  static const Color green = Color(0xFF35C95B);
  static const Color amber = Color(0xFFFFC400);
  static const Color red = Color(0xFFFF534B);
  static const Color chipIdleText = Color(0xFF7C8293);

  /// Bóng mềm cho các thẻ trắng.
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x12101828), blurRadius: 26, offset: Offset(0, 14)),
  ];

  /// Bóng mềm cho nút phụ (nền trắng).
  static const List<BoxShadow> quietShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F101828), blurRadius: 12, offset: Offset(0, 6)),
  ];

  /// Bóng màu cho nút chính / nút xanh.
  static const List<BoxShadow> blueShadow = <BoxShadow>[
    BoxShadow(color: Color(0x3D107FE8), blurRadius: 18, offset: Offset(0, 9)),
  ];
  static const List<BoxShadow> greenShadow = <BoxShadow>[
    BoxShadow(color: Color(0x3D22A94E), blurRadius: 18, offset: Offset(0, 9)),
  ];

  static const LinearGradient greenCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF41D366), Color(0xFF1FA24C)],
  );
  static const LinearGradient amberCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54A), Color(0xFFFF9000)],
  );
  static const LinearGradient redChip = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6A5E), Color(0xFFEF2E26)],
  );
  static const LinearGradient blueButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2196FF), Color(0xFF0067DE)],
  );
  static const LinearGradient greenButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF43D26A), Color(0xFF1E9C48)],
  );
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({
    super.key,
    this.sessionId = 'PK3-20260918-01',
    this.roomId = 'PK3',
    this.staffId = 'NV-VNT',
    this.roomName = 'Phòng khám 3',
    this.doctorName = 'BS. Vũ Nam Tuấn',
    this.departmentName = 'Khoa Tim',
    this.hospitalName = 'Bệnh viện Bạch Mai',
    this.initialCurrent = 1,
    this.startingNumber = 1,
  });

  /// Mã phiên khám – gom các lượt của cùng một buổi/ngày.
  final String sessionId;

  /// Mã phòng khám.
  final String? roomId;

  /// Mã nhân viên phụ trách phòng khám.
  final String? staffId;

  /// Thông tin phòng/khoa được chọn ở màn hình trước.
  final String roomName;
  final String doctorName;
  final String departmentName;
  final String hospitalName;

  /// Số hiện tại khi mở lại một phòng đang chạy.
  final int initialCurrent;

  /// Số bắt đầu của phiên – dùng cho nút “Đặt lại số”.
  /// Mặc định là 1 (mọi phòng đều bắt đầu ở số 1).
  final int startingNumber;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  /// Số hiện tại khởi tạo theo phòng được chọn.
  late int current;
  late int next;

  /// Hàng đợi: luôn là MỘT HÀNG số tăng dần, gọi theo thứ tự từ đầu hàng.
  /// Mỗi lần một số rời hàng đợi, _refillQueue() tự sinh thêm số mới (+1)
  /// ở cuối nên dải số tự chạy và không bao giờ cạn.
  late List<int> waiting;

  /// Số lớn nhất đã phát ra, dùng để sinh số tiếp theo cho hàng đợi.
  late int lastIssued;

  /// Các số đã qua lượt:
  ///  - deferred = false: đã khám xong (dùng cho "Gọi lại số").
  ///  - deferred = true : bệnh nhân xin đợi (dùng cho "+ Chèn" để chèn lại).
  final List<PassedEntry> passed = <PassedEntry>[];

  /// Số ô hiển thị trong dải "SỐ ĐANG ĐỢI" và là mức tối thiểu của hàng chờ.
  static const int queueWindow = 5;

  int? selected;
  bool paused = false;
  String? message;

  /// Khóa lưu trạng thái phòng trong [RoomSessionStore] (ưu tiên mã phòng).
  String get _storeKey => widget.roomId ?? widget.sessionId;

  @override
  void initState() {
    super.initState();
    final snapshot = RoomSessionStore.instance.sessionOf(_storeKey);
    if (snapshot.started) {
      // Mở lại phòng: khôi phục đúng trạng thái đã có trong bộ nhớ
      // (số hiện tại, hàng chờ, các số đã đợi/đã khám, tạm dừng…).
      current = snapshot.current;
      next = snapshot.next;
      waiting = List<int>.of(snapshot.waiting);
      lastIssued = snapshot.lastIssued;
      passed
        ..clear()
        ..addAll(
          snapshot.examinedNumbers.map(
            (number) => (number: number, deferred: false),
          ),
        )
        ..addAll(
          snapshot.deferredNumbers.map(
            (number) => (number: number, deferred: true),
          ),
        );
      paused = snapshot.paused;
    } else {
      // Mở phòng lần đầu: bắt đầu từ số khởi tạo (mặc định 1).
      final start = widget.initialCurrent;
      current = start;
      next = start + 1;
      waiting = List<int>.generate(queueWindow, (index) => start + 2 + index);
      lastIssued = start + 1 + queueWindow;
      snapshot
        ..started = true
        ..paused = false;
    }
    // Đẩy trạng thái ra kho chung sau khi frame đầu vẽ xong, để trang chính
    // (màn hình chọn khoa/phòng) nhận đúng thông tin khi quay lại.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRoomState();
    });
  }

  /// Ghi trạng thái hiện tại của phòng vào [RoomSessionStore] và báo cho
  /// màn hình chính vẽ lại (trạng thái Tạm dừng / Đang khám, số hiện tại,
  /// số đang đợi, số đã khám).
  void _syncRoomState() {
    final store = RoomSessionStore.instance;
    store.sessionOf(_storeKey)
      ..started = true
      ..current = current
      ..next = next
      ..waiting = List<int>.of(waiting)
      ..lastIssued = lastIssued
      ..paused = paused
      ..examinedNumbers = <int>[
        for (final entry in passed)
          if (!entry.deferred) entry.number,
      ]
      ..deferredNumbers = <int>[
        for (final entry in passed)
          if (entry.deferred) entry.number,
      ];
    store.refresh();
  }

  void notify(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _Ui.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        ),
      );
  }

  /// Bù số mới (+1) vào cuối hàng đợi để dải số luôn đầy.
  void _refillQueue() {
    while (waiting.length < queueWindow) {
      waiting.add(++lastIssued);
    }
  }

  bool get _currentConfirmed =>
      passed.any((entry) => entry.number == current && !entry.deferred);

  /// Số của những bệnh nhân đã bấm "Đợi" – danh sách hiện trong màn hình Chèn.
  List<int> get deferredNumbers => passed
      .where((entry) => entry.deferred)
      .map((entry) => entry.number)
      .toList();

  /// Số của những bệnh nhân đã khám xong – dùng cho mục "Gọi lại số".
  List<int> get examinedNumbers => passed
      .where((entry) => !entry.deferred)
      .map((entry) => entry.number)
      .toList();

  /// Nút "Tiếp theo" (đã gộp với "Xác nhận khám"): xác nhận số hiện tại đã
  /// khám xong rồi gọi số kế tiếp trong một lần bấm.
  void callNext() {
    if (paused) {
      notify('Vui lòng tiếp tục khám trước khi gọi số.');
      return;
    }
    setState(() {
      final finished = current;
      if (!_currentConfirmed) {
        // Xác nhận khám: ghi số hiện tại vào danh sách đã khám.
        passed.add((number: current, deferred: false));
      }
      current = next;
      next = waiting.removeAt(
        0,
      ); // hàng đợi không bao giờ rỗng nhờ _refillQueue()
      _refillQueue();
      if (selected != null && !waiting.contains(selected)) selected = null;
      message =
          'Đã xác nhận bệnh nhân số $finished khám xong.\n'
          'Đã gọi bệnh nhân số $current – vui lòng chờ bệnh nhân vào phòng khám.';
      _syncRoomState();
    });
  }

  /// Nút “Đặt lại số”: đưa phòng về đúng trạng thái ban đầu – số hiện tại =
  /// [QueueScreen.startingNumber], số tiếp theo = số đó + 1, hàng chờ là
  /// [queueWindow] số kế tiếp, xoá toàn bộ số đã đợi/đã khám và phòng trở về
  /// “Đang khám”. Có hộp thoại xác nhận vì thao tác này không thể hoàn tác.
  Future<void> resetNumbers() async {
    final start = widget.startingNumber;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đặt lại số'),
        content: Text(
          'Đưa ${widget.roomName} về trạng thái ban đầu?\n\n'
          '• Số hiện tại: $start\n'
          '• Số tiếp theo: ${start + 1}\n'
          '• Hàng chờ: ${start + 2} → ${start + 1 + queueWindow}\n'
          '• Xoá toàn bộ số đã đợi và số đã khám\n'
          '• Phòng trở về “Đang khám”\n\n'
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      current = start;
      next = start + 1;
      waiting = List<int>.generate(queueWindow, (index) => start + 2 + index);
      lastIssued = start + 1 + queueWindow;
      passed.clear();
      selected = null;
      paused = false;
      message =
          'Đã đặt lại số: số hiện tại = $current, số tiếp theo = $next.\n'
          'Hàng chờ bắt đầu lại từ số ${waiting.first}.';
      // Ghi trạng thái mới ra kho chung để trang chính hiển thị đúng:
      // số hiện tại = $start, 0 đang đợi, 0 đã khám, “Đang khám”.
      _syncRoomState();
    });
    notify('Đã đặt lại hàng chờ của ${widget.roomName}.');
  }

  /// Nút "Xác nhận vắng mặt":
  ///  1. Mở bảng chọn số – CHỈ gồm những số đã bấm "Đợi" (danh sách
  ///     "SỐ ĐÃ CHO QUA" trên màn hình chính).
  ///  2. Hỏi xác nhận rồi ghi nhận số được chọn là vắng mặt và bỏ số đó khỏi
  ///     danh sách chờ chèn lại.
  ///
  /// Không đụng tới số đang khám, số kế tiếp hay các số còn trong hàng chờ.
  Future<void> markCurrentAbsent() async {
    if (paused) {
      notify('Vui lòng tiếp tục khám trước khi cập nhật lượt.');
      return;
    }

    final absentNumbers = deferredNumbers;
    if (absentNumbers.isEmpty) {
      notify('Chưa có bệnh nhân nào bấm “Đợi” để xác nhận vắng mặt.');
      return;
    }

    final absentNumber = await _pickAbsentNumber(absentNumbers);
    if (!mounted || absentNumber == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận vắng mặt'),
        content: Text(
          'Bệnh nhân số $absentNumber đã bấm “Đợi” nhưng không quay lại. '
          'Ghi nhận trạng thái “Vắng mặt” và bỏ số này khỏi danh sách chờ '
          'chèn lại?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      // Số đã xin đợi nay xác nhận vắng mặt: bỏ khỏi danh sách "SỐ ĐÃ CHO QUA".
      passed.removeWhere(
        (entry) => entry.deferred && entry.number == absentNumber,
      );
      message =
          'Đã ghi nhận bệnh nhân số $absentNumber vắng mặt.'
          '\nSố $absentNumber đã được bỏ khỏi danh sách “SỐ ĐÃ CHO QUA”.';
      _syncRoomState();
    });
  }

  /// Bảng chọn số cần ghi nhận vắng mặt – chỉ gồm các số đã bấm "Đợi".
  Future<int?> _pickAbsentNumber(
    List<int> absentNumbers,
  ) => showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.66,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E6EF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Xác nhận vắng mặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _Ui.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chọn số trong danh sách đã bấm “Đợi” để xác nhận vắng mặt.',
                  style: TextStyle(fontSize: 12.5, color: _Ui.textSecondary),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'ĐÃ BẤM ĐỢI · CHỌN SỐ VẮNG MẶT',
                  count: absentNumbers.length,
                  accent: _Ui.amber,
                  accentSoft: const Color(0x24FFB300),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bấm một số để ghi nhận bệnh nhân đó vắng mặt. Số mới bấm “Đợi” hiện trước.',
                  style: TextStyle(fontSize: 11.5, color: _Ui.textFaint),
                ),
                const SizedBox(height: 12),
                if (absentNumbers.isEmpty)
                  const _EmptyHint(
                    icon: Icons.pause_circle_outline_rounded,
                    text: 'Chưa có số nào bấm “Đợi”.',
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Số mới bấm "Đợi" hiện trước.
                      for (final n in absentNumbers.reversed)
                        _AbsentChip(
                          number: n,
                          onTap: () => Navigator.of(sheetContext).pop<int>(n),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// Cho một số bất kỳ trong hàng chờ xin đợi (qua lượt): số đó rời hàng chờ và
  /// được lưu lại để chèn lại sau; nếu là số kế tiếp thì số liền sau lên thay.
  void deferNumber(int number) {
    if (paused) {
      notify('Vui lòng tiếp tục khám trước khi đổi lượt.');
      return;
    }
    final isNext = number == next;
    if (!isNext && !waiting.contains(number)) {
      notify('Số $number không còn trong hàng chờ.');
      return;
    }
    setState(() {
      passed.add((number: number, deferred: true));
      if (isNext) {
        next = waiting.removeAt(0);
      } else {
        waiting.remove(number);
      }
      _refillQueue();
      if (selected != null && !waiting.contains(selected)) selected = null;
      message = isNext
          ? 'Bệnh nhân số $number xin đợi.\nSố $number đã được lưu lại; số $next được gọi tiếp theo.\n'
                'Khi bệnh nhân quay lại, bấm “+ Chèn” để đưa số $number trở lại hàng chờ.'
          : 'Bệnh nhân số $number xin đợi.\nSố $number đã được lưu lại.\n'
                'Khi bệnh nhân quay lại, bấm “+ Chèn” để đưa số $number trở lại hàng chờ.';
      _syncRoomState();
    });
  }

  /// Gọi lại một bệnh nhân đã khám xong: đưa số đó vào "SỐ HIỆN TẠI" ngay,
  /// số đang khám cũ lùi về "SỐ TIẾP THEO"; số kế tiếp cũ (chưa được gọi) quay
  /// trở lại đầu hàng chờ để không bị mất lượt.
  void recallNumber(int picked) {
    if (paused) {
      notify('Vui lòng tiếp tục khám trước khi gọi lại số.');
      return;
    }
    setState(() {
      final previousCurrent = current;
      final previousNext = next;
      // Bệnh nhân vào phòng khám ngay: bỏ khỏi danh sách đã khám, sẽ được đưa
      // lại danh sách khi bác sĩ nhấn "Tiếp theo".
      passed.removeWhere((entry) => entry.number == picked && !entry.deferred);
      current = picked;
      next = previousCurrent;
      waiting.insert(
        0,
        previousNext,
      ); // số kế tiếp cũ chưa gọi -> về đầu hàng chờ
      if (selected != null && !waiting.contains(selected)) selected = null;
      message =
          'Đã gọi lại bệnh nhân số $picked – số $picked đang khám.\n'
          'Số $previousCurrent trở thành số tiếp theo; số $previousNext quay lại đầu hàng chờ.';
      _syncRoomState();
    });
    notify('Mời bệnh nhân số $picked đến ${widget.roomName.toLowerCase()}.');
  }

  /// Nút "Đợi / Gọi lại" (đã gộp 2 chức năng): mở bảng chọn số mong muốn.
  ///  - Mục "Đang chờ": bấm một số bất kỳ (kể cả số kế tiếp) để cho qua lượt.
  ///  - Mục "Đã khám": bấm một số để gọi lại bệnh nhân đã khám xong.
  Future<void> openHoldOrRecallSheet() async {
    final recallable = examinedNumbers;
    final holdable = <int>[next, ...waiting]; // số kế tiếp + các số đang chờ
    final picked = await showModalBottomSheet<QueueAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.66,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3E6EF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Đợi / Gọi lại số',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _Ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chọn số cần xử lý – thao tác áp dụng ngay cho số được chọn.',
                    style: TextStyle(fontSize: 12.5, color: _Ui.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'ĐANG CHỜ · CHỌN ĐỂ CHO QUA LƯỢT',
                    count: holdable.length,
                    accent: _Ui.red,
                    accentSoft: const Color(0x1FFF534B),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bấm một số để bệnh nhân đó xin đợi. Số có viền vàng là số kế tiếp.',
                    style: TextStyle(fontSize: 11.5, color: _Ui.textFaint),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final n in holdable)
                        _SheetWaitChip(
                          number: n,
                          isNext: n == next,
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop<QueueAction>((number: n, hold: true)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'ĐÃ KHÁM · CHỌN ĐỂ GỌI LẠI',
                    count: recallable.length,
                    accent: _Ui.green,
                    accentSoft: const Color(0x1F2AC653),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bấm một số để gọi lại: số đó vào “số hiện tại”, số đang khám lùi về “số tiếp theo”.',
                    style: TextStyle(fontSize: 11.5, color: _Ui.textFaint),
                  ),
                  const SizedBox(height: 12),
                  if (recallable.isEmpty)
                    const _EmptyHint(
                      icon: Icons.inbox_rounded,
                      text: 'Chưa có bệnh nhân nào đã khám',
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Số mới khám xong hiện trước.
                        for (final n in recallable.reversed)
                          _RecallChip(
                            number: n,
                            onTap: () => Navigator.of(
                              sheetContext,
                            ).pop<QueueAction>((number: n, hold: false)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (picked.hold) {
      deferNumber(picked.number);
    } else {
      recallNumber(picked.number);
    }
  }

  /// Nhấn "+ Chèn" (hoặc bấm một số trong hàng "SỐ ĐÃ CHO QUA"): mở màn hình
  /// chèn. Danh sách trong màn hình là những số đã bấm "Đợi"; chọn một số rồi
  /// nhập vị trí để đưa số đó trở lại hàng chờ.
  Future<void> openInsertScreen({int? initialNumber}) async {
    if (deferredNumbers.isEmpty) {
      notify('Chưa có bệnh nhân nào bấm “Đợi” để chèn lại.');
      return;
    }
    final result = await Navigator.of(context).push<InsertResult>(
      MaterialPageRoute(
        builder: (_) => InsertPositionScreen(
          deferredNumbers: deferredNumbers,
          waiting: List<int>.of(waiting),
          initialNumber: initialNumber,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      // Bệnh nhân đã quay lại: bỏ khỏi danh sách xin đợi và đưa về hàng chờ.
      passed.removeWhere(
        (entry) => entry.deferred && entry.number == result.number,
      );
      var index = result.targetIndex;
      if (index < 0) index = 0;
      if (index > waiting.length) index = waiting.length;
      waiting.insert(index, result.number);
      _refillQueue();
      selected = result.number;
      message =
          'Đã đưa số ${result.number} trở lại hàng chờ tại vị trí thứ ${index + 1}.';
      _syncRoomState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Ui.bgTop, _Ui.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final gap = compact ? 10.0 : 14.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 22,
                      20,
                      compact ? 16 : 22,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _RoundIconButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Quay lại',
                              onPressed: () async {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  notify('Bạn đang ở màn hình chính.');
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.departmentName} - ${widget.hospitalName}',
                                    style: TextStyle(
                                      fontSize: compact ? 16.5 : 19,
                                      fontWeight: FontWeight.w800,
                                      color: _Ui.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const _PulseDot(),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${widget.roomName} · ${widget.doctorName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: _Ui.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _NumberCard(
                                label: 'SỐ HIỆN TẠI',
                                value: '$current',
                                gradient: _Ui.greenCard,
                                foreground: Colors.white,
                                glow: const Color(0x4D1FA24C),
                                icon: Icons.person_rounded,
                                compact: compact,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: _NumberCard(
                                label: 'SỐ TIẾP THEO',
                                value: '$next',
                                gradient: _Ui.amberCard,
                                foreground: const Color(0xFF3A2A00),
                                glow: const Color(0x4DFF9A00),
                                icon: Icons.hourglass_bottom_rounded,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SoftCard(
                          padding: EdgeInsets.all(compact ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'SỐ ĐANG ĐỢI',
                                count: waiting.length,
                                accent: _Ui.red,
                                accentSoft: const Color(0x1FFF534B),
                              ),
                              const SizedBox(height: 14),
                              if (waiting.isEmpty)
                                const _EmptyHint(
                                  icon: Icons.people_outline_rounded,
                                  text: 'Chưa có bệnh nhân đang đợi',
                                )
                              else
                                SizedBox(
                                  height: compact ? 52 : 58,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.zero,
                                    itemCount: waiting.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(width: compact ? 9 : 13),
                                    itemBuilder: (context, index) {
                                      final number = waiting[index];
                                      return _WaitingChip(
                                        number: number,
                                        selected: selected == number,
                                        compact: compact,
                                        onTap: () =>
                                            setState(() => selected = number),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 18),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: _Ui.divider,
                              ),
                              const SizedBox(height: 16),
                              _SectionHeader(
                                title: 'SỐ ĐÃ CHO QUA',
                                count: deferredNumbers.length,
                                accent: _Ui.amber,
                                accentSoft: const Color(0x24FFB300),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Bấm vào số để chèn lại vào hàng chờ.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _Ui.textFaint,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (deferredNumbers.isEmpty)
                                const _EmptyHint(
                                  icon: Icons.pause_circle_outline_rounded,
                                  text: 'Chưa có số nào bị cho qua',
                                )
                              else
                                SizedBox(
                                  height: 42,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.zero,
                                    itemCount: deferredNumbers.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 9),
                                    itemBuilder: (context, index) {
                                      final number = deferredNumbers[index];
                                      return _DeferredChip(
                                        number: number,
                                        onTap: () => openInsertScreen(
                                          initialNumber: number,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Hai nút chính: "+ Chèn" và "Đợi / Gọi lại" (đã gộp), cùng
                        // nút "Tiếp theo" (đã gộp với "Xác nhận khám").
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ActionButton(
                                label: '+ Chèn',
                                icon: Icons.add_rounded,
                                iconLeading: true,
                                onPressed: openInsertScreen,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              flex: 4,
                              child: _ActionButton(
                                label: 'Đợi / Gọi lại',
                                icon: Icons.swap_horiz_rounded,
                                onPressed: openHoldOrRecallSheet,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              flex: 4,
                              child: _ActionButton(
                                label: 'Tiếp theo',
                                icon: Icons.arrow_forward_rounded,
                                primary: true,
                                onPressed: callNext,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ActionButton(
                                label: 'Xác nhận vắng mặt',
                                icon: Icons.person_off_rounded,
                                iconLeading: true,
                                onPressed: markCurrentAbsent,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              flex: 2,
                              child: _ActionButton(
                                label: 'Đặt lại số',
                                icon: Icons.restart_alt_rounded,
                                iconLeading: true,
                                danger: true,
                                onPressed: resetNumbers,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: paused
                                    ? 'Tiếp tục khám'
                                    : 'Tạm dừng khám',
                                icon: paused
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.pause_circle_filled_rounded,
                                iconLeading: true,
                                color: paused ? _Ui.green : Colors.white,
                                onPressed: () => setState(() {
                                  paused = !paused;
                                  message = paused
                                      ? 'Bác sĩ đã nhấn nút “Tạm dừng khám”.\nViệc gọi số tiếp theo tạm thời bị dừng.\n'
                                            'Vui lòng chờ đến khi bác sĩ tiếp tục khám.'
                                      : null;
                                  // Cập nhật ngay trạng thái phòng cho trang chính:
                                  // chỉ khi bấm nút này phòng mới hiện "Tạm dừng".
                                  _syncRoomState();
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _StatusBanner(
                          paused: paused,
                          message:
                              message ??
                              (paused
                                  ? 'Bác sĩ đã nhấn nút “Tạm dừng khám”.\nViệc gọi số tiếp theo tạm thời bị dừng.\nVui lòng chờ đến khi bác sĩ tiếp tục khám.'
                                  : 'Bệnh nhân số $current đang khám.\nNhấn “Tiếp theo” để xác nhận khám xong và gọi số $next.'),
                          footer:
                              '${widget.roomName} · ${widget.doctorName} · 08:42',
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
}

/// Màn hình "Khoa - Số hàng chờ": chọn một số đã bấm "Đợi" và nhập vị trí để
/// chèn số đó trở lại hàng chờ.
class InsertPositionScreen extends StatefulWidget {
  const InsertPositionScreen({
    super.key,
    required this.deferredNumbers,
    required this.waiting,
    this.initialNumber,
  });

  /// Số của những bệnh nhân đã bấm "Đợi" – danh sách để chọn chèn lại.
  final List<int> deferredNumbers;

  /// Ảnh chụp hàng chờ hiện tại (đúng thứ tự sẽ gọi) – dùng để quy đổi vị trí.
  final List<int> waiting;

  /// Số được chọn sẵn khi mở màn hình (bấm từ hàng "SỐ ĐÃ CHO QUA").
  final int? initialNumber;

  @override
  State<InsertPositionScreen> createState() => _InsertPositionScreenState();
}

class _InsertPositionScreenState extends State<InsertPositionScreen> {
  int? selected;
  String? submitError;
  final Map<int, TextEditingController> controllers = {};
  final Map<int, FocusNode> focusNodes = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialNumber;
    if (initial != null && widget.deferredNumbers.contains(initial)) {
      selected = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodeFor(initial).requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final focusNode in focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int number) =>
      controllers.putIfAbsent(number, () => TextEditingController());

  FocusNode _focusNodeFor(int number) =>
      focusNodes.putIfAbsent(number, () => FocusNode());

  void select(int number) {
    if (selected == number) {
      _focusNodeFor(number).requestFocus();
      return;
    }
    // Chỉ một ô nhập được dùng tại một thời điểm.
    for (final entry in controllers.entries) {
      if (entry.key != number) entry.value.clear();
    }
    setState(() {
      selected = number;
      submitError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodeFor(number).requestFocus();
    });
  }

  /// Tính trước kết quả chèn để hiển thị dòng preview / cảnh báo.
  /// Vị trí được tính trong hàng chờ hiện tại:
  ///  - Nhập một số đang có trong hàng chờ  -> chèn ngay TRƯỚC số đó.
  ///  - Nhập vị trí thứ N (1, 2, 3…)        -> chèn vào vị trí thứ N;
  ///    nếu lớn hơn độ dài hàng thì tự xếp vào cuối hàng.
  ({String text, int? number, int? index}) _preview(int number) {
    final raw = _controllerFor(number).text.trim();
    if (raw.isEmpty) {
      return (
        text: 'Nhập vị trí chèn cho số $number.',
        number: null,
        index: null,
      );
    }
    final value = int.tryParse(raw);
    if (value == null || value < 1) {
      return (
        text: 'Vị trí phải là số nguyên lớn hơn 0.',
        number: null,
        index: null,
      );
    }
    final refIndex = widget.waiting.indexOf(value);
    if (refIndex != -1) {
      return (
        text: 'Số $number sẽ được chèn ngay trước số $value trong hàng chờ.',
        number: number,
        index: refIndex,
      );
    }
    var index = value - 1;
    if (index < 0) index = 0;
    if (index > widget.waiting.length) index = widget.waiting.length;
    return (
      text:
          'Số $number sẽ được chèn vào vị trí thứ ${index + 1} trong hàng chờ.',
      number: number,
      index: index,
    );
  }

  void submit() {
    final number = selected;
    if (number == null) {
      setState(() => submitError = 'Chọn một số trong danh sách trước đã.');
      return;
    }
    final preview = _preview(number);
    if (preview.number == null || preview.index == null) {
      setState(() => submitError = preview.text);
      return;
    }
    Navigator.of(
      context,
    ).pop<InsertResult>((number: preview.number!, targetIndex: preview.index!));
  }

  @override
  Widget build(BuildContext context) {
    final number = selected;
    final preview = number == null ? null : _preview(number);
    final caption =
        submitError ??
        preview?.text ??
        'Chọn số cần chèn, rồi nhập vị trí muốn chèn.';
    final isError = submitError != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Ui.bgTop, _Ui.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final gap = compact ? 10.0 : 14.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 22,
                      20,
                      compact ? 16 : 22,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _RoundIconButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Quay lại',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Khoa - Số hàng chờ',
                                style: TextStyle(
                                  fontSize: compact ? 16.5 : 19,
                                  fontWeight: FontWeight.w800,
                                  color: _Ui.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 14 : 18),
                        const Text(
                          'Chọn số cần chèn, rồi nhập vị trí vào ô bên cạnh',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6F7583),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Danh sách gồm những số đã bấm “Đợi” ở màn hình chính.',
                          style: TextStyle(fontSize: 12, color: _Ui.textFaint),
                        ),
                        const SizedBox(height: 16),
                        _SoftCard(
                          padding: EdgeInsets.all(compact ? 16 : 20),
                          child: widget.deferredNumbers.isEmpty
                              ? const _EmptyHint(
                                  icon: Icons.pause_circle_outline_rounded,
                                  text: 'Chưa có bệnh nhân nào bấm “Đợi”.',
                                )
                              : Column(
                                  children: widget.deferredNumbers
                                      .map(
                                        (n) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _buildRow(n, compact),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        SizedBox(height: compact ? 18 : 22),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _ActionButton(
                                label: 'Chèn',
                                icon: Icons.playlist_add_check_rounded,
                                iconLeading: true,
                                primary: true,
                                onPressed: submit,
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              flex: 2,
                              child: _ActionButton(
                                label: 'Hủy',
                                icon: Icons.close_rounded,
                                iconLeading: true,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isError
                                ? const Color(0xFFFFF1F0)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isError
                                  ? const Color(0xFFFFD6D2)
                                  : _Ui.cardBorder,
                            ),
                            boxShadow: _Ui.quietShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isError
                                    ? Icons.error_outline_rounded
                                    : Icons.info_outline_rounded,
                                size: 16,
                                color: isError
                                    ? const Color(0xFFE5483F)
                                    : _Ui.textFaint,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  caption,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                    color: isError
                                        ? const Color(0xFFD64545)
                                        : _Ui.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildRow(int number, bool compact) {
    final isSelected = selected == number;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => select(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF3D778) : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            // Badge số: viền vàng + bóng khi được chọn.
            AnimatedScale(
              scale: isSelected ? 1.05 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                width: 47,
                height: 47,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFCF00)
                        : Colors.transparent,
                    width: 3.5,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x33EE2F26),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _Ui.redChip,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: IgnorePointer(
                ignoring: !isSelected,
                child: TextField(
                  controller: _controllerFor(number),
                  focusNode: _focusNodeFor(number),
                  enabled: isSelected,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                  onChanged: (_) => setState(() => submitError = null),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
                    color: _Ui.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Vị trí chèn',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB6BCC9),
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isSelected
                        ? Colors.white
                        : const Color(0xFFF6F8FC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE3E7F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE3E7F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2A3242),
                        width: 1.6,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE9ECF4)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ trắng bo tròn có bóng mềm – khối nội dung chính của các màn hình.
class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _Ui.cardBorder),
      boxShadow: _Ui.cardShadow,
    ),
    child: child,
  );
}

/// Tiêu đề mục nhỏ: chấm màu + tiêu đề + nhãn số lượng.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.count,
    required this.accent,
    required this.accentSoft,
  });

  final String title;
  final int? count;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 14,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: _Ui.textSecondary,
          ),
        ),
      ),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
      ],
    ],
  );
}

/// Chấm xanh nhấp nháy nhẹ báo phòng khám đang hoạt động.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: _Ui.green, shape: BoxShape.circle),
    ),
  );
}

/// Nút icon tròn (nút quay lại) có bóng mềm.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 42,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Ui.cardBorder),
          ),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, color: _Ui.textPrimary, size: 28),
          ),
        ),
      ),
    ),
  );
}

/// Thẻ số lớn (SỐ HIỆN TẠI / SỐ TIẾP THEO): gradient, vòng trang trí và
/// hiệu ứng trượt khi số đổi.
class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    required this.gradient,
    required this.foreground,
    required this.glow,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String value;
  final LinearGradient gradient;
  final Color foreground;
  final Color glow;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labelColor = foreground == Colors.white
        ? const Color(0xE6FFFFFF)
        : const Color(0xB31F1400);
    return Container(
      height: compact ? 146 : 162,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 26, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            top: -38,
            child: _DecoCircle(size: 118, color: Color(0x2EFFFFFF)),
          ),
          const Positioned(
            right: 44,
            bottom: -52,
            child: _DecoCircle(size: 94, color: Color(0x1FFFFFFF)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0x33FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 15, color: labelColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previousChildren, ?currentChild],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    value,
                    key: ValueKey<String>('number-$value'),
                    style: TextStyle(
                      fontSize: compact ? 58 : 72,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vòng tròn trang trí mờ trên thẻ gradient.
class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Ô số đang chờ trong dải "SỐ ĐANG ĐỢI".
class _WaitingChip extends StatelessWidget {
  const _WaitingChip({
    required this.number,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: 'Bệnh nhân số $number',
    child: AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: compact ? 54 : 76,
        height: compact ? 52 : 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? const Color(0xFFFFD400) : Colors.transparent,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x59FFB300)
                  : const Color(0x33EE2F26),
              blurRadius: selected ? 20 : 13,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: _Ui.redChip,
              borderRadius: BorderRadius.circular(13),
            ),
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Ô số trong bảng "Đợi / Gọi lại" (mục ĐANG CHỜ): bấm để cho số đó xin đợi.
/// Số kế tiếp có viền vàng để phân biệt.
class _SheetWaitChip extends StatelessWidget {
  const _SheetWaitChip({
    required this.number,
    required this.isNext,
    required this.onTap,
  });

  final int number;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: isNext ? 'Cho số kế tiếp $number xin đợi' : 'Cho số $number xin đợi',
    child: Container(
      width: 74,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isNext ? const Color(0xFFFFD400) : Colors.transparent,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext ? const Color(0x59FFB300) : const Color(0x2EEE2F26),
            blurRadius: isNext ? 18 : 11,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: _Ui.redChip,
            borderRadius: BorderRadius.circular(13),
          ),
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Ô số trong bảng "Đợi / Gọi lại" (mục ĐÃ KHÁM): bấm để gọi lại bệnh nhân.
class _RecallChip extends StatelessWidget {
  const _RecallChip({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Gọi lại bệnh nhân số $number',
    child: Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0x1F2AC653),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF25A94C),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$number',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _Ui.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ô số trong hàng "SỐ ĐÃ CHO QUA": bấm để mở màn hình chèn lại số đó.
class _DeferredChip extends StatelessWidget {
  const _DeferredChip({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Số $number đã bị cho qua, bấm để chèn lại',
    child: Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECF4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0x24FFB300),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 13,
                  color: Color(0xFFD98E00),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$number',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _Ui.chipIdleText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ô số trong bảng "Xác nhận vắng mặt" (chỉ gồm các số đã bấm "Đợi").
/// Bấm để chọn số cần ghi nhận vắng mặt.
class _AbsentChip extends StatelessWidget {
  const _AbsentChip({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ghi nhận bệnh nhân số $number vắng mặt',
    child: Container(
      width: 86,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2EEE2F26),
            blurRadius: 11,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: _Ui.redChip,
            borderRadius: BorderRadius.circular(13),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_rounded,
                      size: 11,
                      color: Color(0xD9FFFFFF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Đã cho qua',
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Thẻ thông báo từ bác sĩ: xanh khi đang khám, kem + icon cam khi tạm dừng.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.paused,
    required this.message,
    required this.footer,
  });

  final bool paused;
  final String message;
  final String footer;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOut,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    decoration: BoxDecoration(
      color: paused ? const Color(0xFFFFF8E8) : const Color(0xFFEAF9F0),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: paused ? const Color(0xFFFFE6BC) : const Color(0xFFCFF0DC),
      ),
      boxShadow: [
        BoxShadow(
          color: paused ? const Color(0x1FF5A623) : const Color(0x1F2AC653),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: paused ? const Color(0x2EF5A623) : const Color(0x2E2AC653),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: paused ? const Color(0xFFF5A623) : const Color(0xFF2AC653),
              shape: BoxShape.circle,
            ),
            child: Icon(
              paused ? Icons.pause_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paused ? 'Thông báo tạm dừng khám' : 'Thông báo từ Bác sĩ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: paused
                      ? const Color(0xFF6B4A00)
                      : const Color(0xFF14532C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12.2,
                  height: 1.55,
                  color: paused
                      ? const Color(0xFF8A6A2F)
                      : const Color(0xFF38624A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: paused
                          ? const Color(0xFFC9A96A)
                          : const Color(0xFF7FAE92),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    footer,
                    style: TextStyle(
                      fontSize: 10.3,
                      fontWeight: FontWeight.w500,
                      color: paused
                          ? const Color(0xFFB08F4E)
                          : const Color(0xFF8AA79A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Dòng gợi ý khi danh sách trống.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: _Ui.textFaint),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: _Ui.textFaint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

/// Nút hành động: biến thể chính (xanh dương), phụ (trắng) và nút xanh lá.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.iconLeading = false,
    this.color = Colors.white,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Nút chính màu xanh dương, chữ trắng.
  final bool primary;

  /// Đặt icon trước chữ (mặc định icon nằm sau chữ ở nút chính).
  final bool iconLeading;

  /// Màu nền nút: trắng (mặc định) hoặc xanh lá cho nút "Tiếp tục khám".
  final Color color;

  /// Nút phụ mang tính xoá/đặt lại: nền trắng, chữ và icon màu đỏ.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final isGreen = !primary && color != Colors.white;
    final filled = primary || isGreen;
    final gradient = primary
        ? _Ui.blueButton
        : (isGreen ? _Ui.greenButton : null);
    final foreground = filled
        ? Colors.white
        : (danger ? const Color(0xFFD64545) : _Ui.textPrimary);
    final iconColor = filled
        ? Colors.white
        : (danger ? const Color(0xFFE5483F) : const Color(0xFF6B7285));
    final leading = icon != null && (!primary || iconLeading);
    final shadow = primary
        ? _Ui.blueShadow
        : (isGreen ? _Ui.greenShadow : _Ui.quietShadow);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? Colors.white : null,
            borderRadius: BorderRadius.circular(17),
            border: filled
                ? null
                : Border.all(
                    color: danger
                        ? const Color(0xFFF6D5D2)
                        : const Color(0xFFE7EAF3),
                    width: 1.4,
                  ),
          ),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading) ...[
                        Icon(icon, size: 19, color: iconColor),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: foreground,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (icon != null && !leading) ...[
                        const SizedBox(width: 6),
                        Icon(icon, size: 19, color: iconColor),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
