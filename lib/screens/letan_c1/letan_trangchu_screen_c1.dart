import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_letan_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_model_c1.dart';
import 'letan_baocaoloi_screen_c1.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
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

  // Header: Chào mừng lễ tân khoa + Nút Báo cáo lỗi
  Widget _buildHeader() {
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
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trang chủ Lễ tân',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Nút Báo cáo lỗi
        InkWell(
          onTap: () {
            _showDialogBaoCaoLoi();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
            ),
            child: const Text(
              '⚠ Báo cáo lỗi',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê hôm nay',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
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
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '${thongKe.dangCho}',
                nhanDe: 'Đang chờ',
                mauSo: const Color(0xFF007AFF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '${thongKe.daKham}',
                nhanDe: 'Đã khám',
                mauSo: const Color(0xFF34C759),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
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
            style: const TextStyle(
              color: Color(0xFF8E8E93),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chức năng nhanh',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Vuốt ngang ➔',
              style: TextStyle(
                color: Color(0xFF8E8E93),
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
                mauNenIcon: const Color(0xFFE8F4FD),
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
                mauNenIcon: const Color(0xFFFFF5E6),
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
                mauNenIcon: const Color(0xFFECFDF5),
                onTap: _moManHinhQuetQr,
              ),
              const SizedBox(width: 10),

              // 4. Báo cáo sự cố
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Báo cáo sự cố',
                moTa: 'Gửi lỗi hệ thống',
                iconData: Icons.warning_amber_rounded,
                mauIcon: const Color(0xFFFF3B30),
                mauNenIcon: const Color(0xFFFEE2E2),
                onTap: _showDialogBaoCaoLoi,
              ),
              const SizedBox(width: 10),

              // 5. Hồ sơ cá nhân
              _buildItemChucNangNhanhNgang(
                tieuDe: 'Hồ sơ lễ tân',
                moTa: 'Đổi mật khẩu / Khoa',
                iconData: Icons.person_outline,
                mauIcon: const Color(0xFF8B5CF6),
                mauNenIcon: const Color(0xFFF3E8FF),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                    style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moTa,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách đang chờ',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
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
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.khoa} · ${item.gioKham}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
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
    );
  }

  // Thanh điều hướng dưới cùng chuẩn Material 3 NavigationBar
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        AppDesignSystemC1.hapticLight();
        setState(() {
          _currentIndex = index;
        });
      },
      backgroundColor: Colors.white,
      indicatorColor: AppDesignSystemC1.primaryLight,
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
}
