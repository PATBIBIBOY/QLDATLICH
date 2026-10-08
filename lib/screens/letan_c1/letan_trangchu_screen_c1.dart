import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_letan_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_model_c1.dart';
import '../../models/letan_c1/letan_qr_model_c1.dart';
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

  void _moManHinhQuetQr() {
    setState(() {
      _currentIndex = 1; // Chuyển thẳng sang Tab Quét QR giữ nguyên 4 nút dưới đáy
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
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
        );
      },
    );
  }

  Widget _buildCurrentBody() {
    if (_currentIndex == 1) {
      return const LetanQuetQrCameraScreenC1();
    }
    if (_currentIndex == 2) {
      return const LetanLichhenScreenC1();
    }
    if (_currentIndex == 3) {
      return const LetanProfileTabC1();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, Lễ tân ${widget.tenKhoa}',
                style: TextStyle(
                  color: subTextCol,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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

  // Mục thống kê hôm nay (Đã tiếp nhận, Đang chờ, Đã khám)
  Widget _buildThongKe() {
    const thongKe = DuLieuMauLeTanC1.thongKe;
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê hôm nay',
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildItemThongKe(
                soLuong: '${thongKe.daTiepNhan}',
                nhanDe: 'Đã tiếp nhận',
                mauSo: const Color(0xFFFF9500),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '${thongKe.dangCho}',
                nhanDe: 'Đang chờ',
                mauSo: const Color(0xFF007AFF),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '${thongKe.daKham}',
                nhanDe: 'Đã khám',
                mauSo: const Color(0xFF34C759),
                isDark: isDark,
              ),
            ),
          ],
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

  // Danh sách đang chờ
  Widget _buildDanhSachCho() {
    final danhSach = DuLieuMauLeTanC1.danhSachCho;
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách đang chờ',
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: danhSach.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildItemBenhNhan(danhSach[index]);
          },
        ),
      ],
    );
  }

  Widget _buildItemBenhNhan(BenhNhanChoKhamC1 item) {
    Color badgeBg;
    Color badgeText;
    Color avatarBg;
    Color avatarText;

    if (item.trangThai == 'Tiếp theo') {
      badgeBg = const Color(0xFFE8F8EF);
      badgeText = const Color(0xFF34C759);
      avatarBg = const Color(0xFFE8F8EF);
      avatarText = const Color(0xFF34C759);
    } else if (item.trangThai == 'Đang chờ') {
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
                soThuTu: item.trangThai == 'Tiếp theo' ? 14 : 15,
                gioKhamDuKien: '${item.gioKham} - 09:30',
                hoTen: item.ten.toUpperCase(),
                maBenhNhan: 'BN-2026-${item.id}',
                namSinhGioiTinh: '1992 - Nam',
                cccd: '001092008892',
                bhyt: 'BHYT 100%',
                khoaKham: item.khoa,
                phongKham: 'Phòng 204 - Tầng 2 Khu A',
                bacSi: 'BS. CKII Lê Hoàng Nam',
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
            // Avatar viết tắt
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                item.avatarInitials,
                style: TextStyle(
                  color: avatarText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tên & giờ khám
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ten,
                    style: TextStyle(
                      color: textCol,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.khoa} · ${item.gioKham}',
                    style: TextStyle(
                      color: subTextCol,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Badge trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.trangThai,
                style: TextStyle(
                  color: badgeText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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

  // POPUP LISTVIEW CÁC THÔNG BÁO DÀNH CHO LỄ TÂN
  void _showModalThongBao() {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    final tatCaThongBao = DuLieuMauLeTanC1.danhSachThongBao;
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
            final soLuongChuaDoc = tatCaThongBao.where((e) => !e.daDoc).length;
            final danhSachHienThi = tabLocHienTai == 'chua_doc'
                ? tatCaThongBao.where((e) => !e.daDoc).toList()
                : tatCaThongBao;

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
                                    boxShadow: tabLocHienTai == 'tat_ca'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
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
                                          '${tatCaThongBao.length}',
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
                                    boxShadow: tabLocHienTai == 'chua_doc'
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
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

                    // Danh sách thông báo dạng ListView theo bộ lọc
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
                                    'Không có thông báo chưa đọc',
                                    style: TextStyle(
                                      color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tất cả thông báo của ca trực lễ tân đều đã được xem.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                      fontSize: 12.5,
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
                                return _buildItemThongBao(item, isDark);
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
  }

  // Từng item trong ListView thông báo
  Widget _buildItemThongBao(ThongBaoLeTanC1 item, bool isDark) {
    Color iconColor;
    Color iconBg;
    IconData iconData;

    switch (item.loai) {
      case 'khan_cap':
        iconColor = const Color(0xFFEF4444);
        iconBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2);
        iconData = Icons.warning_amber_rounded;
        break;
      case 'lich_hen':
        iconColor = const Color(0xFF0284C7);
        iconBg = isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE);
        iconData = Icons.event_available_rounded;
        break;
      case 'he_thong':
        iconColor = const Color(0xFF10B981);
        iconBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5);
        iconData = Icons.dns_rounded;
        break;
      default:
        iconColor = const Color(0xFFFF9500);
        iconBg = isDark ? const Color(0xFF451A03) : const Color(0xFFFFF5E6);
        iconData = Icons.badge_outlined;
    }

    return InkWell(
      onTap: () {
        AppDesignSystemC1.hapticLight();
        Navigator.pop(context); // Đóng modal danh sách
        _showDialogChiTietThongBao(item); // Mở popup xem chi tiết
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.tieuDe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!item.daDoc)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.thoiGian,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG XEM CHI TIẾT THÔNG BÁO KHI ẤN VÀO
  void _showDialogChiTietThongBao(ThongBaoLeTanC1 item) {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;

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
                    item.thoiGian,
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
            const SizedBox(height: 12),
            Text(
              item.tieuDe,
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFEDF2F7),
            ),
            const SizedBox(height: 14),
            Text(
              item.noiDungChiTiet,
              style: TextStyle(
                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF334155),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  AppDesignSystemC1.hapticLight();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystemC1.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Đã Hiểu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
