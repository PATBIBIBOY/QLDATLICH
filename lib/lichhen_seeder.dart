import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LichHenSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // Tên các collection (cố ý KHÔNG dùng 'danh_sach' để các truy vấn
  // collectionGroup('danh_sach') của danh sách bệnh viện không bị lẫn lịch hẹn)
  static const String _colLichHen = 'LichHen';
  static const String _colCaTrongNgay = 'ca';
  static const String _colBenhVien = 'benh_vien';
  static const String _colKhoa = 'khoa';
  static const String _colPhongKham = 'phong_kham';
  static const String _colBenhNhan = 'benh_nhan';
  static const String _colLichHenCuaBenhNhan = 'lich_hen';

  static const String _benhVienId = 'BV001';

  /// Các ngày cần seed: 18, 19, 20, 21, 22 / 10 / 2026
  static final List<DateTime> _danhSachNgayHen = [
    DateTime(2026, 10, 18),
    DateTime(2026, 10, 19),
    DateTime(2026, 10, 20),
    DateTime(2026, 10, 21),
    DateTime(2026, 10, 22),
  ];

  /// Dữ liệu bảng Ca (dùng chung cho seedCaKham và seedLichHen)
  static const List<Map<String, String>> _danhSachCa = [
    {
      'id': 'ca_sang',
      'ten_ca': 'Ca sáng',
      'gio_bat_dau': '07:30',
      'gio_ket_thuc': '12:00',
    },
    {
      'id': 'ca_chieu',
      'ten_ca': 'Ca chiều',
      'gio_bat_dau': '13:30',
      'gio_ket_thuc': '17:00',
    },
  ];

  // ───────────────────────── Hàm định dạng ngày ─────────────────────────

  /// Id của ngày trong Firestore: 2026-10-18
  /// (không dùng "18/10/2026" vì Firestore không cho phép dấu "/" trong id)
  static String _ngayId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Dạng liền để ghép vào id lịch hẹn: 20261018
  static String _ngayCode(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  /// Dạng hiển thị: 18/10/2026
  static String _ngayHienThi(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ═══════════════════════════════════════════════════════════════
  // 1. SEED BẢNG CA  (Ca/ca_sang, Ca/ca_chieu)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> seedCaKham() async {
    print('⏳ Đang tạo dữ liệu ca khám...');

    try {
      for (final ca in _danhSachCa) {
        await _firestore.collection('Ca').doc(ca['id']).set({
          'id': ca['id'],
          'ten_ca': ca['ten_ca'],
          'gio_bat_dau': ca['gio_bat_dau'],
          'gio_ket_thuc': ca['gio_ket_thuc'],
          'ngay_tao': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print('✅ Hoàn tất seeding bảng Ca!\n');
    } catch (e) {
      print('❌ Lỗi khi seed bảng Ca: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. SEED LỊCH HẸN CHO NHIỀU NGÀY (18 -> 22/10/2026)
  //    Ngày -> Ca -> Bệnh viện (BV001) -> Khoa -> Phòng khám
  //    -> Bệnh nhân -> Lịch hẹn
  //
  // [force] = false: ngày nào đã có dữ liệu thì bỏ qua (tránh tạo trùng).
  // ═══════════════════════════════════════════════════════════════
  static Future<void> seedLichHen({bool force = false}) async {
    print('⏳ Đang tạo lịch hẹn cho ${_danhSachNgayHen.length} ngày...');

    try {
      // ── 0. Xác định ngày nào cần seed (bỏ qua ngày đã có dữ liệu) ──
      final List<DateTime> ngayCanSeed = [];
      for (final ngay in _danhSachNgayHen) {
        final ngayRef = _firestore.collection(_colLichHen).doc(_ngayId(ngay));
        if (!force && (await ngayRef.get()).exists) {
          print('⚠️ Ngày ${_ngayHienThi(ngay)} đã có dữ liệu, bỏ qua.');
        } else {
          ngayCanSeed.add(ngay);
        }
      }

      if (ngayCanSeed.isEmpty) {
        print(
          '✅ Không có ngày nào cần seed. '
          '(Xoá dữ liệu cũ trong Firestore hoặc gọi force: true để seed lại)',
        );
        return;
      }

      // ── 1. Kiểm tra bệnh viện BV001 ──
      final hospitalDoc = await _firestore
          .collection('BenhVien')
          .doc('10')
          .collection('co_so')
          .doc('Cong_lap')
          .collection('bhyt')
          .doc('Co_BHYT')
          .collection('danh_sach')
          .doc(_benhVienId)
          .get();

      if (!hospitalDoc.exists) {
        throw Exception('Không tìm thấy bệnh viện $_benhVienId');
      }
      final tenBenhVien = hospitalDoc.data()?['ten_benh_vien'];

      // ── 2. Lấy tất cả khoa của BV001 ──
      final khoaSnapshot = await _firestore
          .collection('Khoa')
          .doc(_benhVienId)
          .collection('danh_sach')
          .get();

      if (khoaSnapshot.docs.isEmpty) {
        throw Exception('$_benhVienId chưa có khoa nào');
      }
      print('🔍 Tìm thấy ${khoaSnapshot.docs.length} khoa của $_benhVienId');

      // ── 3. Lấy phòng khám của từng khoa (đọc 1 lần, dùng cho mọi ngày và ca) ──
      final List<_KhoaVaPhongKham> khoaList = [];
      for (final khoaDoc in khoaSnapshot.docs) {
        final khoaId = khoaDoc.id;
        final tenKhoa = (khoaDoc.data()['ten_khoa'] ?? 'Khoa').toString();

        final phongKhamSnapshot = await _firestore
            .collection('PhongKham')
            .doc(_benhVienId)
            .collection('danh_sach')
            .doc(khoaId)
            .collection('danh_sach')
            .get();

        if (phongKhamSnapshot.docs.isEmpty) {
          print('   ⚠️ Khoa $tenKhoa ($khoaId) chưa có phòng khám nào, bỏ qua');
          continue;
        }

        print(
          '   🔬 Khoa $tenKhoa ($khoaId): ${phongKhamSnapshot.docs.length} phòng khám',
        );
        khoaList.add(_KhoaVaPhongKham(khoaId, tenKhoa, phongKhamSnapshot.docs));
      }

      if (khoaList.isEmpty) {
        throw Exception('Không có khoa nào có phòng khám để tạo lịch hẹn');
      }

      // ── 4. Seed từng ngày ──
      int tongLichHen = 0;
      for (final ngay in ngayCanSeed) {
        tongLichHen += await _seedMotNgay(
          ngay: ngay,
          tenBenhVien: tenBenhVien,
          khoaList: khoaList,
        );
      }

      print('\n🎉 HOÀN TẤT SEEDING LỊCH HẸN!');
      print('📅 Số ngày đã seed: ${ngayCanSeed.length}');
      print('📊 Tổng số lịch hẹn đã tạo: $tongLichHen');
      print('🏥 Bệnh viện: $_benhVienId');
      print('🕒 Số ca mỗi ngày: ${_danhSachCa.length} (ca_sang, ca_chieu)');
      print('🏷️ Số khoa có phòng khám: ${khoaList.length}');
    } catch (e) {
      print('❌ Lỗi khi seed lịch hẹn: $e');
      rethrow;
    }
  }

  /// Seed toàn bộ lịch hẹn của 1 ngày. Trả về số lịch hẹn đã tạo.
  static Future<int> _seedMotNgay({
    required DateTime ngay,
    required dynamic tenBenhVien,
    required List<_KhoaVaPhongKham> khoaList,
  }) async {
    final ngayId = _ngayId(ngay);
    final ngayCode = _ngayCode(ngay);
    final ngayRef = _firestore.collection(_colLichHen).doc(ngayId);

    print('\n════════ Ngày ${_ngayHienThi(ngay)} (id: $ngayId) ════════');

    final writer = _BatchWriter(_firestore);
    int soLichHen = 0; // đếm trong ngày này

    // Cấp 1: ngày
    await writer.set(ngayRef, {
      'ngay': Timestamp.fromDate(ngay),
      'ngay_hien_thi': _ngayHienThi(ngay),
      'ngay_tao': FieldValue.serverTimestamp(),
    });

    // Cấp 2: ca
    for (final ca in _danhSachCa) {
      final caId = ca['id']!;
      print('📅 Ca: ${ca['ten_ca']} ($caId)');

      final caRef = ngayRef.collection(_colCaTrongNgay).doc(caId);
      await writer.set(caRef, {
        'ca_id': caId, // id của bảng Ca
        'ten_ca': ca['ten_ca'],
        'gio_bat_dau': ca['gio_bat_dau'],
        'gio_ket_thuc': ca['gio_ket_thuc'],
      });

      // Cấp 3: bệnh viện BV001
      final bvRef = caRef.collection(_colBenhVien).doc(_benhVienId);
      await writer.set(bvRef, {
        'benh_vien_id': _benhVienId,
        'ten_benh_vien': tenBenhVien,
      });

      // Cấp 4: khoa
      for (final khoa in khoaList) {
        final khoaRef = bvRef.collection(_colKhoa).doc(khoa.id);
        await writer.set(khoaRef, {'khoa_id': khoa.id, 'ten_khoa': khoa.ten});

        // Cấp 5: phòng khám
        for (final phongKhamDoc in khoa.phongKham) {
          final phongKhamId = phongKhamDoc.id;
          final soBenhNhanToiDa = max(
            1,
            (phongKhamDoc.data()['so_benh_nhan_toi_da'] as num?)?.toInt() ?? 25,
          );

          // Số bệnh nhân ngẫu nhiên của phòng khám này: từ 1 đến tối đa
          final soBenhNhan = _random.nextInt(soBenhNhanToiDa) + 1;

          final phongKhamRef = khoaRef
              .collection(_colPhongKham)
              .doc(phongKhamId);
          await writer.set(phongKhamRef, {
            'phong_kham_id': phongKhamId,
            'so_benh_nhan_toi_da': soBenhNhanToiDa,
            'so_lich_hen': soBenhNhan,
          });

          // Cấp 6: bệnh nhân -> Cấp 7: danh sách lịch hẹn -> dữ liệu lịch hẹn
          for (int i = 1; i <= soBenhNhan; i++) {
            soLichHen++;

            // Id bệnh nhân giả lập: BN0001, BN0002...
            final benhNhanId = 'BN${soLichHen.toString().padLeft(4, '0')}';
            // Id lịch hẹn có kèm ngày nên không trùng giữa các ngày
            final lichHenId = 'LH$ngayCode${soLichHen.toString().padLeft(5, '0')}';

            // Giờ dự kiến ngẫu nhiên trong ca
            final int hour = caId == 'ca_sang'
                ? _random.nextInt(5) + 7 // 7 - 11
                : _random.nextInt(4) + 13; // 13 - 16
            final int minute = _random.nextInt(4) * 15; // 0, 15, 30, 45
            final gioDuKien =
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

            // Trạng thái theo bảng TrangThai: 1 = Chờ duyệt,
            // 2 = Đã xác nhận, 3 = Chưa xác nhận
            final trangThaiId = _random.nextInt(3) + 1;

            final lichHenData = {
              'id': lichHenId,
              'ngay_hen': Timestamp.fromDate(ngay),
              'ca_id': caId, // ← id của bảng Ca (ca_sang / ca_chieu)
              'benh_vien_id': _benhVienId, // ← id bệnh viện
              'khoa_id': khoa.id,
              'phong_kham_id': phongKhamId,
              'benh_nhan_id': benhNhanId,
              'gio_du_kien': gioDuKien,
              'so_thu_tu': i,
              'trang_thai_id': trangThaiId,
              'nguoi_duyet_id': null,
              'ly_do_tu_choi': null,
              'thoi_gian_duyet': null,
              'ma_qr':
                  'QR$ngayCode${DateTime.now().millisecondsSinceEpoch}$soLichHen',
              'qr_da_su_dung': 0,
              'qr_het_han_luc': null,
              'ly_do_huy': null,
              'ngay_tao': FieldValue.serverTimestamp(),
              'ngay_cap_nhat': FieldValue.serverTimestamp(),
            };

            // Cấp 6: document bệnh nhân (chứa danh sách id lịch hẹn bên dưới)
            final benhNhanRef = phongKhamRef
                .collection(_colBenhNhan)
                .doc(benhNhanId);
            await writer.set(benhNhanRef, {
              'benh_nhan_id': benhNhanId,
              'so_lich_hen': 1,
            });

            // Cấp 7: danh sách id lịch hẹn của bệnh nhân -> dữ liệu lịch hẹn
            final lichHenRef = benhNhanRef
                .collection(_colLichHenCuaBenhNhan)
                .doc(lichHenId);
            await writer.set(lichHenRef, lichHenData);

            if (soLichHen % 100 == 0) {
              print('      ✅ Đã tạo $soLichHen lịch hẹn...');
            }
          }
        }
      }
    }

    await writer.flush(); // ghi nốt phần còn lại của ngày
    print('✅ Xong ngày ${_ngayHienThi(ngay)}: $soLichHen lịch hẹn');
    return soLichHen;
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. CHẠY TẤT CẢ
  // ═══════════════════════════════════════════════════════════════
  static Future<void> seedAllLichHen() async {
    print('⏳ Bắt đầu quá trình seeding lịch hẹn...\n');

    try {
      await seedCaKham();
      await seedLichHen();

      print('\n🎉 HOÀN TẤT TOÀN BỘ SEEDING LỊCH HẸN!');
    } catch (error) {
      print('❌ Seeder thất bại: $error');
    }
  }
}

/// Khoa kèm danh sách phòng khám của khoa đó.
class _KhoaVaPhongKham {
  final String id;
  final String ten;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> phongKham;

  _KhoaVaPhongKham(this.id, this.ten, this.phongKham);
}

/// Gom nhiều lệnh ghi vào 1 batch (Firestore cho tối đa 500 lệnh / batch).
class _BatchWriter {
  final FirebaseFirestore _db;
  WriteBatch _batch;
  int _count = 0;

  _BatchWriter(this._db) : _batch = _db.batch();

  Future<void> set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    _batch.set(ref, data);
    _count++;
    if (_count >= 400) await flush();
  }

  Future<void> flush() async {
    if (_count == 0) return;
    await _batch.commit();
    _batch = _db.batch();
    _count = 0;
  }
}