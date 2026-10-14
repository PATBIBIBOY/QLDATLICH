import 'package:cloud_firestore/cloud_firestore.dart';

/// Service kết nối Firebase Firestore cho Module Lễ tân & CSKH C1 (Đinh Hoàng Cước)
/// Tuân thủ nguyên tắc ghi_chu_c1.md:
/// - Chỉ query dữ liệu cần thiết theo ID hoặc Collection cụ thể.
/// - Có cơ chế Fallback (dùng mock data nếu Firebase trống hoặc offline) để app luôn chạy mượt.
class FirebaseServiceC1 {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Đường dẫn chính xác tuyệt đối trên Firestore của C1:
  /// /Khoa/dFmZHBjFNUT1eRzJjXp5/danh_sach
  static const String duongDanKhoaCha = 'Khoa';
  static const String docKhoaChaId = 'dFmZHBjFNUT1eRzJjXp5';
  static const String subCollectionDanhSach = 'danh_sach';

  /// Lấy danh sách các chuyên khoa thời gian thực (Stream)
  /// Trỏ chính xác vào /Khoa/dFmZHBjFNUT1eRzJjXp5/danh_sach
  static Stream<List<Map<String, dynamic>>> streamDanhSachKhoa() {
    return _firestore
        .collection(duongDanKhoaCha)
        .doc(docKhoaChaId)
        .collection(subCollectionDanhSach)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final tenKhoa = data['tenKhoa'] ?? 'Khoa Khám';
        final phongDau = data['phongDau']?.toString() ?? '101';
        final soPhong = (data['soPhong'] as num?)?.toInt() ?? 1;
        final soCaMoiNgay = (data['soCaMoiNgay'] as num?)?.toInt() ?? 2;
        final trangThai = data['trangThai'] ?? 'dang_mo';

        return {
          'id': doc.id,
          'tenKhoa': tenKhoa,
          'phongDau': phongDau,
          'soPhong': soPhong,
          'soCaMoiNgay': soCaMoiNgay,
          'trangThai': trangThai,
          'moTaPhong': 'Phòng $phongDau • ${trangThai == 'dang_mo' ? 'Đang mở' : 'Tạm đóng'}',
        };
      }).toList();
    });
  }

  /// Lấy danh sách tên các khoa dạng `List<String>` để đưa vào Dropdown/Modal chọn khoa
  static Future<List<String>> layDanhSachTenKhoa() async {
    try {
      final snapshot = await _firestore
          .collection(duongDanKhoaCha)
          .doc(docKhoaChaId)
          .collection(subCollectionDanhSach)
          .get();

      if (snapshot.docs.isEmpty) return [];
      return snapshot.docs
          .map((doc) => (doc.data()['tenKhoa'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi lấy danh sách tên khoa từ Firebase: $e');
      return [];
    }
  }

  /// Lấy danh sách khoa 1 lần (Future)
  static Future<List<Map<String, dynamic>>> layDanhSachKhoaMotLan() async {
    try {
      final snapshot = await _firestore
          .collection(duongDanKhoaCha)
          .doc(docKhoaChaId)
          .collection(subCollectionDanhSach)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'tenKhoa': data['tenKhoa'] ?? 'Khoa Khám',
          'phongDau': data['phongDau']?.toString() ?? '101',
          'soPhong': (data['soPhong'] as num?)?.toInt() ?? 1,
          'soCaMoiNgay': (data['soCaMoiNgay'] as num?)?.toInt() ?? 2,
          'trangThai': data['trangThai'] ?? 'dang_mo',
          'moTaPhong': 'Phòng ${data['phongDau'] ?? '101'} • ${data['trangThai'] == 'dang_mo' ? 'Đang mở' : 'Tạm đóng'}',
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Lỗi lấy danh sách khoa từ Firebase: $e');
      return [];
    }
  }

  /// Khởi tạo dữ liệu mẫu lên Firebase cho C1 (Chuyên khoa, Bác sĩ, Lịch hẹn)
  /// Giúp C1 có ngay dữ liệu hoàn chỉnh trên Firebase chỉ bằng 1 nút bấm
  static Future<void> khoiTaoDuLieuMauC1() async {
    // 1. Khởi tạo danh sách Chuyên Khoa vào đúng cấu trúc Khoa -> default -> danh_sach
    final batch = _firestore.batch();
    final khoaRef = _firestore.collection('Khoa').doc('dFmZHBjFNUT1eRzJjXp5').collection('danh_sach');

    final danhSachKhoaMau = [
      {
        'id': 'ZQ8letlnFik9GO1LLxM8',
        'tenKhoa': 'KHOA TIM',
        'phongDau': '110',
        'soPhong': 1,
        'soCaMoiNgay': 2,
        'trangThai': 'dang_mo',
        'ngayTao': FieldValue.serverTimestamp(),
      },
      {
        'id': 'KHOA_NOI_TONG_QUAT',
        'tenKhoa': 'KHOA NỘI TỔNG QUÁT',
        'phongDau': '102',
        'soPhong': 2,
        'soCaMoiNgay': 2,
        'trangThai': 'dang_mo',
        'ngayTao': FieldValue.serverTimestamp(),
      },
      {
        'id': 'KHOA_NHI',
        'tenKhoa': 'KHOA NHI',
        'phongDau': '305',
        'soPhong': 1,
        'soCaMoiNgay': 2,
        'trangThai': 'dang_mo',
        'ngayTao': FieldValue.serverTimestamp(),
      },
      {
        'id': 'KHOA_RANG_HAM_MAT',
        'tenKhoa': 'KHOA RĂNG HÀM MẶT',
        'phongDau': '401',
        'soPhong': 1,
        'soCaMoiNgay': 2,
        'trangThai': 'dang_mo',
        'ngayTao': FieldValue.serverTimestamp(),
      },
      {
        'id': 'KHOA_MAT',
        'tenKhoa': 'KHOA MẮT',
        'phongDau': '204',
        'soPhong': 1,
        'soCaMoiNgay': 2,
        'trangThai': 'dang_mo',
        'ngayTao': FieldValue.serverTimestamp(),
      },
    ];

    for (var k in danhSachKhoaMau) {
      final id = k['id'] as String;
      final copyMap = Map<String, dynamic>.from(k)..remove('id');
      batch.set(khoaRef.doc(id), copyMap, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
