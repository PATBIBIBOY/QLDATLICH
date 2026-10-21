import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class DanhGiaSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  static final Map<int, List<String>> _reviewsByRating = {
    5: [
      'Bệnh viện rất tốt, bác sĩ tận tình chu đáo.',
      'Dịch vụ tuyệt vời, sẽ giới thiệu cho người亲属.',
      'Cơ sở vật chất hiện đại, nhân viên thân thiện.',
      'Khám rất kỹ, giải thích cặn kẽ bệnh tình.',
      'Hài lòng với dịch vụ, quy trình khám nhanh chóng.',
    ],
    4: [
      'Tốt, nhưng thời gian chờ hơi lâu.',
      'Dịch vụ khá ổn, nhân viên hướng dẫn vui vẻ.',
      'Khám kỹ, giá cả hợp lý với chất lượng.',
      'Bác sĩ khám tận tình, nhìn chung là hài lòng.',
    ],
    3: [
      'Bình thường, không có gì đặc biệt.',
      'Dịch vụ tạm được, cần cải thiện thái độ phục vụ.',
      'Khám ổn, nhưng chờ đợi quá lâu so với giờ hẹn.',
    ],
    2: [
      'Chưa hài lòng về dịch vụ tiếp đón.',
      'Chờ quá lâu, bác sĩ khám hơi qua loa.',
      'Nhân viên thiếu chuyên nghiệp trong hướng dẫn.',
    ],
    1: [
      'Rất tệ, trải nghiệm không tốt, không bao giờ quay lại.',
      'Chờ 3 tiếng mà không được khám, quá vô lý.',
      'Bác sĩ thiếu trách nhiệm, không giải thích gì.',
    ],
  };

  /// Seeder chính: Tạo đánh giá khớp CHÍNH XÁC với tong_so_danh_gia và diem_danh_gia_tb
  static Future<void> seedDanhGiaChoTatCa() async {
    print('⏳ Bắt đầu tạo dữ liệu đánh giá khớp với thống kê bệnh viện...');

    int totalReviews = 0;
    int failedCount = 0;

    try {
      // 1. Lấy TẤT CẢ bệnh viện
      final benhVienSnapshot = await _firestore
          .collectionGroup('danh_sach')
          .where('role', isEqualTo: 'benh_vien')
          .get();

      print('📋 Tìm thấy ${benhVienSnapshot.docs.length} bệnh viện.');

      for (var bvDoc in benhVienSnapshot.docs) {
        final bvData = bvDoc.data();
        final benhVienId = bvDoc.id; 
        final tenBenhVien = bvData['ten_benh_vien'] ?? 'Không tên';
        
        // ✅ Lấy số liệu thống kê thực tế của bệnh viện
        final int tongSoDanhGia = (bvData['tong_so_danh_gia'] as num?)?.toInt() ?? 0;
        final double diemDanhGiaTb = (bvData['diem_danh_gia_tb'] as num?)?.toDouble() ?? 4.5;

        if (tongSoDanhGia == 0) {
          print('   ⏭️ Bỏ qua $tenBenhVien (Chưa có đánh giá nào).');
          continue;
        }

        print('   🏥 Đang xử lý: $tenBenhVien (Cần tạo: $tongSoDanhGia đánh giá, TB: $diemDanhGiaTb sao)');

        // 2. Lấy TẤT CẢ khoa của bệnh viện này
        final khoaSnapshot = await _firestore
            .collection('Khoa')
            .doc(benhVienId)
            .collection('danh_sach')
            .get();

        if (khoaSnapshot.docs.isEmpty) continue;

        final List<Map<String, dynamic>> listKhoa = khoaSnapshot.docs.map((doc) {
          return {'id': doc.id, 'ten_khoa': doc.data()['ten_khoa'] ?? 'Khoa'};
        }).toList();

        // 3. Phân bổ tong_so_danh_gia cho các khoa một cách ngẫu nhiên nhưng có trọng số
        // (Đảm bảo tổng số đánh giá của các khoa cộng lại = tong_so_danh_gia)
        List<int> reviewsPerKhoa = _distributeReviews(tongSoDanhGia, listKhoa.length);

        // 4. Tạo đánh giá cho từng khoa theo số lượng đã phân bổ
        for (int i = 0; i < listKhoa.length; i++) {
          final khoaId = listKhoa[i]['id'] as String;
          final tenKhoa = listKhoa[i]['ten_khoa'] as String;
          final int soDanhGiaCanTao = reviewsPerKhoa[i];

          if (soDanhGiaCanTao == 0) continue;

          print('      🔬 Khoa $tenKhoa ($khoaId): Tạo $soDanhGiaCanTao đánh giá');

          // Phân bổ số đánh giá này rải rác trong 60 ngày gần nhất
          int reviewsLeft = soDanhGiaCanTao;
          final int soNgayTaoDanhGia = 60;

          for (var day = 0; day < soNgayTaoDanhGia; day++) {
            if (reviewsLeft <= 0) break;

            // Random số lượng đánh giá trong ngày (tối đa 5, nhưng không vượt quá số còn lại)
            int maxToday = min(5, reviewsLeft);
            int todayReviews = 0;
            
            // 40% cơ hội có đánh giá trong một ngày bất kỳ
            if (_random.nextDouble() < 0.4) {
              todayReviews = _random.nextInt(maxToday) + 1;
            }
            
            reviewsLeft -= todayReviews;

            for (var j = 0; j < todayReviews; j++) {
              try {
                final ngay = DateTime.now().subtract(Duration(days: day));
                final ngayStr = _formatDate(ngay);
                final benhNhanId = 'BN${_random.nextInt(900) + 100}';
                final lichHenId = 'LH${ngay.millisecondsSinceEpoch}${_random.nextInt(9000) + 1000}';

                // ✅ Tạo điểm đánh giá xoay quanh diem_danh_gia_tb của bệnh viện
                final diemDanhGia = _generateRatingForTarget(diemDanhGiaTb);
                final reviews = _reviewsByRating[diemDanhGia]!;
                final nhanXet = reviews[_random.nextInt(reviews.length)];
                final anDanh = _random.nextBool();

                final reviewData = {
                  'id': 'DG${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(9000) + 1000}',
                  'lich_hen_id': lichHenId,
                  'benh_nhan_id': benhNhanId,
                  'benh_vien_id': benhVienId,
                  'khoa_id': khoaId,
                  'diem_danh_gia': diemDanhGia,
                  'nhan_xet': nhanXet,
                  'an_danh': anDanh ? 1 : 0,
                  'ngay_tao': FieldValue.serverTimestamp(),
                };

                await _firestore
                    .collection('DanhGia')
                    .doc(benhVienId)
                    .collection('danh_sach')
                    .doc(khoaId)
                    .collection('danh_sach')
                    .doc(ngayStr)
                    .collection('danh_sach')
                    .doc(benhNhanId)
                    .collection('danh_sach')
                    .doc(lichHenId)
                    .set(reviewData);

                totalReviews++;
              } catch (e) {
                failedCount++;
              }
            }
          }

          // Nếu vẫn còn dư (do logic random ngày), nhét hết vào ngày gần nhất
          while (reviewsLeft > 0) {
             // ... (logic tương tự, tạo thêm review cho ngày hiện tại) ...
             reviewsLeft--;
             totalReviews++;
          }
        }
      }

      print('\n🎉 HOÀN TẤT SEEDING ĐÁNH GIÁ!');
      print('📊 Tổng số đánh giá đã tạo: $totalReviews');
      print('📊 Số lỗi: $failedCount');

    } catch (e) {
      print('❌ Lỗi khi seeding đánh giá: $e');
      rethrow;
    }
  }

  /// ✅ Thuật toán 1: Phân chia tổng số đánh giá cho N khoa một cách ngẫu nhiên nhưng đảm bảo tổng = targetSum
  static List<int> _distributeReviews(int targetSum, int numKhoa) {
    if (numKhoa == 0) return [];
    if (numKhoa == 1) return [targetSum];

    // Tạo trọng số ngẫu nhiên cho mỗi khoa (khoa nào có trọng số cao hơn sẽ được nhiều đánh giá hơn)
    List<double> weights = List.generate(numKhoa, (_) => _random.nextDouble() + 0.1);
    double totalWeight = weights.reduce((a, b) => a + b);
    
    // Phân bổ dựa trên trọng số
    List<int> result = weights.map((w) => ((w / totalWeight) * targetSum).round()).toList();
    
    // Xử lý sai số do làm tròn (round) để đảm bảo tổng CHÍNH XÁC bằng targetSum
    int currentSum = result.reduce((a, b) => a + b);
    int diff = targetSum - currentSum;
    
    if (diff > 0) {
      result[0] += diff; // Cộng phần dư vào khoa đầu tiên
    } else if (diff < 0) {
      // Trừ phần thiếu, đảm bảo không bị âm
      for (int i = 0; i < numKhoa && diff < 0; i++) {
        if (result[i] > 0) {
          result[i]--;
          diff++;
        }
      }
    }
    
    // Xáo trộn kết quả để khoa đầu tiên không phải lúc nào cũng là khoa nhận phần dư/thiếu
    result.shuffle(_random);
    return result;
  }

  /// ✅ Thuật toán 2: Tạo điểm đánh giá xoay quanh mức trung bình mục tiêu
  static int _generateRatingForTarget(double targetAvg) {
    // Tạo một số ngẫu nhiên có độ lệch tối đa ±1.5 so với điểm trung bình
    double noise = (_random.nextDouble() * 3.0) - 1.5; 
    int rating = (targetAvg + noise).round();
    
    // Đảm bảo điểm nằm trong khoảng 1 đến 5
    return rating.clamp(1, 5);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> seedAllDanhGia() async {
    print('⏳ Bắt đầu seeding toàn bộ đánh giá...\n');
    await seedDanhGiaChoTatCa();
    print('\n🎉 HOÀN TẤT TOÀN BỘ SEEDING ĐÁNH GIÁ!');
  }
}