import 'package:cloud_firestore/cloud_firestore.dart';

/// KhungGio: khung giờ làm việc của một ca (giờ bắt đầu, giờ kết thúc).
class KhungGio {
  final String batDau;
  final String ketThuc;
  const KhungGio(this.batDau, this.ketThuc);

  Map<String, dynamic> toMap() => {'batDau': batDau, 'ketThuc': ketThuc};
  String get text => '$batDau - $ketThuc';

  int get soPhut => _phut(ketThuc) - _phut(batDau);

  /// _phut: đổi chuỗi "HH:mm" thành tổng số phút trong ngày.
  static int _phut(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

/// KhoaVuaTao: kết quả trả về sau khi tạo khoa thành công.
class KhoaVuaTao {
  final String khoaId;
  final String tenKhoa;
  final int soCaMoiNgay;
  final int gioiHanBenhNhan;
  final List<KhungGio> khungGio;
  final String lichLamViec;

  const KhoaVuaTao({
    required this.khoaId,
    required this.tenKhoa,
    required this.soCaMoiNgay,
    required this.gioiHanBenhNhan,
    required this.khungGio,
    required this.lichLamViec,
  });
}

/// TrangThaiPhong: trạng thái hoạt động của phòng khám (12 tạm dừng, 13 đang khám, 14 đóng cửa).
enum TrangThaiPhong {
  tamDung(12),
  dangKham(13),
  dongCua(14);

  final int ma;
  const TrangThaiPhong(this.ma);

  /// tuMa: đổi giá trị đọc từ Firestore (số hoặc chuỗi) thành trạng thái phòng, không khớp thì xem là đang khám.
  static TrangThaiPhong tuMa(dynamic v) {
    final int? maSo = v is int ? v : int.tryParse(v?.toString() ?? '');
    switch (maSo) {
      case 12:
        return TrangThaiPhong.tamDung;
      case 14:
        return TrangThaiPhong.dongCua;
      default:
        return TrangThaiPhong.dangKham;
    }
  }
}

/// PhongKhamTrangThai: trạng thái phòng khám kèm thông tin thời gian tạm dừng trong ngày.
class PhongKhamTrangThai {
  final TrangThaiPhong trangThai;
  final DateTime? tamDungTu;
  final int tongPhutTamDung;
  final String? ngayTamDung;

  const PhongKhamTrangThai({
    required this.trangThai,
    this.tamDungTu,
    this.tongPhutTamDung = 0,
    this.ngayTamDung,
  });

  static const PhongKhamTrangThai macDinh = PhongKhamTrangThai(
    trangThai: TrangThaiPhong.dangKham,
  );

  /// tuMap: dựng trạng thái phòng từ document PhongKham (trạng thái đọc từ trang_thai_id).
  factory PhongKhamTrangThai.tuMap(Map<String, dynamic> d) {
    final ts = d['tam_dung_tu'];
    final tong = d['tong_phut_tam_dung'];
    return PhongKhamTrangThai(
      trangThai: TrangThaiPhong.tuMa(d['trang_thai_id']),
      tamDungTu: ts is Timestamp ? ts.toDate() : null,
      tongPhutTamDung: tong is num ? tong.toInt() : int.tryParse('$tong') ?? 0,
      ngayTamDung: d['ngay_tam_dung']?.toString(),
    );
  }

  /// phutDangTamDung: số phút của đợt tạm dừng hiện tại (0 nếu phòng không đang tạm dừng).
  int phutDangTamDung(DateTime now) {
    if (trangThai != TrangThaiPhong.tamDung || tamDungTu == null) return 0;
    final phut = now.difference(tamDungTu!).inMinutes;
    return phut < 0 ? 0 : phut;
  }

  /// phutTamDung: tổng số phút phòng đã tạm dừng trong ngày, gồm các đợt đã kết thúc và đợt đang diễn ra.
  int phutTamDung(DateTime now) {
    final daTichLuy = ngayTamDung == _ngayId(now) ? tongPhutTamDung : 0;
    return daTichLuy + phutDangTamDung(now);
  }
}

/// _ngayId: định dạng ngày thành chuỗi "yyyy-MM-dd".
String _ngayId(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// nhanNgay: đổi số thứ trong tuần thành nhãn (2..7 là Thứ 2..Thứ 7, 8 là Chủ nhật).
String nhanNgay(int d) => d == 8 ? 'CN' : 'Thứ $d';

/// taoLichLamViec: tạo chuỗi lịch làm việc, ví dụ [2..7] thành "Thứ 2 đến Thứ 7", không liên tục thành "Thứ 2, Thứ 4, CN".
String taoLichLamViec(List<int> ngay) {
  final s = [...ngay]..sort();
  if (s.isEmpty) return '';
  if (s.length == 7) return 'Cả tuần';
  final lienTuc = s.length >= 3 && s.last - s.first == s.length - 1;
  if (lienTuc) return '${nhanNgay(s.first)} đến ${nhanNgay(s.last)}';
  return s.map(nhanNgay).join(', ');
}

/// tachSoPhong: tách số phòng từ tên phòng, ví dụ "Phòng 405 - Tầng 4" thành "405" (không thấy thì trả về rỗng).
String tachSoPhong(String tenPhong) {
  final m = RegExp(r'[Pp]hòng\s*([0-9]+[A-Za-z]?)').firstMatch(tenPhong);
  return m?.group(1) ?? '';
}

/// KhoaService: truy cập Firestore cho khoa khám, phòng khám và trạng thái phòng khám.
class KhoaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _colPhongKham = 'PhongKham';

  /// _khoaRef: tham chiếu document khoa Khoa/{benhVienId}/danh_sach/{khoaId}.
  DocumentReference<Map<String, dynamic>> _khoaRef(
    String benhVienId,
    String khoaId,
  ) => _db
      .collection('Khoa')
      .doc(benhVienId)
      .collection('danh_sach')
      .doc(khoaId);

  /// themKhoa: tạo một khoa cùng các phòng khám của khoa trong một batch.
  Future<KhoaVuaTao> themKhoa({
    required String benhVienId,
    required String tenKhoa,
    required int soCaMoiNgay,
    required int gioiHanBenhNhan,
    required List<KhungGio> khungGio,
    required List<int> ngayLamViec,
    required List<String> phongKham,
  }) async {
    if (benhVienId.trim().isEmpty) {
      throw Exception(
        'Chưa có benhVienId. Hãy truyền ID document trong collection benhVien vào ThemKhoaScreen.',
      );
    }

    // Bước 1: tạo tham chiếu khoa với ID tự sinh và tính lịch làm việc.
    final khoaRef = _db
        .collection('Khoa')
        .doc(benhVienId)
        .collection('danh_sach')
        .doc();
    final lich = taoLichLamViec(ngayLamViec);

    // Bước 2: sắp xếp khung giờ, lấy giờ mở sớm nhất, giờ đóng muộn nhất và thời gian khám mỗi bệnh nhân.
    final ds = [...khungGio]..sort((a, b) => a.batDau.compareTo(b.batDau));
    final gioMoCua = ds.first.batDau;
    final gioDongCua = ds
        .map((e) => e.ketThuc)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final thoiGianKham = (ds.first.soPhut ~/ gioiHanBenhNhan)
        .clamp(1, 1000)
        .toInt();

    final batch = _db.batch();

    // Bước 3: ghi document khoa.
    batch.set(khoaRef, {
      'tenKhoa': tenKhoa,
      'moTa': '',
      'soPhong': phongKham.length,
      'soCaMoiNgay': soCaMoiNgay,
      'gioiHanBenhNhan': gioiHanBenhNhan,
      'phongDau': phongKham.isNotEmpty ? phongKham.first : '',
      'khungGio': ds.map((e) => e.toMap()).toList(),
      'ngayLamViec': ([...ngayLamViec]..sort()),
      'lichLamViec': lich,
      'trangThai': 'dang_mo',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    // Bước 4: ghi từng phòng khám với trạng thái mặc định là đang khám (13).
    for (final ten in phongKham) {
      final phongRef = khoaRef.collection('phongKham').doc();
      batch.set(phongRef, {
        'tenPhong': ten,
        'soPhong': tachSoPhong(ten),
        'gioMoCua': gioMoCua,
        'gioDongCua': gioDongCua,
        'khungGio': ds.map((e) => e.toMap()).toList(),
        'thoiGianKham': thoiGianKham,
        'soBenhNhanToiDa': gioiHanBenhNhan,
        'trang_thai_id': TrangThaiPhong.dangKham.ma,
        'tam_dung_tu': null,
        'tong_phut_tam_dung': 0,
        'ngay_tam_dung': null,
        'nhanVienId': null,
      });
    }

    // Bước 5: ghi batch và trả về thông tin khoa vừa tạo.
    await batch.commit();

    return KhoaVuaTao(
      khoaId: khoaRef.id,
      tenKhoa: tenKhoa,
      soCaMoiNgay: soCaMoiNgay,
      gioiHanBenhNhan: gioiHanBenhNhan,
      khungGio: ds,
      lichLamViec: lich,
    );
  }

  /// capNhatKhoa: cập nhật thông tin khoa và đồng bộ danh sách phòng khám (giữ trạng thái của phòng cũ).
  Future<void> capNhatKhoa({
    required String benhVienId,
    required String khoaId,
    required String tenKhoa,
    required int soCaMoiNgay,
    required int gioiHanBenhNhan,
    required List<KhungGio> khungGio,
    required List<int> ngayLamViec,
    required List<String> phongKham,
  }) async {
    // Bước 1: tính lịch làm việc, giờ mở đóng cửa và thời gian khám mỗi bệnh nhân.
    final khoaRef = _khoaRef(benhVienId, khoaId);
    final lich = taoLichLamViec(ngayLamViec);

    final ds = [...khungGio]..sort((a, b) => a.batDau.compareTo(b.batDau));
    final gioMoCua = ds.first.batDau;
    final gioDongCua = ds
        .map((e) => e.ketThuc)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final thoiGianKham = (ds.first.soPhut ~/ gioiHanBenhNhan)
        .clamp(1, 1000)
        .toInt();

    final batch = _db.batch();

    // Bước 2: cập nhật document khoa.
    batch.update(khoaRef, {
      'tenKhoa': tenKhoa,
      'soPhong': phongKham.length,
      'soCaMoiNgay': soCaMoiNgay,
      'gioiHanBenhNhan': gioiHanBenhNhan,
      'phongDau': phongKham.isNotEmpty ? phongKham.first : '',
      'khungGio': ds.map((e) => e.toMap()).toList(),
      'ngayLamViec': ([...ngayLamViec]..sort()),
      'lichLamViec': lich,
      'ngayCapNhat': FieldValue.serverTimestamp(),
    });

    // Bước 3: đọc các phòng cũ và xóa những phòng không còn trong danh sách mới.
    final oldRoomsSnap = await khoaRef.collection('phongKham').get();
    final Map<String, DocumentSnapshot<Map<String, dynamic>>> oldRooms = {
      for (final d in oldRoomsSnap.docs)
        (d.data()['tenPhong'] ?? '').toString(): d,
    };

    for (final d in oldRoomsSnap.docs) {
      final oldName = (d.data()['tenPhong'] ?? '').toString();
      if (!phongKham.contains(oldName)) {
        batch.delete(d.reference);
      }
    }

    // Bước 4: thêm phòng mới hoặc cập nhật phòng cũ, giữ nguyên trạng thái và nhân viên phụ trách.
    for (final ten in phongKham) {
      final docRef = oldRooms.containsKey(ten)
          ? oldRooms[ten]!.reference
          : khoaRef.collection('phongKham').doc();

      final existingData = oldRooms[ten]?.data();

      batch.set(docRef, {
        'tenPhong': ten,
        'soPhong': tachSoPhong(ten),
        'gioMoCua': gioMoCua,
        'gioDongCua': gioDongCua,
        'khungGio': ds.map((e) => e.toMap()).toList(),
        'thoiGianKham': thoiGianKham,
        'soBenhNhanToiDa': gioiHanBenhNhan,
        'trang_thai_id':
            existingData?['trang_thai_id'] ?? TrangThaiPhong.dangKham.ma,
        'nhanVienId': existingData?['nhanVienId'],
      }, SetOptions(merge: true));
    }

    // Bước 5: ghi batch.
    await batch.commit();
  }

  /// xoaKhoa: xóa khoa cùng toàn bộ phòng khám thuộc khoa.
  Future<void> xoaKhoa({
    required String benhVienId,
    required String khoaId,
  }) async {
    // Bước 1: lấy các phòng khám con và đưa vào batch xóa.
    final khoaRef = _khoaRef(benhVienId, khoaId);
    final phongs = await khoaRef.collection('phongKham').get();
    final batch = _db.batch();
    for (final d in phongs.docs) {
      batch.delete(d.reference);
    }

    // Bước 2: xóa document khoa rồi ghi batch.
    batch.delete(khoaRef);
    await batch.commit();
  }

  /// dsKhoa: lắng nghe danh sách khoa của bệnh viện cho màn Trang chủ.
  Stream<QuerySnapshot<Map<String, dynamic>>> dsKhoa(String benhVienId) {
    return _db
        .collection('Khoa')
        .doc(benhVienId)
        .collection('danh_sach')
        .orderBy('ngayTao', descending: true)
        .snapshots();
  }

  /// dsPhong: lấy danh sách phòng khám của một khoa.
  Future<List<Map<String, dynamic>>> dsPhong(
    String benhVienId,
    String khoaId,
  ) async {
    final snap = await _khoaRef(
      benhVienId,
      khoaId,
    ).collection('phongKham').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// theoDoiTrangThaiPhong: lắng nghe trực tiếp trạng thái phòng khám từ collection PhongKham.
  Stream<PhongKhamTrangThai> theoDoiTrangThaiPhong({
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
  }) {
    return _db.collection(_colPhongKham).doc(phongKhamId).snapshots().map((
      snap,
    ) {
      final data = snap.data();
      if (!snap.exists || data == null) return PhongKhamTrangThai.macDinh;
      return PhongKhamTrangThai.tuMap(data);
    });
  }

  /// capNhatTrangThaiPhong: đổi trạng thái phòng khám và cộng dồn số phút tạm dừng trong ngày khi phòng thoát khỏi trạng thái tạm dừng.
  Future<void> capNhatTrangThaiPhong({
    required String benhVienId,
    required String khoaId,
    required String phongKhamId,
    required TrangThaiPhong trangThaiMoi,
  }) async {
    final ref = _db.collection(_colPhongKham).doc(phongKhamId);

    await _db.runTransaction((tx) async {
      // Bước 1: đọc trạng thái hiện tại của phòng.
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Không tìm thấy phòng khám.');
      final data = snap.data()!;
      final hienTai = PhongKhamTrangThai.tuMap(data);
      final now = DateTime.now();
      final homNay = _ngayId(now);

      // Bước 2: lấy số phút đã tích lũy của hôm nay (sang ngày mới thì tính lại từ 0).
      var tong = hienTai.ngayTamDung == homNay ? hienTai.tongPhutTamDung : 0;

      // Bước 3: nếu phòng đang tạm dừng và chuyển sang trạng thái khác thì cộng đợt tạm dừng vừa kết thúc.
      final dangTamDung = hienTai.trangThai == TrangThaiPhong.tamDung;
      if (dangTamDung && trangThaiMoi != TrangThaiPhong.tamDung) {
        tong += hienTai.phutDangTamDung(now);
      }

      // Bước 4: xác định thời điểm bắt đầu tạm dừng (giữ nguyên nếu đang tạm dừng, đặt mới nếu vừa chuyển sang tạm dừng).
      final Object? tamDungTu;
      if (trangThaiMoi != TrangThaiPhong.tamDung) {
        tamDungTu = null;
      } else if (dangTamDung && data['tam_dung_tu'] != null) {
        tamDungTu = data['tam_dung_tu'];
      } else {
        tamDungTu = FieldValue.serverTimestamp();
      }

      // Bước 5: ghi trạng thái mới cùng thông tin tạm dừng.
      tx.update(ref, {
        'trang_thai_id': trangThaiMoi.ma,
        'tam_dung_tu': tamDungTu,
        'tong_phut_tam_dung': tong,
        'ngay_tam_dung': homNay,
        'thoi_gian_cap_nhat': FieldValue.serverTimestamp(),
      });
    });
  }
}