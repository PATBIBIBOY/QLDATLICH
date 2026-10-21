import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhongKhamSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // ==========================================
  // 1. MAPPING TÊN KHOA → PREFIX
  // ==========================================
  static final Map<String, String> _khoaPrefixMap = {
    'Khoa Nội tổng quát': 'NTQ', 'Khoa Ngoại tổng quát': 'NGT', 'Khoa Cấp cứu': 'CC',
    'Khoa Tim mạch': 'TM', 'Khoa Tiêu hóa': 'TH', 'Khoa Hô hấp': 'HH',
    'Khoa Thần kinh': 'TK', 'Khoa Cơ xương khớp': 'CXK', 'Khoa Sản phụ khoa': 'SPK',
    'Khoa Nhi': 'N', 'Khoa Mắt': 'M', 'Khoa Tai Mũi Họng': 'TMH',
    'Khoa Răng Hàm Mặt': 'NHM', 'Khoa Da liễu': 'DL', 'Khoa Ung bướu': 'UB',
    'Khoa Thận - Tiết niệu': 'TNU', 'Khoa Nội tiết': 'NT', 'Khoa Truyền nhiễm': 'TRI',
    'Khoa Hồi sức tích cực (ICU)': 'HS', 'Khoa Gây mê hồi sức': 'GM',
    'Khoa Chẩn đoán hình ảnh': 'CDHA', 'Khoa Xét nghiệm': 'XN',
    'Khoa Vật lý trị liệu': 'VLTL', 'Khoa Tâm thần': 'TT',
    'Khoa Y học cổ truyền': 'YHCT', 'Khoa Dinh dưỡng': 'DD',
    'Khoa Huyết học': 'HUY', 'Khoa Lão khoa': 'LK', 'Khoa Thẩm mỹ': 'THM',
    'Khoa Kiểm soát nhiễm khuẩn': 'KSNK',
  };

  static final List<String> _gioMoCua = ['07:00:00', '07:30:00', '08:00:00', '08:30:00'];
  static final List<String> _gioDongCua = ['16:00:00', '16:30:00', '17:00:00', '17:30:00', '18:00:00'];

  /// Hàm chính: Tạo dữ liệu Phòng Khám theo cấu trúc mới
  /// PhongKham/{hospitalId}/danh_sach/{khoaId}/danh_sach/{tenPhong}
  static Future<void> seedPhongKham() async {
    print('⏳ Bắt đầu tạo dữ liệu Phòng Khám...');
    print('📋 Cấu trúc: PhongKham/{hospitalId}/danh_sach/{khoaId}/danh_sach/{tenPhong}');

    int totalPhongKham = 0;
    int failedCount = 0;

    try {
      // 1. Lấy tất cả các khoa từ collection `Khoa`
      // Cấu trúc: Khoa/{hospitalId}/danh_sach/{khoaId}
      final khoaSnapshot = await _firestore.collectionGroup('danh_sach').get();
      print('🔍 Tìm thấy ${khoaSnapshot.docs.length} khoa từ tất cả bệnh viện.');

      // 2. Group các khoa theo hospitalId để tối ưu việc tạo document
      Map<String, List<Map<String, dynamic>>> hospitalsWithDepartments = {};

      for (var khoaDoc in khoaSnapshot.docs) {
        final pathSegments = khoaDoc.reference.path.split('/');
        if (pathSegments.length != 4 || pathSegments.first != 'Khoa') {
          continue;
        }

        final khoaData = khoaDoc.data();
        final khoaId = khoaDoc.id;
        final hospitalId = khoaDoc.reference.parent.parent?.id ?? '';
        final tenKhoa = khoaData['ten_khoa'] ?? 'Khoa không tên';

        if (!hospitalsWithDepartments.containsKey(hospitalId)) {
          hospitalsWithDepartments[hospitalId] = [];
        }

        hospitalsWithDepartments[hospitalId]!.add({
          'khoaId': khoaId,
          'tenKhoa': tenKhoa,
        });
      }

      print('📊 Tổng số bệnh viện có khoa: ${hospitalsWithDepartments.length}');

      // 3. Tạo dữ liệu cho từng bệnh viện
      for (var entry in hospitalsWithDepartments.entries) {
        final hospitalId = entry.key;
        final departments = entry.value;

        try {
          // Tạo document cho bệnh viện trong collection PhongKham
          final hospitalRef = _firestore.collection('PhongKham').doc(hospitalId);

          for (var dept in departments) {
            final khoaId = dept['khoaId'] as String;
            final tenKhoa = dept['tenKhoa'] as String;
            final prefix = _khoaPrefixMap[tenKhoa] ?? 'PK';

            // Tạo subcollection danh_sach cho khoa
            final khoaRef = hospitalRef.collection('danh_sach').doc(khoaId);

            // Tạo ngẫu nhiên 2-4 phòng khám cho mỗi khoa
            final numPhong = _random.nextInt(3) + 2;

            for (int i = 1; i <= numPhong; i++) {
              final roomName = '$prefix${i.toString().padLeft(3, '0')}';
              final doc = '${hospitalId}_${khoaId}_$roomName';
              try {
                // Tên phòng khám: N001, TM002, SPK003...
                final phongKhamData = {
                  'id': '${hospitalId}_${khoaId}_$roomName',
                  'hospital_id': hospitalId,
                  'khoa_id': khoaId,
                  'ten_phong': roomName,
                  'ten_khoa_goc': tenKhoa,
                  'prefix_khoa': prefix,
                  'gio_mo_cua': _gioMoCua[_random.nextInt(_gioMoCua.length)],
                  'gio_dong_cua': _gioDongCua[_random.nextInt(_gioDongCua.length)],
                  'thoi_gian_kham': [15, 20, 30][_random.nextInt(3)],
                  'so_benh_nhan_toi_da': 20 + _random.nextInt(31),
                  'nhan_vien_id': null,
                  'ngay_tao': FieldValue.serverTimestamp(),
                };

                // Lưu vào subcollection danh_sach của khoa
                await khoaRef
                  .collection('danh_sach')
                  .doc(doc)
                  .set(phongKhamData);

                totalPhongKham++;

                if (totalPhongKham % 100 == 0) {
                  print('   ✅ Đã tạo $totalPhongKham phòng khám...');
                }
              } catch (e) {
                failedCount++;
                print('   ❌ Lỗi khi tạo phòng khám $roomName cho khoa $khoaId: $e');
              }
            }
          }
        } catch (e) {
          failedCount++;
          print('❌ Lỗi khi xử lý bệnh viện $hospitalId: $e');
        }
      }

      print('\n🎉 HOÀN TẤT SEEDING PHÒNG KHÁM!');
      print('📊 Tổng số phòng khám đã tạo: $totalPhongKham');
      print('📊 Tổng số bệnh viện: ${hospitalsWithDepartments.length}');
      if (failedCount > 0) print('⚠️ Số lỗi: $failedCount');

    } catch (e) {
      print('❌ Lỗi khi seed phòng khám: $e');
      rethrow;
    }
  }
}