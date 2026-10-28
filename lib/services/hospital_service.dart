import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/phong_kham_model.dart';

class HospitalPageResult {
  final List<Map<String, dynamic>> hospitals;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final String? locationSourceMessage;

  HospitalPageResult({
    required this.hospitals,
    required this.lastDocument,
    required this.hasMore,
    this.locationSourceMessage,
  });
}

class HospitalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final int _pageSize = 15;

  static const _fRole = 'role';
  static const _fCoSo = 'co_so_id';
  static const _fBhyt = 'bhyt_id';
  static const _fRating = 'diem_danh_gia_tb';
  static const _fSpecialties = 'chuyen_khoa_ids';

  Future<List<Map<String, dynamic>>> getCoSoList() async {
    final snapshot = await _firestore.collection('CoSo').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getBhytList() async {
    final snapshot = await _firestore.collection('BHYT').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Query<Map<String, dynamic>> _buildHospitalQuery({
    String? coSoId,
    String? bhytId,
    double? minRating,
    double? maxRating,
    List<String>? specialtyIds,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup('danh_sach')
        .where(_fRole, isEqualTo: 'benh_vien'); // loại document của Khoa

    if (coSoId != null && coSoId.isNotEmpty) {
      query = query.where(_fCoSo, isEqualTo: coSoId);
    }
    if (bhytId != null && bhytId.isNotEmpty) {
      query = query.where(_fBhyt, isEqualTo: bhytId);
    }
    if (minRating != null) {
      query = query.where(_fRating, isGreaterThanOrEqualTo: minRating);
    }
    if (maxRating != null) {
      query = query.where(_fRating, isLessThanOrEqualTo: maxRating);
    }
    if (specialtyIds != null && specialtyIds.isNotEmpty) {
      // Firestore chỉ cho tối đa 10 giá trị với arrayContainsAny
      query = query.where(
        _fSpecialties,
        arrayContainsAny: specialtyIds.take(10).toList(),
      );
    }
    return query;
  }

  /// Trả về null nếu đếm thất bại (KHÔNG trả 0 giả như trước).
  Future<int?> getFilteredHospitalCount({
    String? coSoId,
    String? bhytId,
    double? minRating,
    double? maxRating,
    List<String>? specialtyIds,
  }) async {
    try {
      final query = _buildHospitalQuery(
        coSoId: coSoId,
        bhytId: bhytId,
        minRating: minRating,
        maxRating: maxRating,
        specialtyIds: specialtyIds,
      );
      final snapshot = await query.count().get();
      return snapshot.count;
    } catch (e) {
      // Nếu lỗi là "requires an index" thì trong thông báo có link để tạo index
      print('❌ Lỗi khi đếm số lượng bệnh viện: $e');
      return null;
    }
  }

  Future<HospitalPageResult> getHospitalsPage({
    String? coSoId,
    String? bhytId,
    double? minRating,
    double? maxRating,
    Position? savedUserLocation,
    double? minDistance,
    double? maxDistance,
    DocumentSnapshot? lastDocument,
    List<String>? specialtyIds,
  }) async {
    try {
      // 1. Xác định Collection gốc
      Query<Map<String, dynamic>> query;
      if (coSoId != null &&
          coSoId.isNotEmpty &&
          bhytId != null &&
          bhytId.isNotEmpty) {
        query = _firestore
            .collection('BenhVien')
            .doc('10')
            .collection('co_so')
            .doc(coSoId)
            .collection('bhyt')
            .doc(bhytId)
            .collection('danh_sach');
      } else {
        query = _firestore.collectionGroup('danh_sach');
      }

      // 2. Áp dụng các bộ lọc an toàn cho Firestore
      if (specialtyIds != null && specialtyIds.isNotEmpty) {
        final validSpecialtyIds = specialtyIds.take(10).toList();
        query = query.where(
          'chuyen_khoa_ids',
          arrayContainsAny: validSpecialtyIds,
        );
      }

      // ✅ Chỉ dùng minRating trong Firestore để tránh xung đột index với arrayContainsAny
      if (minRating != null && minRating > 0) {
        query = query.where(
          'diem_danh_gia_tb',
          isGreaterThanOrEqualTo: minRating,
        );
      }

      // 3. Xác định logic vị trí và sắp xếp
      final hasDistanceFilter = minDistance != null || maxDistance != null;
      final locationResult = hasDistanceFilter
          ? await _locationService.getUserLocationWithSource(savedUserLocation)
          : null;
      final currentUserLocation = locationResult?.position;
      final applyDistanceFilter =
          currentUserLocation != null && hasDistanceFilter;

      // ✅ Luôn sắp xếp theo Rating giảm dần trong Firestore để lấy bệnh viện tốt nhất trước
      // Sau đó sẽ sắp xếp lại theo khoảng cách ở client-side nếu cần
      query = query
          .orderBy('diem_danh_gia_tb', descending: true)
          .orderBy('tong_so_danh_gia', descending: true)
          .orderBy(FieldPath.documentId);

      // 4. Cơ chế Phân trang bù đắp (Compensation Pagination)
      List<Map<String, dynamic>> finalPageResults = [];
      DocumentSnapshot? currentCursor = lastDocument;
      bool hasMoreInFirestore = true;

      // ✅ Nếu lọc khoảng cách, tải nhiều hơn _pageSize để có đủ dữ liệu lọc và sắp xếp lại
      final fetchBuffer = applyDistanceFilter
          ? (_pageSize * 3).clamp(30, 100)
          : _pageSize;

      while (finalPageResults.length < _pageSize && hasMoreInFirestore) {
        Query<Map<String, dynamic>> pageQuery = query;
        if (currentCursor != null) {
          pageQuery = pageQuery.startAfterDocument(currentCursor);
        }

        final snapshot = await pageQuery.limit(fetchBuffer).get();
        if (snapshot.docs.isEmpty) {
          hasMoreInFirestore = false;
          break;
        }

        List<Map<String, dynamic>> validCandidates = [];

        for (final doc in snapshot.docs) {
          currentCursor = doc; // ✅ Cập nhật cursor liên tục
          final path = doc.reference.path.split('/');

          // Xác thực đường dẫn (nếu dùng collectionGroup)
          if (path.length >= 8 && path[0] == 'BenhVien' && path[1] == '10') {
            if (coSoId != null && path[3] != coSoId) continue;
            if (bhytId != null && path[5] != bhytId) continue;
          }

          final hospital = {...doc.data(), 'id': doc.id};

          // --- BỘ LỌC CLIENT-SIDE ---

          // A. Lọc theo Max Rating
          final rating =
              (hospital['diem_danh_gia_tb'] as num?)?.toDouble() ?? 0.0;
          if (maxRating != null && rating > maxRating) continue;

          // B. Lọc theo Khoảng cách
          if (applyDistanceFilter) {
            final lat = hospital['vi_do'];
            final lon = hospital['kinh_do'];

            if (lat is num && lon is num) {
              final distance = _locationService.calculateDistanceInKm(
                currentUserLocation!.latitude,
                currentUserLocation!.longitude,
                lat.toDouble(),
                lon.toDouble(),
              );
              hospital['distance_km'] = distance;

              if ((minDistance != null && distance < minDistance) ||
                  (maxDistance != null && distance > maxDistance)) {
                continue; // Loại bỏ nếu nằm ngoài khoảng cách yêu cầu
              }
            } else {
              continue; // Loại bỏ nếu thiếu dữ liệu tọa độ
            }
          }

          validCandidates.add(hospital);
        }

        // ✅ Sắp xếp lại ứng viên hợp lệ theo khoảng cách (nếu đang lọc khoảng cách)
        if (applyDistanceFilter) {
          validCandidates.sort((a, b) {
            final distA = (a['distance_km'] as num).toDouble();
            final distB = (b['distance_km'] as num).toDouble();
            return distA.compareTo(distB);
          });
        }

        // Thêm vào kết quả cuối cùng cho đến khi đủ _pageSize
        for (var candidate in validCandidates) {
          finalPageResults.add(candidate);
          if (finalPageResults.length == _pageSize) break;
        }
      }

      // 5. Trả về kết quả
      return HospitalPageResult(
        hospitals: finalPageResults,
        lastDocument: currentCursor, // ✅ Cursor chính xác cho lần tải tiếp theo
        hasMore:
            hasMoreInFirestore, // ✅ Nếu Firestore hết dữ liệu, không thể tải thêm
        locationSourceMessage: locationResult?.message,
      );
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách bệnh viện: $e');
    }
  }

  // Helper function để tìm index của lastDocument
  int _findStartIndex(
    List<Map<String, dynamic>> hospitals,
    DocumentSnapshot lastDoc,
  ) {
    // Logic tìm index dựa vào ID hoặc timestamp
    // Đây là placeholder, bạn cần implement dựa trên cấu trúc dữ liệu thực tế
    return 0;
  }

  /// ✅ Lấy danh sách tất cả chuyên khoa từ collection 'chuyen_khoa'
  Future<List<Map<String, dynamic>>> getSpecialtiesList() async {
    try {
      final snapshot = await _firestore.collection('chuyen_khoa').get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách chuyên khoa: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHospitals() async {
    final snapshot = await _firestore
        .collectionGroup('danh_sach')
        .where('role', isEqualTo: 'benh_vien') // loại document của Khoa
        .get();

    return snapshot.docs
        .map(
          (doc) => {...doc.data(), 'id': doc.id},
        ) // UI đang dùng hospital['id']
        .toList();
  }

  Future<List<PhongKhamModel>> getPhongKhamList({
    required String hospitalId,
    required String khoaId,
  }) async {
    try {
    
      final snapshot = await _firestore
          .collection('PhongKham')
          .doc(hospitalId)
          .collection('danh_sach')
          .doc(khoaId)
          .collection('danh_sach')
          .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Tìm thấy ${snapshot.docs.length} phòng khám (subcollection).');
        return snapshot.docs.map((doc) {
          return PhongKhamModel.fromMap(doc.data(), doc.id);
        }).toList();
      }

      // Dự phòng: Tìm trực tiếp trong root collection PhongKham (theo chuẩn hình ảnh)
      final rootSnap = await _firestore
          .collection('PhongKham')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('khoaId', isEqualTo: khoaId)
          .get();

      debugPrint('✅ Tìm thấy ${rootSnap.docs.length} phòng khám (root collection).');
      return rootSnap.docs.map((doc) {
        return PhongKhamModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy danh sách phòng khám: $e');
      throw Exception('Lỗi khi lấy danh sách phòng khám: $e');
    }
  }
}
