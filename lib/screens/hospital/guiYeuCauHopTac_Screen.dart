import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import '../../providers/auth_provider.dart';
import 'guiDonThanhCong_Screen.dart';

class GuiYeuCauHopTacScreen extends StatefulWidget {
  final String? initialTenBenhVien;
  final String? initialDiaChi;

  const GuiYeuCauHopTacScreen({
    super.key,
    this.initialTenBenhVien,
    this.initialDiaChi,
  });

  @override
  State<GuiYeuCauHopTacScreen> createState() => _GuiYeuCauHopTacScreenState();
}

class _GuiYeuCauHopTacScreenState extends State<GuiYeuCauHopTacScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenBenhVienCtrl;
  late final TextEditingController _maCoSoCtrl;
  late final TextEditingController _maSoThueCtrl;
  late final TextEditingController _diaChiCtrl;

  String _loaiHinh = 'Bệnh viện Tư lập';
  bool _coBhyt = true;
  String _tenFileDinhKem = 'giay_phep_byt.pdf';
  String _dungLuongFile = '2.4 MB • Đã tải lên';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tenBv = widget.initialTenBenhVien ??
        auth.hospital?.tenBenhVien ??
        'Bệnh viện Đa Khoa An Bình';
    final diaChi = widget.initialDiaChi ??
        auth.hospital?.diaChi ??
        '146 An Bình, Phường 7, Quận 5, TP.HCM';

    _tenBenhVienCtrl = TextEditingController(text: tenBv);
    _maCoSoCtrl = TextEditingController(text: 'BV-79-102');
    _maSoThueCtrl = TextEditingController(text: '0312891201');
    _diaChiCtrl = TextEditingController(text: diaChi);
  }

  @override
  void dispose() {
    _tenBenhVienCtrl.dispose();
    _maCoSoCtrl.dispose();
    _maSoThueCtrl.dispose();
    _diaChiCtrl.dispose();
    super.dispose();
  }

  String _getHospitalUid() {
    final auth = context.read<AuthProvider>();
    return FirebaseAuth.instance.currentUser?.uid ??
        auth.hospital?.uid ??
        AppSession.benhVienId;
  }

  void _doiFileDinhKem() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn tệp giấy phép hoạt động y tế',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFE11D48)),
              title: const Text('giay_phep_kinh_doanh_byt_2026.pdf'),
              subtitle: const Text('3.1 MB'),
              onTap: () {
                setState(() {
                  _tenFileDinhKem = 'giay_phep_kinh_doanh_byt_2026.pdf';
                  _dungLuongFile = '3.1 MB • Đã tải lên';
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF0284C7)),
              title: const Text('chung_chi_hanh_nghe_coso.pdf'),
              subtitle: const Text('1.8 MB'),
              onTap: () {
                setState(() {
                  _tenFileDinhKem = 'chung_chi_hanh_nghe_coso.pdf';
                  _dungLuongFile = '1.8 MB • Đã tải lên';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guiYeuCau() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final hospitalUid = _getHospitalUid();
      final randSuffix = Random().nextInt(900) + 100;
      final maHoSo = '#HS-BV-2026$randSuffix';

      final dataToSave = {
        'uid': hospitalUid,
        'benh_vien_id': hospitalUid,
        'ten_benh_vien': _tenBenhVienCtrl.text.trim(),
        'ma_co_so_byt': _maCoSoCtrl.text.trim(),
        'so_giay_phep': _maCoSoCtrl.text.trim(),
        'ma_so_thue': _maSoThueCtrl.text.trim(),
        'dia_chi': _diaChiCtrl.text.trim(),
        'loai_hinh': _loaiHinh,
        'co_bhyt': _coBhyt,
        'file_giay_phep': _tenFileDinhKem,
        'ma_ho_so': maHoSo,
        'da_gui_don': true,
        'trang_thai_hop_tac_id': 1, // 1: Chờ duyệt
        'ngay_gui_don': FieldValue.serverTimestamp(),
        'thoi_gian_gui_str': DateTime.now().toIso8601String(),
      };

      // 1. Lưu trực tiếp vào doc BenhVien/{uid}
      await FirebaseFirestore.instance
          .collection('BenhVien')
          .doc(hospitalUid)
          .set(dataToSave, SetOptions(merge: true));

      // 2. Lưu vào collection YeuCauHopTac để Admin quản lý phê duyệt
      try {
        await FirebaseFirestore.instance
            .collection('YeuCauHopTac')
            .doc(hospitalUid)
            .set(dataToSave, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Lưu YeuCauHopTac: $e');
      }

      // Cập nhật AppSession
      AppSession.benhVienId = hospitalUid;

      if (!mounted) return;

      // 3. Chuyển sang màn hình Đã Gửi Đơn Thành Công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GuiDonThanhCongScreen(
            maHoSo: maHoSo,
            tenBenhVien: _tenBenhVienCtrl.text.trim(),
            loaiHinh: _loaiHinh,
            coBhyt: _coBhyt,
            hospitalUid: hospitalUid,
            extraData: dataToSave,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi hồ sơ lên hệ thống: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        title: const Text(
          'Gửi Yêu Cầu Hợp Tác',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tên bệnh viện
                          _buildLabelWithRequired('Tên bệnh viện'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tenBenhVienCtrl,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Nhập tên bệnh viện',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập tên bệnh viện';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 2. Mã cơ sở (BYT) & Mã số thuế
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabelWithRequired('Mã cơ sở (BYT)'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _maCoSoCtrl,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: _inputDecoration(
                                        hintText: 'BV-79-102',
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Nhập mã BYT';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Mã số thuế'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _maSoThueCtrl,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: _inputDecoration(
                                        hintText: '0312891201',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Địa chỉ trụ sở
                          _buildLabelWithRequired('Địa chỉ trụ sở'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _diaChiCtrl,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _inputDecoration(
                              hintText: 'Số nhà, đường, phường, quận, tỉnh/thành',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập địa chỉ trụ sở';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // 4. Loại hình bệnh viện (Tiêu chí duyệt Admin)
                          _buildSectionHeaderWithNote(
                            title: 'Loại hình bệnh viện',
                            note: '(Tiêu chí duyệt Admin)',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Bệnh viện Công lập',
                                  isSelected: _loaiHinh == 'Bệnh viện Công lập',
                                  onTap: () => setState(
                                    () => _loaiHinh = 'Bệnh viện Công lập',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Bệnh viện Tư lập',
                                  isSelected: _loaiHinh == 'Bệnh viện Tư lập',
                                  onTap: () => setState(
                                    () => _loaiHinh = 'Bệnh viện Tư lập',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 5. Khám chữa bệnh BHYT (Tiêu chí duyệt Admin)
                          _buildSectionHeaderWithNote(
                            title: 'Khám chữa bệnh BHYT',
                            note: '(Tiêu chí duyệt Admin)',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildBhytCard(
                                  title: 'Có BHYT',
                                  subtitle: 'Thông tuyến KCB',
                                  subtitleColor: const Color(0xFF16A34A),
                                  isSelected: _coBhyt == true,
                                  onTap: () => setState(() => _coBhyt = true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBhytCard(
                                  title: 'Không BHYT',
                                  subtitle: 'Dịch vụ 100%',
                                  subtitleColor: const Color(0xFF64748B),
                                  isSelected: _coBhyt == false,
                                  onTap: () => setState(() => _coBhyt = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 6. Giấy phép hoạt động y tế (Đính kèm)
                          _buildLabel('Giấy phép hoạt động y tế (Đính kèm)'),
                          const SizedBox(height: 8),
                          _buildAttachedFileCard(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Nút Gửi đơn xác nhận & Đăng ký
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _guiYeuCau,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.near_me_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Gửi Đơn Xác Nhận & Đăng Ký',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildLabelWithRequired(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithNote({
    required String title,
    required String note,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          note,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBhytCard({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedFileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 22,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenFileDinhKem,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dungLuongFile,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _doiFileDinhKem,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Đổi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
