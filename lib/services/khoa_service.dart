import 'package:cloud_firestore/cloud_firestore.dart';

class KhungGio {
  final String batDau; // "07:30"
  final String ketThuc; // "11:30"
  const KhungGio(this.batDau, this.ketThuc);

  Map<String, dynamic> toMap() => {'batDau': batDau, 'ketThuc': ketThuc};
  String get text => '$batDau - $ketThuc';

  int get soPhut => _phut(ketThuc) - _phut(batDau);

  static int _phut(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

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

/// 2..7 = Thứ 2..Thứ 7, 8 = Chủ nhật
String nhanNgay(int d) => d == 8 ? 'CN' : 'Thứ $d';

/// [2,3,4,5,6,7] -> "Thứ 2 đến Thứ 7"; không liên tục -> "Thứ 2, Thứ 4, CN"
String taoLichLamViec(List<int> ngay) {
  final s = [...ngay]..sort();
  if (s.isEmpty) return '';
  if (s.length == 7) return 'Cả tuần';
  final lienTuc = s.length >= 3 && s.last - s.first == s.length - 1;
  if (lienTuc) return '${nhanNgay(s.first)} đến ${nhanNgay(s.last)}';
  return s.map(nhanNgay).join(', ');
}

/// "Phòng 405 - Tầng 4 ..." -> "405"; không tìm thấy -> ""
String tachSoPhong(String tenPhong) {
  final m = RegExp(r'[Pp]hòng\s*([0-9]+[A-Za-z]?)').firstMatch(tenPhong);
  return m?.group(1) ?? '';
}

class KhoaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tạo 1 document `khoa` + N document `phongKham` trong cùng một batch.
  /// Đường dẫn: Khoa/{benhVienId}/danh_sach/{khoaId}/phongKham/{phongId}
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
    final khoaRef = _db
        .collection('Khoa')
        .doc(benhVienId)
        .collection('danh_sach')
        .doc(); // ID tự sinh
    final lich = taoLichLamViec(ngayLamViec);

    // Giờ mở sớm nhất / đóng muộn nhất (chuỗi "HH:mm" so sánh được)
    final ds = [...khungGio]..sort((a, b) => a.batDau.compareTo(b.batDau));
    final gioMoCua = ds.first.batDau;
    final gioDongCua = ds
        .map((e) => e.ketThuc)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);

    // Số phút khám mỗi bệnh nhân = thời lượng buổi đầu / số BN mỗi buổi
    final thoiGianKham = (ds.first.soPhut ~/ gioiHanBenhNhan)
        .clamp(1, 1000)
        .toInt();

    final batch = _db.batch();

    // 1) Khoa
    batch.set(khoaRef, {
      'tenKhoa': tenKhoa,
      'moTa': '',
      'soPhong': phongKham.length,
      'soCaMoiNgay': soCaMoiNgay,
      'gioiHanBenhNhan': gioiHanBenhNhan, // dùng cho thẻ ở Trang chủ
      'phongDau': phongKham.first, // tên phòng đầu tiên, dùng cho thẻ
      'khungGio': ds.map((e) => e.toMap()).toList(), // dùng cho màn chi tiết
      'ngayLamViec': ([...ngayLamViec]..sort()),
      'lichLamViec': lich,
      'trangThai': 'dang_mo',
      'ngayTao': FieldValue.serverTimestamp(),
    });

    // 2) Các phòng khám (subcollection của khoa)
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
        'trangThai': 'san_sang', // san_sang | dang_kham | tam_dong
        'nhanVienId': null, // gán bác sĩ phụ trách sau ở màn Nhân viên
      });
    }

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

  /// Lấy danh sách khoa cho màn Trang chủ
  Stream<QuerySnapshot<Map<String, dynamic>>> dsKhoa(String benhVienId) {
    return _db
        .collection('Khoa')
        .doc(benhVienId)
        .collection('danh_sach')
        .orderBy('ngayTao', descending: true)
        .snapshots();
  }

  /// Lấy các phòng của một khoa
  Future<List<Map<String, dynamic>>> dsPhong(
    String benhVienId,
    String khoaId,
  ) async {
    final snap = await _db
        .collection('Khoa')
        .doc(benhVienId)
        .collection('danh_sach')
        .doc(khoaId)
        .collection('phongKham')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
