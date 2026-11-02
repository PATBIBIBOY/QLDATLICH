import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../department_room_picker.dart';

class DoctorInitialSetupScreen extends StatefulWidget {
  final String maNhanVienMacDinh;

  const DoctorInitialSetupScreen({super.key, this.maNhanVienMacDinh = 'HTBS_01'});

  @override
  State<DoctorInitialSetupScreen> createState() => _DoctorInitialSetupScreenState();
}

class _DoctorInitialSetupScreenState extends State<DoctorInitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maNvCtrl;
  final _hoTenCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matKhauCtrl = TextEditingController();

  bool _anMatKhau = true;
  bool _dangXuLy = false;

  @override
  void initState() {
    super.initState();
    _maNvCtrl = TextEditingController(text: widget.maNhanVienMacDinh);
  }

  @override
  void dispose() {
    _maNvCtrl.dispose();
    _hoTenCtrl.dispose();
    _emailCtrl.dispose();
    _matKhauCtrl.dispose();
    super.dispose();
  }

  Future<void> _xacNhan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _dangXuLy = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final maNv = _maNvCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final hoTen = _hoTenCtrl.text.trim();
      final matKhau = _matKhauCtrl.text.trim();

      final snap = await firestore
          .collectionGroup('danh_sach')
          .where('ma_tai_khoan', isEqualTo: maNv)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({
          'email': email,
          'ho_ten': hoTen,
          'mat_khau': matKhau,
          'da_kich_hoat': true,
          'ngay_cap_nhat': FieldValue.serverTimestamp(),
        });
      } else {
        await firestore
            .collection('NhanVien')
            .doc('BV502')
            .collection('danh_sach')
            .doc(maNv)
            .set({
          'ma_tai_khoan': maNv,
          'email': email,
          'ho_ten': hoTen,
          'mat_khau': matKhau,
          'da_kich_hoat': true,
          'role': 'doctorAssistant',
          'chuc_vu': 'Hỗ trợ bác sĩ',
          'ngay_tao': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() => _dangXuLy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Thiết lập thông tin thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClinicRoomPickerScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _dangXuLy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Thiết Lập Tài Khoản Mới', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lần đầu đăng nhập: Vui lòng nhập họ tên, liên kết Gmail và tạo mật khẩu mới an toàn.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _maNvCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Mã nhân viên',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoTenCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                decoration: InputDecoration(
                  labelText: 'Họ và tên bác sĩ / trợ lý',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                validator: (v) => (v == null || !v.contains('@')) ? 'Vui lòng nhập đúng Gmail' : null,
                decoration: InputDecoration(
                  labelText: 'Gmail liên kết chính thức',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matKhauCtrl,
                obscureText: _anMatKhau,
                validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu ít nhất 6 ký tự' : null,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _dangXuLy ? null : _xacNhan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _dangXuLy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('XÁC NHẬN & BẮT ĐẦU CA TRỰC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
