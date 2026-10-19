import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../services/location_service.dart';
import 'dart:async';

class HospitalFilterScreen extends StatefulWidget {
  const HospitalFilterScreen({super.key});

  @override
  State<HospitalFilterScreen> createState() => _HospitalFilterScreenState();
}

class _HospitalFilterScreenState extends State<HospitalFilterScreen> {
  static const _primary = Color(0xFF1E78E0);
  static const _bgColor = Color(0xFFF5F7FA);
  static const _textDark = Color(0xFF0F172A);
  static const _textGrey = Color(0xFF64748B);

  final _searchCtrl = TextEditingController();
  bool _isFilterExpanded = false;
  Timer? _debounce;
  final FocusNode _searchFocus = FocusNode();

  // ✅ Khởi tạo LocationService để tính toán khoảng cách
  final LocationService _locationService = LocationService();
  Position? _currentUserPosition;

  RangeValues _distanceRange = const RangeValues(0, 50);
  RangeValues _ratingRange = const RangeValues(0, 5);
  String? _insuranceType;
  String? _facilityType;

  // ✅ Lưu trữ ID của chuyên khoa (ví dụ: 'CK01', 'CK04')
  final List<String> _selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().init();
    });
  }

  // ✅ Lấy vị trí người dùng 1 lần duy nhất khi vào màn hình
  Future<void> _initLocation() async {
    final result = await _locationService.getUserLocationWithSource(null);
    if (mounted) {
      setState(() {
        _currentUserPosition = result.position;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String? _getCoSoId([HospitalProvider? provider]) =>
      provider?.selectedCoSoId ??
      (_facilityType == 'Công lập'
          ? 'Cong_lap'
          : (_facilityType == 'Tư nhân' ? 'Tu_nhan' : null));

  String? _getBhytId([HospitalProvider? provider]) =>
      provider?.selectedBhytId ??
      (_insuranceType == 'Có BHYT'
          ? 'Co_BHYT'
          : (_insuranceType == 'Không BHYT' ? 'Khong_BHYT' : null));

  void _applyFilters([HospitalProvider? provider]) {
    final currentProvider = provider ?? context.read<HospitalProvider>();
    currentProvider.fetchAndFilterHospitals(
      coSoId: _getCoSoId(currentProvider),
      bhytId: _getBhytId(currentProvider),
      minRating: _ratingRange.start,
      specialtyIds: _selectedSpecialties,
    );
  }

  void _searchByKeyword(String keyword, [HospitalProvider? provider]) {
    final currentProvider = provider ?? context.read<HospitalProvider>();
    currentProvider.searchHospitalsByKeyword(keyword);
  }

  void _resetFilters() {
    setState(() {
      _distanceRange = const RangeValues(0, 50);
      _ratingRange = const RangeValues(0, 5);
      _insuranceType = null;
      _facilityType = null;
      _selectedSpecialties.clear();
      _searchCtrl.clear();
    });
    context.read<HospitalProvider>().resetFilters();
  }

  String _getSelectedSpecialtyNames(HospitalProvider provider) {
    if (_selectedSpecialties.isEmpty) return 'Chọn chuyên khoa';

    final names = provider.specialtiesList
        .where((spec) => _selectedSpecialties.contains(spec['id']))
        .map((spec) => spec['ten_khoa'] as String)
        .toList();

    return names.join(', ');
  }

  void _showSpecialtySelection() {
    String query = ''; // từ khóa tìm kiếm trong sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // ✅ SỬA LỖI: sheet không còn chui xuống status bar
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = context.watch<HospitalProvider>();

            // Lọc theo từ khóa tìm kiếm
            final list = provider.specialtiesList.where((s) {
              final name = (s['ten_khoa'] as String).toLowerCase();
              return name.contains(query.trim().toLowerCase());
            }).toList();

            return Padding(
              // Đẩy sheet lên khi bàn phím hiện
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Thanh kéo ──────────────────────────────
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // ── Tiêu đề ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.medical_services_outlined,
                              color: _primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chọn chuyên khoa',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedSpecialties.isEmpty
                                      ? 'Có thể chọn nhiều chuyên khoa'
                                      : 'Đã chọn ${_selectedSpecialties.length} chuyên khoa',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedSpecialties.isEmpty
                                        ? _textGrey
                                        : _primary,
                                    fontWeight: _selectedSpecialties.isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedSpecialties.isNotEmpty)
                            TextButton(
                              onPressed: () => setModalState(
                                () => _selectedSpecialties.clear(),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: const Text(
                                'Xóa tất cả',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Ô tìm kiếm ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'Tìm chuyên khoa...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // ── Danh sách ──────────────────────────────
                    if (provider.isLookupLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: _primary),
                      )
                    else if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Không tìm thấy chuyên khoa',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final specialty = list[index];
                            final specId = specialty['id'] as String;
                            final specName = specialty['ten_khoa'] as String;
                            final isSelected = _selectedSpecialties.contains(
                              specId,
                            );

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setModalState(() {
                                if (isSelected) {
                                  _selectedSpecialties.remove(specId);
                                } else {
                                  _selectedSpecialties.add(specId);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primary.withOpacity(0.07)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? _primary
                                        : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _primary.withOpacity(0.12)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.health_and_safety_outlined,
                                        color: isSelected
                                            ? _primary
                                            : _textGrey,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        specName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? _primary
                                              : _textDark,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? _primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? _primary
                                              : Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ── Nút Áp dụng ────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _applyFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.filter_alt_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedSpecialties.isEmpty
                                        ? 'Áp dụng bộ lọc'
                                        : 'Áp dụng bộ lọc (${_selectedSpecialties.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Consumer<HospitalProvider>(
          builder: (context, provider, child) {
            return NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 300) {
                  if (!provider.isLoadingMore &&
                      provider.hasMore &&
                      !provider.isLoading) {
                    provider.loadMoreHospitals();
                  }
                }
                return true;
              },
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 24),
                          _buildFilterSection(provider),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Thanh nhấn màu bên trái tiêu đề
                              Container(
                                width: 5,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Danh sách bệnh viện',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ),

                              // Nhãn số lượng, số nhảy mượt khi thay đổi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _primary.withOpacity(0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_hospital_rounded,
                                      size: 15,
                                      color: _primary,
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                      child: Text.rich(
                                        TextSpan(
                                          text:
                                              '${provider.currentFilteredCount}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: _primary,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: ' bệnh viện',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _primary.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        key: ValueKey(
                                          provider.currentFilteredCount,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  if (provider.isLoading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      ),
                    )
                  else if (provider.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _buildErrorState(provider.errorMessage!),
                    )
                  else if (provider.hospitals.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == provider.hospitals.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                ),
                              ),
                            );
                          }

                          final hospital = provider.hospitals[index];
                          final hospitalId = hospital['id']?.toString() ?? '';
                          final name =
                              hospital['ten_benh_vien']?.toString() ??
                              'Cơ sở y tế';
                          final address =
                              hospital['dia_chi']?.toString() ??
                              'Chưa cập nhật địa chỉ';
                          final type =
                              hospital['co_so']?.toString() ??
                              hospital['loai_hinh']?.toString() ??
                              'Chưa cập nhật';

                          final ratingValue =
                              hospital['diem_danh_gia_tb'] ??
                              hospital['diem_danh_gia'];
                          final reviewCountValue =
                              hospital['tong_so_danh_gia'] ??
                              hospital['so_luong_danh_gia'];

                          double calculatedDistance = 0.0;
                          if (_currentUserPosition != null &&
                              hospital['vi_do'] != null &&
                              hospital['kinh_do'] != null) {
                            calculatedDistance = _locationService
                                .calculateDistanceInKm(
                                  _currentUserPosition!.latitude,
                                  _currentUserPosition!.longitude,
                                  (hospital['vi_do'] as num).toDouble(),
                                  (hospital['kinh_do'] as num).toDouble(),
                                );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: _buildHospitalCard(
                              hospitalData: hospital,
                              id: hospitalId,
                              name: name,
                              address: address,
                              type: type,
                              rating: ratingValue is num
                                  ? ratingValue.toDouble()
                                  : 0.0,
                              reviewCount: reviewCountValue is num
                                  ? reviewCountValue.toInt()
                                  : 0,
                              initials: _getInitials(name),
                              bgColor: type == 'Công lập'
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0xFFFEF3C7),
                              textColor: type == 'Công lập'
                                  ? _primary
                                  : const Color(0xFFD97706),
                              distance:
                                  calculatedDistance, // ✅ Truyền khoảng cách đã tính vào widget
                            ),
                          );
                        },
                        childCount:
                            provider.hospitals.length +
                            (provider.hasMore ? 1 : 0),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= WIDGET HELPER =================

  Widget _buildHeader() {
    final userName = context.watch<AuthProvider>().user?.hoTen ?? '';

    // Chữ cái đầu của tên (từ cuối cùng): "Nguyễn Văn A" -> "A"
    final words = userName.trim().split(' ');
    final initial = words.last.isNotEmpty ? words.last[0].toUpperCase() : '?';

    // Lời chào theo giờ trong ngày
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Chào buổi sáng'
        : hour < 14
        ? 'Chào buổi trưa'
        : hour < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';

    return Row(
      children: [
        // ── Ảnh đại diện chữ cái ──
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primary.withOpacity(0.65)],
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // ── Lời chào + tên ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: const TextStyle(
                  fontSize: 13,
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // ── Nút thông báo có chấm đỏ ──
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // TODO: mở màn hình thông báo
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: _primary,
                    size: 26,
                  ),
                ),
              ),
            ),
            // Chấm đỏ báo có thông báo mới (xoá nếu không cần)
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final FocusNode _searchFocus = FocusNode();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Lắng nghe nội dung ô nhập để hiện/ẩn nút xóa
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchCtrl,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;

          return TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onTapOutside: (_) => _searchFocus.unfocus(),
            cursorColor: _primary,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
            onChanged: (text) {
              _debounce?.cancel(); // đợi người dùng ngừng gõ 300ms mới tìm
              _debounce = Timer(const Duration(milliseconds: 300), () {
                _searchByKeyword(text);
              });
            },
            // Bấm nút "Tìm" trên bàn phím: tìm ngay, không chờ debounce
            onSubmitted: (text) {
              _debounce?.cancel();
              _searchByKeyword(text);
              _searchFocus.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Tìm tên bệnh viện, địa chỉ...',
              hintStyle: const TextStyle(color: _textGrey, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.search_rounded, color: _primary, size: 24),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Xóa',
                      icon: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        _debounce?.cancel();
                        _searchCtrl.clear();
                        _searchByKeyword(''); // trả danh sách về ban đầu
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(HospitalProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _resetFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: _primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Đặt lại',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nội dung (thu gọn / mở rộng) ───────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 18),

                  // Khoảng cách
                  _buildSectionTitle(
                    Icons.near_me_outlined,
                    'Khoảng cách',
                    trailing: _buildValuePill(
                      '${_distanceRange.start.toStringAsFixed(0)} – ${_distanceRange.end.toStringAsFixed(0)} km',
                    ),
                  ),
                  SliderTheme(
                    data: _sliderTheme(),
                    child: RangeSlider(
                      values: _distanceRange,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      labels: RangeLabels(
                        '${_distanceRange.start.round()} km',
                        '${_distanceRange.end.round()} km',
                      ),
                      onChanged: (values) =>
                          setState(() => _distanceRange = values),
                      onChangeEnd: (values) => provider.fetchAndFilterHospitals(
                        minDistance: values.start,
                        maxDistance: values.end,
                      ),
                    ),
                  ),
                  if (provider.locationMessage != null &&
                      (_distanceRange.start > 0 || _distanceRange.end < 50))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: _primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.locationMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Chuyên khoa
                  _buildSectionTitle(
                    Icons.medical_services_outlined,
                    'Chuyên khoa',
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showSpecialtySelection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSpecialties.isEmpty
                            ? const Color(0xFFF8FAFC)
                            : _primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedSpecialties.isEmpty
                              ? Colors.grey.shade300
                              : _primary,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            size: 20,
                            color: _selectedSpecialties.isEmpty
                                ? _textGrey
                                : _primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getSelectedSpecialtyNames(provider),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedSpecialties.isEmpty
                                    ? _textGrey
                                    : _textDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _textGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Đánh giá
                  _buildSectionTitle(
                    Icons.star_rounded,
                    'Đánh giá',
                    trailing: _buildValuePill(
                      '${_ratingRange.start.toStringAsFixed(1)} – ${_ratingRange.end.toStringAsFixed(1)} sao',
                    ),
                  ),
                  SliderTheme(
                    data: _sliderTheme(),
                    child: RangeSlider(
                      values: _ratingRange,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      labels: RangeLabels(
                        '${_ratingRange.start.toStringAsFixed(1)} sao',
                        '${_ratingRange.end.toStringAsFixed(1)} sao',
                      ),
                      onChanged: (values) =>
                          setState(() => _ratingRange = values),
                      onChangeEnd: (values) => provider.fetchAndFilterHospitals(
                        minRating: values.start,
                        maxRating: values.end,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 18),

                  // BHYT
                  _buildSectionTitle(Icons.verified_user_outlined, 'BHYT'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (provider.bhytList.isEmpty
                                ? [
                                    {'ten_bhyt': 'Có BHYT', 'id': 'Co_BHYT'},
                                    {
                                      'ten_bhyt': 'Không BHYT',
                                      'id': 'Khong_BHYT',
                                    },
                                  ]
                                : provider.bhytList)
                            .map<Widget>(
                              (bhyt) => _buildChoiceChip(
                                (bhyt['ten_bhyt'] ?? 'BHYT').toString(),
                                (bhyt['id'] ?? '').toString(),
                                provider.selectedBhytId,
                                (val) {
                                  provider.setSelectedBhytId(val);
                                  _applyFilters(provider);
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),

                  // Cơ sở
                  _buildSectionTitle(Icons.apartment_rounded, 'Cơ sở'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (provider.coSoList.isEmpty
                                ? [
                                    {'ten_co_so': 'Công lập', 'id': 'Cong_lap'},
                                    {'ten_co_so': 'Tư nhân', 'id': 'Tu_nhan'},
                                  ]
                                : provider.coSoList)
                            .map<Widget>(
                              (coSo) => _buildChoiceChip(
                                (coSo['ten_co_so'] ?? 'Cơ sở').toString(),
                                (coSo['id'] ?? '').toString(),
                                provider.selectedCoSoId,
                                (val) {
                                  provider.setSelectedCoSoId(val);
                                  _applyFilters(provider);
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ───────────────── Các hàm phụ ─────────────────
  /// Tiêu đề từng mục: icon + chữ, có thể kèm nhãn giá trị bên phải.
  Widget _buildSectionTitle(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Nhãn hiển thị giá trị đang chọn của thanh trượt.
  Widget _buildValuePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _primary,
        ),
      ),
    );
  }

  /// Kiểu dáng thanh trượt: thanh mỏng, nút tròn có viền trắng.
  SliderThemeData _sliderTheme() {
    return SliderTheme.of(context).copyWith(
      trackHeight: 5,
      activeTrackColor: _primary,
      inactiveTrackColor: _primary.withOpacity(0.15),
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
      thumbColor: _primary,
      overlayColor: _primary.withOpacity(0.12),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      valueIndicatorColor: _primary,
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    );
  }

  /// Lựa chọn dạng chip thay cho radio (chọn 1 giá trị).
  Widget _buildChoiceChip(
    String label,
    String value,
    String? groupValue,
    ValueChanged<String> onChanged,
  ) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? _primary : Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard({
    required Map<String, dynamic> hospitalData,
    required String id,
    required String name,
    required String address,
    required String type,
    required double rating,
    required int reviewCount,
    required String initials,
    required Color bgColor,
    required Color textColor,
    required double distance,
  }) {
    final hasDistance = distance > 0;
    final hasRating = rating > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.bookAppointment,
            arguments: hospitalData,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hàng trên: ảnh đại diện + thông tin chính ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chữ viết tắt trên nền gradient
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            bgColor,
                            Color.lerp(bgColor, Colors.white, 0.5)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Loại hình + đánh giá
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hasRating
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 15,
                                      color: hasRating
                                          ? const Color(0xFFF59E0B)
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      hasRating
                                          ? rating.toStringAsFixed(1)
                                          : 'Chưa có đánh giá',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: hasRating
                                            ? const Color(0xFFB45309)
                                            : _textGrey,
                                      ),
                                    ),
                                    if (hasRating)
                                      Text(
                                        ' ($reviewCount)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textGrey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút chat
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Địa chỉ + khoảng cách ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _textGrey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: _textGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasDistance
                        ? _primary.withOpacity(0.08)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: hasDistance ? _primary : _textGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasDistance
                            ? 'Cách bạn ${distance.toStringAsFixed(1)} km'
                            : 'Chưa xác định khoảng cách',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasDistance ? _primary : _textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Nút đặt lịch ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primary.withOpacity(0.78)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đặt lịch khám',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy bệnh viện nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy thử thay đổi bộ lọc của bạn',
              style: TextStyle(fontSize: 14, color: _textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words[0]
        .substring(0, words[0].length > 2 ? 2 : words[0].length)
        .toUpperCase();
  }
}
