import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_profile_model_c1.dart';
import 'letan_capnhat_profile_screen_c1.dart';
import 'letan_doimatkhau_screen_c1.dart';
import 'letan_quenmatkhau_screen_c1.dart';

class LetanProfileTabC1 extends StatefulWidget {
  final VoidCallback? onDangXuat;

  const LetanProfileTabC1({
    super.key,
    this.onDangXuat,
  });

  @override
  State<LetanProfileTabC1> createState() => _LetanProfileTabC1State();
}

class _LetanProfileTabC1State extends State<LetanProfileTabC1> {
  ThongTinLeTanC1 _thongTin = DuLieuProfileMauC1.thongTinHienTai;

  // Điều hướng sang trang chỉnh sửa thông tin và reload lại khi có kết quả mới
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
        DuLieuProfileMauC1.thongTinHienTai = ketQuaMoi;
      });
    }
  }

  // Điều hướng sang trang đổi mật khẩu
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          _buildHeaderProfile(),
          const SizedBox(height: 18),
          _buildCardThongTinCaNhan(),
          const SizedBox(height: 16),
          _buildCardTaiKhoanBaoMat(),
          const SizedBox(height: 20),
          _buildButtonDangXuat(),
        ],
      ),
    );
  }

  // Header Avatar lớn + Tên + Badge Khoa
  Widget _buildHeaderProfile() {
    final initials = _thongTin.hoTen.split(' ').map((e) => e[0]).take(2).join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar hình tròn nổi bật
          Stack(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isNotEmpty ? initials : 'LT',
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
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tên lễ tân
          Text(
            _thongTin.hoTen,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          // CHỨC VỤ LỚN NẰM NGAY DƯỚI TÊN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC00)),
            ),
            child: Text(
              _thongTin.chucVu,
              style: const TextStyle(
                color: Color(0xFFFF9500),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Khối thông tin chi tiết: Tên, Mã NV, Thuộc khoa, Gmail
  Widget _buildCardThongTinCaNhan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin nhân sự',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _moTrangChinhSua,
                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFFF9500)),
                label: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    color: Color(0xFFFF9500),
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
          const Divider(height: 18, color: Color(0xFFF2F2F7)),
          _buildItemInfo(Icons.person_outline, 'Họ và tên', _thongTin.hoTen),
          _buildItemInfo(Icons.badge_outlined, 'Mã nhân viên', _thongTin.maNhanVien),
          _buildItemInfo(Icons.local_hospital_outlined, 'Thuộc khoa', _thongTin.khoa),
          _buildItemInfo(Icons.alternate_email, 'Gmail tài khoản', _thongTin.email),
        ],
      ),
    );
  }

  // Khối Tài khoản & Đổi mật khẩu / Quên mật khẩu
  Widget _buildCardTaiKhoanBaoMat() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bảo mật & Mật khẩu',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFFFF9500), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Cập nhật mật khẩu bảo mật mới',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF8E8E93), size: 16),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mail_lock_outlined, color: Color(0xFF007AFF), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Gửi mã xác thực qua Gmail (mô phỏng Firebase)',
                          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF8E8E93), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Nút Đăng xuất
  Widget _buildButtonDangXuat() {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ca làm việc lễ tân?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng xuất tài khoản!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30), foregroundColor: Colors.white),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Text(
              'Đăng Xuất Tài Khoản',
              style: TextStyle(
                color: Color(0xFFEF4444),
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
