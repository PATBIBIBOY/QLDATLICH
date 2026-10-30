import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_letan_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';
import '../../models/letan_c1/letan_qr_model_c1.dart';
import '../../services/letan_c1/letan_firebase_service_c1.dart';
import 'letan_baocaoloi_screen_c1.dart';
import 'letan_ketqua_qr_screen_c1.dart';
import 'letan_lichhen_screen_c1.dart';
import 'letan_profile_tab_c1.dart';
import 'letan_quet_qr_camera_screen_c1.dart';
import 'letan_timkiem_screen_c1.dart';

class LeTanHomeScreenC1 extends StatefulWidget {
  final String tenKhoa;

  const LeTanHomeScreenC1({
    super.key,
    this.tenKhoa = DuLieuMauLeTanC1.tenKhoaMacDinh,
  });

  @override
  State<LeTanHomeScreenC1> createState() => _LeTanHomeScreenC1State();
}

class _LeTanHomeScreenC1State extends State<LeTanHomeScreenC1> {
  int _currentIndex = 0; // 0: Trang chu, 1: Quet QR, 2: Lich hen, 3: Profile
  late String _tenKhoaHienTai;
  DateTime _ngayChon = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tenKhoaHienTai = widget.tenKhoa;
  }

  Future<void> _chonNgayLichHen() async {
    AppDesignSystemC1.hapticLight();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayChon,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN NGÀY XEM LỊCH HẸN',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked != null && picked != _ngayChon) {
      setState(() {
        _ngayChon = picked;
      });
    }
  }

  void _moManHinhQuetQr() {
    setState(() {
      _currentIndex = 1; // Chuyển thẳng sang Tab Quét QR giữ nguyên 4 nút dưới đáy
    });
  }

  // Mở popup chọn Khoa nạp trực tiếp từ /Khoa/BO85AxXqDMSB68hnYjzhYfPIxHC2/danh_sach
  void _moModalChonKhoaFirebase() {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded, color: Color(0xFF1E88E5), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Chọn Khoa Tiếp Nhận',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Firebase Live',
                        style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn khoa của bạn hoặc xem Tổng toàn viện',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseServiceC1.streamDanhSachKhoa(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(strokeWidth: 2),
                                const SizedBox(height: 12),
                                Text(
                                  'Đang tải danh sách khoa từ Firebase...',
                                  style: TextStyle(
                                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Tạo danh sách bao gồm tùy chọn "Tất cả các khoa (Tổng)" ở đầu
                      final danhSachKhoa = [
                        {
                          'tenKhoa': 'Tất cả các khoa (Tổng)',
                          'moTaPhong': 'Toàn viện • Xem và duyệt mọi lịch khám',
                          'laTong': true,
                        },
                        ...snapshot.data!,
                      ];

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: danhSachKhoa.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = danhSachKhoa[index];
                          final tenKhoa = item['tenKhoa'] ?? 'Khoa Khám';
                          final moTa = item['moTaPhong'] ?? '';
                          final laTong = item['laTong'] == true;
                          final isSelected = laTong
                              ? FirebaseServiceC1.laCheDoTong(_tenKhoaHienTai)
                              : FirebaseServiceC1.laCungKhoa(tenKhoa, _tenKhoaHienTai);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _tenKhoaHienTai = tenKhoa;
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã chuyển bàn làm việc sang: $tenKhoa'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF0C2444) : const Color(0xFFEFF6FF))
                                    : (isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1E88E5) : (isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF1E88E5) : (isDark ? AppDesignSystemC1.darkSurface : Colors.white),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      laTong ? Icons.dashboard_outlined : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tenKhoa,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF1E88E5)
                                                : (isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E)),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          moTa,
                                          style: TextStyle(
                                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF1E88E5), size: 22)
                                  else
                                    const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 22),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return PopScope(
          canPop: _currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Nếu đang ở tab khác (Quét QR, Lịch hẹn, Profile), bấm back sẽ quay về Trang chủ tab 0
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF2F2F7),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _buildCurrentBody(),
                  ),
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentBody() {
    if (_currentIndex == 1) {
      return const LetanQuetQrCameraScreenC1();
    }
    if (_currentIndex == 2) {
      return LetanLichhenScreenC1(
        tenKhoa: _tenKhoaHienTai,
        ngayChonBanDau: _ngayChon,
      );
    }
    if (_currentIndex == 3) {
      return LetanProfileTabC1(
        tenKhoaHienTai: _tenKhoaHienTai,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBannerQuetQr(),
          const SizedBox(height: 20),
          _buildThongKe(),
          const SizedBox(height: 20),
          _buildChucNangNhanh(),
          const SizedBox(height: 20),
          _buildDanhSachCho(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Header: Chào mừng lễ tân khoa + Nút Báo cáo lỗi + Nút Sáng/Tối
  Widget _buildHeader() {
    final isDark = AppDesignSystemC1.laCheDoToi;
    final textCol = isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E);
    final subTextCol = isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InkWell(
            onTap: _moModalChonKhoaFirebase,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          DuLieuProfileMauC1.thongTinHienTai.tenBenhVien.isNotEmpty
                              ? DuLieuProfileMauC1.thongTinHienTai.tenBenhVien
                              : 'Bệnh viện BV502',
                          style: const TextStyle(
                            color: Color(0xFFFF9500),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Xin chào, Lễ tân $_tenKhoaHienTai',
                          style: TextStyle(
                            color: subTextCol,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: subTextCol),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trang chủ Lễ tân',
                    style: TextStyle(
                      color: textCol,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            // Nút chuyển chế độ Sáng / Tối
            IconButton(
              onPressed: () {
                AppDesignSystemC1.batTatCheDoSangToi();
              },
              tooltip: isDark ? 'Chuyển giao diện Sáng' : 'Chuyển giao diện Tối',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : const Color(0xFF475569),
                size: 24,
              ),
            ),
            const SizedBox(width: 4),
            // NÚT THÔNG BÁO VỚI BADGE CHƯA ĐỌC
            InkWell(
              onTap: () {
                _showModalThongBao();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          size: 20,
                        ),
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Thông báo',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Banner: Quét mã QR bệnh nhân (Gradient Cam - Vàng)
  Widget _buildBannerQuetQr() {
    return InkWell(
      onTap: _moManHinhQuetQr,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9500).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon QR Code khung trắng
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quét mã QR bệnh nhân',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tự động nhận diện & mở hồ sơ tiếp nhận',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mục thống kê theo ngày (Đã tiếp nhận, Đang chờ, Đã khám) - Đọc Realtime từ Firestore theo Khoa hoặc Toàn viện
  Widget _buildThongKe() {
    final isDark = AppDesignSystemC1.laCheDoToi;
    final String ngayHienThi = '${_ngayChon.day.toString().padLeft(2, '0')}/${_ngayChon.month.toString().padLeft(2, '0')}/${_ngayChon.year}';

    return StreamBuilder<Map<String, int>>(
      stream: FirebaseServiceC1.streamThongKeHomNay(
        tenKhoa: _tenKhoaHienTai,
        ngayChon: _ngayChon,
      ),
      builder: (context, snapshot) {
        final thongKe = snapshot.data ?? {
          'daTiepNhan': 0,
          'dangCho': 0,
          'daKham': 0,
          'tongSo': 0,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Thống kê lịch khám',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        FirebaseServiceC1.laCheDoTong(_tenKhoaHienTai) ? 'Toàn viện' : _tenKhoaHienTai,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _chonNgayLichHen,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 4),
                        Text(
                          ngayHienThi,
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildItemThongKe(
                    soLuong: '${thongKe['daTiepNhan'] ?? 0}',
                    nhanDe: 'Đã tiếp nhận',
                    mauSo: const Color(0xFFFF9500),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildItemThongKe(
                    soLuong: '${thongKe['dangCho'] ?? 0}',
                    nhanDe: 'Đang chờ',
                    mauSo: const Color(0xFF007AFF),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildItemThongKe(
                    soLuong: '${thongKe['daKham'] ?? 0}',
                    nhanDe: 'Đã khám',
                    mauSo: const Color(0xFF34C759),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemThongKe({
    required String soLuong,
    required String nhanDe,
    required Color mauSo,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Text(
            soLuong,
            style: TextStyle(
              color: mauSo,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nhanDe,
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách đang chờ - Đọc Realtime từ Firestore theo khoa đã chọn hoặc Tổng
  Widget _buildDanhSachCho() {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseServiceC1.streamDanhSachLichHen(
        tenKhoa: _tenKhoaHienTai,
        boLocTrangThai: 'Đang chờ',
        ngayChon: _ngayChon,
      ),
      builder: (context, snapshot) {
        final danhSach = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách đang chờ',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${danhSach.length} bệnh nhân',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (danhSach.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hiện chưa có bệnh nhân nào chờ khám',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    fontSize: 13,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: danhSach.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildItemBenhNhanMap(danhSach[index]);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildItemBenhNhanMap(Map<String, dynamic> item) {
    Color badgeBg;
    Color badgeText;
    Color avatarBg;
    Color avatarText;

    final trangThai = item['trangThai'] ?? 'Đang chờ';
    if (trangThai == 'Tiếp theo') {
      badgeBg = const Color(0xFFE8F8EF);
      badgeText = const Color(0xFF34C759);
      avatarBg = const Color(0xFFE8F8EF);
      avatarText = const Color(0xFF34C759);
    } else if (trangThai == 'Đang chờ') {
      badgeBg = const Color(0xFFE8F4FD);
      badgeText = const Color(0xFF007AFF);
      avatarBg = const Color(0xFFE8F4FD);
      avatarText = const Color(0xFF007AFF);
    } else {
      badgeBg = const Color(0xFFF2F2F7);
      badgeText = const Color(0xFF8E8E93);
      avatarBg = const Color(0xFFF2F2F7);
      avatarText = const Color(0xFF8E8E93);
    }

    final isDark = AppDesignSystemC1.laCheDoToi;
    final cardBg = isDark ? AppDesignSystemC1.darkSurface : Colors.white;
    final borderCol = isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA);
    final textCol = isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E);
    final subTextCol = isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93);

    final hoTen = (item['hoTen'] ?? 'Bệnh nhân').toString();
    final initials = hoTen.trim().isNotEmpty
        ? hoTen.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'BN';

    return InkWell(
      onTap: () {
        AppDesignSystemC1.hapticLight();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LetanKetquaQrScreenC1(
              ketQua: KetQuaQuetQrC1(
                thanhCong: true,
                thongBao: 'Hồ sơ tiếp nhận bệnh nhân',
                chiTietLoi: 'Đã tiếp nhận vào hàng chờ',
                soThuTu: int.tryParse(item['stt']?.toString() ?? '1') ?? 1,
                gioKhamDuKien: '${item['gioKham']} - Hôm nay',
                hoTen: hoTen.toUpperCase(),
                maBenhNhan: (item['maBenhNhan'] ?? '').toString(),
                namSinhGioiTinh: [item['namSinh']?.toString() ?? '', item['gioiTinh']?.toString() ?? ''].where((s) => s.isNotEmpty).join(' - '),
                cccd: (item['cccd'] ?? '').toString(),
                bhyt: (item['bhyt'] ?? '').toString(),
                khoaKham: (item['tenKhoa'] ?? '').toString(),
                phongKham: (item['phongKham'] ?? '').toString(),
                bacSi: (item['bacSi'] ?? '').toString(),
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: avatarText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hoTen,
                    style: TextStyle(
                      color: textCol,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item['gioKham']} • STT: ${item['stt']} • ${item['tenKhoa']}',
                    style: TextStyle(
                      color: subTextCol,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trangThai,
                style: TextStyle(
                  color: badgeText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chức năng nhanh (Lướt ngang đa chức năng)
  Widget _buildChucNangNhanh() {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chức năng nhanh',
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Vuốt ngang ➔',
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              // 1. Tìm bệnh nhân
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Tìm bệnh nhân',
                moTa: 'Theo tên / SĐT',
                iconData: Icons.search,
                mauIcon: const Color(0xFF007AFF),
                mauNenIcon: isDark ? const Color(0xFF0C2444) : const Color(0xFFE8F4FD),
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LetanTimkiemScreenC1()),
                  );
                },
              ),
              const SizedBox(width: 10),

              // 2. Lịch hẹn hôm nay
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Lịch hẹn hôm nay',
                moTa: '28 lịch hẹn',
                iconData: Icons.calendar_today,
                mauIcon: const Color(0xFFFF9500),
                mauNenIcon: isDark ? const Color(0xFF332005) : const Color(0xFFFFF5E6),
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // Sang Tab Lịch hẹn
                  });
                },
              ),
              const SizedBox(width: 10),

              // 3. Quét mã QR
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Quét mã QR',
                moTa: 'Tiếp đón tại quầy',
                iconData: Icons.qr_code_scanner,
                mauIcon: const Color(0xFF10B981),
                mauNenIcon: isDark ? const Color(0xFF052A1C) : const Color(0xFFECFDF5),
                isDark: isDark,
                onTap: _moManHinhQuetQr,
              ),
              const SizedBox(width: 10),

              // 4. Báo cáo sự cố
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Báo cáo sự cố',
                moTa: 'Gửi lỗi hệ thống',
                iconData: Icons.warning_amber_rounded,
                mauIcon: const Color(0xFFFF3B30),
                mauNenIcon: isDark ? const Color(0xFF33100D) : const Color(0xFFFEE2E2),
                isDark: isDark,
                onTap: _showDialogBaoCaoLoi,
              ),
              const SizedBox(width: 10),

              // 5. Hồ sơ cá nhân
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Hồ sơ lễ tân',
                moTa: 'Đổi mật khẩu / Khoa',
                iconData: Icons.person_outline,
                mauIcon: const Color(0xFF8B5CF6),
                mauNenIcon: isDark ? const Color(0xFF23143E) : const Color(0xFFF3E8FF),
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _currentIndex = 3; // Sang Tab Profile
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemChucNangNhanhNgang({
    required String tieuDe,
    required String moTa,
    required IconData iconData,
    required Color mauIcon,
    required Color mauNenIcon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mauNenIcon,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: mauIcon, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tieuDe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moTa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thanh điều hướng dưới cùng chuẩn Material 3 NavigationBar
  Widget _buildBottomNav() {
    final isDark = AppDesignSystemC1.laCheDoToi;
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        AppDesignSystemC1.hapticLight();
        setState(() {
          _currentIndex = index;
        });
      },
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      indicatorColor: isDark ? AppDesignSystemC1.primary.withValues(alpha: 0.3) : AppDesignSystemC1.primaryLight,
      elevation: 2,
      height: 65,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.home, color: AppDesignSystemC1.primary),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.qr_code_scanner, color: AppDesignSystemC1.primary),
          label: 'Quét QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.calendar_today, color: AppDesignSystemC1.primary),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.person, color: AppDesignSystemC1.primary),
          label: 'Profile',
        ),
      ],
    );
  }

  // Mở màn hình Báo cáo lỗi
  void _showDialogBaoCaoLoi() {
    AppDesignSystemC1.hapticLight();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetanBaocaoloiScreenC1(tenKhoa: widget.tenKhoa),
      ),
    );
  }

  // POPUP LISTVIEW CÁC THÔNG BÁO DÀNH CHO LỄ TÂN (Realtime từ Firestore /ThongBaoHeThong)
  void _showModalThongBao() {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    String tabLocHienTai = 'tat_ca'; // 'tat_ca' hoặc 'chua_doc'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseServiceC1.streamThongBaoRealtime(vaiTro: 'le_tan'),
              builder: (context, snapshot) {
                final dsRaw = snapshot.data ?? [];
                final soLuongChuaDoc = dsRaw.where((e) => e['da_doc'] != true).length;
                final danhSachHienThi = tabLocHienTai == 'chua_doc'
                    ? dsRaw.where((e) => e['da_doc'] != true).toList()
                    : dsRaw;

                return SafeArea(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thanh kéo nhẹ
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header Popup
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_rounded,
                                      color: Color(0xFF0284C7),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thông Báo Lễ Tân',
                                        style: TextStyle(
                                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '$soLuongChuaDoc thông báo chưa đọc',
                                        style: TextStyle(
                                          color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                ),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2 TAB CHUYỂN ĐỔI: "TẤT CẢ" VÀ "CHƯA ĐỌC"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Tab 1: Tất cả
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      AppDesignSystemC1.hapticLight();
                                      setModalState(() {
                                        tabLocHienTai = 'tat_ca';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: tabLocHienTai == 'tat_ca'
                                            ? (isDark ? AppDesignSystemC1.darkSurface : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Tất cả',
                                            style: TextStyle(
                                              color: tabLocHienTai == 'tat_ca'
                                                  ? (isDark ? Colors.white : AppDesignSystemC1.primary)
                                                  : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B)),
                                              fontSize: 13.5,
                                              fontWeight: tabLocHienTai == 'tat_ca' ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: tabLocHienTai == 'tat_ca'
                                                  ? (isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE))
                                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${dsRaw.length}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: tabLocHienTai == 'tat_ca'
                                                    ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                    : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Tab 2: Chưa đọc
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      AppDesignSystemC1.hapticLight();
                                      setModalState(() {
                                        tabLocHienTai = 'chua_doc';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: tabLocHienTai == 'chua_doc'
                                            ? (isDark ? AppDesignSystemC1.darkSurface : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Chưa đọc',
                                            style: TextStyle(
                                              color: tabLocHienTai == 'chua_doc'
                                                  ? const Color(0xFFFF3B30)
                                                  : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B)),
                                              fontSize: 13.5,
                                              fontWeight: tabLocHienTai == 'chua_doc' ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                          if (soLuongChuaDoc > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF3B30),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '$soLuongChuaDoc',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Divider(
                          height: 1,
                          color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFEDF2F7),
                        ),

                        // Danh sách thông báo dạng ListView theo bộ lọc từ Firestore
                        Flexible(
                          child: danhSachHienThi.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.mark_email_read_outlined,
                                        size: 48,
                                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Không có thông báo nào',
                                        style: TextStyle(
                                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  itemCount: danhSachHienThi.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = danhSachHienThi[index];
                                    final id = item['id']?.toString() ?? '';
                                    final tieuDe = (item['tieu_de'] ?? item['tieuDe'] ?? 'Thông báo').toString();
                                    final noiDung = (item['noi_dung'] ?? item['noiDung'] ?? '').toString();
                                    final thoiGian = (item['thoi_gian_hien_thi'] ?? item['thoiGian'] ?? 'Vừa xong').toString();
                                    final daDoc = item['da_doc'] == true;

                                    return InkWell(
                                      onTap: () {
                                        if (id.isNotEmpty) {
                                          FirebaseServiceC1.danhDauDaDocThongBao(id);
                                        }
                                        _showDialogChiTietThongBaoRaw(item);
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tieuDe,
                                                    style: TextStyle(
                                                      color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (!daDoc)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF0284C7),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              noiDung,
                                              style: TextStyle(
                                                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              thoiGian,
                                              style: TextStyle(
                                                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
      },
    );
  }

  // DIALOG XEM CHI TIẾT THÔNG BÁO TỪ FIRESTORE
  void _showDialogChiTietThongBaoRaw(Map<String, dynamic> item) {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    final tieuDe = (item['tieu_de'] ?? item['tieuDe'] ?? 'Thông báo').toString();
    final noiDung = (item['noi_dung'] ?? item['noiDung'] ?? '').toString();
    final thoiGian = (item['thoi_gian_hien_thi'] ?? item['thoiGian'] ?? 'Vừa xong').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    thoiGian,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              tieuDe,
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              noiDung,
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystemC1.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
