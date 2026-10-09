import 'package:flutter/material.dart';

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

/// Trạng thái một lượt khám – giá trị lưu ở cột `trang_thai` trong CSDL.
enum VisitStatus {
  waiting('cho_kham'),
  inProgress('dang_kham'),
  deferred('xin_doi'),
  examConfirmed('da_xac_nhan_kham');

  const VisitStatus(this.dbValue);

  /// Giá trị dùng khi ghi xuống CSDL.
  final String dbValue;
}

/// Một lượt khám – ánh xạ 1-1 với 1 hàng trong bảng CSDL (ví dụ bảng
/// `luot_kham`). Dùng [toMap]/[fromMap] để ghi/đọc SQLite, REST API…
///
/// Gợi ý schema CSDL:
/// ```sql
/// CREATE TABLE luot_kham (
///   id                 INTEGER PRIMARY KEY AUTOINCREMENT,
///   ma_phien_kham      TEXT    NOT NULL,          -- phiên khám (ngày + phòng)
///   ma_phong_kham      TEXT,                      -- FK -> phong_kham.ma_phong
///   ma_nhan_vien       TEXT,                      -- FK -> nhan_vien.ma_nhan_vien
///   ma_benh_nhan       TEXT,                      -- FK -> benh_nhan.ma_benh_nhan
///   so_thu_tu          INTEGER NOT NULL,          -- số trong phiên
///   trang_thai         TEXT    NOT NULL,          -- cho_kham/dang_kham/xin_doi/da_xac_nhan_kham
///   da_xac_nhan_kham   INTEGER NOT NULL DEFAULT 0,
///   thoi_gian_goi      TEXT,
///   thoi_gian_xin_doi  TEXT,
///   thoi_gian_xac_nhan TEXT,
///   UNIQUE (ma_phien_kham, so_thu_tu)
/// );
/// ```
class VisitRecord {
  VisitRecord({
    required this.id,
    required this.number,
    this.sessionId = '',
    this.roomId,
    this.staffId,
    this.patientId,
    this.status = VisitStatus.waiting,
    this.examConfirmed = false,
    this.calledAt,
    this.deferredAt,
    this.confirmedAt,
  });

  /// Khóa chính của lượt khám (cột `id`, tự tăng trong CSDL).
  /// Ở tầng giao diện, id được cấp tuần tự bởi _QueueScreenState; khi ghi vào
  /// SQLite có thể bỏ qua cột này để CSDL tự sinh (AUTOINCREMENT).
  final int id;

  /// Số thứ tự bệnh nhân trong phiên khám (cột `so_thu_tu`).
  /// Duy nhất theo từng phiên: UNIQUE(ma_phien_kham, so_thu_tu).
  final int number;

  /// Mã phiên khám – gom các lượt của cùng một buổi/ngày (cột `ma_phien_kham`).
  final String sessionId;

  /// Mã phòng khám (cột `ma_phong_kham`).
  final String? roomId;

  /// Mã nhân viên phụ trách (cột `ma_nhan_vien`).
  final String? staffId;

  /// Mã bệnh nhân (cột `ma_benh_nhan`) – app điền sau khi tra cứu bệnh nhân.
  String? patientId;

  /// Trạng thái lượt khám (cột `trang_thai`).
  VisitStatus status;

  /// Mục "đã xác nhận khám": true khi bác sĩ xác nhận bệnh nhân đã khám xong.
  /// Được đặt khi nhấn nút "Tiếp theo" (cột `da_xac_nhan_kham`).
  bool examConfirmed;

  /// Thời điểm gọi vào phòng khám (cột `thoi_gian_goi`).
  DateTime? calledAt;

  /// Thời điểm bệnh nhân xin đợi (cột `thoi_gian_xin_doi`).
  DateTime? deferredAt;

  /// Thời điểm xác nhận khám xong (cột `thoi_gian_xac_nhan`).
  DateTime? confirmedAt;

  /// Đổ bản ghi sang map để ghi xuống CSDL.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'ma_phien_kham': sessionId,
    'ma_phong_kham': roomId,
    'ma_nhan_vien': staffId,
    'ma_benh_nhan': patientId,
    'so_thu_tu': number,
    'trang_thai': status.dbValue,
    'da_xac_nhan_kham': examConfirmed ? 1 : 0,
    'thoi_gian_goi': calledAt?.toIso8601String(),
    'thoi_gian_xin_doi': deferredAt?.toIso8601String(),
    'thoi_gian_xac_nhan': confirmedAt?.toIso8601String(),
  };

  /// Đọc một bản ghi từ hàng CSDL.
  factory VisitRecord.fromMap(Map<String, Object?> map) => VisitRecord(
    id: (map['id'] as num?)?.toInt() ?? 0,
    number: (map['so_thu_tu'] as num).toInt(),
    sessionId: '${map['ma_phien_kham'] ?? ''}',
    roomId: map['ma_phong_kham'] as String?,
    staffId: map['ma_nhan_vien'] as String?,
    patientId: map['ma_benh_nhan'] as String?,
    status: VisitStatus.values.firstWhere(
      (status) => status.dbValue == map['trang_thai'],
      orElse: () => VisitStatus.waiting,
    ),
    examConfirmed: (map['da_xac_nhan_kham'] as num? ?? 0) != 0,
    calledAt: DateTime.tryParse('${map['thoi_gian_goi'] ?? ''}'),
    deferredAt: DateTime.tryParse('${map['thoi_gian_xin_doi'] ?? ''}'),
    confirmedAt: DateTime.tryParse('${map['thoi_gian_xac_nhan'] ?? ''}'),
  );
}

/// Hành động ghi vào nhật ký sự kiện – giá trị cột `hanh_dong`.
enum VisitAction {
  created('tao_moi'),
  called('goi_so'),
  deferred('xin_doi'),
  recalled('goi_lai'),
  reinserted('chen_lai'),
  examConfirmed('xac_nhan_kham');

  const VisitAction(this.dbValue);

  /// Giá trị dùng khi ghi xuống CSDL.
  final String dbValue;
}

/// Một sự kiện của lượt khám – mỗi thao tác (gọi số, xin đợi, gọi lại, chèn
/// lại, xác nhận khám…) là 1 hàng trong bảng nhật ký `su_kien_luot_kham`.
///
/// Gợi ý schema CSDL:
/// ```sql
/// CREATE TABLE su_kien_luot_kham (
///   id           INTEGER PRIMARY KEY AUTOINCREMENT,
///   luot_kham_id INTEGER NOT NULL REFERENCES luot_kham(id),
///   so_thu_tu    INTEGER NOT NULL,
///   hanh_dong    TEXT    NOT NULL,   -- tao_moi/goi_so/xin_doi/goi_lai/chen_lai/xac_nhan_kham
///   vi_tri       INTEGER,            -- vị trí trong hàng chờ (khi chèn lại)
///   thoi_gian    TEXT    NOT NULL
/// );
/// ```
class VisitEvent {
  VisitEvent({
    required this.id,
    required this.visitId,
    required this.number,
    required this.action,
    required this.at,
    this.position,
  });

  /// Khóa chính của sự kiện (cột `id`).
  final int id;

  /// FK -> luot_kham.id (cột `luot_kham_id`).
  final int visitId;

  /// Số thứ tự trong phiên, lưu kèm cho tiện truy vấn (cột `so_thu_tu`).
  final int number;

  /// Hành động xảy ra (cột `hanh_dong`).
  final VisitAction action;

  /// Thời điểm xảy ra (cột `thoi_gian`).
  final DateTime at;

  /// Vị trí trong hàng chờ khi chèn lại (cột `vi_tri`, có thể null).
  final int? position;

  /// Đổ bản ghi sang map để ghi xuống CSDL.
  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'luot_kham_id': visitId,
    'so_thu_tu': number,
    'hanh_dong': action.dbValue,
    'vi_tri': position,
    'thoi_gian': at.toIso8601String(),
  };

  /// Đọc một bản ghi từ hàng CSDL.
  factory VisitEvent.fromMap(Map<String, Object?> map) => VisitEvent(
    id: (map['id'] as num?)?.toInt() ?? 0,
    visitId: (map['luot_kham_id'] as num?)?.toInt() ?? 0,
    number: (map['so_thu_tu'] as num?)?.toInt() ?? 0,
    action: VisitAction.values.firstWhere(
      (action) => action.dbValue == map['hanh_dong'],
      orElse: () => VisitAction.created,
    ),
    at: DateTime.tryParse('${map['thoi_gian'] ?? ''}') ?? DateTime.now(),
    position: (map['vi_tri'] as num?)?.toInt(),
  );
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({
    super.key,
    this.onVisitSaved,
    this.onEventSaved,
    this.sessionId = 'PK3-20260918-01',
    this.roomId = 'PK3',
    this.staffId = 'NV-VNT',
  });

  /// Callback ghi CSDL – được gọi mỗi khi một lượt khám thay đổi
  /// (gọi số, xác nhận khám, xin đợi, gọi lại, chèn lại, sinh số mới).
  /// Ví dụ với sqflite:
  ///   QueueScreen(onVisitSaved: (record) {
  ///     db.insert('luot_kham', record.toMap(),
  ///         conflictAlgorithm: ConflictAlgorithm.replace);
  ///   })
  final void Function(VisitRecord record)? onVisitSaved;

  /// Callback ghi nhật ký sự kiện – mỗi thao tác là 1 hàng cho bảng
  /// `su_kien_luot_kham` (dùng để tra soát lịch sử của từng lượt khám).
  ///   QueueScreen(onEventSaved: (event) => db.insert('su_kien_luot_kham', event.toMap()))
  final void Function(VisitEvent event)? onEventSaved;

  /// Mã phiên khám – gom các lượt của cùng một buổi/ngày (cột `ma_phien_kham`).
  final String sessionId;

  /// Mã phòng khám (cột `ma_phong_kham`).
  final String? roomId;

  /// Mã nhân viên phụ trách phòng khám (cột `ma_nhan_vien`).
  final String? staffId;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  /// Bắt đầu đánh số từ 1.
  int current = 1;
  int next = 2;

  /// Hàng đợi: luôn là MỘT HÀNG số tăng dần, gọi theo thứ tự từ đầu hàng.
  /// Mỗi lần một số rời hàng đợi, _refillQueue() tự sinh thêm số mới (+1)
  /// ở cuối nên dải số tự chạy và không bao giờ cạn.
  final List<int> waiting = <int>[3, 4, 5, 6, 7];

  /// Số lớn nhất đã phát ra, dùng để sinh số tiếp theo cho hàng đợi.
  int lastIssued = 7;

  /// Các số đã qua lượt:
  ///  - deferred = false: đã khám xong (dùng cho "Gọi lại số").
  ///  - deferred = true : bệnh nhân xin đợi (dùng cho "+ Chèn" để chèn lại).
  final List<PassedEntry> passed = <PassedEntry>[];

  /// "Bảng lượt khám" trong bộ nhớ – mỗi phần tử là 1 hàng CSDL.
  /// Đọc toàn bộ bằng [visitRows]; mỗi thay đổi được đẩy ra ngoài qua
  /// [QueueScreen.onVisitSaved] để app ghi xuống CSDL thật.
  final List<VisitRecord> visitDb = <VisitRecord>[];

  /// "Bảng nhật ký sự kiện" trong bộ nhớ – mỗi thao tác là 1 hàng CSDL.
  /// Đọc toàn bộ bằng [eventRows].
  final List<VisitEvent> eventDb = <VisitEvent>[];

  /// Bộ đếm cấp id tuần tự cho khóa chính (khi ghi SQLite thật có thể để
  /// AUTOINCREMENT tự sinh, id ở đây dùng cho tầng giao diện/bộ nhớ).
  int _visitIdSeq = 0;
  int _eventIdSeq = 0;

  /// Số ô hiển thị trong dải "SỐ ĐANG ĐỢI" và là mức tối thiểu của hàng chờ.
  static const int queueWindow = 5;

  int? selected;
  bool paused = false;
  String? message;

  @override
  void initState() {
    super.initState();
    // Khởi tạo bảng lượt khám cho các số đang có trên màn hình.
    _markInProgress(current);
    _markWaiting(next);
    for (final number in waiting) {
      _markWaiting(number);
    }
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
      _markWaiting(lastIssued);
    }
  }

  /// Toàn bộ bản ghi lượt khám dưới dạng map – sẵn sàng ghi vào bảng CSDL.
  List<Map<String, Object?>> get visitRows =>
      visitDb.map((record) => record.toMap()).toList();

  /// Toàn bộ nhật ký sự kiện dưới dạng map – sẵn sàng ghi vào bảng CSDL.
  List<Map<String, Object?>> get eventRows =>
      eventDb.map((event) => event.toMap()).toList();

  /// Lấy bản ghi của một số trong "bảng" (tự tạo hàng mới kèm id nếu chưa có).
  VisitRecord _recordFor(int number) {
    for (final record in visitDb) {
      if (record.number == number && record.sessionId == widget.sessionId) {
        return record;
      }
    }
    final record = VisitRecord(
      id: ++_visitIdSeq,
      number: number,
      sessionId: widget.sessionId,
      roomId: widget.roomId,
      staffId: widget.staffId,
    );
    visitDb.add(record);
    return record;
  }

  /// Ghi một sự kiện vào nhật ký (bảng `su_kien_luot_kham`).
  void _logEvent(int number, VisitAction action, {int? position}) {
    final record = _recordFor(number);
    final event = VisitEvent(
      id: ++_eventIdSeq,
      visitId: record.id, // FK -> luot_kham.id
      number: number,
      action: action,
      at: DateTime.now(),
      position: position,
    );
    eventDb.add(event);
    widget.onEventSaved?.call(event);
  }

  /// Ghi một bản ghi xuống CSDL.
  /// TODO(CSDL): thay phần thân bằng ghi thật, ví dụ:
  ///   sqflite: await db.insert('luot_kham', record.toMap(),
  ///                            conflictAlgorithm: ConflictAlgorithm.replace);
  ///   REST   : await http.post(Uri.parse('$baseUrl/luot_kham'),
  ///                            body: jsonEncode(record.toMap()));
  void _persistVisit(VisitRecord record) => widget.onVisitSaved?.call(record);

  /// Đánh dấu số đang chờ trong hàng đợi. Nếu là lượt mới hoàn toàn thì ghi
  /// thêm sự kiện "tạo mới" vào nhật ký.
  void _markWaiting(int number) {
    final isNew = !visitDb.any(
      (record) =>
          record.number == number && record.sessionId == widget.sessionId,
    );
    final record = _recordFor(number)
      ..status = VisitStatus.waiting
      ..examConfirmed = false;
    _persistVisit(record);
    if (isNew) _logEvent(number, VisitAction.created);
  }

  /// Đánh dấu số đang được khám (vừa được gọi vào phòng khám).
  void _markInProgress(int number) {
    final record = _recordFor(number)
      ..status = VisitStatus.inProgress
      ..examConfirmed = false
      ..calledAt = DateTime.now();
    _persistVisit(record);
    _logEvent(number, VisitAction.called);
  }

  /// Đánh dấu bệnh nhân xin đợi (qua lượt).
  void _markDeferred(int number) {
    final record = _recordFor(number)
      ..status = VisitStatus.deferred
      ..examConfirmed = false
      ..deferredAt = DateTime.now();
    _persistVisit(record);
    _logEvent(number, VisitAction.deferred);
  }

  /// Mục "đã xác nhận khám": đặt khi bác sĩ nhấn "Tiếp theo" cho bệnh nhân đã
  /// khám xong – đây là dữ liệu chính để ghi vào CSDL.
  void _markExamConfirmed(int number) {
    final record = _recordFor(number)
      ..status = VisitStatus.examConfirmed
      ..examConfirmed = true
      ..confirmedAt = DateTime.now();
    _persistVisit(record);
    _logEvent(number, VisitAction.examConfirmed);
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
        // Xác nhận khám: ghi số hiện tại vào danh sách đã khám và đánh dấu
        // "đã xác nhận khám" trong bảng lượt khám (để ghi CSDL).
        passed.add((number: current, deferred: false));
        _markExamConfirmed(finished);
      }
      current = next;
      next = waiting.removeAt(
        0,
      ); // hàng đợi không bao giờ rỗng nhờ _refillQueue()
      _refillQueue();
      _markInProgress(current); // bệnh nhân mới được gọi vào phòng khám
      if (selected != null && !waiting.contains(selected)) selected = null;
      message =
          'Đã xác nhận bệnh nhân số $finished khám xong.\n'
          'Đã gọi bệnh nhân số $current – vui lòng chờ bệnh nhân vào phòng khám.';
    });
  }

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
      _markDeferred(number); // ghi trạng thái "xin đợi" vào bảng lượt khám
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
      // Bệnh nhân vào phòng khám ngay: bỏ khỏi danh sách đã khám, sẽ được ghi
      // lại khi bác sĩ nhấn "Tiếp theo".
      passed.removeWhere((entry) => entry.number == picked && !entry.deferred);
      current = picked;
      next = previousCurrent;
      waiting.insert(
        0,
        previousNext,
      ); // số kế tiếp cũ chưa gọi -> về đầu hàng chờ
      // Cập nhật bảng lượt khám: số gọi lại đang khám, số kế tiếp cũ về hàng chờ.
      _markInProgress(picked);
      _markWaiting(previousNext);
      _logEvent(picked, VisitAction.recalled);
      _logEvent(previousNext, VisitAction.reinserted, position: 0);
      if (selected != null && !waiting.contains(selected)) selected = null;
      message =
          'Đã gọi lại bệnh nhân số $picked – số $picked đang khám.\n'
          'Số $previousCurrent trở thành số tiếp theo; số $previousNext quay lại đầu hàng chờ.';
    });
    notify('Mời bệnh nhân số $picked đến phòng khám 3.');
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
      _markWaiting(result.number); // số quay lại hàng chờ
      _logEvent(result.number, VisitAction.reinserted, position: index);
      selected = result.number;
      message =
          'Đã đưa số ${result.number} trở lại hàng chờ tại vị trí thứ ${index + 1}.';
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
                      12,
                      compact ? 16 : 22,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Giờ và ngày cố định để khớp ảnh mẫu.
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '08:42',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _Ui.textPrimary,
                              ),
                            ),
                            Text(
                              'Thứ Sáu, 18/09/2026',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _Ui.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
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
                                    'Khoa Tim - Bệnh viện Bạch Mai',
                                    style: TextStyle(
                                      fontSize: compact ? 16.5 : 19,
                                      fontWeight: FontWeight.w800,
                                      color: _Ui.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Row(
                                    children: [
                                      _PulseDot(),
                                      SizedBox(width: 6),
                                      Text(
                                        'Phòng khám 3 · BS. Vũ Nam Tuấn',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: _Ui.textSecondary,
                                          fontWeight: FontWeight.w500,
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
                      12,
                      compact ? 16 : 22,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Giờ và ngày cố định để khớp ảnh mẫu.
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '08:42',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _Ui.textPrimary,
                              ),
                            ),
                            Text(
                              'Thứ Sáu, 18/09/2026',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _Ui.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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

/// Thẻ thông báo từ bác sĩ: xanh khi đang khám, kem + icon cam khi tạm dừng.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.paused, required this.message});

  final bool paused;
  final String message;

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
                    'Phòng khám 3 · BS. Vũ Nam Tuấn · 08:42',
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

  @override
  Widget build(BuildContext context) {
    final isGreen = !primary && color != Colors.white;
    final filled = primary || isGreen;
    final gradient = primary
        ? _Ui.blueButton
        : (isGreen ? _Ui.greenButton : null);
    final foreground = filled ? Colors.white : _Ui.textPrimary;
    final iconColor = filled ? Colors.white : const Color(0xFF6B7285);
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
                : Border.all(color: const Color(0xFFE7EAF3), width: 1.4),
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
