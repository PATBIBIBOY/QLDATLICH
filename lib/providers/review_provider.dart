import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;

  // Khoá của lần tải gần nhất (bệnh viện + khoa) để khỏi tải lại khi không đổi
  String? _loadedKey;
  // Mỗi lần gọi có 1 số thứ tự: kết quả của lần gọi cũ (về trễ) sẽ bị bỏ
  int _requestToken = 0;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ───────────────────────── Thống kê (UI dùng trực tiếp) ─────────────────────────

  int get totalCount => _reviews.length;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(0, (s, r) => s + r.diemDanhGia);
    return sum / _reviews.length;
  }

  /// Số đánh giá theo từng mức sao: {5: 12, 4: 3, 3: 0, 2: 1, 1: 0}
  Map<int, int> get countByStar {
    final result = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final star = r.diemDanhGia;
      if (result.containsKey(star)) result[star] = result[star]! + 1;
    }
    return result;
  }

  /// Các đánh giá của đúng [star] sao (giữ thứ tự mới nhất trước).
  List<ReviewModel> reviewsByStar(int star) =>
      _reviews.where((r) => r.diemDanhGia == star).toList();

  // ───────────────────────── Tải dữ liệu ─────────────────────────

  Future<void> fetchReviews({
    required String hospitalId,
    required String khoaId,
    bool force = false,
  }) async {
    final key = '$hospitalId|$khoaId';

    // Đã tải đúng khoa này và không lỗi -> dùng lại
    if (!force && key == _loadedKey && _error == null) return;

    final token = ++_requestToken;
    _loadedKey = key;
    _isLoading = true;
    _error = null;
    _reviews = []; // tránh hiện nhầm đánh giá của khoa trước
    notifyListeners();

    try {
      final result = await _service.getReviewsByDepartment(
        hospitalId: hospitalId,
        khoaId: khoaId,
      );
      if (token != _requestToken) return; // đã có yêu cầu mới hơn
      _reviews = result;
    } catch (e) {
      if (token != _requestToken) return;
      _error = e is ReviewException ? e.message : 'Không thể tải đánh giá.';
      _loadedKey = null; // cho phép thử lại
    } finally {
      if (token == _requestToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clearReviews() {
    _requestToken++; // huỷ mọi yêu cầu đang chạy
    _reviews = [];
    _error = null;
    _isLoading = false;
    _loadedKey = null;
    notifyListeners();
  }
}