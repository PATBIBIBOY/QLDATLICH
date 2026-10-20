import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/appointment_item.dart';          // ✅ THÊM
import '../../models/lichhen_model.dart';
import '../../models/phong_kham_model.dart';
import '../../models/review_model.dart';
import '../../providers/lich_hen_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/hospital_service.dart';
import '../../services/lichhen_service.dart';
import '../../widgets/appointment_card.dart';
import 'booking_confirm_sheet.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  // Bảng màu lấy từ hình ảnh
  static const Color _bgColor = Color(0xFFF7F7F8);
  static const Color _primaryBlue = Color(0xFF2196F3);
  static const Color _primaryGreen = Color(
    0xFF5B8C3E,
  ); // Màu xanh olive của nút bấm
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _borderColor = Color(0xFFE0E0E0);

  /// Số ngày hiển thị sẵn trong danh sách: hôm nay + 5 ngày tiếp theo.
  static const int _soNgayHienThi = 6;

  bool _isSpecialtyExpanded =
      true; // Mặc định mở rộng danh sách khoa như trong hình

  Map<String, dynamic>? _hospitalData;
  List<Map<String, dynamic>> _departments = [];
  bool _isLoadingDepartments = true;
  String? _departmentLoadError;
  final Set<String> _selectedDepartmentIds = {};

  // ── Lịch khám theo từng khoa ──
  // ID của khoa đang được hiển thị lịch khám (null khi chưa chọn khoa nào)
  String? _activeDepartmentId;
  // Mỗi khoa nhớ riêng phòng khám, ngày và ca (id ca) đã chọn
  final Map<String, String> _selectedRoomByDept = {}; // id khoa -> id phòng
  final Map<String, DateTime> _selectedDayByDept = {}; // id khoa -> ngày khám
  final Map<String, String> _selectedSlotByDept =
      {}; // id khoa -> id ca (ca_sang / ca_chieu)

  // Điều khiển cuộn danh sách ngày (để cuộn tới ngày chọn từ lịch tháng)
  final ScrollController _dayScroll = ScrollController();

  // ── Phòng khám lấy từ Firestore (HospitalService) ──
  final HospitalService _hospitalService = HospitalService();
  final LichHenService _lichHenService = LichHenService();
  String _hospitalId = '';
  // Cache danh sách phòng theo khoa: id khoa -> danh sách phòng
  final Map<String, List<PhongKhamModel>> _roomsByDept = {};
  final Set<String> _loadingRoomDepts = {};
  final Map<String, String> _roomErrorByDept = {};

  // ── Đánh giá (tab 5 sao → 1 sao) ──
  int _selectedStar = 5; // tab sao đang chọn
  int _reviewVisibleCount = 5; // số đánh giá đang hiện (bấm "Xem thêm" để tăng)

  @override
  void dispose() {
    _dayScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 2. Lấy dữ liệu chỉ 1 lần duy nhất khi màn hình mở
    if (_hospitalData == null) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        _hospitalData = args;
        final hospitalId = (args['id'] ?? args['ma_benh_vien'] ?? '')
            .toString();
        _hospitalId = hospitalId;
        _fetchDepartments(hospitalId);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    }
  }

  Future<void> _fetchDepartments(String hospitalId) async {
    if (hospitalId.isEmpty) {
      setState(() {
        _isLoadingDepartments = false;
        _departmentLoadError = 'Không xác định được bệnh viện.';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Khoa')
          .doc(hospitalId)
          .collection('danh_sach')
          .get();

      if (!mounted) return;
      setState(() {
        _departments = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _isLoadingDepartments = false;
        _departmentLoadError = null;
      });
    } catch (e) {
      debugPrint('Lỗi khi lấy danh sách khoa: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingDepartments = false;
        _departmentLoadError = 'Không thể tải danh sách chuyên khoa.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hospitalData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHospitalCard(),
                    const SizedBox(height: 16),
                    _buildInfoBox(),
                    const SizedBox(height: 24),
                    _buildSpecialtySection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildReviewSection(),
                    const SizedBox(
                      height: 100,
                    ), // Chừa chỗ cho nút bấm và bottom nav
                  ],
                ),
              ),
            ),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  // 1. HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.grey.shade100,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: _textDark,
                ),
              ),
            ),
          ),
          const Text(
            'Điền thông tin đặt lịch',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, size: 20, color: _textGrey),
          ),
        ],
      ),
    );
  }

  // 2. HOSPITAL CARD
  Widget _buildHospitalCard() {
    final hospitalName =
        _hospitalData!['ten_benh_vien']?.toString() ?? 'Tên bệnh viện';
    final hospitalAddress = _hospitalData!['dia_chi']?.toString() ?? 'Địa chỉ';
    final ratingValue =
        _hospitalData!['diem_danh_gia_tb'] ?? _hospitalData!['diem_danh_gia'];
    final hospitalRating = ratingValue is num
        ? ratingValue.toDouble()
        : double.tryParse(ratingValue?.toString() ?? '') ?? 0;
    final reviewCountValue =
        _hospitalData!['tong_so_danh_gia'] ??
        _hospitalData!['so_luong_danh_gia'];
    final reviewCount = reviewCountValue is num
        ? reviewCountValue.toInt()
        : int.tryParse(reviewCountValue?.toString() ?? '') ?? 0;

    final facilityValue =
        (_hospitalData!['co_so'] ?? _hospitalData!['co_so_id'] ?? '')
            .toString()
            .toLowerCase();
    final isPublic = facilityValue == 'cong_lap' || facilityValue == 'công lập';
    final isPrivate = facilityValue == 'tu_nhan' || facilityValue == 'tư nhân';
    final facilityLabel = isPublic
        ? 'Bệnh viện công'
        : isPrivate
        ? 'Bệnh viện tư'
        : 'Chưa cập nhật loại cơ sở';
    final facilityColor = isPublic
        ? _primaryBlue
        : isPrivate
        ? const Color(0xFFD97706)
        : _textGrey;
    final facilityBackground = isPublic
        ? const Color(0xFFE3F2FD)
        : isPrivate
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFF1F1F1);

    final bhytValue =
        (_hospitalData!['bhyt'] ?? _hospitalData!['bhyt_id'] ?? '')
            .toString()
            .toLowerCase();
    final hasBhyt =
        bhytValue == 'co_bhyt' || bhytValue == 'có bhyt' || bhytValue == 'true';
    final noBhyt = bhytValue == 'khong_bhyt' || bhytValue == 'không bhyt';
    final bhytColor = hasBhyt
        ? _primaryGreen
        : noBhyt
        ? const Color(0xFFB42318)
        : _textGrey;
    final bhytText = hasBhyt
        ? 'Bệnh viện có hỗ trợ khám BHYT'
        : noBhyt
        ? 'Bệnh viện không hỗ trợ khám BHYT'
        : 'Chưa cập nhật thông tin BHYT';
    final bhytIcon = hasBhyt
        ? Icons.check_circle_rounded
        : noBhyt
        ? Icons.cancel_rounded
        : Icons.info_outline_rounded;

    // ───────────────────────── Giao diện ─────────────────────────
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hàng trên: biểu tượng + tên + nhãn ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      facilityBackground,
                      Color.lerp(facilityBackground, Colors.white, 0.5)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 30,
                  color: facilityColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Nhãn loại cơ sở
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: facilityBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            facilityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: facilityColor,
                            ),
                          ),
                        ),
                        // Nhãn đánh giá
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: hospitalRating > 0
                                ? const Color(0xFFFFF8E1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: hospitalRating > 0
                                    ? const Color(0xFFFFA000)
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hospitalRating > 0
                                    ? hospitalRating.toStringAsFixed(1)
                                    : 'Chưa có đánh giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: hospitalRating > 0
                                      ? _textDark
                                      : _textGrey,
                                ),
                              ),
                              if (hospitalRating > 0 && reviewCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($reviewCount)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _textGrey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),

          // ── Địa chỉ ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    hospitalAddress,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: _textGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Thông tin BHYT ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bhytColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bhytColor.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(bhytIcon, size: 22, color: bhytColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bhytText,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: bhytColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. INFO BOX
  Widget _buildInfoBox() {
    const green = Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô icon thông tin
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.info_rounded, color: green, size: 20),
          ),
          const SizedBox(width: 12),

          // Nội dung, in đậm các từ khoá quan trọng
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 13.5, color: green, height: 1.45),
                  children: [
                    TextSpan(text: 'Vui lòng chọn '),
                    TextSpan(
                      text: 'Chuyên khoa',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ', '),
                    TextSpan(
                      text: 'Phòng khám',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' và '),
                    TextSpan(
                      text: 'Ngày khám',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' phù hợp. Lịch sẽ được '),
                    TextSpan(
                      text: 'xét duyệt',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. SPECIALTY SECTION (Phần chọn chuyên khoa)
  Widget _buildSpecialtySection() {
    final selectedCount = _selectedDepartmentIds.length;
    final selectedNames = _departments
        .where(
          (department) =>
              _selectedDepartmentIds.contains(_departmentIdOf(department)),
        )
        .map(
          (department) => department['ten_khoa']?.toString() ?? 'Chuyên khoa',
        )
        .toList();

    // Khung thông báo cho các trạng thái lỗi / rỗng
    Widget messageBox(IconData icon, String text, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: _textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Nhãn ──
        const Text.rich(
          TextSpan(
            text: 'Chọn chuyên khoa khám',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Ô chọn (dropdown giả lập) ──
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () =>
                setState(() => _isSpecialtyExpanded = !_isSpecialtyExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primaryBlue, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 20,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: selectedCount == 0
                        // Chưa chọn khoa nào
                        ? const Text(
                            'Chọn chuyên khoa',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: _textGrey,
                            ),
                          )
                        // Đã chọn: dòng nhỏ "Đã chọn" + tên các khoa đã chọn
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đã chọn ($selectedCount)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                // Nếu danh sách khoa chưa tải xong thì tạm hiện số lượng
                                selectedNames.isEmpty
                                    ? '$selectedCount chuyên khoa'
                                    : selectedNames.join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                  ),
                  AnimatedRotation(
                    turns: _isSpecialtyExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 26,
                      color: _primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Danh sách khoa (mở / thu gọn mượt) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_isSpecialtyExpanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _isLoadingDepartments
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _departmentLoadError != null
                          ? messageBox(
                              Icons.error_outline_rounded,
                              _departmentLoadError!,
                              Colors.redAccent,
                            )
                          : _departments.isEmpty
                          ? messageBox(
                              Icons.search_off_rounded,
                              'Bệnh viện chưa có danh sách chuyên khoa.',
                              Colors.grey.shade400,
                            )
                          // Danh sách dài thì cuộn bên trong khung
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 340),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _departments.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: _borderColor),
                                itemBuilder: (context, index) {
                                  final department = _departments[index];
                                  final departmentId = _departmentIdOf(
                                    department,
                                  );
                                  final name =
                                      department['ten_khoa']?.toString() ??
                                      'Chuyên khoa';
                                  final description =
                                      department['mo_ta']?.toString() ?? '';
                                  final isSelected = _selectedDepartmentIds
                                      .contains(departmentId);

                                  return Material(
                                    color: isSelected
                                        ? _primaryBlue.withOpacity(0.07)
                                        : Colors.white,
                                    child: InkWell(
                                      // Chọn / bỏ chọn khoa và chuyển sang xem lịch khoa đó
                                      onTap: () =>
                                          _toggleDepartment(departmentId),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            // Ô tick
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? _primaryBlue
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? _primaryBlue
                                                      : Colors.grey.shade400,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),

                                            // Ô icon khoa
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? _primaryBlue.withOpacity(
                                                        0.14,
                                                      )
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons
                                                    .health_and_safety_outlined,
                                                size: 21,
                                                color: isSelected
                                                    ? _primaryBlue
                                                    : _textGrey,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Tên + mô tả
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isSelected
                                                          ? _primaryBlue
                                                          : _textDark,
                                                    ),
                                                  ),
                                                  if (description
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      description,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        height: 1.3,
                                                        color: _textGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ───────────────────────── HÀM HỖ TRỢ LỊCH KHÁM ─────────────────────────

  /// Id của khoa = field `id` (vd: K001), không dùng `chuyen_khoa_id`.
  String _departmentIdOf(Map department) =>
      (department['id'] ?? department['ten_khoa'] ?? '').toString();

  String _departmentName(String id) {
    for (final d in _departments) {
      if (_departmentIdOf(d) == id) {
        return d['ten_khoa']?.toString() ?? 'Chuyên khoa';
      }
    }
    return 'Chuyên khoa';
  }

  /// Chọn / bỏ chọn 1 khoa. Khoa vừa chọn sẽ thành khoa đang xem lịch.
  /// Bỏ chọn khoa thì xoá luôn phòng, ngày, ca đã chọn của khoa đó.
  void _toggleDepartment(String departmentId) {
    setState(() {
      if (_selectedDepartmentIds.contains(departmentId)) {
        _selectedDepartmentIds.remove(departmentId);
        _selectedRoomByDept.remove(departmentId);
        _selectedDayByDept.remove(departmentId);
        _selectedSlotByDept.remove(departmentId);
        if (_activeDepartmentId == departmentId) {
          _activeDepartmentId = _selectedDepartmentIds.isEmpty
              ? null
              : _selectedDepartmentIds.last;
        }
      } else {
        _selectedDepartmentIds.add(departmentId);
        _activeDepartmentId = departmentId;
      }
    });
    // Vừa chọn khoa -> tải danh sách phòng khám của khoa đó (có cache)
    if (_selectedDepartmentIds.contains(departmentId)) {
      _fetchRooms(departmentId);
    }

    // Tải đánh giá của khoa đang xem (bỏ chọn hết khoa thì xoá đánh giá)
    _loadReviewsForActive();
  }

  /// Tải đánh giá của khoa đang xem. Gọi mỗi khi đổi khoa đang xem.
  void _loadReviewsForActive({bool force = false}) {
    final provider = context.read<ReviewProvider>();
    final id = _activeDepartmentId;

    if (id == null || !_selectedDepartmentIds.contains(id)) {
      provider.clearReviews();
      return;
    }

    setState(() {
      _selectedStar = 5;
      _reviewVisibleCount = 5;
    });
    provider.fetchReviews(hospitalId: _hospitalId, khoaId: id, force: force);
  }

  /// Chọn phòng khám cho 1 khoa. Đổi sang phòng khác thì phải chọn lại ngày + ca,
  /// vì mỗi phòng có lịch riêng.
  void _selectRoom(String departmentId, String roomId) {
    setState(() {
      if (_selectedRoomByDept[departmentId] != roomId) {
        _selectedRoomByDept[departmentId] = roomId;
        _selectedDayByDept.remove(departmentId);
        _selectedSlotByDept.remove(departmentId);
      }
    });
  }

  /// Khoa này đã chọn đủ phòng + ngày + giờ chưa?
  bool _hasScheduleFor(String id) =>
      _selectedRoomByDept.containsKey(id) &&
      _selectedDayByDept.containsKey(id) &&
      _selectedSlotByDept.containsKey(id);

  /// Dùng để kiểm tra trước khi bấm "Đặt lịch": mọi khoa đã chọn đều có phòng + ngày + giờ.
  bool get _isScheduleComplete =>
      _selectedDepartmentIds.isNotEmpty &&
      _selectedDepartmentIds.every(_hasScheduleFor);

  // ── Đọc dữ liệu từ PhongKhamModel ──
  // Nếu tên field trong model của bạn khác, chỉ cần sửa 3 hàm này.
  String _roomIdOf(PhongKhamModel room) => room.id;
  String _roomNameOf(PhongKhamModel room) => room.tenPhong;
  // Dòng phụ dưới tên phòng (vd: tầng). Để rỗng thì không hiển thị.
  String _roomSubtitleOf(PhongKhamModel room) => '';
  // Số bệnh nhân tối đa của phòng khám (field so_benh_nhan_toi_da).
  int _roomMaxOf(PhongKhamModel room) {
    final dynamic r = room;
    try {
      final v = r.soBenhNhanToiDa;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Tải danh sách phòng khám của 1 khoa từ Firestore.
  Future<void> _fetchRooms(String departmentId, {bool force = false}) async {
    if (_hospitalId.isEmpty) return;
    if (!force &&
        (_roomsByDept.containsKey(departmentId) ||
            _loadingRoomDepts.contains(departmentId))) {
      return;
    }

    setState(() {
      _loadingRoomDepts.add(departmentId);
      _roomErrorByDept.remove(departmentId);
    });

    try {
      final rooms = await _hospitalService.getPhongKhamList(
        hospitalId: _hospitalId,
        khoaId: departmentId,
      );
      
      if (!mounted) return;

      setState(() {
        _roomsByDept[departmentId] = rooms;
        _loadingRoomDepts.remove(departmentId);
      });
    } catch (e) {
      debugPrint('Lỗi khi lấy danh sách phòng khám: $e');
      if (!mounted) return;
      setState(() {
        _loadingRoomDepts.remove(departmentId);
        _roomErrorByDept[departmentId] = 'Không thể tải danh sách phòng khám.';
      });
    }
  }

  String _roomName(String departmentId, String roomId) {
    for (final r in _roomsByDept[departmentId] ?? <PhongKhamModel>[]) {
      if (_roomIdOf(r) == roomId) return _roomNameOf(r);
    }
    return 'Phòng khám';
  }

  /// Số bệnh nhân tối đa của 1 phòng khám trong 1 khoa (0 nếu không tìm thấy).
  int _roomMax(String departmentId, String roomId) {
    for (final r in _roomsByDept[departmentId] ?? <PhongKhamModel>[]) {
      if (_roomIdOf(r) == roomId) return _roomMaxOf(r);
    }
    return 0;
  }

  // ───────────────────────── NGÀY KHÁM ─────────────────────────

  /// Ngày hôm nay (đã bỏ giờ/phút).
  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Dữ liệu hiển thị của 1 ô ngày: nhãn thứ, số ngày, và DateTime.
  Map<String, dynamic> _dayEntry(DateTime date) {
    const weekdayLabels = [
      'THỨ 2',
      'THỨ 3',
      'THỨ 4',
      'THỨ 5',
      'THỨ 6',
      'T.BẢY',
      'C.NHẬT',
    ];
    return {
      'label': _isSameDay(date, _today())
          ? 'HÔM NAY'
          : weekdayLabels[date.weekday - 1],
      'day': date.day.toString(),
      'date': date,
    };
  }

  /// Các ngày hiển thị sẵn: hôm nay + 5 ngày tiếp theo.
  List<Map<String, dynamic>> _scheduleDays() {
    final t = _today();
    return List.generate(
      _soNgayHienThi,
      (i) => _dayEntry(DateTime(t.year, t.month, t.day + i)),
    );
  }

  /// Khoá cache của LichHenProvider cho (bệnh viện, khoa, phòng, ngày).
  String _slotKeyFor(String departmentId, String roomId, DateTime date) {
    return LichHenProvider.makeKey(
      ngay: date,
      benhVienId: _hospitalId,
      khoaId: departmentId,
      phongKhamId: roomId,
    );
  }

  /// Chọn ngày cho 1 khoa -> xoá ca đã chọn (vì ca phụ thuộc ngày) và tải
  /// tình trạng các ca của ngày đó từ Firestore (qua LichHenProvider, có cache).
  void _selectDay(String departmentId, String roomId, DateTime date) {
    setState(() {
      final current = _selectedDayByDept[departmentId];
      if (current == null || !_isSameDay(current, date)) {
        _selectedDayByDept[departmentId] = date;
        _selectedSlotByDept.remove(departmentId);
      }
    });
    context.read<LichHenProvider>().loadSlots(
      ngay: date,
      benhVienId: _hospitalId,
      khoaId: departmentId,
      phongKhamId: roomId,
      soBenhNhanToiDa: _roomMax(departmentId, roomId),
    );
  }

  /// Mở dialog lịch tháng để chọn ngày (kể cả ngày xa hơn 6 ngày hiển thị sẵn).
  Future<void> _openMonthCalendar(String departmentId, String roomId) async {
    final today = _today();
    var initial = _selectedDayByDept[departmentId] ?? today;
    if (initial.isBefore(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(today.year, today.month + 3, today.day),
      helpText: 'Chọn ngày khám',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _primaryBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    _selectDay(departmentId, roomId, picked);

    // Ngày nằm ngoài 6 ngày hiển thị sẵn -> cuộn tới ô ngày vừa được thêm
    final isOutside = !_scheduleDays().any(
      (d) => _isSameDay(d['date'] as DateTime, picked),
    );
    if (isOutside) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayScroll.hasClients) {
          _dayScroll.animateTo(
            _dayScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatDayMonth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  /// Màu theo số chỗ còn lại: nhiều (xanh) / sắp hết (cam) / gần hết (đỏ) / hết (xám)
  Color _availabilityColor(int left, int total) {
    if (left <= 0 || total <= 0) return Colors.grey;
    final ratio = left / total;
    if (ratio >= 0.5) return _primaryGreen;
    if (ratio >= 0.2) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  // ───────────────────────── LỊCH KHÁM THEO TỪNG KHOA ─────────────────────────

  // Tiêu đề nhỏ cho từng bước (1. Phòng khám, 2. Ngày, 3. Khung giờ)
  Widget _stepTitle(int step, String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // Danh sách phòng khám của khoa đang xem
  Widget _buildRoomList(String activeId) {
    // Khung thông báo cho trạng thái lỗi / rỗng
    Widget infoBox(IconData icon, String text, Color color, {Widget? action}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _textGrey,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      );
    }

    if (_loadingRoomDepts.contains(activeId)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_roomErrorByDept[activeId] != null) {
      return infoBox(
        Icons.error_outline_rounded,
        _roomErrorByDept[activeId]!,
        Colors.redAccent,
        action: TextButton(
          onPressed: () => _fetchRooms(activeId, force: true),
          child: const Text('Thử lại'),
        ),
      );
    }

    final rooms = _roomsByDept[activeId] ?? <PhongKhamModel>[];
    if (rooms.isEmpty) {
      return infoBox(
        Icons.meeting_room_outlined,
        'Chuyên khoa này chưa có phòng khám.',
        Colors.grey.shade400,
      );
    }

    final selectedRoomId = _selectedRoomByDept[activeId];

    return Column(
      children: List.generate(rooms.length, (i) {
        final room = rooms[i];
        final roomId = _roomIdOf(room);
        final subtitle = _roomSubtitleOf(room);
        final isSelected = selectedRoomId == roomId;

        return Padding(
          padding: EdgeInsets.only(bottom: i == rooms.length - 1 ? 0 : 10),
          child: Material(
            color: isSelected ? _primaryBlue.withOpacity(0.07) : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? _primaryBlue : _borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => _selectRoom(activeId, roomId),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primaryBlue.withOpacity(0.14)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        size: 22,
                        color: isSelected ? _primaryBlue : _textGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _roomNameOf(room),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? _primaryBlue : _textDark,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Vòng chọn
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _primaryBlue : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _primaryBlue
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // Khung thông báo dùng cho danh sách ca (trống / lỗi / nhắc chọn ngày)
  Widget _noticeBox(IconData icon, String text, Color color, {Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4, color: _textGrey),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  // Danh sách ca khám của phòng đang chọn trong ngày đang chọn
  Widget _buildSlotList(
    String activeId,
    String roomId,
    DateTime? date,
    LichHenProvider lichHen,
  ) {
    // Chưa chọn ngày
    if (date == null) {
      return _noticeBox(
        Icons.touch_app_rounded,
        'Hãy chọn ngày khám để xem các khung giờ còn trống.',
        Colors.grey.shade400,
      );
    }

    final key = _slotKeyFor(activeId, roomId, date);
    final error = lichHen.slotsErrorOf(key);

    // Lỗi tải
    if (error != null) {
      return _noticeBox(
        Icons.error_outline_rounded,
        error,
        Colors.redAccent,
        action: TextButton(
          onPressed: () => context.read<LichHenProvider>().loadSlots(
            ngay: date,
            benhVienId: _hospitalId,
            khoaId: activeId,
            phongKhamId: roomId,
            soBenhNhanToiDa: _roomMax(activeId, roomId),
            force: true,
          ),
          child: const Text('Thử lại'),
        ),
      );
    }

    // Đang tải (hoặc chưa kịp bắt đầu tải)
    if (lichHen.isLoadingSlots(key) || !lichHen.hasLoadedSlots(key)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final slots = lichHen.slotsOf(key);

    // Ngày này phòng chưa có lịch
    if (slots.isEmpty) {
      return _noticeBox(
        Icons.event_busy_rounded,
        'Phòng khám chưa có lịch khám vào ngày này.\nVui lòng chọn ngày khác.',
        Colors.grey.shade400,
      );
    }

    final selectedCaId = _selectedSlotByDept[activeId];

    return Column(
      children: List.generate(slots.length, (i) {
        final slot = slots[i];
        final left = slot.conLai;
        final total = slot.tongSo;
        // Chưa biết số tối đa (total = 0): coi là còn trống, không phải hết chỗ
        final isUnknownTotal = total <= 0;
        final isFull = !isUnknownTotal && left <= 0;
        final isSelected = selectedCaId == slot.caId;
        final color = isUnknownTotal
            ? _primaryGreen
            : _availabilityColor(left, total);
        final isMorning =
            slot.caId.toLowerCase().contains('sang') ||
            slot.tenCa.toLowerCase().contains('sáng');

        return Padding(
          padding: EdgeInsets.only(bottom: i == slots.length - 1 ? 0 : 10),
          child: Opacity(
            opacity: isFull ? 0.55 : 1,
            child: Material(
              color: isSelected ? _primaryBlue.withOpacity(0.07) : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? _primaryBlue : _borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: isFull
                    ? null
                    : () => setState(
                        () => _selectedSlotByDept[activeId] = slot.caId,
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isMorning
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isMorning
                                  ? Icons.wb_sunny_rounded
                                  : Icons.wb_twilight_rounded,
                              size: 22,
                              color: isMorning
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.tenCa,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? _primaryBlue
                                        : _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${slot.gioBatDau} - ${slot.gioKetThuc}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Vòng chọn
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _primaryBlue
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? _primaryBlue
                                    : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Thanh số chỗ còn lại
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? left / total : 1,
                                minHeight: 6,
                                backgroundColor: color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isFull
                                ? 'Hết chỗ'
                                : isUnknownTotal
                                ? 'Còn trống'
                                : 'Còn $left/$total chỗ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // 5. DATE & TIME SECTION
  Widget _buildDateTimeSection() {
    final selectedIds = _selectedDepartmentIds.toList();

    // Khoa đang xem: nếu khoa active không còn được chọn thì lấy khoa đầu tiên
    final String? activeId = selectedIds.contains(_activeDepartmentId)
        ? _activeDepartmentId
        : (selectedIds.isEmpty ? null : selectedIds.first);

    final titleWidget = const Text.rich(
      TextSpan(
        text: 'Chọn phòng khám, ngày và khung giờ khám',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _textDark,
        ),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );

    // ── Chưa chọn khoa nào ──
    if (activeId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 30,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa chọn chuyên khoa',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hãy chọn chuyên khoa ở trên để chọn phòng khám,\nngày và khung giờ khám.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.4, color: _textGrey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Đã chọn khoa: dữ liệu lịch của khoa đang xem ──
    final selectedRoomId = _selectedRoomByDept[activeId];
    final DateTime? selectedDay = _selectedDayByDept[activeId];
    final doneCount = selectedIds.where(_hasScheduleFor).length;

    // Danh sách ngày chỉ có khi đã chọn phòng khám: hôm nay + 5 ngày tiếp theo
    final days = selectedRoomId == null
        ? <Map<String, dynamic>>[]
        : _scheduleDays();
    // Ngày chọn từ lịch tháng nằm ngoài 6 ngày hiển thị sẵn -> thêm 1 ô vào cuối
    if (selectedDay != null &&
        days.isNotEmpty &&
        !days.any((d) => _isSameDay(d['date'] as DateTime, selectedDay))) {
      days.add(_dayEntry(selectedDay));
    }

    // Các ca thật của phòng khám trong ngày đang chọn (từ LichHenProvider)
    final lichHen = context.watch<LichHenProvider>();
    final List<CaSlotModel> slots =
        (selectedRoomId != null && selectedDay != null)
        ? lichHen.slotsOf(_slotKeyFor(activeId, selectedRoomId, selectedDay))
        : <CaSlotModel>[];
    CaSlotModel? selectedSlot;
    for (final sl in slots) {
      if (sl.caId == _selectedSlotByDept[activeId]) selectedSlot = sl;
    }

    // Nhãn tháng: theo ngày đang chọn, chưa chọn thì theo hôm nay
    final labelDate = selectedDay ?? _today();
    final monthLabel =
        'Tháng ${labelDate.month.toString().padLeft(2, '0')}, ${labelDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleWidget,
        const SizedBox(height: 10),

        // ── Thanh các khoa đã chọn (chỉ hiện khi chọn từ 2 khoa) ──
        if (selectedIds.length > 1) ...[
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final id = selectedIds[i];
                final isActive = id == activeId;
                final isDone = _hasScheduleFor(id);

                return GestureDetector(
                  onTap: () {
                    setState(() => _activeDepartmentId = id);
                    _loadReviewsForActive();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isActive ? _primaryBlue : _borderColor,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : (isDone ? _primaryGreen : Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            _departmentName(id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã chọn lịch cho $doneCount/${selectedIds.length} khoa',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: doneCount == selectedIds.length
                  ? _primaryGreen
                  : _textGrey,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Thẻ lịch khám của khoa đang xem ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên khoa đang xem
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 20,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch khám của',
                          style: TextStyle(fontSize: 11.5, color: _textGrey),
                        ),
                        Text(
                          _departmentName(activeId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Bước 1: chọn phòng khám ──
              _stepTitle(1, 'Chọn phòng khám'),
              const SizedBox(height: 10),
              _buildRoomList(activeId),

              // ── Chưa chọn phòng: nhắc người dùng, chưa hiện ngày / ca ──
              if (selectedRoomId == null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_clock_rounded,
                        size: 18,
                        color: _textGrey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hãy chọn phòng khám để xem ngày và khung giờ khám.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: _textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: _borderColor),
                const SizedBox(height: 14),

                // ── Bước 2: chọn ngày ──
                _stepTitle(2, 'Chọn ngày khám'),
                const SizedBox(height: 10),

                // Tháng + nút xem lịch tháng (mở dialog lịch)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openMonthCalendar(activeId, selectedRoomId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: _primaryBlue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Xem lịch tháng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Chọn ngày: hôm nay + 5 ngày tiếp theo (cuộn ngang)
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    controller: _dayScroll,
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final date = days[i]['date'] as DateTime;
                      final isSelected =
                          selectedDay != null && _isSameDay(date, selectedDay);
                      return GestureDetector(
                        onTap: () => _selectDay(activeId, selectedRoomId, date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 66,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _primaryBlue,
                                      _primaryBlue.withOpacity(0.75),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _primaryBlue : _borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _primaryBlue.withOpacity(0.28),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                days[i]['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.9)
                                      : _textGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                days[i]['day'] as String,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : _textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: _borderColor),
                const SizedBox(height: 14),

                // ── Bước 3: chọn khung giờ (dữ liệu thật từ Firestore) ──
                _stepTitle(3, 'Khung giờ khám'),
                const SizedBox(height: 10),
                _buildSlotList(activeId, selectedRoomId, selectedDay, lichHen),

                // Tóm tắt lựa chọn của khoa đang xem
                if (selectedDay != null && selectedSlot != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: _primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã chọn: ${_roomName(activeId, selectedRoomId)} · '
                            'ngày ${_formatDayMonth(selectedDay)} · '
                            '${selectedSlot.tenCa} '
                            '(${selectedSlot.gioBatDau} - ${selectedSlot.gioKetThuc})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 6. LOCATION SECTION
  Widget _buildLocationSection() {
    final latitudeValue = _hospitalData!['vi_do'];
    final longitudeValue = _hospitalData!['kinh_do'];
    final latitude = latitudeValue is num
        ? latitudeValue.toDouble()
        : double.tryParse(latitudeValue?.toString() ?? '');
    final longitude = longitudeValue is num
        ? longitudeValue.toDouble()
        : double.tryParse(longitudeValue?.toString() ?? '');
    final hasCoordinates = latitude != null && longitude != null;
    final hospitalName =
        _hospitalData!['ten_benh_vien']?.toString() ?? 'Bệnh viện';
    final hospitalAddress =
        _hospitalData!['dia_chi']?.toString() ?? 'Địa chỉ chưa cập nhật';

    Future<void> openGoogleMaps() async {
      if (!hasCoordinates) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bệnh viện chưa có tọa độ bản đồ')),
        );
        return;
      }

      final uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$latitude,$longitude',
      });

      try {
        var launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        if (!launched && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
        }
      } catch (error) {
        debugPrint('Không thể mở Google Maps: $error');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
        }
      }
    }

    Future<void> copyAddress() async {
      await Clipboard.setData(ClipboardData(text: hospitalAddress));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép địa chỉ'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tiêu đề ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.map_rounded, size: 18, color: _primaryBlue),
            ),
            const SizedBox(width: 10),
            const Text(
              'Vị trí bệnh viện',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Thẻ gồm bản đồ + địa chỉ ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // ── Bản đồ minh hoạ (bấm để mở Google Maps) ──
                SizedBox(
                  height: 176,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: openGoogleMaps,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _MiniMapPainter(accent: _primaryBlue),
                          ),

                          // Ghim bệnh viện
                          Align(
                            alignment: const Alignment(0, -0.12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE53935,
                                        ).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 10,
                                  color: const Color(0xFFE53935),
                                ),
                                Container(
                                  width: 16,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tên bệnh viện (nhãn nổi, góc trên trái)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 120,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasCoordinates
                                        ? Icons.place_rounded
                                        : Icons.location_off_rounded,
                                    size: 15,
                                    color: hasCoordinates
                                        ? _primaryBlue
                                        : _textGrey,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      hasCoordinates
                                          ? hospitalName
                                          : 'Chưa có tọa độ bản đồ',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Nút Chỉ đường (góc dưới phải)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: hasCoordinates
                                      ? [
                                          _primaryBlue,
                                          _primaryBlue.withOpacity(0.82),
                                        ]
                                      : [
                                          Colors.grey.shade500,
                                          Colors.grey.shade400,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryBlue.withOpacity(
                                      hasCoordinates ? 0.35 : 0,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chỉ đường',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Địa chỉ ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Địa chỉ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _textGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hospitalAddress,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sao chép địa chỉ',
                        onPressed: copyAddress,
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 19,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 7. REVIEW SECTION
  Widget _buildReviewSection() {
    final activeId = _activeDepartmentId;
    final hasDepartment =
        activeId != null && _selectedDepartmentIds.contains(activeId);

    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final total = reviewProvider.totalCount;
        final counts = reviewProvider.countByStar;
        final starReviews = reviewProvider.reviewsByStar(_selectedStar);
        final visible = starReviews.take(_reviewVisibleCount).toList();
        const avatarColors = [
          Color(0xFFBBDEFB),
          Color(0xFFFFE0B2),
          Color(0xFFC8E6C9),
          Color(0xFFE1BEE7),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tiêu đề + tên khoa đang xem ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.rate_review_rounded,
                    size: 18,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đánh giá và nhận xét',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ),
                if (hasDepartment)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _departmentName(activeId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Các trạng thái ──
            if (!hasDepartment)
              _buildReviewMessage(
                Icons.touch_app_rounded,
                'Hãy chọn chuyên khoa để xem đánh giá của khoa đó.',
                _primaryBlue,
              )
            else if (reviewProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (reviewProvider.error != null)
              _buildReviewMessage(
                Icons.error_outline_rounded,
                reviewProvider.error!,
                Colors.redAccent,
                onRetry: () => _loadReviewsForActive(force: true),
              )
            else if (total == 0)
              _buildReviewMessage(
                Icons.rate_review_outlined,
                'Chưa có đánh giá nào cho chuyên khoa này.',
                Colors.grey.shade500,
              )
            else ...[
              // ── Tổng quan: điểm trung bình + biểu đồ theo sao ──
              _buildReviewSummary(reviewProvider.averageRating, total, counts),
              const SizedBox(height: 16),

              // ── Tab 5 sao → 1 sao ──
              Row(
                children: [5, 4, 3, 2, 1]
                    .map(
                      (star) => _buildStarTab(
                        star: star,
                        count: counts[star] ?? 0,
                        selected: star == _selectedStar,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // ── Danh sách đánh giá của tab đang chọn (mờ dần khi đổi tab) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey<int>(_selectedStar),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: starReviews.isEmpty
                      ? <Widget>[
                          _buildReviewMessage(
                            Icons.star_border_rounded,
                            'Chưa có đánh giá $_selectedStar sao nào.',
                            Colors.grey.shade500,
                          ),
                        ]
                      : List<Widget>.generate(visible.length, (index) {
                          final review = visible[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visible.length - 1 ? 0 : 12,
                            ),
                            child: _buildReviewCard(
                              name: _reviewerName(review),
                              rating: review.diemDanhGia,
                              comment: review.nhanXet,
                              avatarText: _reviewerInitial(review),
                              avatarColor:
                                  avatarColors[index % avatarColors.length],
                              timeAgo: _getTimeAgo(review.ngayTao),
                            ),
                          );
                        }),
                ),
              ),

              // ── Nút "Xem thêm" ──
              if (starReviews.length > visible.length) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _reviewVisibleCount += 5),
                    icon: const Icon(Icons.expand_more_rounded, size: 20),
                    label: Text(
                      'Xem thêm ${starReviews.length - visible.length} đánh giá',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryBlue,
                      side: BorderSide(color: _primaryBlue.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // --- Các widget phụ cho phần đánh giá ---

  /// Nhãn mô tả theo điểm trung bình.
  String _ratingLabelOfAverage(double average) {
    if (average >= 4.5) return 'Tuyệt vời';
    if (average >= 4) return 'Rất tốt';
    if (average >= 3) return 'Tốt';
    if (average >= 2) return 'Trung bình';
    return 'Cần cải thiện';
  }

  /// Nhãn theo số sao của 1 đánh giá.
  String _ratingChipText(int rating) {
    if (rating >= 5) return 'Rất hài lòng';
    if (rating == 4) return 'Hài lòng';
    if (rating == 3) return 'Bình thường';
    if (rating == 2) return 'Chưa hài lòng';
    return 'Không hài lòng';
  }

  /// Màu nhãn theo số sao của 1 đánh giá.
  Color _ratingChipColor(int rating) {
    if (rating >= 4) return _primaryGreen;
    if (rating == 3) return const Color(0xFFF59E0B);
    if (rating == 2) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  /// Hàng sao (hỗ trợ nửa sao) theo điểm trung bình.
  Widget _starRow(double value, {double size = 16, bool center = false}) {
    const amber = Color(0xFFFFA000);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: List.generate(5, (i) {
        final IconData icon;
        if (value >= i + 1) {
          icon = Icons.star_rounded;
        } else if (value >= i + 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: amber);
      }),
    );
  }

  /// Thẻ tổng quan: điểm trung bình (bên trái) + thanh phân bố từng mức sao (bên phải).
  Widget _buildReviewSummary(double average, int total, Map<int, int> counts) {
    const amber = Color(0xFFFFA000);
    const orange = Color(0xFFFF7043);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4D6), Color(0xFFFFFBF0)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: amber.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: amber.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Điểm trung bình ──
          Container(
            width: 108,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                _starRow(average, size: 15, center: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _ratingLabelOfAverage(average),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total đánh giá',
                  style: const TextStyle(fontSize: 11.5, color: _textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Phân bố theo sao ──
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = counts[star] ?? 0;
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                        child: Text(
                          '$star',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.star_rounded, size: 12, color: amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: amber.withOpacity(0.16),
                              ),
                              FractionallySizedBox(
                                widthFactor: fraction.clamp(0.0, 1.0),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [amber, orange],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Một tab sao: "5 ★" + số đánh giá. Bấm vào để xem đánh giá của mức sao đó.
  Widget _buildStarTab({
    required int star,
    required int count,
    required bool selected,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: star == 1 ? 0 : 8),
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedStar = star;
            _reviewVisibleCount = 5; // đổi tab thì hiện lại từ 5 đánh giá đầu
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryBlue, _primaryBlue.withOpacity(0.78)],
                    )
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _primaryBlue : _borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : (count == 0 ? _textGrey : _textDark),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : (count == 0
                                ? Colors.grey.shade400
                                : const Color(0xFFFFA000)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.25)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Khung thông báo (chưa chọn khoa / lỗi / không có đánh giá), có nút "Thử lại" tuỳ chọn.
  Widget _buildReviewMessage(
    IconData icon,
    String text,
    Color color, {
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: _textGrey,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  /// Thẻ 1 đánh giá.
  Widget _buildReviewCard({
    required String name,
    required int rating,
    required String comment,
    required String avatarText,
    required Color avatarColor,
    required String timeAgo,
  }) {
    final chipText = _ratingChipText(rating);
    final chipColor = _ratingChipColor(rating);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh đại diện
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      avatarColor,
                      Color.lerp(avatarColor, Colors.white, 0.45)!,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    avatarText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Tên + sao + nhãn mức độ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _starRow(rating.toDouble(), size: 15),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chipText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nội dung nhận xét
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: _primaryBlue.withOpacity(0.55),
                    width: 3,
                  ),
                ),
              ),
              child: _ExpandableText(
                text: comment.trim(),
                accent: _primaryBlue,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tên người đánh giá: ẩn danh thì hiện "Người dùng ẩn danh",
  /// ngược lại che bớt mã bệnh nhân (chỉ hiện 3 ký tự cuối).
  String _reviewerName(ReviewModel review) {
    if (review.anDanh) return 'Người dùng ẩn danh';
    final id = review.benhNhanId;
    if (id.isEmpty) return 'Bệnh nhân';
    return id.length > 3
        ? 'Bệnh nhân ···${id.substring(id.length - 3)}'
        : 'Bệnh nhân $id';
  }

  /// Chữ cái trong ảnh đại diện (an toàn khi mã bệnh nhân rỗng).
  String _reviewerInitial(ReviewModel review) {
    if (review.anDanh) return '?';
    final id = review.benhNhanId.trim();
    return id.isEmpty ? 'B' : id.substring(id.length - 1).toUpperCase();
  }

  /// Thời gian đã qua: "Vừa xong", "5 phút trước", "2 ngày trước", "3 tuần trước"...
  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} tuần trước';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30} tháng trước';
    return '${diff.inDays ~/ 365} năm trước';
  }

  // 8. BOTTOM ACTION
  Future<void> _continueBooking() async {
    if (_selectedDepartmentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chuyên khoa khám')),
      );
      return;
    }
    if (!_isScheduleComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn phòng khám, ngày và khung giờ cho tất cả chuyên khoa đã chọn',
          ),
        ),
      );
      return;
    }
 
    // 1. Thu thập dữ liệu chi tiết cho từng lịch hẹn
    final lichHenProvider = context.read<LichHenProvider>();
    final List<Map<String, String>> bookingDetails = [];
    final List<Future<void> Function()> saveTasks = [];
 
    // Dữ liệu sẽ truyền sang trang "Đã gửi yêu cầu đặt lịch"
    final List<String> departmentNames = [];
    final List<String> dateLabels = [];
    final List<String> shiftLabels = [];
    final List<String> lichHenIds = [];
 
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final String benhNhanId = firebaseAuth.currentUser?.uid ?? '';
    final String trangThaiId = '1'; // 1 = Chờ xét duyệt
 
    for (final departmentId in _selectedDepartmentIds) {
      final roomId = _selectedRoomByDept[departmentId]!;
      final date = _selectedDayByDept[departmentId]!;
      final caId = _selectedSlotByDept[departmentId]!;
 
      final slotKey = _slotKeyFor(departmentId, roomId, date);
 
      CaSlotModel? selectedSlot;
      for (final slot in lichHenProvider.slotsOf(slotKey)) {
        if (slot.caId == caId) {
          selectedSlot = slot;
          break;
        }
      }
 
      if (selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy khung giờ đã chọn. Vui lòng chọn lại.'),
          ),
        );
        return;
      }
 
      final lichHenId = 'LH${DateTime.now().microsecondsSinceEpoch}';
      final shiftLabel =
          '${selectedSlot.tenCa} (${selectedSlot.gioBatDau} - ${selectedSlot.gioKetThuc})';
 
      // Thêm vào danh sách để hiển thị trên UI
      bookingDetails.add({
        'departmentName': _departmentName(departmentId),
        'shiftLabel': shiftLabel,
      });
      departmentNames.add(_departmentName(departmentId));
      dateLabels.add(_formatDayMonth(date));
      shiftLabels.add(shiftLabel);
      lichHenIds.add(lichHenId);
 
      // Tạo task lưu vào Firestore
      saveTasks.add(
        () => _lichHenService.saveBooking(
          trangThaiId: trangThaiId,
          ngayDat: date,
          caId: caId,
          benhVienId: _hospitalId,
          khoaId: departmentId,
          phongKhamId: roomId,
          benhNhanId: benhNhanId,
          lichHenId: lichHenId,
        ),
      );
    }
 
    // 2. Chuẩn bị dữ liệu hiển thị chung
    final hospitalName =
        _hospitalData!['ten_benh_vien']?.toString() ?? 'Bệnh viện';
    final address =
        _hospitalData!['dia_chi']?.toString() ?? 'Địa chỉ chưa cập nhật';
    final bhyt = (_hospitalData!['bhyt'] ?? _hospitalData!['bhyt_id'] ?? '')
        .toString()
        .toLowerCase();
    final bhytNote = (bhyt == 'co_bhyt' || bhyt == 'có bhyt')
        ? 'Có hỗ trợ khám BHYT'
        : 'Không hỗ trợ khám BHYT';
 
    // Gộp các ngày khác nhau (nhiều khoa có thể khám khác ngày)
    final dateLabel = dateLabels.toSet().join(', ');
 
    // 3. Hiển thị bảng xác nhận
    final confirmed = await showBookingConfirmSheet(
      context,
      hospitalName: hospitalName,
      bookingDetails: bookingDetails,
      dateLabel: dateLabel,
      address: address,
      bhytNote: bhytNote,
    );
 
    // 4. Nếu người dùng bấm Xác nhận
    if (confirmed == true && mounted) {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
 
      try {
        // Thực hiện lưu tất cả lịch hẹn song song
        await Future.wait(saveTasks.map((saveTask) => saveTask()));
 
        // Xóa cache để cập nhật lại số chỗ trống, rồi tải lại các ca vừa đặt
        // (để quay lại màn hình này vẫn thấy số chỗ mới, không bị quay mãi)
        lichHenProvider.clearCache();
        for (final departmentId in _selectedDepartmentIds) {
          final roomId = _selectedRoomByDept[departmentId]!;
          lichHenProvider.loadSlots(
            ngay: _selectedDayByDept[departmentId]!,
            benhVienId: _hospitalId,
            khoaId: departmentId,
            phongKhamId: roomId,
            soBenhNhanToiDa: _roomMax(departmentId, roomId),
            force: true,
          );
        }
 
        if (!mounted) return;
        Navigator.pop(context); // Tắt loading
 
        // Dữ liệu cho trang "Đã gửi yêu cầu đặt lịch"
        final departmentLabel = departmentNames.join(', ');
        final shiftLabel = shiftLabels.join('; ');
        final appointment = MyAppointmentItem(
          // Nhiều khoa -> nhiều lịch hẹn: hiện mã đầu tiên kèm số lịch còn lại
          id: lichHenIds.length == 1
              ? '#${lichHenIds.first}'
              : '#${lichHenIds.first} (+${lichHenIds.length - 1})',
          hospitalName: hospitalName,
          subtitle: '$departmentLabel · $dateLabel · $shiftLabel',
          status: AppointmentStatus.pending,
          departmentName: departmentLabel,
          dateLabel: dateLabel,
          timeLabel: shiftLabel,
        );
 
        Navigator.pushNamed(
          context,
          AppRoutes.bookingRequestSent,
          arguments: appointment,
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đặt lịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBottomActionArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _continueBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tiếp tục đặt lịch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bản đồ minh hoạ vẽ bằng CustomPaint: khối nhà, đường phố, công viên,
class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nền
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFEBE3),
    );

    // Đường phố (lưới)
    const cols = 6;
    const rows = 4;
    final cw = w / cols;
    final ch = h / rows;
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9;
    for (var c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, h), roadPaint);
    }
    for (var r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(w, r * ch), roadPaint);
    }

    // Khối nhà
    final blockPaint = Paint()..color = const Color(0xFFE4DFD3);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cw + 8, r * ch + 8, cw - 16, ch - 16),
            const Radius.circular(6),
          ),
          blockPaint,
        );
      }
    }

    // Công viên
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.12, w * 0.22, h * 0.34),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFCDE7C2),
    );

    // Dòng sông
    final river = Path()
      ..moveTo(w * 0.66, -10)
      ..cubicTo(w * 0.56, h * 0.3, w * 0.84, h * 0.6, w * 0.74, h + 10);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFBFDDF3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );

    // Đường lớn (chéo)
    final avenue = Path()
      ..moveTo(-10, h * 0.78)
      ..lineTo(w + 10, h * 0.3);
    canvas.drawPath(
      avenue,
      Paint()
        ..color = const Color(0xFFD9D3C5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );
    canvas.drawPath(
      avenue,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    // Tuyến đường nét đứt tới bệnh viện
    final route = Path()
      ..moveTo(w * 0.08, h * 0.96)
      ..cubicTo(w * 0.3, h * 0.84, w * 0.3, h * 0.66, w * 0.5, h * 0.6);
    final routePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 10),
          routePaint,
        );
        distance += 18;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Đoạn nhận xét dài được rút gọn 3 dòng, bấm "Xem thêm" / "Thu gọn" để mở rộng.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({
    required this.text,
    required this.style,
    required this.accent,
  });

  final String text;
  final TextStyle style;
  final Color accent;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const int _collapsedLines = 3;
  static const int _longThreshold = 140; // ký tự
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > _longThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: (_expanded || !isLong) ? null : _collapsedLines,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
        if (isLong)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _expanded ? 'Thu gọn' : 'Xem thêm',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: widget.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
