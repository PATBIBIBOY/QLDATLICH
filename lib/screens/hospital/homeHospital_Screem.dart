import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/benhVien_service.dart';
import 'guiDonThanhCong_Screen.dart';
import 'guiYeuCauHopTac_Screen.dart';
import 'listKhoaDieuTri.dart';
import 'nhanSu_Screen.dart';

/// 1240 -> "1,240"
String _soCoDauPhay(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// "Bệnh Viện Đa Khoa An Bình" -> "AB"
String _chuVietTat(String ten) {
  final tu = ten.split(' ').where((e) => e.isNotEmpty).toList();
  if (tu.isEmpty) return 'AB';
  if (tu.length == 1) return tu[0].substring(0, 1).toUpperCase();
  return (tu.first[0] + tu.last[0]).toUpperCase();
}

class HomeHospitalScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeHospitalScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeHospitalScreen> createState() => _HomeHospitalScreenState();
}

class _HomeHospitalScreenState extends State<HomeHospitalScreen> {
  late int _currentBottomNavIndex;
  bool _dangGuiDon = false;

  @override
  void initState() {
    super.initState();
    _currentBottomNavIndex = widget.initialTabIndex;
  }

  String _getHospitalUid(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return auth.hospital?.uid ??
        FirebaseAuth.instance.currentUser?.uid ??
        AppSession.benhVienId;
  }

  // ignore: unused_element
  void _moModalGuiDon({
    required BuildContext context,
    required String hospitalUid,
    required String tenBenhVien,
    Map<String, dynamic>? currentData,
  }) {
    final giayPhepCtrl = TextEditingController(
      text: (currentData?['so_giay_phep'] ?? '').toString(),
    );
    final sdtCtrl = TextEditingController(
      text: (currentData?['so_dien_thoai_lh'] ??
              currentData?['so_dien_thoai'] ??
              '')
          .toString(),
    );
    String loaiHinh = (currentData?['loai_hinh'] ?? 'Bệnh viện đa khoa tư nhân')
        .toString();
    bool coBhyt = currentData?['co_bhyt'] ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Color(0xFF0284C7),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn Xác Nhận Hợp Tác',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gửi hồ sơ pháp lý đến Admin hệ thống',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Số giấy phép hoạt động khám chữa bệnh *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: giayPhepCtrl,
                    decoration: InputDecoration(
                      hintText: 'VD: 123/BYT-GPHĐ',
                      prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Số điện thoại đại diện liên hệ *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sdtCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'VD: 0912 345 678',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loại hình cơ sở y tế',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: loaiHinh,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Bệnh viện đa khoa tư nhân',
                        child: Text(
                          'Bệnh viện đa khoa tư nhân',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bệnh viện công lập',
                        child: Text(
                          'Bệnh viện công lập',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Phòng khám đa khoa quốc tế',
                        child: Text(
                          'Phòng khám đa khoa quốc tế',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => loaiHinh = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Có tiếp nhận khám Bảo hiểm Y tế (BHYT)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: coBhyt,
                    onChanged: (v) => setModalState(() => coBhyt = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _dangGuiDon
                          ? null
                          : () async {
                              final soGiayPhep = giayPhepCtrl.text.trim();
                              final sdt = sdtCtrl.text.trim();
                              if (soGiayPhep.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng nhập số giấy phép hoạt động',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => _dangGuiDon = true);
                              try {
                                final dataToSave = {
                                  'so_giay_phep': soGiayPhep,
                                  'so_dien_thoai_lh': sdt,
                                  'loai_hinh': loaiHinh,
                                  'co_bhyt': coBhyt,
                                  'da_gui_don': true,
                                  'ngay_gui_don': FieldValue.serverTimestamp(),
                                  'trang_thai_hop_tac_id': TrangThaiId.choDuyet,
                                };

                                // 1. Lưu trực tiếp vào doc BenhVien/{uid}
                                await FirebaseFirestore.instance
                                    .collection('BenhVien')
                                    .doc(hospitalUid)
                                    .set(
                                      dataToSave,
                                      SetOptions(merge: true),
                                    );

                                // 2. Lưu vào collection YeuCauHopTac để Admin truy vấn danh sách duyệt
                                await FirebaseFirestore.instance
                                    .collection('YeuCauHopTac')
                                    .doc(hospitalUid)
                                    .set({
                                      'benh_vien_id': hospitalUid,
                                      'ten_benh_vien': tenBenhVien,
                                      ...dataToSave,
                                    }, SetOptions(merge: true));

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã lưu hồ sơ lên Firebase và gửi đến Admin thành công!',
                                    ),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => _dangGuiDon = false);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi gửi hồ sơ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _dangGuiDon
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Xác Nhận Gửi Hồ Sơ Lên Hệ Thống',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _thongBaoChuaKichHoat(String chucNang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chức năng "$chucNang" sẽ được mở sau khi Admin phê duyệt đơn hợp tác.',
        ),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalUid = _getHospitalUid(context);

    // Lắng nghe dữ liệu realtime từ Firestore của đúng tài khoản bệnh viện này
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('BenhVien')
          .doc(hospitalUid)
          .snapshots(),
      builder: (context, snapshot) {
        final authProvider = context.watch<AuthProvider>();
        final data = snapshot.data?.data();

        // Tên bệnh viện động từ Firestore / AuthProvider / fallback
        final tenBenhVien = data?['ten_benh_vien'] ??
            data?['tenBenhVien'] ??
            authProvider.hospital?.tenBenhVien ??
            'BV Đa Khoa An Bình';

        // Trạng thái hợp tác: 1 = Chờ duyệt, 2 = Đã xác nhận, 7 = Hoạt động
        final trangThaiId = (data?['trang_thai_hop_tac_id'] ??
                authProvider.hospital?.trangThaiHopTacId ??
                TrangThaiId.choDuyet) as int;

        // Bệnh viện đã gửi đơn hay chưa
        final bool daGuiDon = (data?['da_gui_don'] == true) ||
            (data?['so_giay_phep'] != null &&
                data!['so_giay_phep'].toString().isNotEmpty);

        // Đã được Admin phê duyệt hợp tác hay chưa
        final bool daXacThuc = trangThaiId == TrangThaiId.daXacNhan ||
            trangThaiId == TrangThaiId.hoatDong;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    // Header chuẩn theo tài khoản đang đăng nhập
                    _buildHeader(
                      hospitalUid: hospitalUid,
                      tenBenhVien: tenBenhVien,
                      daGuiDon: daGuiDon,
                      daXacThuc: daXacThuc,
                    ),

                    // Body: Nếu đã xác thực -> Hiện theo Tab được chọn; Nếu chưa -> Hiện màn hình Chào mừng & Gửi đơn
                    Expanded(
                      child: daXacThuc
                          ? _buildBodyForCurrentTab(hospitalUid: hospitalUid)
                          : _buildUnverifiedBody(
                              hospitalUid: hospitalUid,
                              tenBenhVien: tenBenhVien,
                              daGuiDon: daGuiDon,
                              data: data,
                            ),
                    ),

                    // Thanh điều hướng 4 nút
                    _buildBottomNav(daXacThuc: daXacThuc),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== GIAO DIỆN KHI CHƯA GỬI ĐƠN / CHỜ ADMIN DUYỆT ====================
  Widget _buildUnverifiedBody({
    required String hospitalUid,
    required String tenBenhVien,
    required bool daGuiDon,
    Map<String, dynamic>? data,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 36),

          // Icon tài liệu y tế
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Color(0xFF0284C7),
                ),
                Positioned(
                  right: 25,
                  bottom: 25,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F9FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tiêu đề chào mừng
          const Text(
            'Chào mừng Bệnh viện mới!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Dòng mô tả
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Trang chủ chưa có dữ liệu. Bệnh viện cần gửi\nđơn xác nhận hợp tác để kích hoạt các tính năng\nquản lý khoa và phân luồng tiếp đón.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Card Quy trình 3 bước kích hoạt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quy trình 3 bước kích hoạt:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepRow(
                  stepNumber: '1',
                  title: 'Điền thông tin pháp lý & loại hình cơ sở',
                  isActive: true,
                  isDone: daGuiDon,
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  stepNumber: '2',
                  title: 'Admin đối soát giấy phép & phê duyệt',
                  isActive: daGuiDon,
                  isDone: false,
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  stepNumber: '3',
                  title: 'Kích hoạt tạo khoa, phân luồng & cấp tài khoản',
                  isActive: false,
                  isDone: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Nút Gửi đơn xác nhận hợp tác
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (daGuiDon) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuiDonThanhCongScreen(
                        maHoSo: (data?['ma_ho_so'] ?? '#HS-BV-202688').toString(),
                        tenBenhVien: tenBenhVien,
                        loaiHinh: (data?['loai_hinh'] ?? 'Bệnh viện Tư lập').toString(),
                        coBhyt: data?['co_bhyt'] ?? true,
                        hospitalUid: hospitalUid,
                        extraData: data,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuiYeuCauHopTacScreen(
                        initialTenBenhVien: tenBenhVien,
                        initialDiaChi: data?['dia_chi']?.toString(),
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                daGuiDon
                    ? Icons.hourglass_top_rounded
                    : Icons.assignment_outlined,
                size: 20,
              ),
              label: Text(
                daGuiDon
                    ? 'Đã Gửi Đơn - Chờ Admin Phê Duyệt'
                    : 'Gửi Đơn Xác Nhận Hợp Tác',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: daGuiDon
                    ? const Color(0xFFD97706)
                    : const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== GIAO DIỆN THEO TAB ====================
  Widget _buildBodyForCurrentTab({required String hospitalUid}) {
    switch (_currentBottomNavIndex) {
      case 1:
        // Tab "Khoa khám": Hiển thị tất cả các khoa khám hiện có
        return const TatCaKhoaTab();
      case 2:
        // Tab "Nhân sự": Danh sách nhân sự & nút Cấp tài khoản
        return const NhanSuScreen();
      case 3:
        // Tab "Cài đặt": Thông tin & Đăng xuất
        return _buildSettingsTab(hospitalUid: hospitalUid);
      case 0:
      default:
        // Tab "Trang chủ"
        return _buildVerifiedDashboard(hospitalUid: hospitalUid);
    }
  }

  Widget _buildSettingsTab({required String hospitalUid}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt tài khoản Bệnh viện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.business_rounded, color: Color(0xFF0284C7)),
                  title: const Text('Thông tin cơ sở y tế'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang hoàn thiện.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7)),
                  title: const Text('Đổi mật khẩu & Bảo mật'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang hoàn thiện.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GIAO DIỆN KHI ĐÃ ĐƯỢC ADMIN DUYỆT ====================
  Widget _buildVerifiedDashboard({required String hospitalUid}) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Expanded(child: TongSoKhoaCard()),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: BenhVienService.thongKeHomNay(hospitalUid),
                  builder: (context, snap) {
                    final d = snap.data?.data();
                    final tong = ((d?['tongBenhNhan'] ?? 0) as num).toInt();
                    final dang = ((d?['dangKham'] ?? 0) as num).toInt();
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1D89D1), Color(0xFF1E79C2)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bệnh nhân hôm nay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _soCoDauPhay(tong),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đang khám: $dang lượt',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                AppSession.benhVienId = hospitalUid;
                Navigator.pushNamed(context, AppRoutes.addClinic);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Thêm Khoa Khám Mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E87D8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListKhoaDieuTri(
            onXemTatCa: () => setState(() => _currentBottomNavIndex = 1),
          ),
        ),
      ],
    );
  }

  // Header hiển thị tên Bệnh viện và huy hiệu xác thực
  Widget _buildHeader({
    required String hospitalUid,
    required String tenBenhVien,
    required bool daGuiDon,
    required bool daXacThuc,
  }) {
    String badgeText = 'Chưa xác thực';
    Color badgeBg = const Color(0xFFFFFBEB);
    Color badgeTextColor = const Color(0xFFD97706);
    Color badgeBorder = const Color(0xFFFDE68A);

    if (daXacThuc) {
      badgeText = 'Đã hợp tác';
      badgeBg = const Color(0xFFECFDF5);
      badgeTextColor = const Color(0xFF059669);
      badgeBorder = const Color(0xFFA7F3D0);
    } else if (daGuiDon) {
      badgeText = 'Đang chờ duyệt';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      badgeBorder = const Color(0xFFFCD34D);
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _chuVietTat(tenBenhVien),
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenBenhVien,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeBorder, width: 0.8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nút DEV: Tự duyệt / Khóa lại để chuyển đổi màn hình làm các chức năng khác
          InkWell(
            onTap: () async {
              final newStatus = daXacThuc ? 1 : 2;
              await FirebaseFirestore.instance
                  .collection('BenhVien')
                  .doc(hospitalUid)
                  .set({
                'trang_thai_hop_tac_id': newStatus,
                'da_gui_don': true,
              }, SetOptions(merge: true));

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newStatus == 2
                        ? '⚡ [DEV] Đã tự duyệt: Chuyển sang Dashboard đầy đủ!'
                        : '⚡ [DEV] Đã chuyển về: Chờ Admin phê duyệt!',
                  ),
                  backgroundColor: newStatus == 2
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: daXacThuc
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: daXacThuc
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF86EFAC),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    daXacThuc
                        ? Icons.lock_open_rounded
                        : Icons.bolt_rounded,
                    size: 15,
                    color: daXacThuc
                        ? const Color(0xFF64748B)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    daXacThuc ? 'Khóa lại' : 'Tự duyệt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: daXacThuc
                          ? const Color(0xFF64748B)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF334155),
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không có thông báo mới.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required bool isActive,
    required bool isDone,
  }) {
    Color circleColor = const Color(0xFFE2E8F0);
    Widget circleChild = Text(
      stepNumber,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );

    if (isDone) {
      circleColor = const Color(0xFF16A34A);
      circleChild = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isActive) {
      circleColor = const Color(0xFF0284C7);
      circleChild = Text(
        stepNumber,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: circleChild,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: (isActive || isDone)
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF475569),
              fontWeight:
                  (isActive || isDone) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav({required bool daXacThuc}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Trang chủ',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.grid_view_rounded,
            activeIcon: Icons.grid_view_rounded,
            label: 'Khoa khám',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Khoa khám'),
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Nhân sự',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Nhân sự'),
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Cài đặt',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Cài đặt'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    VoidCallback? onTapBlocked,
  }) {
    final isSelected = _currentBottomNavIndex == index;
    final color =
        isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        if (onTapBlocked != null) {
          onTapBlocked();
          return;
        }
        setState(() => _currentBottomNavIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
