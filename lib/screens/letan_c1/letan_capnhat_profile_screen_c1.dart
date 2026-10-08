import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';

class LetanCapnhatProfileScreenC1 extends StatefulWidget {
  final ThongTinLeTanC1 thongTinHienTai;

  const LetanCapnhatProfileScreenC1({
    super.key,
    required this.thongTinHienTai,
  });

  @override
  State<LetanCapnhatProfileScreenC1> createState() => _LetanCapnhatProfileScreenC1State();
}

class _LetanCapnhatProfileScreenC1State extends State<LetanCapnhatProfileScreenC1> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hoTenController;
  late TextEditingController _chucVuController;
  late TextEditingController _maNhanVienController;
  late String _khoaDuocChon;

  @override
  void initState() {
    super.initState();
    _hoTenController = TextEditingController(text: widget.thongTinHienTai.hoTen);
    _chucVuController = TextEditingController(text: widget.thongTinHienTai.chucVu);
    _maNhanVienController = TextEditingController(text: widget.thongTinHienTai.maNhanVien);
    
    // Đảm bảo khoa hiện tại nằm trong danh sách chọn có sẵn
    if (DuLieuProfileMauC1.danhSachKhoaCoSan.contains(widget.thongTinHienTai.khoa)) {
      _khoaDuocChon = widget.thongTinHienTai.khoa;
    } else {
      _khoaDuocChon = DuLieuProfileMauC1.danhSachKhoaCoSan.first;
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _chucVuController.dispose();
    _maNhanVienController.dispose();
    super.dispose();
  }

  void _moModalChonKhoa() {
    final isDark = AppDesignSystemC1.laCheDoToi;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: Color(0xFFFF9500), size: 22),
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
                const SizedBox(height: 4),
                Text(
                  'Chọn khoa chuyên môn bạn đang trực ca tiếp nhận',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: DuLieuProfileMauC1.danhSachKhoaCoSan.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final khoa = DuLieuProfileMauC1.danhSachKhoaCoSan[index];
                      final bool isSelected = khoa == _khoaDuocChon;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _khoaDuocChon = khoa;
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF5E6) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF9500) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF9500) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  size: 18,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  khoa,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFFF9500) : const Color(0xFF1C1C1E),
                                    fontSize: 14.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9500), size: 22)
                              else
                                const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _luuThayDoi() {
    if (_formKey.currentState!.validate()) {
      final thongTinMoi = widget.thongTinHienTai.copyWith(
        hoTen: _hoTenController.text.trim(),
        chucVu: _chucVuController.text.trim(),
        maNhanVien: _maNhanVienController.text.trim(),
        khoa: _khoaDuocChon,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Color(0xFF34C759),
        ),
      );

      // Trả về thông tin mới cho trang Profile reload lại
      Navigator.pop(context, thongTinMoi);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesignSystemC1.laCheDoToi;

    return Scaffold(
      backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context), // Hủy bỏ
        ),
        title: Text(
          'Chỉnh Sửa Thông Tin',
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Khối thông tin cố định Gmail
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
                  ),
                  child: _buildRowThongTinCoDinh(
                    icon: Icons.alternate_email,
                    label: 'Gmail đăng nhập (Cố định bảo mật)',
                    val: widget.thongTinHienTai.email,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Form chỉnh sửa thông tin
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Họ và tên lễ tân',
                        controller: _hoTenController,
                        icon: Icons.person_outline,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Chức vụ hiển thị',
                        controller: _chucVuController,
                        icon: Icons.workspace_premium_outlined,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập chức vụ' : null,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Mã nhân viên',
                        controller: _maNhanVienController,
                        icon: Icons.badge_outlined,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập mã nhân viên' : null,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      // Selector chọn Khoa có sẵn của bệnh viện dạng BottomSheet hiện đại
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thuộc khoa tiếp nhận',
                            style: TextStyle(
                              color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _moModalChonKhoa,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.35), width: 1.2),
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
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFF5E6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFFF9500), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Khoa đang công tác',
                                          style: TextStyle(
                                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _khoaDuocChon,
                                          style: TextStyle(
                                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE8F4FD),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text(
                                          'Thay đổi',
                                          style: TextStyle(
                                            color: Color(0xFF007AFF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.keyboard_arrow_right, color: Color(0xFF007AFF), size: 16),
                                      ],
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
                ),
                const SizedBox(height: 30),

                // Nút Lưu thay đổi
                ElevatedButton(
                  onPressed: _luuThayDoi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lưu Thay Đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Hủy bỏ (về lại trang Profile, không đổi gì)
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE5E5EA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Hủy Bỏ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowThongTinCoDinh({
    required IconData icon,
    required String label,
    required String val,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93), size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F2F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDark ? const BorderSide(color: AppDesignSystemC1.darkBorder) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDark ? const BorderSide(color: AppDesignSystemC1.darkBorder) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF9500), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
