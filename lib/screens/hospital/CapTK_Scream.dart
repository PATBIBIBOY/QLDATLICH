import 'package:flutter/material.dart';

import 'danhSachTaiKhoanDaTao_Screen.dart';

class CapTaiKhoanNhanVienScreen extends StatefulWidget {
  const CapTaiKhoanNhanVienScreen({super.key});

  @override
  State<CapTaiKhoanNhanVienScreen> createState() =>
      _CapTaiKhoanNhanVienScreenState();
}

class _CapTaiKhoanNhanVienScreenState
    extends State<CapTaiKhoanNhanVienScreen> {
  static const _blue = Color(0xFF2F83FF);
  static const _departments = [
    'Khoa Tim Mạch',
    'Khoa Mắt Kỹ Thuật Cao',
    'Khoa Nhi',
    'Khoa Răng Hàm Mặt',
  ];

  String? _selectedDepartment;
  _StaffRole _selectedRole = _StaffRole.receptionist;
  int _accountCount = 5;

  Future<void> _selectDepartment() async {
    final department = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn khoa làm việc',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ..._departments.map(
                (department) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(department),
                  trailing: department == _selectedDepartment
                      ? const Icon(Icons.check_circle, color: _blue)
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Color(0xFFB8C0CC),
                        ),
                  onTap: () => Navigator.pop(context, department),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (department != null) {
      setState(() => _selectedDepartment = department);
    }
  }

  void _changeCount(int amount) {
    setState(() {
      _accountCount = (_accountCount + amount).clamp(1, 99);
    });
  }

  String _getDepartmentCode(String dept) {
    if (dept.contains('Tim')) return 'TM';
    if (dept.contains('Mắt')) return 'MT';
    if (dept.contains('Nhi')) return 'NH';
    if (dept.contains('Răng')) return 'RHM';
    return 'KHOA';
  }

  String _getRolePrefix(_StaffRole role) {
    switch (role) {
      case _StaffRole.receptionist:
        return 'LT';
      case _StaffRole.doctorAssistant:
        return 'BS';
      case _StaffRole.customerSupport:
        return 'SP';
    }
  }

  void _taoTaiKhoan() {
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khoa làm việc.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    final deptShort = _getDepartmentCode(_selectedDepartment!);
    final rolePrefix = _getRolePrefix(_selectedRole);
    const commonPassword = StaffAccountStore.matKhauMacDinh;

    final List<TaiKhoanItem> danhSach = [];
    for (int i = 1; i <= _accountCount; i++) {
      final numStr = i.toString().padLeft(2, '0');
      final maTk = '${rolePrefix}_${deptShort}_$numStr';
      danhSach.add(TaiKhoanItem(maTk: maTk, matKhau: commonPassword));
    }

    final dotMoi = DotCapTaiKhoan(
      tenKhoa: _selectedDepartment!,
      vaiTro: _selectedRole.title,
      soLuong: _accountCount,
      danhSachTaiKhoan: danhSach,
    );
    StaffAccountStore.luuDotCap(dotMoi);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DanhSachTaiKhoanDaTaoScreen(
          tenKhoa: dotMoi.tenKhoa,
          vaiTro: dotMoi.vaiTro,
          soLuong: dotMoi.soLuong,
          danhSachTaiKhoan: dotMoi.danhSachTaiKhoan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Chọn khoa làm việc', required: true),
                        const SizedBox(height: 6),
                        _buildDepartmentSelector(),
                        const SizedBox(height: 12),
                        _buildRoleHeader(),
                        const SizedBox(height: 7),
                        for (final role in _StaffRole.values) ...[
                          _buildRoleCard(role),
                          const SizedBox(height: 7),
                        ],
                        const SizedBox(height: 3),
                        _buildSectionLabel('Số lượng tài khoản', required: true),
                        const SizedBox(height: 7),
                        _buildCounter(),
                        const SizedBox(height: 9),
                        _buildPresets(),
                        const SizedBox(height: 10),
                        _buildPolicy(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _taoTaiKhoan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        'Tạo $_accountCount Tài Khoản Nhân Viên',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EBEF))),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Cấp Tài Khoản Nhân Viên',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF0F1F3),
                minimumSize: const Size(32, 32),
                maximumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF171A1F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: '  *',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSelector() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _selectDepartment,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9DDE3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF9AA1AA),
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedDepartment ?? 'Chọn khoa',
                  style: TextStyle(
                    color: _selectedDepartment == null
                        ? const Color(0xFF858B94)
                        : const Color(0xFF252A32),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9299A3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeader() {
    return Row(
      children: [
        Expanded(child: _buildSectionLabel('Chọn vai trò', required: true)),
        const Text(
          'Phân quyền ca\ntrực',
          textAlign: TextAlign.right,
          style: TextStyle(color: Color(0xFF9AA1AA), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildRoleCard(_StaffRole role) {
    final selected = _selectedRole == role;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF3FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _blue : const Color(0xFFD9DDE3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFD5E8FF)
                      : const Color(0xFFF0F1F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  role.icon,
                  color: selected
                      ? const Color(0xFF3388F5)
                      : const Color(0xFF7B838E),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.title,
                      style: const TextStyle(
                        color: Color(0xFF252A32),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: const TextStyle(
                        color: Color(0xFF858B94),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _blue : const Color(0xFFC6CBD2),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9DDE3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove,
            onPressed: _accountCount > 1 ? () => _changeCount(-1) : null,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_accountCount',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'tài khoản',
                  style: TextStyle(color: Color(0xFF858B94), fontSize: 9),
                ),
              ],
            ),
          ),
          _CounterButton(
            icon: Icons.add,
            onPressed: _accountCount < 99 ? () => _changeCount(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Row(
      children: [
        _PresetButton(label: '+1 acc', onTap: () => _changeCount(1)),
        const SizedBox(width: 7),
        _PresetButton(
          label: '+5 acc',
          selected: true,
          onTap: () => _changeCount(5),
        ),
        const SizedBox(width: 7),
        _PresetButton(label: '+10 acc', onTap: () => _changeCount(10)),
      ],
    );
  }

  Widget _buildPolicy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD0D5DD),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quy chuẩn cấp phát:',
            style: TextStyle(
              color: Color(0xFF252A32),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Mật khẩu khởi tạo chung cho tất cả tài khoản: ${StaffAccountStore.matKhauMacDinh}. Nhân viên đổi mật khẩu ở lần đăng nhập đầu tiên.',
            style: const TextStyle(
              color: Color(0xFF737B86),
              fontSize: 9.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StaffRole {
  receptionist(
    title: 'Lễ tân',
    description: 'Quét QR, tiếp nhận bệnh nhân',
    icon: Icons.people_alt_outlined,
  ),
  doctorAssistant(
    title: 'Hỗ trợ bác sĩ',
    description: 'Hồ sơ, điều phối khám',
    icon: Icons.person_outline_rounded,
  ),
  customerSupport(
    title: 'Support',
    description: 'Đặt lịch hẹn, hỗ trợ bệnh nhân',
    icon: Icons.support_agent_rounded,
  );

  const _StaffRole({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: double.infinity,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: const Color(0xFF606873),
        disabledColor: const Color(0xFFC6CBD2),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 31,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                selected ? const Color(0xFF2679EE) : const Color(0xFF656D78),
            backgroundColor:
                selected ? const Color(0xFFEAF3FF) : Colors.white,
            side: BorderSide(
              color: selected ? _CapTaiKhoanNhanVienScreenState._blue : const Color(0xFFD9DDE3),
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
