import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_cskh_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_model_c1.dart';
import 'cskh_danhsach_don_khoa_screen_c1.dart';
import 'cskh_danhsach_tinnhan_screen_c1.dart';
import 'cskh_profile_tab_c1.dart';
import 'letan_baocaoloi_screen_c1.dart';

/// Model đại diện cho một chuyên khoa khám bệnh
class KhoaKhamModelC1 {
  final String tenKhoa;
  final String moTaPhong;
  final String soLuongDon; // Ví dụ: "25/25 Đơn", "20 Đơn"
  final IconData icon;
  final bool laKhoaDangChon;
  final bool laDayDon; // Nếu đầy đơn hiển thị badge đỏ

  const KhoaKhamModelC1({
    required this.tenKhoa,
    required this.moTaPhong,
    required this.soLuongDon,
    required this.icon,
    this.laKhoaDangChon = false,
    this.laDayDon = false,
  });
}

/// MÀN HÌNH TRANG CHỦ CSKH & DUYỆT ĐƠN THEO KHOA
/// Có cùng cấu trúc & chuẩn thẩm mỹ với Module Lễ tân C1
class CskhDuyetdonKhoaScreenC1 extends StatefulWidget {
  const CskhDuyetdonKhoaScreenC1({super.key});

  @override
  State<CskhDuyetdonKhoaScreenC1> createState() => _CskhDuyetdonKhoaScreenC1State();
}

class _CskhDuyetdonKhoaScreenC1State extends State<CskhDuyetdonKhoaScreenC1> {
  int _currentBottomNavIndex = 0; // 0: Trang chủ, 1: Duyệt đơn, 2: CSKH, 3: Profile

  // Danh sách 5 chuyên khoa theo thiết kế Figma
  final List<KhoaKhamModelC1> _danhSachKhoa = const [
    KhoaKhamModelC1(
      tenKhoa: 'Khoa Tim Mạch',
      moTaPhong: 'Phòng 201 • Ca sáng &\nchiều',
      soLuongDon: '25/25\nĐơn',
      icon: Icons.favorite_border_rounded,
      laKhoaDangChon: true,
      laDayDon: true,
    ),
    KhoaKhamModelC1(
      tenKhoa: 'Khoa Nội Tổng Quát',
      moTaPhong: 'Phòng 102 • BS. Nguyễn Văn Hùng',
      soLuongDon: '20 Đơn',
      icon: Icons.local_hospital_outlined,
      laKhoaDangChon: false,
      laDayDon: false,
    ),
    KhoaKhamModelC1(
      tenKhoa: 'Khoa Nhi',
      moTaPhong: 'Phòng 305 • Khám nhi đồng',
      soLuongDon: '15 Đơn',
      icon: Icons.child_care_rounded,
      laKhoaDangChon: false,
      laDayDon: false,
    ),
    KhoaKhamModelC1(
      tenKhoa: 'Khoa Răng Hàm Mặt',
      moTaPhong: 'Phòng 401 • Nha khoa chuyên sâu',
      soLuongDon: '12 Đơn',
      icon: Icons.sentiment_satisfied_alt_rounded,
      laKhoaDangChon: false,
      laDayDon: false,
    ),
    KhoaKhamModelC1(
      tenKhoa: 'Khoa Mắt',
      moTaPhong: 'Phòng 204 • Đo thị lực & khúc xạ',
      soLuongDon: '10 Đơn',
      icon: Icons.remove_red_eye_outlined,
      laKhoaDangChon: false,
      laDayDon: false,
    ),
  ];

  // Danh sách thông báo lấy từ lớp dữ liệu tập trung
  final List<ThongBaoLeTanC1> _thongBaoCskh = DuLieuCskhKhoaC1.danhSachThongBao;

  void _onSelectKhoa(KhoaKhamModelC1 khoa) {
    AppDesignSystemC1.hapticLight();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CskhDanhsachDonKhoaScreenC1(
          tenKhoa: khoa.tenKhoa,
          phongKham: khoa.moTaPhong.split('•').first.trim(),
          caKham: khoa.moTaPhong.contains('•') ? khoa.moTaPhong.split('•').last.trim().replaceAll('\n', ' ') : 'Ca sáng',
          tongDon: 25,
        ),
      ),
    );
  }

  void _moBaoCaoLoi() {
    AppDesignSystemC1.hapticLight();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LetanBaocaoloiScreenC1()),
    );
  }

  // Popup thông báo CSKH
  void _showModalThongBao() {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    String tabLocHienTai = 'tat_ca';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final soLuongChuaDoc = _thongBaoCskh.where((e) => !e.daDoc).length;
            final danhSachHienThi = tabLocHienTai == 'chua_doc'
                ? _thongBaoCskh.where((e) => !e.daDoc).toList()
                : _thongBaoCskh;

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: isDark ? AppDesignSystemC1.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
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
                                  'Thông Báo CSKH',
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
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tabs lọc: Tất cả / Chưa đọc
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppDesignSystemC1.darkSurface : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                AppDesignSystemC1.hapticLight();
                                setModalState(() => tabLocHienTai = 'tat_ca');
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: tabLocHienTai == 'tat_ca'
                                      ? (isDark ? const Color(0xFF0C2444) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Tất cả (${_thongBaoCskh.length})',
                                  style: TextStyle(
                                    color: tabLocHienTai == 'tat_ca'
                                        ? const Color(0xFF0284C7)
                                        : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B)),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                AppDesignSystemC1.hapticLight();
                                setModalState(() => tabLocHienTai = 'chua_doc');
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: tabLocHienTai == 'chua_doc'
                                      ? (isDark ? const Color(0xFF0C2444) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Chưa đọc ($soLuongChuaDoc)',
                                  style: TextStyle(
                                    color: tabLocHienTai == 'chua_doc'
                                        ? const Color(0xFFFF3B30)
                                        : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B)),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: danhSachHienThi.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = danhSachHienThi[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
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
                                  Text(
                                    item.tieuDe,
                                    style: TextStyle(
                                      color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (!item.daDoc)
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
                                item.noiDungNgan,
                                style: TextStyle(
                                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.thoiGian,
                                style: TextStyle(
                                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Header chuẩn cấu trúc giống Bàn Lễ Tân
                _buildHeader(isDark),

                // 2. Nội dung chính theo Tab được chọn
                Expanded(
                  child: _buildBodyContent(isDark),
                ),

                // 3. Thanh Bottom Navigation Bar chuẩn Material 3
                _buildBottomNav(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // Nội dung body hiển thị tùy theo tab Bottom Navigation Bar
  Widget _buildBodyContent(bool isDark) {
    // Tab 2: CSKH (Tin nhắn hỗ trợ bệnh nhân)
    if (_currentBottomNavIndex == 2) {
      return const CskhDanhsachTinnhanScreenC1();
    }

    // Tab 3: Profile CSKH
    if (_currentBottomNavIndex == 3) {
      return CskhProfileTabC1(
        onChuyenSangLeTan: () {
          Navigator.pop(context);
        },
        onDangXuat: () {
          // Khi đăng xuất sẽ pop trở về Bàn Lễ Tân
          Navigator.pop(context);
        },
      );
    }

    // Mặc định: Giao diện Trang chủ & Duyệt đơn CSKH
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner lớn duyệt đơn hôm nay (Gradient xanh dương y tế)
          _buildBannerTongDon(),
          const SizedBox(height: 18),

          // Khối thống kê nhanh tình trạng đơn khám
          _buildThongKeNhanh(isDark),
          const SizedBox(height: 18),

          // Tiêu đề danh sách chuyên khoa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH CÁC KHOA KHÁM',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ấn để duyệt đơn',
                  style: TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách 5 chuyên khoa
          ..._danhSachKhoa.map((khoa) => _buildCardKhoa(khoa, isDark)),
          const SizedBox(height: 10),

          // Nút Báo cáo lỗi hệ thống
          _buildNutBaoCaoLoi(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Header chuẩn: Chào mừng CSKH + Nút Sáng/Tối + Nút Thông báo (y hệt Header Lễ tân)
  Widget _buildHeader(bool isDark) {
    final textCol = isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A);
    final subTextCol = isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Xin chào, Chuyên viên CSKH',
                      style: TextStyle(
                        color: subTextCol,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _currentBottomNavIndex == 3
                      ? 'Hồ Sơ CSKH'
                      : (_currentBottomNavIndex == 2
                          ? 'Tin Nhắn Hỗ Trợ'
                          : 'Duyệt Đơn Theo Khoa'),
                  style: TextStyle(
                    color: textCol,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
                  size: 22,
                ),
              ),
              const SizedBox(width: 4),

              // Nút Thông báo có badge đỏ (Đồng bộ cấu trúc Lễ tân)
              InkWell(
                onTap: _showModalThongBao,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                    ),
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
                            size: 19,
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
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
                      const SizedBox(width: 5),
                      Text(
                        'Thông báo',
                        style: TextStyle(
                          color: textCol,
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
        ],
      ),
    );
  }

  // Banner Gradient tổng số đơn hôm nay
  Widget _buildBannerTongDon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'TỔNG ĐƠN KHÁM HÔM NAY',
                style: TextStyle(
                  color: Color(0xFFE0F2FE),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '82 / 100 Đơn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '5 Chuyên khoa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối thống kê hôm nay (Đồng bộ cấu trúc khối thống kê 3 ô của Lễ tân)
  Widget _buildThongKeNhanh(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildItemThongKe(
            soLuong: '82',
            nhanDe: 'Đang chờ',
            mauSo: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildItemThongKe(
            soLuong: '18',
            nhanDe: 'Đã phê duyệt',
            mauSo: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildItemThongKe(
            soLuong: '100',
            nhanDe: 'Chỉ tiêu ngày',
            mauSo: const Color(0xFF0284C7),
            isDark: isDark,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            soLuong,
            style: TextStyle(
              color: mauSo,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            nhanDe,
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Card Chuyên khoa
  Widget _buildCardKhoa(KhoaKhamModelC1 khoa, bool isDark) {
    final bool isHighlighted = khoa.laKhoaDangChon;

    Color bgCard;
    if (isDark) {
      bgCard = isHighlighted ? const Color(0xFF0C2444) : AppDesignSystemC1.darkSurface;
    } else {
      bgCard = isHighlighted ? const Color(0xFFF0F9FF) : Colors.white;
    }

    Color borderCard;
    if (isHighlighted) {
      borderCard = const Color(0xFF0284C7);
    } else {
      borderCard = isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderCard,
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSelectKhoa(khoa),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? (isDark ? const Color(0xFF075985).withValues(alpha: 0.5) : const Color(0xFFE0F2FE))
                        : (isDark ? const Color(0xFF451A03).withValues(alpha: 0.5) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    khoa.icon,
                    size: 23,
                    color: isHighlighted ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        khoa.tenKhoa,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        khoa.moTaPhong,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadgeDon(khoa, isDark),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isHighlighted
                      ? const Color(0xFF0284C7)
                      : (isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Badge số lượng đơn khám (Đỏ hoặc Vàng hổ phách)
  Widget _buildBadgeDon(KhoaKhamModelC1 khoa, bool isDark) {
    if (khoa.laDayDon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF450A0A).withValues(alpha: 0.7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.5 : 0.3),
          ),
        ),
        child: Text(
          khoa.soLuongDon,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.5 : 0.3),
        ),
      ),
      child: Text(
        khoa.soLuongDon,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }

  // Nút Báo cáo lỗi
  Widget _buildNutBaoCaoLoi(bool isDark) {
    return Center(
      child: TextButton.icon(
        onPressed: _moBaoCaoLoi,
        icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF94A3B8)),
        label: const Text(
          'Báo cáo lỗi',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }

  // Thanh Bottom Navigation Bar gồm: Trang chủ, Duyệt đơn, CSKH, Profile
  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _currentBottomNavIndex,
      onDestinationSelected: (index) {
        AppDesignSystemC1.hapticLight();
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      indicatorColor: isDark
          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
          : const Color(0xFFE0F2FE),
      elevation: 2,
      height: 65,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.home, color: Color(0xFF0284C7)),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_turned_in_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.assignment_turned_in, color: Color(0xFF0284C7)),
          label: 'Duyệt đơn',
        ),
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.support_agent, color: Color(0xFF0284C7)),
          label: 'CSKH',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, color: AppDesignSystemC1.textSecondary),
          selectedIcon: Icon(Icons.person, color: Color(0xFF0284C7)),
          label: 'Profile',
        ),
      ],
    );
  }
}
