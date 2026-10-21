import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';

/// Lỗi đã được "dịch" sang thông báo dễ hiểu để hiện lên giao diện.
class ReviewException implements Exception {
  final String message;
  const ReviewException(this.message);

  @override
  String toString() => message;
}

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tên collection chứa đánh giá.
  /// ⚠️ 'danh_sach' đang được dùng chung cho Bệnh viện, Khoa, Phòng khám...
  /// nên truy vấn collectionGroup có thể bị lẫn dữ liệu của bảng khác.
  /// Nên đặt tên riêng (ví dụ 'danh_gia') cho đánh giá rồi sửa hằng số này
  /// (và sửa cả seeder + Security Rules cho khớp).
  static const String _reviewCollection = 'danh_sach';

  /// Lấy các đánh giá mới nhất của 1 khoa.
  /// [limit] mặc định 100: đủ để chia tab theo sao và tính điểm trung bình.
  Future<List<ReviewModel>> getReviewsByDepartment({
    required String hospitalId,
    required String khoaId,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collectionGroup(_reviewCollection)
          .where('benh_vien_id', isEqualTo: hospitalId)
          .where('khoa_id', isEqualTo: khoaId)
          .orderBy('ngay_tao', descending: true)
          .limit(limit)
          .get();

      final reviews = <ReviewModel>[];
      for (final doc in snapshot.docs) {
        // 1 document lỗi không được làm hỏng cả danh sách
        try {
          reviews.add(ReviewModel.fromJson(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Bỏ qua đánh giá không hợp lệ ${doc.reference.path}: $e');
        }
      }
      return reviews;
    } on FirebaseException catch (e) {
      // Với failed-precondition, thông báo gốc có chứa LINK TẠO INDEX
      debugPrint('Lỗi Firestore khi tải đánh giá [${e.code}]: ${e.message}');
      switch (e.code) {
        case 'failed-precondition':
          throw const ReviewException(
            'Cần tạo chỉ mục (index) Firestore cho truy vấn đánh giá. '
            'Xem Debug Console để lấy liên kết tạo.',
          );
        case 'permission-denied':
          throw const ReviewException('Không có quyền đọc đánh giá.');
        default:
          throw const ReviewException('Không thể tải đánh giá. Vui lòng thử lại.');
      }
    } catch (e) {
      debugPrint('Lỗi khi tải đánh giá: $e');
      throw const ReviewException('Không thể tải đánh giá. Vui lòng thử lại.');
    }
  }
}