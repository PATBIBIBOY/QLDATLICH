import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';
import 'letan_capnhat_profile_screen_c1.dart';
import 'letan_doimatkhau_screen_c1.dart';
import 'letan_quenmatkhau_screen_c1.dart';

/// Màn hình Profile / Hồ sơ dành riêng cho vai trò Chăm Sóc Khách Hàng (CSKH)
class CskhProfileTabC1 extends StatefulWidget {
  final VoidCallback? onDangXuat;
  final VoidCallback? onChuyenSangLeTan;

  const CskhProfileTabC1({
    super.key,
    this.onDangXuat,
    this.onChuyenSangLeTan,
  });

  @override
  State<CskhProfileTabC1> createState() => _CskhProfileTabC1State();
}

class _CskhProfileTabC1State extends State<CskhProfileTabC1> {
  // Dữ liệu profile mẫu cho nhân viên CSKH
  ThongTinLeTanC1 _thongTin = const ThongTinLeTanC1(
    hoTen: 'Đinh Hoàng Cước',
    chucVu: 'CHUYÊN VIÊN CHĂM SÓC KHÁCH HÀNG',
    maNhanVien: 'CSKH-HOTLINE-01',
    khoa: 'Bộ Phận CSKH & Tiếp Nhận',
    email: 'cuoc.cskh@benhvien.vn',
  );

  Future<void> _moTrangChinhSua() async {
    final ketQuaMoi = await Navigator.push<ThongTinLeTanC1>(
      context,
      MaterialPageRoute(
        builder: (_) => LetanCapnhatProfileScreenC1(thongTinHienTai: _thongTin),
      ),
    );

    if (ketQuaMoi != null) {
      setState(() {
        _thongTin = ketQuaMoi;
      });
    }
  }

  void _moTrangDoiMatKhau() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetanDoimatkhauScreenC1(email: _thongTin.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _buildHeaderProfile(),
          const SizedBox(height: 16),
          _buildCardThongTinCaNhan(),
          const SizedBox(height: 16),
          _buildCardTaiKhoanBaoMat(),
          const SizedBox(height: 16),
          _buildCardCaiDatGiaoDien(),
          const SizedBox(height: 16),
          _buildCardChuyenSangLeTan(),
          const SizedBox(height: 20),
          _buildButtonDangXuat(),
        ],
      ),
    );
  }

  // Header Avatar lớn + Tên + Badge CSKH
  Widget _buildHeaderProfile() {
    final initials = _thongTin.hoTen.split(' ').map((e) => e[0]).take(2).join();
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar hình tròn gradient xanh dương đặc trưng của CSKH
          Stack(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isNotEmpty ? initials : 'KH',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _moTrangChinhSua,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppDesignSystemC1.darkSurface : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tên nhân sự
          Text(
            _thongTin.hoTen,
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),

          // Badge Chức vụ CSKH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.6 : 1.0)),
            ),
            child: const Text(
              'CHUYÊN VIÊN CHĂM SÓC KHÁCH HÀNG',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối thông tin chi tiết: Tên, Mã NV, Bộ phận, Gmail
  Widget _buildCardThongTinCaNhan() {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông tin nhân sự CSKH',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _moTrangChinhSua,
                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                label: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          Divider(height: 18, color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFF2F2F7)),
          _buildItemInfo(Icons.person_outline, 'Họ và tên', _thongTin.hoTen),
          _buildItemInfo(Icons.badge_outlined, 'Mã nhân viên', _thongTin.maNhanVien),
          _buildItemInfo(Icons.headset_mic_outlined, 'Bộ phận', _thongTin.khoa),
          _buildItemInfo(Icons.alternate_email, 'Gmail tài khoản', _thongTin.email),
        ],
      ),
    );
  }

  // Khối Tài khoản & Đổi mật khẩu / Quên mật khẩu
  Widget _buildCardTaiKhoanBaoMat() {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảo mật & Mật khẩu',
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Nút sang trang Đổi mật khẩu
          InkWell(
            onTap: _moTrangDoiMatKhau,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_reset, color: Color(0xFF0284C7), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Cập nhật mật khẩu bảo mật mới',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút sang trang Quên mật khẩu
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LetanQuenmatkhauScreenC1(emailMacDinh: _thongTin.email),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_lock_outlined, color: Color(0xFF007AFF), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Gửi mã xác thực qua Gmail (mô phỏng Firebase)',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo(IconData icon, String label, String value) {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Khối Cài đặt Giao diện (Chế độ Sáng / Tối)
  Widget _buildCardCaiDatGiaoDien() {
    final isDark = AppDesignSystemC1.laCheDoToi;
    final cardBg = isDark ? AppDesignSystemC1.darkSurface : Colors.white;
    final borderCol = isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA);
    final textCol = isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E);
    final subTextCol = isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao diện ứng dụng',
            style: TextStyle(
              color: textCol,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? Colors.amber : const Color(0xFF0284C7),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ tối (Dark Mode)',
                        style: TextStyle(
                          color: textCol,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isDark ? 'Đang kích hoạt nền tối bảo vệ mắt' : 'Đang sử dụng nền sáng tiêu chuẩn',
                        style: TextStyle(color: subTextCol, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  activeThumbColor: AppDesignSystemC1.primary,
                  onChanged: (val) {
                    AppDesignSystemC1.batTatCheDoSangToi();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Khối chuyển đổi nhanh sang vai trò Lễ tân (tiện cho test/demo)
  Widget _buildCardChuyenSangLeTan() {
    final isDark = AppDesignSystemC1.laCheDoToi;
    final cardBg = isDark ? AppDesignSystemC1.darkSurface : Colors.white;
    final borderCol = isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA);
    final textCol = isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E);
    final subTextCol = isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chuyển đổi vai trò làm việc',
            style: TextStyle(
              color: textCol,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              AppDesignSystemC1.hapticLight();
              if (widget.onChuyenSangLeTan != null) {
                widget.onChuyenSangLeTan!();
              } else {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF451A03).withValues(alpha: 0.3) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF97316).withValues(alpha: isDark ? 0.6 : 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFFEA580C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quay lại Bàn Lễ Tân',
                          style: TextStyle(
                            color: textCol,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chuyển về giao diện tiếp đón & quét QR bệnh nhân',
                          style: TextStyle(color: subTextCol, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFEA580C),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút Đăng xuất: Khi ấn xác nhận sẽ trở về màn hình Lễ tân
  Widget _buildButtonDangXuat() {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ca làm việc CSKH và trở về bàn Lễ tân?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Đóng Dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đăng xuất ca làm việc CSKH! Đang quay lại bàn Lễ tân...'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Quay trở về màn hình Lễ tân
                  if (widget.onDangXuat != null) {
                    widget.onDangXuat!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFFF3B30), size: 18),
            SizedBox(width: 8),
            Text(
              'Đăng xuất ca làm việc CSKH',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
