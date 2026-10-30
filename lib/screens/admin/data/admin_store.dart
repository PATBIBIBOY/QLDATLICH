import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_data.dart';

// ===================================================
// KHO DỮ LIỆU DÙNG CHUNG — Đồng bộ Realtime với Firebase Firestore
// ===================================================
class ErrorReport {
  final String id;
  final String kind; // 'qr' hoặc 'booking'
  final String badge;
  final String title;
  final String sender;
  final String time;
  final String? desc;
  const ErrorReport({
    required this.id,
    required this.kind,
    required this.badge,
    required this.title,
    required this.sender,
    required this.time,
    this.desc,
  });
}

class AdminStore extends ChangeNotifier {
  static final AdminStore instance = AdminStore._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _hospitalsSub;
  StreamSubscription? _pendingSub;
  StreamSubscription? _reportsSub;

  bool isSyncing = false;
  bool isConnected = true;
  DateTime lastSync = DateTime.now();

  List<Hospital> hospitals = List.of(verifiedHospitals);
  List<Map<String, String>> pending =
      pendingHospitals.map((e) => Map<String, String>.of(e)).toList();
  List<Map<String, String>> violations = [
    {
      'name': 'Phòng khám Đa Khoa An Khang',
      'match': 'PK Đa khoa An Khang',
      'complaints': '3 Khiếu nại',
      'location': '📍 Cầu Giấy, Hà Nội · Mã: PK-4912',
      'reason':
          'Lý do: Giấy phép hoạt động hết hạn, chưa hoàn tất kiểm định BYT.',
    },
  ];
  List<ErrorReport> reports = [
    ErrorReport(
      id: 'qr1',
      kind: 'qr',
      badge: 'Lỗi Check-in QR',
      title: 'Quét QR không auto điền form tiếp nhận',
      sender: 'Người gửi: BV Tâm Anh (Quầy lễ tân)',
      time: '10 phút trước',
      desc:
          'Mô tả: Camera quét mở của bệnh nhận Nguyễn Văn A báo mã hợp lệ nhưng không tự load thông tin khám.',
    ),
    ErrorReport(
      id: 'bk1',
      kind: 'booking',
      badge: 'Lỗi Đặt Lịch',
      title: 'Trùng ca khám buổi sáng',
      sender: 'Người gửi: Bệnh nhân Trần Mai Lan',
      time: '1 giờ trước',
    ),
  ];

  int get totalBV => hospitals.length;
  int pendingTotal = 5;
  int errorTotal = 12;

  String get totalBVText => totalBV.toString().padLeft(2, '0');
  String get pendingText => pendingTotal.toString().padLeft(2, '0');
  String get errorText => reports.length.toString().padLeft(2, '0');

  static const List<List<Color>> _avatarPalette = [
    [Color(0xFFDBEAFE), Color(0xFF2563EB)], // Blue
    [Color(0xFFFFEDD5), Color(0xFFD97706)], // Orange
    [Color(0xFFDCFCE7), Color(0xFF16A34A)], // Green
    [Color(0xFFF3E8FF), Color(0xFF9333EA)], // Purple
    [Color(0xFFFEE2E2), Color(0xFFDC2626)], // Red
    [Color(0xFFE0E7FF), Color(0xFF4F46E5)], // Indigo
  ];

  AdminStore._() {
    _initFirebaseSync();
  }

  static String getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'BV';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    // Bỏ các tiền tố chung để lấy chữ cái đại diện rõ hơn
    final filtered = parts.where((p) {
      final l = p.toLowerCase();
      return !['bệnh', 'viện', 'bv', 'phòng', 'khám', 'pk', 'trung', 'tâm', 'tt'].contains(l);
    }).toList();

    if (filtered.length >= 2) {
      return (filtered[0][0] + filtered[1][0]).toUpperCase();
    } else if (filtered.length == 1) {
      return filtered[0].substring(0, filtered[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Kích hoạt đồng bộ tức thời từ Firebase
  Future<void> syncNow() async {
    isSyncing = true;
    notifyListeners();

    try {
      // 1. Tải BenhVien
      final bvSnap = await _firestore.collection('BenhVien').get();
      if (bvSnap.docs.isNotEmpty) {
        _processHospitalsSnapshot(bvSnap);
      }

      // 2. Tải YeuCauHopTac
      final ycSnap = await _firestore.collection('YeuCauHopTac').get();
      _processPendingSnapshot(ycSnap);

      // 3. Tải BaoCaoLoi
      final bcSnap = await _firestore.collection('BaoCaoLoi').get();
      _processReportsSnapshot(bcSnap);

      isConnected = true;
      lastSync = DateTime.now();
    } catch (e) {
      debugPrint('Lỗi syncNow: $e');
      isConnected = false;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  void _processHospitalsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<Hospital> list = [];
    final List<Map<String, String>> viols = [];
    int idx = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = data['ten_benh_vien']?.toString() ??
          data['name']?.toString() ??
          'Bệnh viện ${doc.id}';
      final type = data['co_so']?.toString() ??
          data['loai_hinh']?.toString() ??
          'Công lập';
      final rating =
          (data['diem_danh_gia_tb'] as num?)?.toDouble() ?? 4.5;
      final address = data['dia_chi']?.toString() ??
          'Đang cập nhật địa chỉ';
      final statusId = data['trang_thai_hop_tac_id'] as int? ?? 10;
      final depts = (data['ten_cac_khoa'] as List?)
          ?.map((e) => e.toString())
          .toList();
      final doctorCount = depts != null && depts.isNotEmpty
          ? (depts.length * 8)
          : 35;
      final palette = _avatarPalette[idx % _avatarPalette.length];
      idx++;

      final hospital = Hospital(
        initials: getInitials(name),
        name: name,
        type: type,
        rating: rating,
        doctors: doctorCount,
        avatarBg: palette[0],
        avatarText: palette[1],
        address: address,
        code: doc.id,
        departments: depts,
        totalReviews: (data['tong_so_danh_gia'] as num?)?.toInt() ?? 0,
        phone: data['so_dien_thoai']?.toString(),
        email: data['email']?.toString(),
        status: statusId,
      );

      // Trạng thái != 8 (8 là đã ngừng hợp tác / khóa)
      if (statusId != 8) {
        list.add(hospital);
      }

      // Cơ sở đánh giá thấp hoặc vi phạm
      if (rating < 3.8 || statusId == 8) {
        viols.add({
          'name': name,
          'match': name,
          'complaints': '${data['tong_so_danh_gia'] ?? 3} Khiếu nại/Đánh giá thấp',
          'location': '📍 $address · Mã: ${doc.id}',
          'reason': statusId == 8
              ? 'Lý do: Đã bị tạm dừng/khóa hợp tác.'
              : 'Lý do: Điểm đánh giá $rating★ dưới ngưỡng tiêu chuẩn.',
          'code': doc.id,
        });
      }
    }

    if (list.isNotEmpty) {
      hospitals = list;
    }
    violations = viols;
    lastSync = DateTime.now();
    isConnected = true;
    notifyListeners();
  }

  void _processPendingSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<Map<String, String>> pendingList = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final statusId = data['trang_thai_hop_tac_id'] as int? ?? 1;
      final daDuyet = data['da_duyet'] == true ||
          data['trang_thai'] == 'da_duyet' ||
          statusId == 2 ||
          statusId == 10;
      final tuChoi = data['trang_thai'] == 'tu_choi' || statusId == 4;

      if (!daDuyet && !tuChoi) {
        final name = data['ten_benh_vien']?.toString() ?? 'Cơ sở Y tế mới';
        final type = data['loai_hinh']?.toString() ?? 'Bệnh viện Công lập';
        final code = data['so_giay_phep']?.toString() ??
            data['ma_ho_so']?.toString() ??
            doc.id;
        final timeStr = data['thoi_gian_gui_str']?.toString() ??
            'Mới gửi yêu cầu';
        final docFile = data['file_giay_phep']?.toString() ??
            'giay_phep_byt.pdf';
        final location = data['dia_chi']?.toString() ??
            'Chưa cập nhật địa chỉ';

        pendingList.add({
          'docId': doc.id,
          'name': name,
          'type': type,
          'code': code,
          'tag': getInitials(name),
          'bs': '15 Bác sĩ',
          'time': 'Gửi: $timeStr',
          'docs': 'GP: $docFile',
          'location': location,
          'so_giay_phep': data['so_giay_phep']?.toString() ?? '',
          'ma_so_thue': data['ma_so_thue']?.toString() ?? '',
        });
      }
    }
    pending = pendingList;
    pendingTotal = pendingList.length;
    lastSync = DateTime.now();
    isConnected = true;
    notifyListeners();
  }

  void _processReportsSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<ErrorReport> reportList = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['trang_thai_xu_ly']?.toString() ?? 'CHO_XU_LY';
      if (status != 'DA_GIAI_QUYET') {
        final kind = data['loai']?.toString() == 'booking' ? 'booking' : 'qr';
        final badge = kind == 'qr' ? 'Lỗi Check-in QR' : 'Lỗi Đặt Lịch';
        reportList.add(ErrorReport(
          id: doc.id,
          kind: kind,
          badge: data['tieu_de']?.toString() ?? badge,
          title: data['tieu_de']?.toString() ?? 'Báo cáo sự cố',
          sender: data['nguoi_gui']?.toString() ?? 'Người dùng',
          time: data['thoi_gian_hien_thi']?.toString() ?? 'Gần đây',
          desc: data['noi_dung']?.toString() ?? data['mo_ta']?.toString(),
        ));
      }
    }
    reports = reportList;
    errorTotal = reportList.length;
    lastSync = DateTime.now();
    isConnected = true;
    notifyListeners();
  }

  void _initFirebaseSync() {
    try {
      // 1. Lắng nghe danh sách bệnh viện từ Firestore collection 'BenhVien'
      _hospitalsSub = _firestore.collection('BenhVien').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _processHospitalsSnapshot(snapshot);
          }
        },
        onError: (e) {
          debugPrint('Lỗi realtime BenhVien: $e');
          isConnected = false;
          notifyListeners();
        },
      );

      // 2. Lắng nghe hồ sơ chờ duyệt từ 'YeuCauHopTac'
      _pendingSub = _firestore.collection('YeuCauHopTac').snapshots().listen(
        (snapshot) {
          _processPendingSnapshot(snapshot);
        },
        onError: (e) {
          debugPrint('Lỗi realtime YeuCauHopTac: $e');
          isConnected = false;
          notifyListeners();
        },
      );

      // 3. Lắng nghe báo cáo lỗi từ 'BaoCaoLoi'
      _reportsSub = _firestore.collection('BaoCaoLoi').snapshots().listen(
        (snapshot) {
          _processReportsSnapshot(snapshot);
        },
        onError: (e) {
          debugPrint('Lỗi realtime BaoCaoLoi: $e');
          isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Không thể khởi tạo listener Firestore: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  // ===================================================
  // CÁC HÀNH ĐỘNG CỦA ADMIN (Ghi dữ liệu lên Firebase)
  // ===================================================

  /// DUYỆT BỆNH VIỆN
  void approveHospital(Map<String, String> h) async {
    final docId = h['docId'] ?? h['code'] ?? '';
    pending.removeWhere((e) => (e['docId'] == docId || e['code'] == h['code']));
    pendingTotal = (pendingTotal - 1).clamp(0, 999);
    if (pending.isEmpty) pendingTotal = 0;

    final palette = _avatarPalette[hospitals.length % _avatarPalette.length];
    final bsRaw = h['bs'] ?? '15';
    final doctors = int.tryParse(bsRaw.split(' ').first) ?? 15;

    hospitals.insert(
      0,
      Hospital(
        initials: h['tag'] ?? 'BV',
        name: h['name'] ?? 'Bệnh viện',
        type: h['type'] ?? 'Tư nhân',
        rating: 5.0,
        doctors: doctors,
        avatarBg: palette[0],
        avatarText: palette[1],
        address: h['location'] ?? 'Đang cập nhật địa chỉ',
        code: docId,
      ),
    );
    violations.removeWhere((v) => v['match'] == h['name']);
    notifyListeners();

    // Ghi lên Firestore
    try {
      if (docId.isNotEmpty) {
        await _firestore.collection('YeuCauHopTac').doc(docId).set({
          'trang_thai_hop_tac_id': 10,
          'trang_thai': 'da_duyet',
          'da_duyet': true,
          'ngay_duyet': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('BenhVien').doc(docId).set({
          'ten_benh_vien': h['name'],
          'co_so': h['type'],
          'dia_chi': h['location'],
          'trang_thai_hop_tac_id': 10,
          'diem_danh_gia_tb': 5.0,
          'tong_so_danh_gia': 0,
          'ngay_hop_tac': FieldValue.serverTimestamp(),
          'da_xac_thuc_email': true,
          'role': 'benh_vien',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Lỗi ghi duyệt bệnh viện lên Firebase: $e');
    }
  }

  /// TỪ CHỐI DUYỆT BỆNH VIỆN
  void rejectHospital(Map<String, String> h, {String? reason}) async {
    final docId = h['docId'] ?? h['code'] ?? '';
    pending.removeWhere((e) => (e['docId'] == docId || e['code'] == h['code']));
    pendingTotal = (pendingTotal - 1).clamp(0, 999);
    if (pending.isEmpty) pendingTotal = 0;
    violations.removeWhere((v) => v['match'] == h['name']);
    notifyListeners();

    try {
      if (docId.isNotEmpty) {
        await _firestore.collection('YeuCauHopTac').doc(docId).set({
          'trang_thai_hop_tac_id': 4,
          'trang_thai': 'tu_choi',
          'ly_do_tu_choi': reason ?? 'Hồ sơ chưa đạt tiêu chuẩn quy định.',
          'ngay_tu_choi': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Lỗi từ chối bệnh viện trên Firebase: $e');
    }
  }

  /// XÓA CƠ SỞ VI PHẠM
  void deleteViolation(Map<String, String> v) async {
    violations.remove(v);
    final matched = pending.where((e) => e['name'] == v['match']).toList();
    for (final m in matched) {
      pending.remove(m);
      pendingTotal = (pendingTotal - 1).clamp(0, 999);
    }
    if (pending.isEmpty) pendingTotal = 0;
    notifyListeners();

    try {
      final code = v['code'];
      if (code != null && code.isNotEmpty) {
        await _firestore.collection('BenhVien').doc(code).update({
          'trang_thai_hop_tac_id': 8,
          'ly_do_khoa': v['reason'] ?? 'Vi phạm quy chuẩn BYT',
          'ngay_khoa': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Lỗi khóa cơ sở vi phạm trên Firebase: $e');
    }
  }

  /// XÓA HỢP TÁC VỚI BỆNH VIỆN
  void unpartnerHospital(Hospital h) async {
    hospitals.remove(h);
    notifyListeners();

    try {
      if (h.code != null && h.code!.isNotEmpty) {
        await _firestore.collection('BenhVien').doc(h.code).update({
          'trang_thai_hop_tac_id': 8,
          'ngay_ngung_hop_tac': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Lỗi ngừng hợp tác trên Firebase: $e');
    }
  }

  /// SỬA THÔNG TIN BỆNH VIỆN
  void updateHospital(
    Hospital h, {
    String? name,
    String? type,
    String? address,
    int? doctors,
  }) async {
    if (name != null && name.isNotEmpty) h.name = name;
    if (type != null && type.isNotEmpty) h.type = type;
    if (address != null && address.isNotEmpty) h.address = address;
    if (doctors != null) h.doctors = doctors;
    notifyListeners();

    try {
      if (h.code != null && h.code!.isNotEmpty) {
        final Map<String, dynamic> updateData = {};
        if (name != null && name.isNotEmpty) updateData['ten_benh_vien'] = name;
        if (type != null && type.isNotEmpty) updateData['co_so'] = type;
        if (address != null && address.isNotEmpty) updateData['dia_chi'] = address;
        updateData['ngay_cap_nhat'] = FieldValue.serverTimestamp();

        await _firestore.collection('BenhVien').doc(h.code).update(updateData);
      }
    } catch (e) {
      debugPrint('Lỗi cập nhật bệnh viện trên Firebase: $e');
    }
  }

  /// XỬ LÝ XONG BÁO CÁO LỖI
  void resolveReport(String id) async {
    reports.removeWhere((r) => r.id == id);
    errorTotal = (errorTotal - 1).clamp(0, 999);
    if (reports.isEmpty) errorTotal = 0;
    notifyListeners();

    try {
      await _firestore.collection('BaoCaoLoi').doc(id).update({
        'trang_thai_xu_ly': 'DA_GIAI_QUYET',
        'da_doc': true,
        'ngay_giai_quyet': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Lỗi giải quyết báo cáo trên Firebase: $e');
    }
  }

  /// LỌC BÁO CÁO THEO LOẠI
  List<ErrorReport> filteredReports(int filter) {
    if (filter == 1) {
      return reports.where((r) => r.kind == 'booking').toList();
    }
    if (filter == 2) {
      return reports.where((r) => r.kind == 'qr').toList();
    }
    return List.of(reports);
  }

  @override
  void dispose() {
    _hospitalsSub?.cancel();
    _pendingSub?.cancel();
    _reportsSub?.cancel();
    super.dispose();
  }
}
