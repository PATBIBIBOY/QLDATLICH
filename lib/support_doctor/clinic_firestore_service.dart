import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'department_room_picker.dart';

/// Đọc danh sách khoa/phòng từ Cloud Firestore theo thời gian thực.
///
/// Cấu trúc dữ liệu của project hiện tại:
///
/// ```
/// BenhVien/{hospitalId}                { ten_benh_vien: "Bệnh viện ..." }
/// Khoa/{hospitalId}/danh_sach/{deptId} { ten_khoa: "Khoa ..." }
/// PhongKham/{roomId}                   { hospitalId: "BV001",
///                                         khoaId: "K001",
///                                         tenPhong: "NGT001",
///                                         tenKhoaGoc: "Khoa ...",
///                                         nhanVienId: "NV001" }
/// ```
///
/// Khoa nằm trong subcollection `danh_sach` dưới document bệnh viện,
/// còn phòng nằm ở collection gốc PhongKham dùng chung cho mọi bệnh
/// viện nên khi tải được lọc bằng điều kiện hospitalId == {hospitalId}.
/// Phòng thuộc khoa nào nhờ trường `khoaId` (khớp id document khoa).
/// Tên trường được đọc linh hoạt theo nhiều biến thể (kèm biến thể
/// snake_case dự phòng) — xem các hàm ánh xạ ở cuối file. Tên
/// collection và trường lọc khai báo tập trung ở đầu
/// [ClinicFirestoreService] để đổi nhanh nếu project đặt khác.
///
/// Trạng thái phiên khám (đang khám/tạm dừng, số đang chờ...) KHÔNG lưu ở
/// đây mà vẫn do RoomSessionStore trong bộ nhớ quản lý như trước đây; màn
/// hình chọn phòng chồng hai lớp dữ liệu đó lên nhau.
///
/// Cách nối app với project Firebase: xem FIREBASE_SETUP.md. Điểm vào:
/// main_firebase.dart.
class ClinicFirestoreService {
  ClinicFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection bệnh viện: BenhVien/{hospitalId} (ví dụ BenhVien/BV001).
  static const String hospitalsCollection = 'BenhVien';

  /// Collection gốc của khoa: Khoa/{hospitalId}/danh_sach/{mã khoa}.
  static const String departmentsCollection = 'Khoa';

  /// Collection gốc của phòng: PhongKham/{mã phòng}. Phòng của mọi
  /// bệnh viện nằm chung tại đây, lọc theo trường [roomHospitalField].
  static const String roomsCollection = 'PhongKham';

  /// Subcollection chứa danh sách khoa dưới mỗi bệnh viện.
  static const String listSubcollection = 'danh_sach';

  /// Trường trong document phòng chứa mã bệnh viện của phòng đó
  /// (PhongKham/{mã phòng}.hospitalId == mã bệnh viện đang tải).
  static const String roomHospitalField = 'hospitalId';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _departmentsOf(String hospitalId) =>
      _firestore
          .collection(departmentsCollection)
          .doc(hospitalId)
          .collection(listSubcollection);

  Query<Map<String, dynamic>> _roomsOf(String hospitalId) => _firestore
      .collection(roomsCollection)
      .where(roomHospitalField, isEqualTo: hospitalId);

  /// Theo dõi toàn bộ phòng của một bệnh viện theo thời gian thực.
  ///
  /// Nghe đồng thời danh sách khoa và danh sách phòng, ghép phòng vào
  /// khoa theo trường `khoaId` trong document phòng. Chỉ phát dữ liệu
  /// khi cả hai danh sách đã về ít nhất một lần (để giao diện hiện trạng
  /// thái đang tải thay vì nhấp nháy danh sách rỗng), sau đó phát lại mỗi
  /// khi có khoa/phòng nào thay đổi. Danh sách đã sắp theo tên khoa rồi
  /// theo mã phòng (PK2 đứng trước PK10).
  Stream<List<ClinicRoomData>> watchRooms({required String hospitalId}) {
    var departmentNames = <String, String>{};
    var rawRooms = <(String, Map<String, Object?>)>[];
    var hasDepartments = false;
    var hasRooms = false;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    departmentSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? roomSubscription;

    late final StreamController<List<ClinicRoomData>> controller;

    void emit() {
      if (controller.isClosed || !hasDepartments || !hasRooms) return;
      controller.add(
        clinicRoomsFromFirestore(
          hospitalId: hospitalId,
          departmentNames: departmentNames,
          rooms: rawRooms,
        ),
      );
    }

    void forwardError(Object error, StackTrace stackTrace) {
      if (!controller.isClosed) controller.addError(error, stackTrace);
    }

    controller = StreamController<List<ClinicRoomData>>(
      onListen: () {
        departmentSubscription = _departmentsOf(hospitalId).snapshots().listen((
          snapshot,
        ) {
          departmentNames = {
            for (final doc in snapshot.docs)
              doc.id: clinicDepartmentName(doc.id, doc.data()),
          };
          hasDepartments = true;
          emit();
        }, onError: forwardError);
        roomSubscription = _roomsOf(hospitalId).snapshots().listen((snapshot) {
          rawRooms = [for (final doc in snapshot.docs) (doc.id, doc.data())];
          hasRooms = true;
          emit();
        }, onError: forwardError);
      },
      onCancel: () async {
        await departmentSubscription?.cancel();
        await roomSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Theo dõi tên bệnh viện từ trường `ten_benh_vien` của document
  /// BenhVien/{hospitalId}; chưa có document/trường thì dùng [fallback].
  Stream<String> watchHospitalName({
    required String hospitalId,
    String fallback = 'Bệnh viện',
  }) {
    return _firestore
        .collection(hospitalsCollection)
        .doc(hospitalId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) return fallback;
          return clinicHospitalName(data, fallback: fallback);
        });
  }
}

/// Màn hình chọn khoa/phòng lấy danh sách phòng từ Cloud Firestore theo
/// thời gian thực, trên nền [ClinicRoomPickerScreen].
///
/// Tự hiển thị màn hình đang tải/lỗi; khi có dữ liệu thì chuyển cho
/// [ClinicRoomPickerScreen] như bình thường nên trạng thái phiên khám vẫn
/// được RoomSessionStore phủ lên. Nhớ gọi Firebase.initializeApp() trong
/// main() trước khi dùng (xem main_firebase.dart).
class FirestoreClinicRoomPickerScreen extends StatefulWidget {
  const FirestoreClinicRoomPickerScreen({
    super.key,
    required this.hospitalId,
    this.hospitalName,
    this.initialDepartment = 'Khoa Tim',
    this.service,
    this.onLogout,
  });

  /// Mã bệnh viện trên Firestore (ví dụ 'BV001' — document
  /// BenhVien/BV001, Khoa/BV001/danh_sach và các phòng trong
  /// PhongKham có hospitalId BV001).
  final String hospitalId;

  /// Tên bệnh viện hiển thị; để trống (null) thì tự lấy trường
  /// `ten_benh_vien` từ document BenhVien/{hospitalId} trên Firestore.
  final String? hospitalName;
  final String initialDepartment;

  /// Nguồn dữ liệu Firestore; để trống thì dùng [ClinicFirestoreService]
  /// mặc định (FirebaseFirestore.instance).
  final ClinicFirestoreService? service;
  final Future<void> Function()? onLogout;

  @override
  State<FirestoreClinicRoomPickerScreen> createState() =>
      _FirestoreClinicRoomPickerScreenState();
}

class _FirestoreClinicRoomPickerScreenState
    extends State<FirestoreClinicRoomPickerScreen> {
  late final ClinicFirestoreService _service;
  late Stream<List<ClinicRoomData>> _roomsStream;
  Stream<String>? _hospitalNameStream;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ClinicFirestoreService();
    _roomsStream = _service.watchRooms(hospitalId: widget.hospitalId);
    if (widget.hospitalName == null) {
      _hospitalNameStream = _service.watchHospitalName(
        hospitalId: widget.hospitalId,
      );
    }
  }

  void _retry() {
    setState(() {
      _roomsStream = _service.watchRooms(hospitalId: widget.hospitalId);
    });
  }

  Widget _roomsPicker(String hospitalName) =>
      StreamBuilder<List<ClinicRoomData>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _FirestoreLoadError(error: snapshot.error!, onRetry: _retry);
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const _FirestoreLoading();
          }
          return ClinicRoomPickerScreen(
            rooms: snapshot.data!,
            initialDepartment: widget.initialDepartment,
            hospitalName: hospitalName,
            onLogout: widget.onLogout,
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final providedName = widget.hospitalName;
    if (providedName != null) return _roomsPicker(providedName);
    return StreamBuilder<String>(
      stream: _hospitalNameStream,
      builder: (context, snapshot) =>
          _roomsPicker(snapshot.data ?? 'Bệnh viện'),
    );
  }
}

class _FirestoreLoading extends StatelessWidget {
  const _FirestoreLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải danh sách khoa/phòng…'),
        ],
      ),
    ),
  );
}

class _FirestoreLoadError extends StatelessWidget {
  const _FirestoreLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Không tải được dữ liệu từ Firebase.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Ánh xạ document Firestore → ClinicRoomData. Đây là các hàm thuần (chỉ
// nhận id + Map dữ liệu) để dễ kiểm thử và tái dùng khi đổi nguồn dữ liệu.
//
// Tên trường được đọc theo danh sách ưu tiên: tên thật trên project
// (Khoa/BenhVien dùng snake_case: ten_khoa, ten_benh_vien...; PhongKham
// dùng camelCase: khoaId, tenPhong, nhanVienId...) đứng đầu, kèm các
// biến thể còn lại để dữ liệu lệch chuẩn vẫn đọc được.
// ---------------------------------------------------------------------------

/// Giá trị String đầu tiên không rỗng trong các [keys] (đã cắt khoảng
/// trắng), không có thì trả về null.
String? _firstStringField(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

/// Tên bệnh viện từ document BenhVien/{hospitalId} (trường `ten_benh_vien`).
String clinicHospitalName(
  Map<String, Object?> data, {
  String fallback = 'Bệnh viện',
}) =>
    _firstStringField(data, const [
      'ten_benh_vien',
      'tenBenhVien',
      'ten_benhvien',
      'name',
      'ten',
    ]) ??
    fallback;

/// Tên khoa từ document khoa (trường `ten_khoa`); thiếu thì dùng mã khoa.
String clinicDepartmentName(String departmentId, Map<String, Object?> data) =>
    _firstStringField(data, const ['ten_khoa', 'tenKhoa', 'name', 'ten']) ??
    departmentId;

/// Mã khoa mà một phòng thuộc về, lấy từ document phòng (trường
/// `khoaId`); thiếu thì trả về chuỗi rỗng.
String clinicRoomDepartmentId(Map<String, Object?> data) =>
    _firstStringField(data, const [
      'khoaId',
      'id_khoa',
      'ma_khoa',
      'khoa_id',
      'idKhoa',
      'maKhoa',
      'departmentId',
    ]) ??
    '';

/// Dựng [ClinicRoomData] cho một phòng từ dữ liệu document của nó.
///
/// [departmentName] là tên khoa đã tra từ danh sách khoa; để trống thì
/// lần lượt dùng trường `ten_khoa` ngay trong document phòng rồi tới mã
/// khoa. Phòng mới lấy từ Firestore luôn ở trạng thái đang khám và chưa
/// có số liệu chờ/đã khám — phần trạng thái thật do RoomSessionStore phủ
/// lên khi phòng đã được mở trong phiên app.
ClinicRoomData clinicRoomFromFirestore({
  required String hospitalId,
  required String roomId,
  required Map<String, Object?> data,
  String departmentName = '',
}) {
  final departmentId = clinicRoomDepartmentId(data);
  final resolvedDepartmentName = departmentName.trim().isNotEmpty
      ? departmentName
      : (_firstStringField(data, const ['tenKhoaGoc', 'ten_khoa', 'tenKhoa']) ??
            departmentId);
  Object? startingRaw;
  for (final key in const ['so_bat_dau', 'startingNumber', 'soBatDau']) {
    if (data[key] is num) {
      startingRaw = data[key];
      break;
    }
  }
  return ClinicRoomData(
    hospitalId: hospitalId,
    departmentId: departmentId,
    id: roomId,
    name:
        _firstStringField(data, const [
          'ten_phong',
          'ten_phongkham',
          'ten_phong_kham',
          'tenPhong',
          'name',
          'ten',
        ]) ??
        roomId,
    department: resolvedDepartmentName,
    staffId:
        _firstStringField(data, const [
          'nhanVienId',
          'id_nhanvien',
          'ma_nhanvien',
          'nhan_vien_id',
          'staffId',
          'idNhanVien',
        ]) ??
        '',
    status: ClinicRoomStatus.open,
    currentNumber: startingRaw is num && startingRaw >= 1
        ? startingRaw.toInt()
        : 1,
    waitingCount: 0,
    examinedCount: 0,
  );
}

/// Ghép danh sách phòng thô với tên khoa ([departmentNames]: mã khoa →
/// tên khoa) thành danh sách phẳng đã sắp xếp: theo tên khoa, rồi mã
/// phòng (PK2 trước PK10), rồi tên phòng.
List<ClinicRoomData> clinicRoomsFromFirestore({
  required String hospitalId,
  required Map<String, String> departmentNames,
  required List<(String, Map<String, Object?>)> rooms,
}) {
  final result = <ClinicRoomData>[
    for (final (roomId, data) in rooms)
      clinicRoomFromFirestore(
        hospitalId: hospitalId,
        roomId: roomId,
        data: data,
        departmentName: departmentNames[clinicRoomDepartmentId(data)] ?? '',
      ),
  ];
  result.sort((a, b) {
    final byDepartment = a.department.toLowerCase().compareTo(
      b.department.toLowerCase(),
    );
    if (byDepartment != 0) return byDepartment;
    final byRoomId = compareClinicRoomIds(a.id, b.id);
    if (byRoomId != 0) return byRoomId;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return result;
}

/// So sánh mã phòng theo phần số ở cuối (PK2 < PK10); hai mã cùng phần số
/// hoặc không có số cuối thì so sánh chuỗi như thường.
int compareClinicRoomIds(String a, String b) {
  final numberA = _trailingNumber(a);
  final numberB = _trailingNumber(b);
  if (numberA != null && numberB != null && numberA != numberB) {
    return numberA.compareTo(numberB);
  }
  return a.compareTo(b);
}

int? _trailingNumber(String value) {
  final match = RegExp(r'(\d+)$').firstMatch(value);
  return match == null ? null : int.parse(match.group(1)!);
}
