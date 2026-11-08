import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lichhen_model.dart';
import '../models/family_profile_model.dart';

class LichHenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _colLichHen = 'LichHen';
  static const String _colPhongKham = 'PhongKham';

  /// Mã trạng thái "Đã hủy" (bảng TrangThai).
  static const String trangThaiDaHuy = '3';

  /// Lịch hẹn ở các trạng thái này thì không hủy được:
  /// 4 = đã hủy, 5 = hoàn thành, 6 = vắng mặt.
  static const Set<String> _trangThaiKhongTheHuy = {'4', '5', '6'};

  static const List<Map<String, String>> _caMacDinh = [
    {
      'id': 'ca_sang',
      'ten_ca': 'Ca sáng',
      'gio_bat_dau': '07:30',
      'gio_ket_thuc': '11:30',
    },
    {
      'id': 'ca_chieu',
      'ten_ca': 'Ca chiều',
      'gio_bat_dau': '13:30',
      'gio_ket_thuc': '17:00',
    },
  ];

  /// Cache số bệnh nhân tối đa lấy từ PhongKham: "bv|khoa|phong" -> số.
  final Map<String, int> _tongSoCache = {};

  /// Đọc số nguyên từ Firestore (chấp nhận num hoặc chuỗi "31").
  static int? _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

  static String ngayId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DocumentReference<Map<String, dynamic>> _phongKhamRef({
    required DateTime ngay,
    required String caId,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) {
    return _firestore.collection(_colLichHen).doc(phongKhamId);
  }

  Future<int?> _layTongSoTuPhongKham({
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) async {
    final cacheKey = '$benhVienId|$khoaId|$phongKhamId';
    final cached = _tongSoCache[cacheKey];
    if (cached != null) return cached;

    try {
      final doc = await _firestore
          .collection(_colPhongKham)
          .doc(phongKhamId)
          .get();

      if (!doc.exists) {
        debugPrint('️ Document $phongKhamId không tồn tại');
        return null;
      }

      final data = doc.data() ?? <String, dynamic>{};

      // Kiểm tra xem document này có thuộc bệnh viện và khoa này không
      final docHospitalId = data['hospitalId']?.toString();
      final docKhoaId = data['khoaId']?.toString();

      if (docHospitalId != benhVienId || docKhoaId != khoaId) {
        debugPrint(
          '⚠️ Document $phongKhamId không khớp: '
          'hospitalId=${docHospitalId} (cần $benhVienId), '
          'khoaId=${docKhoaId} (cần $khoaId)',
        );
        return null;
      }

      final v = _toInt(data['soBenhNhanToiDa']);
      if (v != null) {
        debugPrint('✅ PhongKham/$phongKhamId -> soBenhNhanToiDa = $v');
        _tongSoCache[cacheKey] = v;
      } else {
        debugPrint('⚠️ PhongKham/$phongKhamId không có field soBenhNhanToiDa');
      }
      return v;
    } catch (e) {
      debugPrint('❌ Lỗi khi đọc PhongKham/$phongKhamId: $e');
      return null;
    }
  }

  static const List<Object> _trangThaiChiemCho = [2, '2'];

  static const Duration _vnOffset = Duration(hours: 7);

  /// Khoảng [00:00, 24:00) của ngày [ngay] theo giờ Việt Nam, đổi sang UTC.
  /// Chỉ lấy năm/tháng/ngày nên không phụ thuộc múi giờ của máy.
  ({Timestamp start, Timestamp end}) _khoangNgayVN(DateTime ngay) {
    final startUtc = DateTime.utc(
      ngay.year,
      ngay.month,
      ngay.day,
    ).subtract(_vnOffset);
    final endUtc = startUtc.add(const Duration(days: 1));
    return (
      start: Timestamp.fromDate(startUtc),
      end: Timestamp.fromDate(endUtc),
    );
  }

  /// Số lịch hẹn đã chiếm chỗ của 1 ca (bệnh viện + khoa + phòng + ca + ngày).
  Future<int> demLichDaDat({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required String caId,
  }) async {
    final range = _khoangNgayVN(ngay);
    final snapshot = await _firestore
        .collection(_colLichHen)
        .where('benh_vien_id', isEqualTo: benhVienId)
        .where('khoa_id', isEqualTo: khoaId)
        .where('phong_kham_id', isEqualTo: phongKhamId)
        .where('ca_id', isEqualTo: caId)
        .where('trang_thai_id', whereIn: _trangThaiChiemCho)
        .where('ngay_dat', isGreaterThanOrEqualTo: range.start)
        .where('ngay_dat', isLessThan: range.end)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Số chỗ còn lại = tổng số chỗ của phòng − số lịch đã đặt (không âm).
  Future<int> soChoConLai({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required String caId,
    int soBenhNhanToiDa = 0,
  }) async {
    final tongSo =
        await _layTongSoTuPhongKham(
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        ) ??
        soBenhNhanToiDa;
    final daDat = await demLichDaDat(
      ngay: ngay,
      benhVienId: benhVienId,
      khoaId: khoaId,
      phongKhamId: phongKhamId,
      caId: caId,
    );
    final conLai = tongSo - daDat;
    return conLai < 0 ? 0 : conLai;
  }

  Future<List<CaSlotModel>> getCaSlotsTheoPhong({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    int soBenhNhanToiDa = 0,
  }) async {
    // 1. Danh sách ca: bảng Ca; chưa có thì dùng ca mặc định
    final caSnapshot = await _firestore.collection('Ca').get();
    final caList = caSnapshot.docs.isNotEmpty
        ? caSnapshot.docs.map((d) => MapEntry(d.id, d.data())).toList()
        : _caMacDinh
              .map((c) => MapEntry(c['id']!, <String, dynamic>{...c}))
              .toList();
    final macDinhTheoId = {for (final c in _caMacDinh) c['id']!: c};

    // 2. Tổng số chỗ của phòng (lấy 1 lần cho mọi ca)
    final tongSo =
        await _layTongSoTuPhongKham(
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        ) ??
        soBenhNhanToiDa;

    // 3. Đếm số lịch đã đặt của từng ca (chạy song song)
    final results = await Future.wait<CaSlotModel>(
      caList.map((entry) async {
        final caId = entry.key;
        final caData = entry.value;
        final macDinh = macDinhTheoId[caId];

        String caField(String key, String fallback) {
          final v = caData[key]?.toString() ?? '';
          return v.isNotEmpty ? v : (macDinh?[key] ?? fallback);
        }

        final daDat = await demLichDaDat(
          ngay: ngay,
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
          caId: caId,
        );

        return CaSlotModel(
          caId: caId,
          tenCa: caField('ten_ca', caId),
          gioBatDau: caField('gio_bat_dau', ''),
          gioKetThuc: caField('gio_ket_thuc', ''),
          tongSo: tongSo,
          daDat: daDat < 0 ? 0 : daDat,
        );
      }),
    );

    return results..sort((a, b) => a.gioBatDau.compareTo(b.gioBatDau));
  }

  Future<String> generateLichHenId({
    required DateTime ngayDat,
    required String benhVienId,
    required String khoaId,
  }) async {
    // 1. Format ngày khám thành chuỗi DDMMYYYY (Ví dụ: 30102026)
    final dateStr =
        '${ngayDat.day.toString().padLeft(2, '0')}'
        '${ngayDat.month.toString().padLeft(2, '0')}'
        '${ngayDat.year}';

    // 2. Xác định khoảng thời gian bắt đầu và kết thúc của NGÀY KHÁM đó
    final dayStart = Timestamp.fromDate(
      DateTime(ngayDat.year, ngayDat.month, ngayDat.day),
    );
    final dayEnd = Timestamp.fromDate(
      DateTime(ngayDat.year, ngayDat.month, ngayDat.day, 23, 59, 59),
    );

    // 3. Đếm số lượng lịch hẹn ĐÃ ĐƯỢC ĐẶT cho NGÀY KHÁM đó, CỤ THỂ TẠI BỆNH VIỆN VÀ KHOA NÀY
    final snapshot = await _firestore
        .collection(_colLichHen)
        .where('benh_vien_id', isEqualTo: benhVienId) // ✅ Lọc theo Bệnh viện
        .where('khoa_id', isEqualTo: khoaId) // ✅ Lọc theo Khoa
        .where('ngay_dat', isGreaterThanOrEqualTo: dayStart)
        .where('ngay_dat', isLessThanOrEqualTo: dayEnd)
        .count()
        .get();

    final count = snapshot.count ?? 0;
    final nextNumber = count + 1;

    // 4. Format số thứ tự thành 5 chữ số (00001, 00002, ...)
    final numberStr = nextNumber.toString().padLeft(5, '0');

    // 5. Trả về định dạng mới: BV001_K001_LH_20261030_00001
    return '${benhVienId}_${khoaId}_LH_${dateStr}_$numberStr';
  }

  Future<bool> checkExistingBooking({
    required String benhNhanId,
    required String benhVienId,
    required String khoaId,
    required DateTime ngayDat,
    String? profileId, // mới
  }) async {
    final start = DateTime(ngayDat.year, ngayDat.month, ngayDat.day);
    final end = start.add(const Duration(days: 1));
    try {
      final snapshot = await _firestore
          .collection(_colLichHen)
          .where('benh_nhan_id', isEqualTo: benhNhanId)
          .where('benh_vien_id', isEqualTo: benhVienId)
          .where('khoa_id', isEqualTo: khoaId)
          .where('ngay_dat', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngay_dat', isLessThan: Timestamp.fromDate(end))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['trang_thai_id']?.toString();
        if (status == '3' || status == '4') continue; // đã hủy
        final docProfile = (data['profile_id'] ?? FamilyProfileModel.selfId)
            .toString();
        if (profileId == null || docProfile == profileId) return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Lỗi khi kiểm tra trùng lịch: $e');
      return false;
    }
  }

  /// Lưu lịch hẹn mới vào Firestore theo cấu trúc nested sâu
  Future<void> saveBooking({
    required String trangThaiId, // Ví dụ: "1"
    required DateTime ngayDat,
    required String caId,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required String benhNhanId,
    String? lichHenId,
    String? tenBenhVien,
    String? tenKhoa,
    String? tenPhongKham,
    String? profileId,
    String? tenNguoiKham,
    String? quanHe,
    String? tenNguoiDat,
  }) async {
    final finalLichHenId =
        lichHenId ??
        await generateLichHenId(
          ngayDat: ngayDat,
          benhVienId: benhVienId,
          khoaId: khoaId,
        );

    final docRef = _firestore.collection(_colLichHen).doc(finalLichHenId);

    await docRef.set({
      'id': finalLichHenId,
      'trang_thai_id': trangThaiId,
      'ngay_dat': Timestamp.fromDate(ngayDat),
      'ca_id': caId,
      'benh_vien_id': benhVienId,
      'khoa_id': khoaId,
      'phong_kham_id': phongKhamId,
      'benh_nhan_id': benhNhanId,
      if (tenBenhVien != null) 'ten_benh_vien': tenBenhVien,
      if (tenKhoa != null) 'ten_khoa': tenKhoa,
      if (tenPhongKham != null) 'ten_phong_kham': tenPhongKham,
      if (profileId != null) 'profile_id': profileId,
      if (tenNguoiKham != null) 'ten_nguoi_kham': tenNguoiKham,
      if (quanHe != null) 'quan_he': quanHe,
      if (tenNguoiDat != null) 'ten_nguoi_dat': tenNguoiDat,
      'ma_qr': null,
      'ngay_tao': FieldValue.serverTimestamp(),
    });
  }

  static String? _tenPhong(Map<String, dynamic>? d) {
    if (d == null) return null;
    for (final k in ['tenPhongKham', 'ten_phong_kham', 'tenPhong', 'ten']) {
      final v = d[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Future<List<LichHenModel>> getLichHenCuaBenhNhan(String benhNhanId) async {
    try {
      final snapshot = await _firestore
          .collection('LichHen')
          .where('benh_nhan_id', isEqualTo: benhNhanId)
          .get();

      final bookings = snapshot.docs
          .map((doc) => LichHenModel.fromJson(doc.data(), id: doc.id))
          .toList();
      if (bookings.isEmpty) return bookings;

      // ── Tra cứu tên ca: Ca/{caId} ──
      final caIds = bookings
          .where((b) => b.tenCa == null || b.gioBatDau == null)
          .map((b) => b.caId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final caEntries = await Future.wait(
        caIds.map((id) async {
          final doc = await _firestore.collection('Ca').doc(id).get();
          return MapEntry(id, doc.data());
        }),
      );
      final caMap = {for (final e in caEntries) e.key: e.value};

      final phongIds = bookings
          .where((b) => b.tenPhongKham == null && b.phongKhamId.isNotEmpty)
          .map((b) => b.phongKhamId)
          .toSet();
      final phongEntries = await Future.wait(
        phongIds.map((id) async {
          final doc = await _firestore.collection(_colPhongKham).doc(id).get();
          return MapEntry(id, doc.data());
        }),
      );
      final phongMap = {for (final e in phongEntries) e.key: e.value};

      // ── Tra cứu tên khoa: Khoa/{benhVienId}/danh_sach/{khoaId} ──
      final khoaKeys = bookings
          .where(
            (b) =>
                b.tenKhoa == null &&
                b.benhVienId.isNotEmpty &&
                b.khoaId.isNotEmpty,
          )
          .map((b) => '${b.benhVienId}|${b.khoaId}')
          .toSet();
      final khoaEntries = await Future.wait(
        khoaKeys.map((key) async {
          final parts = key.split('|');
          final doc = await _firestore
              .collection('Khoa')
              .doc(parts[0])
              .collection('danh_sach')
              .doc(parts[1])
              .get();
          return MapEntry(key, doc.data());
        }),
      );
      final khoaMap = {for (final e in khoaEntries) e.key: e.value};

      // ── Gộp thông tin vào từng lịch hẹn ──
      final result = bookings.map((b) {
        final ca = caMap[b.caId];
        final khoa = khoaMap['${b.benhVienId}|${b.khoaId}'];
        return b.copyWith(
          tenCa: ca?['ten_ca']?.toString(),
          gioBatDau: ca?['gio_bat_dau']?.toString(),
          gioKetThuc: ca?['gio_ket_thuc']?.toString(),
          tenKhoa: khoa?['ten_khoa']?.toString(),
          tenPhongKham: _tenPhong(phongMap[b.phongKhamId]),
        );
      }).toList();

      // Mới đặt nhất lên đầu
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      result.sort((a, b) {
        final ta = a.ngayTao ?? a.ngayDat ?? epoch;
        final tb = b.ngayTao ?? b.ngayDat ?? epoch;
        return tb.compareTo(ta);
      });
      return result;
    } on FirebaseException catch (e) {
      // failed-precondition: thông báo gốc có chứa LINK TẠO INDEX trong Debug Console
      debugPrint('Lỗi Firestore khi tải lịch hẹn [${e.code}]: ${e.message}');
      switch (e.code) {
        case 'failed-precondition':
          throw Exception(
            'Cần tạo chỉ mục (index) Firestore cho lịch hẹn. '
            'Xem Debug Console để lấy liên kết tạo.',
          );
        case 'permission-denied':
          throw Exception(
            'Không có quyền đọc lịch hẹn (kiểm tra Security Rules).',
          );
        default:
          throw Exception('Không thể tải lịch hẹn. Vui lòng thử lại.');
      }
    }
  }

  Future<Map<String, dynamic>?> getBookingDetail({
    required String trangThaiId,
    required String ngayId,
    required String caId,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required String benhNhanId,
    required String lichHenId,
  }) async {
    try {
      final doc = await _firestore.collection(_colLichHen).doc(lichHenId).get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Lỗi khi lấy chi tiết lịch hẹn: $e');
      return null;
    }
  }

  /// DANH SÁCH LỊCH HẸN của 1 phòng khám trong 1 ngày.
  /// [caId] = null: lấy tất cả các ca.
  Future<List<LichHenModel>> getDanhSachLichHen({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    String? caId,
  }) async {
    final ngayRef = _firestore
        .collection(_colLichHen)
        .where('ngay_hen', isEqualTo: ngay)
        .get();

    List<String> caIds;

    if (caId != null) {
      // 1. Nếu đã truyền sẵn caId, chỉ cần đưa nó vào danh sách
      caIds = [caId];
    } else {
      // 2. Nếu chưa có, ta query trực tiếp vào collection phẳng 'lich_hen'
      // để tìm xem trong ngày đó, phòng khám này có những ca nào đã được đặt lịch.
      final snapshot = await _firestore
          .collection('LichHen') // Sử dụng collection phẳng
          .where(
            'ngay_hen',
            isEqualTo: Timestamp.fromDate(ngay),
          ) // Lọc theo ngày
          .where('benh_vien_id', isEqualTo: benhVienId)
          .where('khoa_id', isEqualTo: khoaId)
          .where('phong_kham_id', isEqualTo: phongKhamId)
          .get();

      // 3. Trích xuất trường 'ca_id' và dùng .toSet() để loại bỏ các giá trị trùng lặp
      caIds = snapshot.docs
          .map((doc) => doc.data()['ca_id'] as String)
          .toSet()
          .toList();
    }

    final perCa = await Future.wait<List<LichHenModel>>(
      caIds.map((id) async {
        final phongRef = _phongKhamRef(
          ngay: ngay,
          caId: id,
          benhVienId: benhVienId,
          khoaId: khoaId,
          phongKhamId: phongKhamId,
        );

        final benhNhanSnapshot = await phongRef.collection('BenhNhan').get();
        final lichHenSnapshots = await Future.wait(
          benhNhanSnapshot.docs.map(
            (bn) => bn.reference.collection('LichHen').get(),
          ),
        );

        return [
          for (final snap in lichHenSnapshots)
            for (final doc in snap.docs)
              LichHenModel.fromJson(doc.data(), id: doc.id),
        ];
      }),
    );

    return perCa.expand((list) => list).toList()..sort((a, b) {
      final byCa = a.caId.compareTo(b.caId);
      return byCa != 0 ? byCa : a.soThuTu.compareTo(b.soThuTu);
    });
  }

  Future<void> _chuyenTrangThai(
    DocumentReference<Map<String, dynamic>> oldRef,
    String trangThaiMoi, {
    String? lyDoHuy,
  }) async {
    final segments = oldRef.path.split('/');
    // Dạng hợp lệ: LichHen/{trangThai}/danh_sach/{ngay}/ca/.../lich_hen/{id}
    if (segments.length < 4 ||
        segments[0] != _colLichHen ||
        segments[2] != 'danh_sach') {
      throw Exception('Lịch hẹn này thuộc dữ liệu cũ nên không thể hủy.');
    }

    final trangThaiCu = segments[1];
    if (trangThaiCu == trangThaiDaHuy) {
      throw Exception('Lịch hẹn này đã được hủy trước đó.');
    }
    if (_trangThaiKhongTheHuy.contains(trangThaiCu)) {
      throw Exception('Lịch hẹn ở trạng thái hiện tại không thể hủy.');
    }

    segments[1] = trangThaiMoi;
    final newRef = _firestore.doc(segments.join('/'));

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(oldRef);
      if (!snap.exists) {
        throw Exception('Không tìm thấy lịch hẹn (có thể đã được xử lý).');
      }
      final data = snap.data() ?? <String, dynamic>{};

      tx.set(newRef, {
        ...data,
        'trang_thai_id': trangThaiMoi,
        'ly_do_huy': lyDoHuy,
        'ngay_cap_nhat': FieldValue.serverTimestamp(),
      });
      tx.delete(oldRef);
    });
  }

  Future<void> huyLichHenTheoId({
    required String benhNhanId,
    required String lichHenId,
    String? lyDoHuy,
  }) async {
    final id = lichHenId.replaceFirst('#', '').trim();
    final ref = _firestore.collection(_colLichHen).doc(id);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Không tìm thấy lịch hẹn cần hủy.');

        final data = snap.data()!;
        if (data['benh_nhan_id'] != benhNhanId) {
          throw Exception('Bạn không có quyền hủy lịch hẹn này.');
        }

        final cu = data['trang_thai_id'].toString();
        if (cu == '3') {
          throw Exception('Lịch hẹn này đã được hủy trước đó.');
        }
        if (_trangThaiKhongTheHuy.contains(cu)) {
          throw Exception('Lịch hẹn ở trạng thái hiện tại không thể hủy.');
        }

        // ✅ CẬP NHẬT: Ghi trạng thái 3 (Bệnh nhân hủy) vào Firestore
        tx.update(ref, {
          'trang_thai_id': '3',
          'huy_boi': 'benh_nhan',
          'ly_do_huy': lyDoHuy ?? 'Bệnh nhân tự hủy qua ứng dụng',
          'ngay_cap_nhat': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi hủy lịch: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> xoaLichHenTheoId({
    required String benhNhanId,
    required String lichHenId,
  }) async {
    final id = lichHenId.replaceFirst('#', '').trim();
    final ref = _firestore.collection(_colLichHen).doc(id);
    try {
      final snap = await ref.get();
      if (!snap.exists) throw Exception('Không tìm thấy lịch hẹn cần xóa.');
      final data = snap.data()!;
      if (data['benh_nhan_id'] != benhNhanId) {
        throw Exception('Bạn không có quyền xóa lịch hẹn này.');
      }
      if (data['trang_thai_id'].toString() != trangThaiDaHuy) {
        throw Exception('Chỉ có thể xóa lịch hẹn đã hủy.');
      }
      await ref.delete();
    } on FirebaseException catch (e) {
      // ... giữ nguyên khối switch cũ
    }
  }

  Stream<List<LichHenModel>> listenToQueue({
    required DateTime ngay,
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) {
    bool cungNgay(DateTime? d) =>
        d != null &&
        d.year == ngay.year &&
        d.month == ngay.month &&
        d.day == ngay.day;

    return _firestore
        .collection(_colLichHen)
        .where('benh_vien_id', isEqualTo: benhVienId)
        .where('khoa_id', isEqualTo: khoaId)
        .where('phong_kham_id', isEqualTo: phongKhamId)
        .snapshots()
        .map((snapshot) {
          final list =
              snapshot.docs
                  .map((doc) => LichHenModel.fromJson(doc.data(), id: doc.id))
                  // 2 = đã xác nhận (đang chờ), 7 = đến trễ
                  .where(
                    (b) =>
                        cungNgay(b.ngayDat) &&
                        (b.trangThaiId == '2' || b.trangThaiId == '7'),
                  )
                  .toList()
                ..sort((a, b) => a.soThuTu.compareTo(b.soThuTu));
          return list;
        });
  }
}
