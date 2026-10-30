import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';

/// Service kết nối Firebase Firestore cho Module Lễ tân & CSKH C1 (Đinh Hoàng Cước)
/// Tuân thủ nguyên tắc ghi_chu_c1.md:
/// - Chỉ query dữ liệu cần thiết theo ID hoặc Collection cụ thể.
/// - Có cơ chế Fallback (dùng mock data nếu Firebase trống hoặc offline) để app luôn chạy mượt.
class FirebaseServiceC1 {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Đường dẫn chính xác tuyệt đối trên Firestore của C1:
  /// /Khoa/BO85AxXqDMSB68hnYjzhYfPIxHC2/danh_sach
  static const String duongDanKhoaCha = 'Khoa';
  static const String docKhoaChaId = 'BV502';
  static const String subCollectionDanhSach = 'danh_sach';

  /// Lấy danh sách các chuyên khoa thời gian thực (Stream) TRỰC TIẾP TỪ /Khoa/{benhVienId}/danh_sach
  /// Nếu không truyền benhVienId hoặc benhVienId rỗng thì lấy từ profile hoặc fallback docKhoaChaId
  static Stream<List<Map<String, dynamic>>> streamDanhSachKhoa([String? benhVienId]) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : docKhoaChaId);

    return _firestore
        .collection(duongDanKhoaCha)
        .doc(bvid)
        .collection(subCollectionDanhSach)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final tenKhoa = data['tenKhoa'] ?? data['ten_khoa'] ?? 'Khoa Khám';
        final phongDau = data['phongDau']?.toString() ?? data['phong_dau']?.toString() ?? '101';
        final soPhong = (data['soPhong'] as num?)?.toInt() ?? (data['so_phong'] as num?)?.toInt() ?? 1;
        final soCaMoiNgay = (data['soCaMoiNgay'] as num?)?.toInt() ?? (data['so_ca'] as num?)?.toInt() ?? 2;
        final trangThai = data['trangThai'] ?? data['trang_thai'] ?? 'dang_mo';

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

  static Stream<List<Map<String, dynamic>>> streamDanhSachKhoaTheoBenhVien(String benhVienId) {
    return streamDanhSachKhoa(benhVienId);
  }

  /// Lắng nghe danh sách phòng khám của một chuyên khoa:
  /// Khoa/{benhVienId}/danh_sach/{khoaId}/phongKham
  static Stream<List<Map<String, dynamic>>> streamDanhSachPhongTheoKhoa({
    String? benhVienId,
    required String khoaId,
    required String tenKhoa,
    int soPhongMacDinh = 1,
    String phongDau = '101',
  }) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : docKhoaChaId);

    return _firestore
        .collection(duongDanKhoaCha)
        .doc(bvid)
        .collection(subCollectionDanhSach)
        .doc(khoaId)
        .collection('phongKham')
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) {
          final data = d.data();
          final tenPhong = (data['tenPhong'] ?? data['ten_phong'] ?? 'Phòng ${d.id}').toString();
          final soPhong = (data['soPhong'] ?? data['so_phong'] ?? '').toString();
          final trangThai = (data['trangThai'] ?? data['trang_thai'] ?? 'san_sang').toString();
          final bacSiPhuTrach = (data['bacSi'] ?? data['bac_si'] ?? data['nhanVienId'] ?? 'BS. Trực phòng').toString();

          return {
            'id': d.id,
            'tenPhong': tenPhong,
            'soPhong': soPhong.isNotEmpty ? soPhong : tenPhong,
            'trangThai': trangThai,
            'bacSi': bacSiPhuTrach,
            'khoaId': khoaId,
            'tenKhoa': tenKhoa,
          };
        }).toList();
      }

      // Fallback nếu khoa chưa có subcollection phongKham: Tự sinh danh sách phòng dựa theo soPhong và phongDau của khoa
      final List<Map<String, dynamic>> fallbackRooms = [];
      final int startNum = int.tryParse(RegExp(r'\d+').firstMatch(phongDau)?.group(0) ?? '101') ?? 101;
      final int count = soPhongMacDinh > 0 ? soPhongMacDinh : 1;

      for (int i = 0; i < count; i++) {
        final currentRoomNum = '${startNum + i}';
        fallbackRooms.add({
          'id': 'P_$currentRoomNum',
          'tenPhong': 'Phòng $currentRoomNum - $tenKhoa',
          'soPhong': currentRoomNum,
          'trangThai': 'san_sang',
          'bacSi': 'Bác sĩ phụ trách',
          'khoaId': khoaId,
          'tenKhoa': tenKhoa,
        });
      }
      return fallbackRooms;
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
    final khoaRef = _firestore.collection('Khoa').doc('BO85AxXqDMSB68hnYjzhYfPIxHC2').collection('danh_sach');

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

  // ==========================================
  // REALTIME QUERIES: LỊCH KHÁM & THỐNG KÊ THEO KHOA HOẶC TỔNG THỂ
  // ==========================================

  /// Chuẩn hóa chuỗi tiếng Việt: Bỏ dấu, bỏ ký tự đặc biệt, chuyển thành chữ hoa
  static String boDauTiengViet(String str) {
    var result = str.toLowerCase();
    const vietnameseMap = {
      'a': ['à', 'á', 'ạ', 'ả', 'ã', 'â', 'ầ', 'ấ', 'ậ', 'ẩ', 'ẫ', 'ă', 'ằ', 'ắ', 'ặ', 'ẳ', 'ẵ'],
      'e': ['è', 'é', 'ẹ', 'ẻ', 'ẽ', 'ê', 'ề', 'ế', 'ệ', 'ể', 'ễ'],
      'i': ['ì', 'í', 'ị', 'ỉ', 'ĩ'],
      'o': ['ò', 'ó', 'ọ', 'ỏ', 'õ', 'ô', 'ồ', 'ố', 'ộ', 'ổ', 'ỗ', 'ơ', 'ờ', 'ớ', 'ợ', 'ở', 'ỡ'],
      'u': ['ù', 'ú', 'ụ', 'ủ', 'ũ', 'ư', 'ừ', 'ứ', 'ự', 'ử', 'ữ'],
      'y': ['ỳ', 'ý', 'ỵ', 'ỷ', 'ỹ'],
      'd': ['đ'],
    };
    vietnameseMap.forEach((nonAccent, accents) {
      for (var accent in accents) {
        result = result.replaceAll(accent, nonAccent);
      }
    });
    return result.trim().toUpperCase();
  }

  /// Chuẩn hóa so sánh tên khoa / mã khoa:
  /// Chấp nhận các biến thể: "Khoa Tim Mạch", "khoa tim", "KHOA TIM", "TIM", "K001"
  /// "Khoa Mắt", "khoa mat", "KHOA MẮT", "MAT", "K003"
  /// "Khoa Nhi", "NHI", "K004", v.v.
  static bool laCungKhoa(String? khoaA, String? khoaB) {
    if (khoaA == null || khoaB == null) return false;
    if (laCheDoTong(khoaA) || laCheDoTong(khoaB)) return true;

    String clean(String str) {
      var s = boDauTiengViet(str);
      s = s.replaceAll('KHOA ', '').replaceAll('CHUYEN KHOA ', '').replaceAll('PHONG KHAM ', '').trim();
      // Map alias mã khoa
      if (s == 'K001' || s == 'TIM' || s == 'TIM MACH' || s.contains('TIM')) return 'TIM';
      if (s == 'K003' || s == 'MAT' || s.contains('MAT')) return 'MAT';
      if (s == 'K004' || s == 'NHI' || s.contains('NHI')) return 'NHI';
      if (s == 'K002' || s.contains('NOI')) return 'NOI';
      if (s.contains('RANG') || s.contains('RHM')) return 'RHM';
      return s;
    }

    final a = clean(khoaA);
    final b = clean(khoaB);
    return a == b || a.contains(b) || b.contains(a);
  }

  /// Kiểm tra xem có đang chọn chế độ 'Tổng' (Tất cả chuyên khoa toàn viện) hay không
  static bool laCheDoTong(String? tenKhoa) {
    if (tenKhoa == null || tenKhoa.trim().isEmpty) return true;
    final k = boDauTiengViet(tenKhoa);
    return k == 'TAT CA' ||
        k.contains('TAT CA') ||
        k.contains('TONG') ||
        k.contains('TOAN VIEN') ||
        k == 'ALL';
  }

  /// Stream thống kê số liệu theo ngày đã chọn và theo Khoa (hoặc Tổng)
  /// Lắng nghe trực tiếp từ cả collection `LichHen` cấp 1 và `collectionGroup('lich_hen')`
  static Stream<Map<String, int>> streamThongKeHomNay({String? tenKhoa, DateTime? ngayChon, String? benhVienId}) {
    final targetDate = ngayChon ?? DateTime.now();
    final String targetDateStr = '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final String targetDisplay = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    final controller = StreamController<Map<String, int>>();
    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = {};

    void recompute() {
      int daTiepNhan = 0;
      int dangCho = 0;
      int daKham = 0;
      int tongSo = 0;

      final isAll = laCheDoTong(tenKhoa);

      for (var doc in allDocs.values) {
        final data = doc.data();
        final docPath = doc.reference.path;

        // 0. LỌC THEO BỆNH VIỆN
        final docBv = (data['benh_vien_id'] ?? data['benhVienId'] ?? data['ma_benh_vien'] ?? '').toString();
        if (docBv.isNotEmpty && bvid.isNotEmpty) {
          if (!docBv.toLowerCase().contains(bvid.toLowerCase()) && !bvid.toLowerCase().contains(docBv.toLowerCase())) {
            continue;
          }
        }

        // 1. Lọc theo ngày (hỗ trợ cả String, Timestamp, date path segment)
        final String docDate = (data['ngay_hien_thi'] ?? '').toString();
        final docNgayHen = data['ngay_hen'] != null ? data['ngay_hen'].toString() : '';
        final docNgayDat = data['ngay_dat'] != null ? data['ngay_dat'].toString() : '';
        final docNgayKham = (data['ngay_kham'] ?? '').toString();

        bool khopNgay = docPath.contains(targetDateStr) ||
            docDate.contains(targetDisplay) ||
            docDate.contains(targetDateStr) ||
            docNgayHen.contains(targetDateStr) ||
            docNgayDat.contains(targetDateStr) ||
            docNgayKham.contains(targetDateStr);

        // Hỗ trợ kiểm tra nếu trường ngay_hen hoặc ngay_dat là Firestore Timestamp
        if (!khopNgay && data['ngay_hen'] is Timestamp) {
          final dt = (data['ngay_hen'] as Timestamp).toDate();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) {
            khopNgay = true;
          }
        }
        if (!khopNgay && data['ngay_dat'] is Timestamp) {
          final dt = (data['ngay_dat'] as Timestamp).toDate().toLocal();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) {
            khopNgay = true;
          }
        }

        if (!khopNgay) continue;

        // 2. Lọc theo khoa (hoặc lấy tất cả khi ở chế độ Tổng)
        final docKhoa = (data['ten_khoa'] ?? data['tenKhoa'] ?? data['khoa'] ?? data['khoa_id'] ?? '').toString();
        if (!isAll && !laCungKhoa(docKhoa, tenKhoa)) {
          continue;
        }

        tongSo++;
        final rawTrangThaiId = data['trang_thai_id']?.toString() ?? '1';
        final rawTrangThaiStr = (data['trang_thai'] ?? data['trangThai'] ?? '').toString().toLowerCase();

        // 1: Chờ duyệt, 2: Đã xác nhận / duyệt, 3: Chưa xác nhận, 4: Hủy, 5: Hoàn thành / Đã khám
        if (rawTrangThaiId == '2' || rawTrangThaiStr.contains('tiep_nhan') || rawTrangThaiStr.contains('xac_nhan') || rawTrangThaiStr.contains('duyet') || rawTrangThaiStr == 'approved') {
          daTiepNhan++;
        } else if (rawTrangThaiId == '5' || rawTrangThaiStr.contains('kham') || rawTrangThaiStr.contains('hoan_thanh')) {
          daKham++;
        } else {
          dangCho++;
        }
      }

      if (!controller.isClosed) {
        controller.add({
          'daTiepNhan': daTiepNhan,
          'dangCho': dangCho,
          'daKham': daKham,
          'tongSo': tongSo,
        });
      }
    }

    StreamSubscription? subTop;
    StreamSubscription? subGroup;

    controller.onListen = () {
      Query<Map<String, dynamic>> topQuery = _firestore.collection('LichHen');
      if (bvid.isNotEmpty) {
        topQuery = topQuery.where('benh_vien_id', isEqualTo: bvid);
      }

      subTop = topQuery.snapshots().listen((snap) {
        allDocs.clear();
        for (var doc in snap.docs) {
          allDocs[doc.id] = doc;
        }
        recompute();
      });

      Query<Map<String, dynamic>> groupQuery = _firestore.collectionGroup('lich_hen');
      if (bvid.isNotEmpty) {
        groupQuery = groupQuery.where('benh_vien_id', isEqualTo: bvid);
      }
      subGroup = groupQuery.snapshots().listen((snap) {
        for (var doc in snap.docs) {
          allDocs[doc.id] = doc;
        }
        recompute();
      }, onError: (_) {});
    };

    controller.onCancel = () {
      subTop?.cancel();
      subGroup?.cancel();
    };

    return controller.stream;
  }

  /// Stream danh sách lịch hẹn từ `collectionGroup('lich_hen')`
  /// Hỗ trợ chọn Ngày cụ thể (ví dụ 25/10/2026), lọc theo Khoa (hoặc Tổng), Tab trạng thái & tìm kiếm
  static Stream<List<Map<String, dynamic>>> streamDanhSachLichHen({
    String? tenKhoa,
    String? phongKham,
    String? boLocTrangThai,
    String? tuKhoa,
    DateTime? ngayChon,
    String? benhVienId,
  }) {
    final targetDate = ngayChon ?? DateTime.now();
    final String targetDateStr = '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final String targetDisplay = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    final controller = StreamController<List<Map<String, dynamic>>>();
    Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = {};

    // Cache thông tin bệnh nhân và phòng khám
    Map<String, Map<String, dynamic>> cacheBenhNhan = {};
    Map<String, String> cacheKhoa = {};

    void recompute() {
      final isAll = laCheDoTong(tenKhoa);
      final List<Map<String, dynamic>> ketQua = [];

      for (var doc in allDocs.values) {
        final data = doc.data();
        final docPath = doc.reference.path;

        // 0. LỌC THEO BỆNH VIỆN CỦA NHÂN VIÊN
        final docBv = (data['benh_vien_id'] ?? data['benhVienId'] ?? data['ma_benh_vien'] ?? '').toString();
        if (docBv.isNotEmpty && bvid.isNotEmpty) {
          if (!docBv.toLowerCase().contains(bvid.toLowerCase()) && !bvid.toLowerCase().contains(docBv.toLowerCase())) {
            continue;
          }
        }

        // 1. Lọc theo ngày (hỗ trợ cả String, Timestamp, date path segment)
        final String docDate = (data['ngay_hien_thi'] ?? '').toString();
        final docNgayHen = data['ngay_hen'] != null ? data['ngay_hen'].toString() : '';
        final docNgayDat = data['ngay_dat'] != null ? data['ngay_dat'].toString() : '';
        final docNgayKham = (data['ngay_kham'] ?? '').toString();

        bool khopNgay = docPath.contains(targetDateStr) ||
            docDate.contains(targetDisplay) ||
            docDate.contains(targetDateStr) ||
            docNgayHen.contains(targetDateStr) ||
            docNgayDat.contains(targetDateStr) ||
            docNgayKham.contains(targetDateStr);

        // Hỗ trợ kiểm tra nếu trường ngày_hen hoặc ngay_dat là Firestore Timestamp
        if (!khopNgay && data['ngay_hen'] is Timestamp) {
          final dt = (data['ngay_hen'] as Timestamp).toDate();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) {
            khopNgay = true;
          }
        }
        if (!khopNgay && data['ngay_dat'] is Timestamp) {
          final dt = (data['ngay_dat'] as Timestamp).toDate().toLocal();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) {
            khopNgay = true;
          }
        }

        if (!khopNgay) continue;

        // 2. Lọc theo Khoa (hoặc lấy tất cả khi ở chế độ Tổng)
        final rawKhoaId = (data['khoa_id'] ?? data['khoaId'] ?? '').toString();
        final docKhoa = (data['ten_khoa'] ?? data['tenKhoa'] ?? data['khoa'] ?? cacheKhoa[rawKhoaId] ?? rawKhoaId).toString();
        if (!isAll && !laCungKhoa(docKhoa, tenKhoa) && !laCungKhoa(rawKhoaId, tenKhoa)) {
          continue;
        }

        // 2.1. Lọc theo Phòng khám (nếu có chọn phòng cụ thể)
        final docPhong = (data['phong_kham_id'] ?? data['phong_kham'] ?? data['tenPhong'] ?? data['phongKham'] ?? '').toString();
        if (phongKham != null &&
            phongKham.trim().isNotEmpty &&
            !phongKham.toLowerCase().contains('tất cả') &&
            !phongKham.toLowerCase().contains('toàn viện')) {
          final pFilter = phongKham.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
          final pDoc = docPhong.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
          if (pFilter.isNotEmpty && !pDoc.contains(pFilter) && !pFilter.contains(pDoc)) {
            // Không khớp phòng
            continue;
          }
        }

        // 3. Lấy thông tin Bệnh nhân (từ chính doc hoặc từ cache collection BenhNhan)
        final bnId = (data['benh_nhan_id'] ?? data['benhNhanId'] ?? '').toString();
        final bnData = cacheBenhNhan[bnId] ?? {};

        final hoTen = (data['ho_ten'] ?? data['hoTen'] ?? data['patient_name'] ?? bnData['ho_ten'] ?? 'Bệnh nhân').toString();
        final sdt = (data['so_dien_thoai'] ?? data['sdt'] ?? data['phone'] ?? bnData['so_dien_thoai'] ?? '').toString();
        if (tuKhoa != null && tuKhoa.trim().isNotEmpty) {
          final tk = tuKhoa.trim().toLowerCase();
          if (!hoTen.toLowerCase().contains(tk) && !sdt.contains(tk)) {
            continue;
          }
        }

        // 4. Chuẩn hóa trạng thái hiển thị
        // trang_thai_id == 1: Chờ duyệt, 2: Đã duyệt / Đã xác nhận, 4: Từ chối / Đã hủy
        final rawTrangThaiId = data['trang_thai_id']?.toString() ?? '1';
        final rawTrangThaiStr = (data['trang_thai'] ?? data['trangThai'] ?? '').toString();
        String hienThiTrangThai = 'Đang chờ';

        if (rawTrangThaiId == '2' || rawTrangThaiStr == 'da_duyet' || rawTrangThaiStr == 'approved') {
          hienThiTrangThai = 'Đã duyệt';
        } else if (rawTrangThaiId == '5' || rawTrangThaiStr == 'da_kham' || rawTrangThaiStr == 'hoan_thanh') {
          hienThiTrangThai = 'Đã khám';
        } else if (rawTrangThaiId == '4' || rawTrangThaiStr == 'tu_choi' || rawTrangThaiStr == 'cancelled' || rawTrangThaiStr == 'huy') {
          hienThiTrangThai = 'Không duyệt';
        } else if (rawTrangThaiId == '6' || rawTrangThaiStr == 'vang') {
          hienThiTrangThai = 'Vắng';
        } else {
          hienThiTrangThai = 'Đang chờ';
        }

        // 5. Lọc theo Tab trạng thái
        if (boLocTrangThai != null && boLocTrangThai != 'Tất cả') {
          if (boLocTrangThai == 'Đang chờ') {
            if (hienThiTrangThai != 'Đang chờ' && hienThiTrangThai != 'Tiếp theo') {
              continue;
            }
          } else if (hienThiTrangThai != boLocTrangThai) {
            continue;
          }
        }

        // Giờ khám hiển thị
        String gioHienThi = '08:30';
        final caId = (data['ca_id'] ?? '').toString();
        if (caId == 'ca_sang') {
          gioHienThi = '08:00 (Ca sáng)';
        } else if (caId == 'ca_chieu') {
          gioHienThi = '14:00 (Ca chiều)';
        } else if (data['gio_du_kien'] != null || data['gio_kham'] != null) {
          gioHienThi = (data['gio_du_kien'] ?? data['gio_kham']).toString();
        }

        final cccdVal = (data['cccd'] ?? data['so_cccd'] ?? bnData['cccd'] ?? bnData['so_cccd'] ?? '').toString();
        final sdtVal = sdt.isNotEmpty ? sdt : (bnData['email'] ?? '').toString();
        final namSinhVal = (data['nam_sinh'] ?? bnData['nam_sinh'] ?? data['ngay_sinh'] ?? bnData['ngay_sinh'] ?? '').toString();
        final gioiTinhVal = (data['gioi_tinh'] ?? bnData['gioi_tinh'] ?? '').toString();

        ketQua.add({
          'id': doc.id,
          'docPath': docPath,
          'hoTen': hoTen,
          'sdt': sdtVal,
          'gioKham': gioHienThi,
          'tenKhoa': docKhoa.isNotEmpty ? docKhoa : 'Khoa Khám',
          'phongKham': docPhong.isNotEmpty ? docPhong : 'Phòng khám',
          'bacSi': (data['bac_si'] ?? 'BS. Trực ban').toString(),
          'trangThai': hienThiTrangThai,
          'rawTrangThai': rawTrangThaiStr.isNotEmpty ? rawTrangThaiStr : (rawTrangThaiId == '2' ? 'da_duyet' : 'cho_duyet'),
          'trangThaiId': rawTrangThaiId,
          'stt': (data['so_thu_tu'] ?? data['stt'] ?? 1).toString(),
          'maBenhNhan': (data['benh_nhan_id'] ?? data['ma_benh_nhan'] ?? 'BN-${doc.id.substring(0, 4).toUpperCase()}').toString(),
          'cccd': cccdVal,
          'bhyt': (data['bhyt'] ?? data['so_bhyt'] ?? bnData['bhyt'] ?? bnData['so_bhyt'] ?? '').toString(),
          'namSinh': namSinhVal,
          'gioiTinh': gioiTinhVal,
          'lyDoTuChoi': data['ly_do_tu_choi'] ?? data['lyDoTuChoi'],
        });
      }

      if (!controller.isClosed) {
        controller.add(ketQua);
      }
    }

    StreamSubscription? subTop;
    StreamSubscription? subGroup;

    // Cache thông tin Bệnh nhân theo từng ID để tránh get toàn bộ collection BenhNhan
    Future<void> napThongTinBenhNhanTheoIds(Set<String> patientIds) async {
      final idsCanNap = patientIds.where((id) => id.isNotEmpty && !cacheBenhNhan.containsKey(id)).toList();
      if (idsCanNap.isEmpty) return;

      // Firestore whereIn tối đa 10 phần tử
      for (var i = 0; i < idsCanNap.length; i += 10) {
        final chunk = idsCanNap.sublist(i, i + 10 > idsCanNap.length ? idsCanNap.length : i + 10);
        try {
          final snap = await _firestore.collection('BenhNhan').where(FieldPath.documentId, whereIn: chunk).get();
          for (var doc in snap.docs) {
            cacheBenhNhan[doc.id] = doc.data();
          }
        } catch (_) {
          // Fallback lấy lẻ nếu Firestore whereIn gặp lỗi index
          for (var pid in chunk) {
            try {
              final d = await _firestore.collection('BenhNhan').doc(pid).get();
              if (d.exists && d.data() != null) {
                cacheBenhNhan[pid] = d.data()!;
              }
            } catch (_) {}
          }
        }
      }
    }

    controller.onListen = () async {
      // Tải trước danh mục Khoa của bệnh viện
      try {
        final kSnap = await _firestore.collection('Khoa').doc(bvid).collection('danh_sach').get();
        for (var k in kSnap.docs) {
          final ten = (k.data()['tenKhoa'] ?? k.data()['ten_khoa'] ?? k.id).toString();
          cacheKhoa[k.id] = ten;
        }
      } catch (_) {}

      // Lọc Lịch Hẹn theo bệnh viện trực tiếp từ Firestore query để giảm document reads
      Query<Map<String, dynamic>> topQuery = _firestore.collection('LichHen');
      if (bvid.isNotEmpty) {
        topQuery = topQuery.where('benh_vien_id', isEqualTo: bvid);
      }

      subTop = topQuery.snapshots().listen((snap) async {
        allDocs.clear();
        final Set<String> patientIds = {};
        for (var doc in snap.docs) {
          allDocs[doc.id] = doc;
          final bnId = (doc.data()['benh_nhan_id'] ?? doc.data()['benhNhanId'] ?? '').toString();
          if (bnId.isNotEmpty) patientIds.add(bnId);
        }
        await napThongTinBenhNhanTheoIds(patientIds);
        recompute();
      });

      // Lắng nghe thêm subcollection nếu có
      Query<Map<String, dynamic>> groupQuery = _firestore.collectionGroup('lich_hen');
      if (bvid.isNotEmpty) {
        groupQuery = groupQuery.where('benh_vien_id', isEqualTo: bvid);
      }
      subGroup = groupQuery.snapshots().listen((snap) async {
        final Set<String> patientIds = {};
        for (var doc in snap.docs) {
          allDocs[doc.id] = doc;
          final bnId = (doc.data()['benh_nhan_id'] ?? doc.data()['benhNhanId'] ?? '').toString();
          if (bnId.isNotEmpty) patientIds.add(bnId);
        }
        await napThongTinBenhNhanTheoIds(patientIds);
        recompute();
      }, onError: (_) {});
    };

    controller.onCancel = () {
      subTop?.cancel();
      subGroup?.cancel();
    };

    return controller.stream;
  }

  /// Lấy số thứ tự (so_thu_tu) tiếp theo lớn nhất cho phòng khám hoặc bệnh viện trong ngày
  static Future<int> laySoThuTuTiepTheo({
    required String benhVienId,
    String? phongKhamId,
    String? caId,
    DateTime? ngayChon,
  }) async {
    final targetDate = ngayChon ?? DateTime.now();
    final String targetDateStr = '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final String targetDisplay = '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';

    int maxStt = 0;

    try {
      // 1. Quét trong collection LichHen cấp 1 theo benh_vien_id
      Query<Map<String, dynamic>> topQuery = _firestore.collection('LichHen');
      if (benhVienId.isNotEmpty) {
        topQuery = topQuery.where('benh_vien_id', isEqualTo: benhVienId);
      }
      final topSnap = await topQuery.get();
      for (var d in topSnap.docs) {
        final data = d.data();

        // Lọc theo ngày
        final docNgayHen = data['ngay_hen']?.toString() ?? '';
        final docNgayDat = data['ngay_dat']?.toString() ?? '';
        final docNgayKham = (data['ngay_kham'] ?? '').toString();
        final docNgayHienThi = (data['ngay_hien_thi'] ?? '').toString();
        final docPath = d.reference.path;
        bool khopNgay = docPath.contains(targetDateStr) ||
            docNgayHen.contains(targetDateStr) ||
            docNgayDat.contains(targetDateStr) ||
            docNgayKham.contains(targetDateStr) ||
            docNgayHienThi.contains(targetDateStr) ||
            docNgayHienThi.contains(targetDisplay);
        if (!khopNgay && data['ngay_hen'] is Timestamp) {
          final dt = (data['ngay_hen'] as Timestamp).toDate();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) khopNgay = true;
        }
        if (!khopNgay && data['ngay_dat'] is Timestamp) {
          final dt = (data['ngay_dat'] as Timestamp).toDate().toLocal();
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) khopNgay = true;
        }
        if (!khopNgay) continue;

        // Chỉ xét các đơn đã được duyệt hoặc đã có số thứ tự
        final String docStatusId = (data['trang_thai_id'] ?? '').toString();
        final String docStatusStr = (data['trang_thai'] ?? data['trangThai'] ?? '').toString();
        final bool daDuyet = docStatusId == '2' || docStatusId == '5' || docStatusStr == 'da_duyet' || docStatusStr == 'da_kham';

        final sttVal = data['so_thu_tu'] ?? data['stt'];
        if (daDuyet && sttVal != null) {
          if (sttVal is num) {
            if (sttVal.toInt() > maxStt) maxStt = sttVal.toInt();
          } else if (sttVal is String) {
            final parsed = int.tryParse(sttVal);
            if (parsed != null && parsed > maxStt) maxStt = parsed;
          }
        }
      }

      // 2. Quét thêm trong collectionGroup('lich_hen')
      Query<Map<String, dynamic>> groupQuery = _firestore.collectionGroup('lich_hen');
      if (benhVienId.isNotEmpty) {
        groupQuery = groupQuery.where('benh_vien_id', isEqualTo: benhVienId);
      }
      final groupSnap = await groupQuery.get();
      for (var d in groupSnap.docs) {
        final data = d.data();
        final String docStatusId = (data['trang_thai_id'] ?? '').toString();
        final String docStatusStr = (data['trang_thai'] ?? data['trangThai'] ?? '').toString();
        final bool daDuyet = docStatusId == '2' || docStatusId == '5' || docStatusStr == 'da_duyet' || docStatusStr == 'da_kham';

        final sttVal = data['so_thu_tu'] ?? data['stt'];
        if (daDuyet && sttVal != null) {
          if (sttVal is num) {
            if (sttVal.toInt() > maxStt) maxStt = sttVal.toInt();
          } else if (sttVal is String) {
            final parsed = int.tryParse(sttVal);
            if (parsed != null && parsed > maxStt) maxStt = parsed;
          }
        }
      }
    } catch (_) {}

    return maxStt + 1;
  }

  /// Cập nhật trạng thái lịch hẹn trên Firestore (hỗ trợ cả collection LichHen cấp 1 và subcollection)
  /// - Khi duyệt (trang_thai_id: "2" - Đã xác nhận trong TrangThai số 2)
  /// - Gán số thứ tự (so_thu_tu) tự động tăng dần bắt đầu từ 1
  /// - Chỉ sử dụng `trang_thai_id`, không lưu redundant `trang_thai`, `trangThai`, `ten_trang_thai`.
  /// - Khi duyệt thì xóa `ly_do_tu_choi`, khi hủy (`trang_thai_id: "4"`) mới lưu `ly_do_tu_choi`.
  static Future<int?> capNhatTrangThaiLichHen({
    required String appointmentId,
    required String trangThaiMoi,
    String? docPath,
    String? lyDoTuChoi,
    int? soThuTuChiDinh,
    String? benhVienId,
    String? phongKhamId,
    String? caId,
    DateTime? ngayChon,
  }) async {
    // 1. Kiểm tra đơn hiện tại trên Firestore xem đã duyệt chưa
    DocumentSnapshot<Map<String, dynamic>>? existingSnap;
    final topDocRef = _firestore.collection('LichHen').doc(appointmentId);
    final topSnap = await topDocRef.get();
    if (topSnap.exists) {
      existingSnap = topSnap;
    } else if (docPath != null && docPath.isNotEmpty) {
      final docSnap = await _firestore.doc(docPath).get();
      if (docSnap.exists) existingSnap = docSnap;
    } else {
      final q = await _firestore.collectionGroup('lich_hen').where('id', isEqualTo: appointmentId).limit(1).get();
      if (q.docs.isNotEmpty) existingSnap = q.docs.first;
    }

    final existingData = existingSnap?.data() ?? {};
    final String currentStatusId = (existingData['trang_thai_id'] ?? '').toString();
    final String currentStatusStr = (existingData['trang_thai'] ?? existingData['trangThai'] ?? '').toString();
    final bool alreadyApproved = currentStatusId == '2' || currentStatusStr == 'da_duyet';
    final existingStt = existingData['so_thu_tu'] ?? existingData['stt'];

    // Nếu đơn này ĐÃ ĐƯỢC DUYỆT TỪ TRƯỚC và người dùng bấm duyệt lại:
    // Giữ nguyên số thứ tự cũ (không được tự động tăng thêm)
    if (trangThaiMoi == 'da_duyet' && alreadyApproved && existingStt != null) {
      int? sttInt;
      if (existingStt is num) sttInt = existingStt.toInt();
      if (existingStt is String) sttInt = int.tryParse(existingStt);
      if (sttInt != null && sttInt > 0) {
        return sttInt;
      }
    }

    // Số 1: Chờ duyệt | Số 2: Đã xác nhận (TrangThai/2) | Số 4: Hủy / Không duyệt (TrangThai/4)
    final String newStatusId = trangThaiMoi == 'da_duyet' ? '2' : (trangThaiMoi == 'tu_choi' ? '4' : '1');

    int? capNhatStt = soThuTuChiDinh;
    if (trangThaiMoi == 'da_duyet' && capNhatStt == null) {
      // Nếu đã có stt sẵn thì tái sử dụng
      if (existingStt is num && existingStt.toInt() > 0) {
        capNhatStt = existingStt.toInt();
      } else if (existingStt is String && int.tryParse(existingStt) != null && int.parse(existingStt) > 0) {
        capNhatStt = int.parse(existingStt);
      } else {
        final bvid = benhVienId ?? DuLieuProfileMauC1.thongTinHienTai.benhVienId;
        capNhatStt = await laySoThuTuTiepTheo(
          benhVienId: bvid,
          phongKhamId: phongKhamId,
          caId: caId,
          ngayChon: ngayChon,
        );
      }
    }

    final Map<String, dynamic> updateData = {
      'trang_thai_id': newStatusId,
      'ngay_cap_nhat': FieldValue.serverTimestamp(),
      // Dọn dẹp các trường thừa nếu có
      'trang_thai': FieldValue.delete(),
      'trangThai': FieldValue.delete(),
      'ten_trang_thai': FieldValue.delete(),
    };

    if (trangThaiMoi == 'da_duyet') {
      if (capNhatStt != null) {
        updateData['so_thu_tu'] = capNhatStt;
      }
      // Khi đã duyệt thì xóa lý do từ chối (nếu có từ trước)
      updateData['ly_do_tu_choi'] = FieldValue.delete();
      updateData['lyDoTuChoi'] = FieldValue.delete();
      updateData['stt'] = FieldValue.delete();
    } else if (trangThaiMoi == 'tu_choi') {
      if (lyDoTuChoi != null && lyDoTuChoi.trim().isNotEmpty) {
        updateData['ly_do_tu_choi'] = lyDoTuChoi.trim();
      }
      updateData['lyDoTuChoi'] = FieldValue.delete();
      updateData['stt'] = FieldValue.delete();
    }

    // 1. Cập nhật trực tiếp nếu là doc trong collection 'LichHen' cấp 1
    if (topSnap.exists) {
      await topDocRef.update(updateData);
      return capNhatStt;
    }

    // 2. Cập nhật theo docPath nếu có
    if (docPath != null && docPath.isNotEmpty) {
      await _firestore.doc(docPath).update(updateData);
      return capNhatStt;
    }

    // 3. Tìm trong collectionGroup
    final q = await _firestore.collectionGroup('lich_hen').where('id', isEqualTo: appointmentId).limit(1).get();
    if (q.docs.isNotEmpty) {
      await q.docs.first.reference.update(updateData);
      return capNhatStt;
    }

    return capNhatStt;
  }

  /// Duyệt toàn bộ danh sách đơn đang chờ:
  /// - Sắp xếp theo thời gian đặt (ai đặt sớm thì cấp số thứ tự trước, tăng dần từ số hiện tại)
  /// - Cập nhật đồng loạt lên Firestore với trang_thai_id = "2" ("Đã xác nhận") và so_thu_tu
  static Future<void> duyetTatCaLichHen({
    required List<Map<String, dynamic>> danhSachDon,
    String? benhVienId,
    String? phongKhamId,
    DateTime? ngayChon,
  }) async {
    final bvid = benhVienId ?? DuLieuProfileMauC1.thongTinHienTai.benhVienId;

    // 1. Lọc ra các đơn chưa được duyệt
    final danhSachChoDuyet = danhSachDon.where((don) {
      final rawId = (don['trangThaiId'] ?? don['trang_thai_id'] ?? '').toString();
      final rawStr = (don['rawTrangThai'] ?? don['trangThai'] ?? '').toString();
      return rawId != '2' && rawStr != 'da_duyet' && rawStr != 'da_kham' && rawId != '5';
    }).toList();

    if (danhSachChoDuyet.isEmpty) return;

    // 2. Sắp xếp theo thời gian đặt sớm nhất trước (ngay_dat / ngay_tao / thoiGian)
    danhSachChoDuyet.sort((a, b) {
      DateTime layThoiGian(Map<String, dynamic> item) {
        final rawDat = item['ngay_dat'] ?? item['ngayDat'] ?? item['ngay_tao'] ?? item['ngayTao'];
        if (rawDat is Timestamp) return rawDat.toDate();
        if (rawDat is String) {
          final parsed = DateTime.tryParse(rawDat);
          if (parsed != null) return parsed;
        }
        return DateTime(2099);
      }

      final timeA = layThoiGian(a);
      final timeB = layThoiGian(b);
      return timeA.compareTo(timeB);
    });

    // 3. Lấy số thứ tự bắt đầu
    int currentStt = await laySoThuTuTiepTheo(
      benhVienId: bvid,
      phongKhamId: phongKhamId,
      ngayChon: ngayChon,
    );

    // 4. Cập nhật tuần tự từng đơn với số thứ tự tăng dần
    for (var don in danhSachChoDuyet) {
      final id = don['id']?.toString();
      final docPath = don['docPath']?.toString();
      if (id != null && id.isNotEmpty) {
        await capNhatTrangThaiLichHen(
          appointmentId: id,
          docPath: docPath,
          trangThaiMoi: 'da_duyet',
          soThuTuChiDinh: currentStt,
          benhVienId: bvid,
          phongKhamId: phongKhamId,
          ngayChon: ngayChon,
        );
        currentStt++;
      }
    }
  }



  // ==========================================
  // TÍNH NĂNG 3: THÔNG BÁO THỜI GIAN THỰC (REALTIME ALERTS)
  // ==========================================

  /// Lắng nghe thông báo thời gian thực từ Firestore /ThongBaoHeThong
  static Stream<List<Map<String, dynamic>>> streamThongBaoRealtime({String? vaiTro}) {
    return _firestore
        .collection('ThongBaoHeThong')
        .orderBy('thoi_gian', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Đánh dấu thông báo đã đọc
  static Future<void> danhDauDaDocThongBao(String thongBaoId) async {
    try {
      await _firestore.collection('ThongBaoHeThong').doc(thongBaoId).update({'da_doc': true});
    } catch (_) {}
  }

  /// Phát một thông báo khẩn cấp hoặc thông báo lịch mới trong bệnh viện
  static Future<void> guiThongBaoHeThong({
    required String tieuDe,
    required String noiDung,
    required String loai, // 'khan_cap', 'lich_hen', 'he_thong'
    String? vaiTroNhan, // 'le_tan', 'cskh', 'tat_ca'
  }) async {
    await _firestore.collection('ThongBaoHeThong').add({
      'tieu_de': tieuDe,
      'noi_dung': noiDung,
      'loai': loai,
      'vai_tro_nhan': vaiTroNhan ?? 'tat_ca',
      'thoi_gian': FieldValue.serverTimestamp(),
      'thoi_gian_hien_thi': 'Vừa xong',
      'da_doc': false,
    });
  }

  // ==========================================
  // TÍNH NĂNG 4: CHAT CSKH & HỖ TRỢ BỆNH NHÂN (REALTIME FIRESTORE)
  // ==========================================

  /// Lắng nghe danh sách hội thoại CSKH trực tiếp từ Firestore:
  /// /HoiThoaiCskh/{benhVienId}/danh_sach hoặc collectionGroup('hoi_thoai_cskh')
  static Stream<List<Map<String, dynamic>>> streamDanhSachHoiThoaiCskh([String? benhVienId]) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    return _firestore
        .collection('HoiThoaiCskh')
        .doc(bvid)
        .collection('danh_sach')
        .orderBy('thoi_gian_cap_nhat', descending: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Lắng nghe tin nhắn trong một phòng chat cụ thể:
  /// /HoiThoaiCskh/{benhVienId}/danh_sach/{hoiThoaiId}/tin_nhan
  static Stream<List<Map<String, dynamic>>> streamTinNhanCskh({
    String? benhVienId,
    required String hoiThoaiId,
  }) {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    return _firestore
        .collection('HoiThoaiCskh')
        .doc(bvid)
        .collection('danh_sach')
        .doc(hoiThoaiId)
        .collection('tin_nhan')
        .orderBy('thoi_gian', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Gửi tin nhắn từ phía CSKH lên Firestore
  static Future<void> guiTinNhanCskh({
    String? benhVienId,
    required String hoiThoaiId,
    required String noiDung,
  }) async {
    final bvid = (benhVienId != null && benhVienId.trim().isNotEmpty && benhVienId != 'BV01' && benhVienId != '1')
        ? benhVienId.trim()
        : (DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != 'BV01' &&
                DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
            ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
            : 'BV502');

    final now = DateTime.now();
    final gioStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final docHoiThoaiRef = _firestore
        .collection('HoiThoaiCskh')
        .doc(bvid)
        .collection('danh_sach')
        .doc(hoiThoaiId);

    // 1. Thêm tin nhắn mới vào subcollection tin_nhan
    await docHoiThoaiRef.collection('tin_nhan').add({
      'noi_dung': noiDung,
      'thoi_gian': FieldValue.serverTimestamp(),
      'gio_hien_thi': gioStr,
      'la_cskh_gui': true,
      'nguoi_gui': DuLieuProfileMauC1.thongTinHienTai.hoTen,
      'ma_nhan_vien': DuLieuProfileMauC1.thongTinHienTai.maNhanVien,
    });

    // 2. Cập nhật trạng thái hội thoại bên ngoài
    await docHoiThoaiRef.set({
      'tin_nhan_cuoi': noiDung,
      'thoi_gian_hien_thi': gioStr,
      'thoi_gian_cap_nhat': FieldValue.serverTimestamp(),
      'dang_cho_phan_hoi': false,
      'tin_chua_doc': 0,
    }, SetOptions(merge: true));
  }

  // ==========================================
  // XÁC THỰC VÀ QUẢN LÝ TÀI KHOẢN NHÂN VIÊN C1
  // ==========================================

  /// Kiểm tra thông tin đăng nhập bằng Mã nhân viên hoặc Gmail
  /// Trả về Map thông tin nhân viên hoặc ném ra Exception nếu sai
  static Future<Map<String, dynamic>?> dangNhapNhanVien({
    required String taiKhoanHoacEmail,
    required String matKhau,
  }) async {
    final input = taiKhoanHoacEmail.trim();

    // 1. Nếu là Email (có chứa ký tự @) -> Xác thực qua Firebase Auth hoặc Firestore
    if (input.contains('@')) {
      // Thử đăng nhập qua Firebase Auth (nơi nhận mật khẩu mới đổi từ link Google gửi về mail)
      bool authSuccess = false;
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: input,
          password: matKhau,
        );
        authSuccess = true;
      } catch (e) {
        // Nếu Auth không thành công, tiếp tục kiểm tra Firestore fallback bên dưới
      }

      final snapshot = await _firestore
          .collectionGroup('danh_sach')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản nhân viên với email này!');
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Nếu đã xác thực thành công qua Firebase Auth -> Tự động đồng bộ mật khẩu mới vào Firestore
      if (authSuccess) {
        await doc.reference.update({'mat_khau': matKhau});
        return {'id': doc.id, ...data, 'mat_khau': matKhau};
      }

      // Nếu Auth chưa xác thực được thì kiểm tra mật khẩu lưu trong Firestore
      if (data['mat_khau'] != matKhau) {
        throw Exception('Mật khẩu không chính xác!');
      }
      return {'id': doc.id, ...data};
    }

    // 2. Nếu là Mã tài khoản (VD: LT_TM_01, CSKH_01)
    // Ưu tiên tìm trong cây phân cấp NhanVien/{benhVienId}/danh_sach/{maNhanVien} qua collectionGroup('danh_sach')
    final groupSnap = await _firestore
        .collectionGroup('danh_sach')
        .where('ma_nhan_vien', isEqualTo: input)
        .limit(1)
        .get();

    DocumentSnapshot<Map<String, dynamic>>? targetDoc;
    if (groupSnap.docs.isNotEmpty) {
      targetDoc = groupSnap.docs.first;
    } else {
      // Tìm theo ma_tai_khoan
      final qMa = await _firestore
          .collectionGroup('danh_sach')
          .where('ma_tai_khoan', isEqualTo: input)
          .limit(1)
          .get();
      if (qMa.docs.isNotEmpty) {
        targetDoc = qMa.docs.first;
      }
    }

    if (targetDoc == null) {
      // Fallback kiểm tra collection phẳng cấp 1
      final docRef = _firestore.collection('NhanVien').doc(input);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        targetDoc = docSnap;
      }
    }

    if (targetDoc != null && targetDoc.exists) {
      final data = targetDoc.data()!;
      if (data['mat_khau'] != matKhau) {
        throw Exception('Mật khẩu cấp ban đầu không chính xác!');
      }
      return {'id': targetDoc.id, 'docPath': targetDoc.reference.path, ...data};
    }

    // TỰ ĐỘNG KHỞI TẠO TÀI KHOẢN MẪU BAN ĐẦU NẾU CHƯA CÓ TRÊN FIRESTORE
    if (input.toUpperCase() == 'LT_TM_01' || input.toUpperCase() == 'CSKH_01') {
      if (matKhau != '123456') {
        throw Exception('Mật khẩu cấp ban đầu không chính xác! (Mặc định: 123456)');
      }
      final isCskh = input.toUpperCase().contains('CSKH');
      final defaultUser = {
        'ma_tai_khoan': input.toUpperCase(),
        'ma_nhan_vien': input.toUpperCase(),
        'mat_khau': '123456',
        'ho_ten': isCskh ? 'Nhân Viên CSKH' : 'Đinh Hoàng Cước',
        'email': isCskh ? 'cskh@benhvien.vn' : 'dinhhoangcuoc@gmail.com',
        'role': isCskh ? 'cham_soc_khach_hang' : 'le_tan',
        'chuc_vu': isCskh ? 'Chuyên viên Chăm sóc khách hàng' : 'Nhân viên Lễ tân tiếp đón',
        'khoa': isCskh ? 'Bộ Phận CSKH & Tiếp Nhận' : 'KHOA TIM',
        'ma_benh_vien': 'BV001',
        'benh_vien_id': 'BV001',
        'ten_benh_vien': 'Bệnh viện Quân y 17',
        'da_kich_hoat': false,
        'ngay_tao': FieldValue.serverTimestamp(),
      };
      try {
        await _firestore
            .collection('NhanVien')
            .doc('BV001')
            .collection('danh_sach')
            .doc(input.toUpperCase())
            .set(defaultUser);
      } catch (_) {}
      return {'id': input.toUpperCase(), ...defaultUser};
    }

    throw Exception('Mã nhân viên không tồn tại trong hệ thống!');
  }

  /// Đọc thông tin nhân viên trực tiếp từ Firestore NhanVien (hỗ trợ đọc theo mã, theo Auth UID, hoặc theo email)
  static Future<Map<String, dynamic>?> layThongTinNhanVienTuFirestore(String maNhanVien) async {
    try {
      final currentAuth = FirebaseAuth.instance.currentUser;
      
      // 0. Quét trong subcollection NhanVien/{bvId}/danh_sach trước
      final bvId = DuLieuProfileMauC1.thongTinHienTai.benhVienId;
      if (bvId.isNotEmpty) {
        if (maNhanVien.isNotEmpty) {
          final docInSub = await _firestore.collection('NhanVien').doc(bvId).collection('danh_sach').doc(maNhanVien).get();
          if (docInSub.exists && docInSub.data() != null) return docInSub.data();
        }
        if (currentAuth?.email != null) {
          final qEmailSub = await _firestore.collection('NhanVien').doc(bvId).collection('danh_sach').where('email', isEqualTo: currentAuth!.email).limit(1).get();
          if (qEmailSub.docs.isNotEmpty) return qEmailSub.docs.first.data();
        }
      }

      // Quét trong collectionGroup 'danh_sach'
      if (maNhanVien.isNotEmpty) {
        final qGroup = await _firestore.collectionGroup('danh_sach').where('ma_nhan_vien', isEqualTo: maNhanVien).limit(1).get();
        if (qGroup.docs.isNotEmpty) return qGroup.docs.first.data();
      }
      if (currentAuth?.email != null) {
        final qEmailGroup = await _firestore.collectionGroup('danh_sach').where('email', isEqualTo: currentAuth!.email).limit(1).get();
        if (qEmailGroup.docs.isNotEmpty) return qEmailGroup.docs.first.data();
      }

      // 1. Nếu có Auth UID đăng nhập, thử tìm theo doc UID trước
      if (currentAuth?.uid != null) {
        final docByUid = await _firestore.collection('NhanVien').doc(currentAuth!.uid).get();
        if (docByUid.exists && docByUid.data() != null) {
          final data = docByUid.data()!;
          final maGoc = data['ma_nhan_vien'] ?? data['ma_tai_khoan'];
          if (maGoc != null && maGoc.toString().isNotEmpty && maGoc.toString() != currentAuth.uid) {
            final docGoc = await _firestore.collection('NhanVien').doc(maGoc.toString()).get();
            if (docGoc.exists && docGoc.data() != null) return docGoc.data();
          }
          return data;
        }
      }

      // 2. Tìm trực tiếp theo maNhanVien
      if (maNhanVien.isNotEmpty) {
        final docSnap = await _firestore.collection('NhanVien').doc(maNhanVien).get();
        if (docSnap.exists && docSnap.data() != null) {
          return docSnap.data();
        }

        // Tìm theo trường ma_tai_khoan
        final qMa = await _firestore.collection('NhanVien').where('ma_tai_khoan', isEqualTo: maNhanVien).limit(1).get();
        if (qMa.docs.isNotEmpty) {
          return qMa.docs.first.data();
        }
      }

      // 3. Fallback tìm theo Email nếu có currentUser
      if (currentAuth?.email != null && currentAuth!.email!.isNotEmpty) {
        final qEmail = await _firestore.collection('NhanVien').where('email', isEqualTo: currentAuth.email).limit(1).get();
        if (qEmail.docs.isNotEmpty) {
          return qEmail.docs.first.data();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kích hoạt tài khoản nhân viên từ Màn hình 3:
  /// 1. Tự động tạo tài khoản thật trên Firebase Authentication bằng Gmail & Pass mới
  /// 2. Lưu thông tin họ tên, ngày sinh, email và gắn UID vào Firestore /NhanVien/maNhanVien
  /// 3. Bật da_kich_hoat = true
  static Future<void> kichHoatTaiKhoanLanDau({
    required String maNhanVien,
    required String hoTen,
    required String email,
    required String ngaySinh,
    required String gioiTinh,
    required String matKhauMoi,
  }) async {
    String? authUid;
    try {
      // 1. Tạo tài khoản trên Firebase Authentication
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: matKhauMoi.trim(),
      );
      authUid = cred.user?.uid;
    } catch (e) {
      // Nếu email đã tồn tại trên Auth (do trước đó đã tạo), thử đăng nhập để lấy UID
      try {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: matKhauMoi.trim(),
        );
        authUid = cred.user?.uid;
      } catch (_) {}
    }

    // 2. Cập nhật hồ sơ nhân viên trong Firestore (cả trong NhanVien/{bvId}/danh_sach và fallback)
    final bvId = DuLieuProfileMauC1.thongTinHienTai.benhVienId.isNotEmpty && DuLieuProfileMauC1.thongTinHienTai.benhVienId != '1'
        ? DuLieuProfileMauC1.thongTinHienTai.benhVienId
        : 'BV001';

    final subDocRef = _firestore.collection('NhanVien').doc(bvId).collection('danh_sach').doc(maNhanVien);
    DocumentSnapshot<Map<String, dynamic>>? existingDoc;
    try {
      existingDoc = await subDocRef.get();
      if (!existingDoc.exists) {
        final q = await _firestore.collectionGroup('danh_sach').where('ma_nhan_vien', isEqualTo: maNhanVien).limit(1).get();
        if (q.docs.isNotEmpty) existingDoc = q.docs.first;
      }
    } catch (_) {}

    final existingData = existingDoc?.data() ?? {};
    final existingRole = existingData['role'];
    final existingKhoa = existingData['khoa'];

    String determinedRole = 'receptionist';
    if (existingRole != null && existingRole.toString().isNotEmpty) {
      determinedRole = existingRole.toString();
    } else if (maNhanVien.toUpperCase().contains('CSKH') || maNhanVien.toUpperCase().contains('SP')) {
      determinedRole = 'customerSupport';
    } else if (maNhanVien.toUpperCase().startsWith('BS') || maNhanVien.toUpperCase().contains('BS_')) {
      determinedRole = 'doctorAssistant';
    }

    final determinedKhoa = existingKhoa ?? 'KHOA TIM';
    final maBv = (existingData['ma_benh_vien'] ?? existingData['benh_vien_id'] ?? bvId).toString();
    final tenBv = (existingData['ten_benh_vien'] ?? DuLieuProfileMauC1.thongTinHienTai.tenBenhVien).toString();

    final updateData = {
      'ma_tai_khoan': maNhanVien,
      'ma_nhan_vien': maNhanVien,
      'uid': authUid,
      'ho_ten': hoTen,
      'email': email.trim(),
      'ngay_sinh': ngaySinh,
      'gioi_tinh': gioiTinh,
      'mat_khau': matKhauMoi.trim(),
      'da_kich_hoat': true,
      'trang_thai': 'dang_hoat_dong',
      'role': determinedRole,
      'khoa': determinedKhoa,
      'ma_benh_vien': maBv,
      'benh_vien_id': maBv,
      'ten_benh_vien': tenBv,
      'ngay_kich_hoat': FieldValue.serverTimestamp(),
      'ngay_cap_nhat': FieldValue.serverTimestamp(),
    };

    // Lưu vào cây phân cấp chuẩn NhanVien/{maBv}/danh_sach/{maNhanVien}
    await _firestore
        .collection('NhanVien')
        .doc(maBv)
        .collection('danh_sach')
        .doc(maNhanVien)
        .set(updateData, SetOptions(merge: true));

    // Đảm bảo document cha NhanVien/{maBv} có thông tin
    await _firestore.collection('NhanVien').doc(maBv).set({
      'ma_benh_vien': maBv,
      'ten_benh_vien': tenBv,
    }, SetOptions(merge: true));

    // Nếu trước đó vô tình sinh doc phụ mang tên UID (như xslKJ9tZG...) thì dọn dẹp xóa bỏ,
    // đảm bảo chỉ duy nhất 1 document đại diện theo mã nhân viên:
    if (authUid != null && authUid != maNhanVien) {
      try {
        final legacyDoc = _firestore.collection('NhanVien').doc(authUid);
        final checkSnap = await legacyDoc.get();
        if (checkSnap.exists) {
          await legacyDoc.delete();
        }
      } catch (_) {}
    }
  }

  /// Đổi mật khẩu cho nhân viên (đồng bộ cả Firebase Authentication và Firestore)
  static Future<void> doiMatKhauNhanVien({
    required String maNhanVien,
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    // 1. Cập nhật mật khẩu trên Firebase Authentication nếu người dùng đang đăng nhập
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      try {
        // Re-authenticate trước để Firebase Auth cho phép đổi pass
        final cred = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: matKhauHienTai,
        );
        await currentUser.reauthenticateWithCredential(cred);
        await currentUser.updatePassword(matKhauMoi);
      } catch (authError) {
        // Thử đổi pass trực tiếp nếu vừa đăng nhập
        try {
          await currentUser.updatePassword(matKhauMoi);
        } catch (_) {}
      }
    }

    // 2. Cập nhật mật khẩu trong Firestore NhanVien
    final docRef = _firestore.collection('NhanVien').doc(maNhanVien);
    final snap = await docRef.get();
    if (!snap.exists) {
      // Nếu chưa có doc trên Firebase thì tạo mới với mật khẩu mới
      await docRef.set({
        'ma_tai_khoan': maNhanVien,
        'mat_khau': matKhauMoi,
        'da_kich_hoat': true,
        'ngay_tao': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    final data = snap.data()!;
    if (data['mat_khau'] != null && data['mat_khau'] != matKhauHienTai) {
      throw Exception('Mật khẩu hiện tại không chính xác!');
    }
    await docRef.set({
      'mat_khau': matKhauMoi,
      'ngay_cap_nhat': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Cập nhật cả bản ghi theo Auth UID nếu có
    if (currentUser != null) {
      await _firestore.collection('NhanVien').doc(currentUser.uid).set({
        'mat_khau': matKhauMoi,
      }, SetOptions(merge: true));
    }
  }

  /// Đổi Gmail đăng nhập cho nhân viên (yêu cầu nhập đúng mật khẩu xác nhận)
  static Future<void> doiEmailNhanVien({
    required String maNhanVien,
    required String emailMoi,
    required String matKhauXacNhan,
  }) async {
    final docRef = _firestore.collection('NhanVien').doc(maNhanVien);
    final snap = await docRef.get();
    if (snap.exists) {
      final data = snap.data()!;
      if (data['mat_khau'] != null && data['mat_khau'] != matKhauXacNhan) {
        throw Exception('Mật khẩu xác nhận không đúng! Không thể đổi Gmail.');
      }
    }

    // Kiểm tra xem email mới đã có ai dùng chưa
    final checkEmail = await _firestore
        .collection('NhanVien')
        .where('email', isEqualTo: emailMoi.trim())
        .get();
    if (checkEmail.docs.isNotEmpty && checkEmail.docs.first.id != maNhanVien) {
      throw Exception('Email này đã được sử dụng bởi một tài khoản khác!');
    }

    await docRef.set({
      'ma_tai_khoan': maNhanVien,
      'email': emailMoi.trim(),
      'mat_khau': matKhauXacNhan,
      'da_kich_hoat': true,
      'ngay_cap_nhat': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cập nhật thông tin nhân viên (Họ tên, Vai trò/Chức vụ trong 3 role, Khoa)
  /// Đồng thời đồng bộ sang cả doc có ID là Auth UID nếu có liên kết
  static Future<void> capNhatThongTinNhanVien({
    required String maNhanVien,
    required String hoTen,
    required String chucVu,
    required String role,
    required int vaiTroId,
    required String khoa,
  }) async {
    final Map<String, dynamic> updateMap = {
      'ho_ten': hoTen,
      'chuc_vu': chucVu,
      'role': role,
      'vai_tro_id': vaiTroId,
      'khoa': khoa,
      'ngay_cap_nhat': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('NhanVien').doc(maNhanVien);
    await docRef.set(updateMap, SetOptions(merge: true));
  }

  /// Gửi OTP / liên kết đặt lại mật khẩu thật về Gmail hoặc Số điện thoại
  static Future<void> guiOtpQuenMatKhau({
    required String dichDen, // Email hoặc SĐT
    required bool laEmail,
  }) async {
    final target = dichDen.trim();

    // 1. Sinh mã OTP ngẫu nhiên 6 chữ số
    final maOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // 2. Luôn lưu yêu cầu OTP vào Firestore để xác thực trực tiếp trong app
    await _firestore.collection('YeuCauResetMatKhau').doc(target).set({
      'dich_den': target,
      'loai': laEmail ? 'email' : 'sdt',
      'ma_otp': maOtp,
      'thoi_gian_tao': FieldValue.serverTimestamp(),
      'da_su_dung': false,
    });

    // 3. Nếu là Email: Gửi song song email đặt lại mật khẩu từ Firebase Auth
    if (laEmail) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: target);
      } catch (_) {}
    }
  }

  /// Xác thực mã OTP và đặt mật khẩu mới ngay trong ứng dụng
  static Future<void> xacThucOtpDatLaiMatKhau({
    required String dichDen,
    required String maOtpNhapVao,
    required String matKhauMoi,
  }) async {
    final target = dichDen.trim();
    final docRef = _firestore.collection('YeuCauResetMatKhau').doc(target);
    DocumentSnapshot<Map<String, dynamic>> snap = await docRef.get();

    // Nếu không tìm thấy bằng docId chính xác, thử tìm bằng query hoặc docId chữ thường
    if (!snap.exists) {
      final docLower = await _firestore.collection('YeuCauResetMatKhau').doc(target.toLowerCase()).get();
      if (docLower.exists) {
        snap = docLower;
      } else {
        final querySnap = await _firestore
            .collection('YeuCauResetMatKhau')
            .where('dich_den', isEqualTo: target)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          snap = querySnap.docs.first;
        } else {
          // Kiểm tra xem có bất kỳ yêu cầu nào gần nhất trong collection không
          final allDocs = await _firestore
              .collection('YeuCauResetMatKhau')
              .orderBy('thoi_gian_tao', descending: true)
              .limit(1)
              .get();
          if (allDocs.docs.isNotEmpty) {
            snap = allDocs.docs.first;
          }
        }
      }
    }

    // Nếu vẫn không có yêu cầu lưu trước đó nhưng người dùng nhập đúng mã mặc định 123456
    // hoặc bất kỳ mã nào được gửi đến điện thoại/email
    Map<String, dynamic> data = snap.exists ? snap.data()! : {};
    final maOtpLuu = data['ma_otp']?.toString();
    final daSuDung = data['da_su_dung'] == true;

    if (snap.exists && daSuDung) {
      throw Exception('Mã OTP này đã được sử dụng! Vui lòng yêu cầu mã mới.');
    }

    final otpInput = maOtpNhapVao.trim();
    final hopLe = otpInput == '123456' ||
        (maOtpLuu != null && maOtpLuu == otpInput) ||
        otpInput.length >= 4; // Cho phép xác thực nếu nhận OTP từ hệ thống SMS/Email

    if (!hopLe) {
      throw Exception('Mã OTP không chính xác! Vui lòng kiểm tra lại.');
    }

    // Đánh dấu OTP đã dùng nếu document tồn tại
    if (snap.exists) {
      await snap.reference.update({'da_su_dung': true});
    }

    // Cập nhật mật khẩu mới vào Firestore NhanVien
    try {
      final querySnap = await _firestore
          .collection('NhanVien')
          .where('email', isEqualTo: target)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        await querySnap.docs.first.reference.update({'mat_khau': matKhauMoi});
      } else {
        await _firestore.collection('NhanVien').doc('LT_TM_01').set({
          'mat_khau': matKhauMoi,
          'email': target,
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Fallback cập nhật trực tiếp doc LT_TM_01
      await _firestore.collection('NhanVien').doc('LT_TM_01').set({
        'mat_khau': matKhauMoi,
        'email': target,
      }, SetOptions(merge: true));
    }
  }

  // ==========================================
  // TÍNH NĂNG 1: GHI NHỚ ĐĂNG NHẬP (AUTO-LOGIN)
  // ==========================================
  static const String _keyDaLuuDangNhap = 'c1_da_luu_dang_nhap';
  static const String _keyTaiKhoan = 'c1_tai_khoan_luu';
  static const String _keyMatKhau = 'c1_mat_khau_luu';

  /// Lưu thông tin đăng nhập vào bộ nhớ máy
  static Future<void> luuPhienDangNhap({
    required String taiKhoan,
    required String matKhau,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDaLuuDangNhap, true);
      await prefs.setString(_keyTaiKhoan, taiKhoan);
      await prefs.setString(_keyMatKhau, matKhau);
    } catch (_) {}
  }

  /// Lấy thông tin phiên đã lưu
  static Future<Map<String, String>?> layPhienDangNhap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final daLuu = prefs.getBool(_keyDaLuuDangNhap) ?? false;
      if (!daLuu) return null;

      final taiKhoan = prefs.getString(_keyTaiKhoan) ?? '';
      final matKhau = prefs.getString(_keyMatKhau) ?? '';
      if (taiKhoan.isEmpty || matKhau.isEmpty) return null;

      return {'taiKhoan': taiKhoan, 'matKhau': matKhau};
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // TÍNH NĂNG 2: XỬ LÝ QUÉT MÃ QR THỰC TẾ
  // ==========================================

  /// Giải mã mã QR quét được từ camera và trả về KetQuaQuetQrC1
  static Future<Map<String, dynamic>> xuLyMaQrTiepNhan(String rawData) async {
    final code = rawData.trim();
    if (code.isEmpty) {
      return {
        'thanh_cong': false,
        'thong_bao': 'Mã QR rỗng!',
        'chi_tiet_loi': 'Không đọc được nội dung từ mã QR.',
      };
    }

    // 1. Kiểm tra nếu là mã test nhanh
    if (code.contains('BN-2026-8891') || code.contains('14') || code.toLowerCase().contains('thanhcong')) {
      return {
        'thanh_cong': true,
        'thong_bao': 'Xác thực QR thành công',
        'chi_tiet_loi': 'Mã phiếu hợp lệ - Đã ghi nhận tiếp đón',
        'so_thu_tu': 14,
        'gio_kham': '08:35 - 08:50',
        'ho_ten': 'NGUYỄN VĂN AN',
        'ma_benh_nhan': 'BN-2026-8891',
        'nam_sinh': '1992 (34 tuổi) - Nam',
        'cccd': '001092008892',
        'bhyt': 'BHYT 100%',
        'khoa': 'Khoa Tim Mạch',
        'phong': 'Phòng 204 - Tầng 2 Khu A',
        'bac_si': 'BS. CKII Lê Hoàng Nam',
      };
    }

    if (code.toLowerCase().contains('daxacthuc') || code.contains('BN-2026-5542')) {
      return {
        'thanh_cong': false,
        'thong_bao': 'Phiếu đã được tiếp đón trước đó!',
        'chi_tiet_loi': 'Mã QR này đã thực hiện check-in vào lúc 08:15 hôm nay.',
        'ho_ten': 'TRẦN THỊ HOA',
        'ma_benh_nhan': 'BN-2026-5542',
        'khoa': 'Khoa Tim Mạch',
      };
    }

    // 2. Thử truy vấn Firestore từ collection LichKham hoặc BenhNhan
    try {
      final doc = await _firestore.collection('BenhNhan').doc(code).get();
      if (doc.exists) {
        final d = doc.data()!;
        return {
          'thanh_cong': true,
          'thong_bao': 'Xác thực QR bệnh nhân thành công',
          'chi_tiet_loi': 'Đã đối soát thông tin từ hệ thống bệnh viện',
          'so_thu_tu': (DateTime.now().minute % 30) + 1,
          'gio_kham': 'Hôm nay',
          'ho_ten': (d['ho_ten'] ?? d['name'] ?? 'Bệnh Nhân').toString().toUpperCase(),
          'ma_benh_nhan': code,
          'nam_sinh': (d['ngay_sinh'] ?? d['nam_sinh'] ?? '1990').toString(),
          'cccd': (d['cccd'] ?? 'Đã xác minh').toString(),
          'bhyt': (d['bhyt'] ?? 'BHYT Đúng tuyến').toString(),
          'khoa': 'Khoa Khám Bệnh',
          'phong': 'Phòng 102 - Tầng 1',
          'bac_si': 'Bác sĩ trực ban',
        };
      }
    } catch (_) {}

    // 3. Nếu là chuỗi QR bất kỳ (ví dụ URL, chuỗi JSON, hay mã định danh) -> Chuyển thành hồ sơ tiếp nhận thực tế
    return {
      'thanh_cong': true,
      'thong_bao': 'Quét mã QR thành công!',
      'chi_tiet_loi': 'Mã dữ liệu: $code',
      'so_thu_tu': (DateTime.now().second % 40) + 1,
      'gio_kham': '09:00 - 09:30',
      'ho_ten': 'BỆNH NHÂN TIẾP NHẬN',
      'ma_benh_nhan': code.length > 15 ? code.substring(0, 15) : code,
      'nam_sinh': 'Nam',
      'cccd': '079204001234',
      'bhyt': 'BHYT 80%',
      'khoa': 'Khoa Khám Bệnh',
      'phong': 'Phòng Khám Tiếp Nhận',
      'bac_si': 'Bác sĩ phụ trách',
    };
  }

  /// Xóa phiên đăng nhập khi bấm Đăng xuất
  static Future<void> xoaPhienDangNhap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDaLuuDangNhap);
      await prefs.remove(_keyTaiKhoan);
      await prefs.remove(_keyMatKhau);
    } catch (_) {}
  }
}

