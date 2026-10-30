import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_profile_model_c1.dart';
import '../../services/letan_c1/letan_firebase_service_c1.dart';
import 'cskh_danhsach_don_khoa_screen_c1.dart';
import 'cskh_danhsach_tinnhan_screen_c1.dart';
import 'cskh_profile_tab_c1.dart';
import 'letan_baocaoloi_screen_c1.dart';
import 'letan_trangchu_screen_c1.dart';

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
  DateTime _ngayChon = DateTime.now();

  // Khoa đang chọn làm việc (mặc định lấy theo khoa của nhân viên trong profile hoặc 'Tất cả các khoa (Tổng)')
  late String _tenKhoaHienTai;
  String? _khoaIdHienTai;

  @override
  void initState() {
    super.initState();
    final khoaNv = DuLieuProfileMauC1.thongTinHienTai.khoa.trim();
    if (khoaNv.isNotEmpty &&
        !khoaNv.toLowerCase().contains('bộ phận') &&
        !khoaNv.toLowerCase().contains('cskh') &&
        !khoaNv.toLowerCase().contains('toàn viện')) {
      _tenKhoaHienTai = khoaNv;
    } else {
      _tenKhoaHienTai = 'Tất cả các khoa (Tổng)';
    }
  }

  // Mở BottomSheet cho phép đổi Chuyên khoa của Bệnh viện
  void _moModalChonKhoa() {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    final bvid = DuLieuProfileMauC1.thongTinHienTai.benhVienId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded, color: Color(0xFF0284C7), size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Chọn Khoa Duyệt Đơn',
                            style: TextStyle(
                              color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1C1C1E),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bệnh Viện',
                          style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Khoa được lấy tự động từ bệnh viện bạn đang làm việc',
                    style: TextStyle(
                      color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF8E8E93),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirebaseServiceC1.streamDanhSachKhoa(bvid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 2),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Đang tải danh sách khoa từ Firebase...',
                                    style: TextStyle(
                                      color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final danhSachKhoa = [
                          {
                            'id': 'ALL',
                            'tenKhoa': 'Tất cả các khoa (Tổng)',
                            'moTaPhong': 'Toàn viện • Duyệt đơn tất cả các khoa',
                            'laTong': true,
                          },
                          ...snapshot.data!,
                        ];

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: danhSachKhoa.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = danhSachKhoa[index];
                            final tenKhoa = (item['tenKhoa'] ?? 'Khoa Khám').toString();
                            final moTa = (item['moTaPhong'] ?? '').toString();
                            final laTong = item['laTong'] == true;
                            final isSelected = laTong
                                ? FirebaseServiceC1.laCheDoTong(_tenKhoaHienTai)
                                : FirebaseServiceC1.laCungKhoa(tenKhoa, _tenKhoaHienTai);

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _tenKhoaHienTai = tenKhoa;
                                  _khoaIdHienTai = laTong ? null : item['id']?.toString();
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã chọn khoa: $tenKhoa'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF0C2444) : const Color(0xFFF0F9FF))
                                      : (isDark ? AppDesignSystemC1.darkSurface : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : (isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0284C7)
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        laTong ? Icons.dashboard_rounded : Icons.local_hospital_rounded,
                                        size: 20,
                                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tenKhoa,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF0284C7)
                                                  : (isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1E293B)),
                                              fontSize: 14.5,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            ),
                                          ),
                                          if (moTa.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              moTa,
                                              style: TextStyle(
                                                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _chonNgay() async {
    AppDesignSystemC1.hapticLight();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayChon,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN NGÀY THỐNG KÊ',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked != null && picked != _ngayChon) {
      setState(() {
        _ngayChon = picked;
      });
    }
  }

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

  // Mở màn hình duyệt đơn cho một phòng khám cụ thể
  void _onSelectPhong(Map<String, dynamic> phong, String tenKhoa) {
    AppDesignSystemC1.hapticLight();
    final tenPhong = (phong['tenPhong'] ?? phong['soPhong'] ?? 'Phòng Khám').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CskhDanhsachDonKhoaScreenC1(
          tenKhoa: tenKhoa,
          phongKham: tenPhong,
          caKham: 'Tất cả các ca',
          tongDon: 0,
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

  // Popup thông báo CSKH kết nối Realtime Firestore /ThongBaoHeThong
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
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirebaseServiceC1.streamThongBaoRealtime(vaiTro: 'cskh'),
              builder: (context, snapshot) {
                final dsThongBaoRaw = snapshot.data ?? [];
                final soLuongChuaDoc = dsThongBaoRaw.where((e) => e['da_doc'] != true).length;
                final danhSachHienThi = tabLocHienTai == 'chua_doc'
                    ? dsThongBaoRaw.where((e) => e['da_doc'] != true).toList()
                    : dsThongBaoRaw;

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
                                      'Tất cả (${dsThongBaoRaw.length})',
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
                        child: danhSachHienThi.isEmpty
                            ? Center(
                                child: Text(
                                  'Không có thông báo nào',
                                  style: TextStyle(
                                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: danhSachHienThi.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = danhSachHienThi[index];
                                  final tieuDe = (item['tieu_de'] ?? item['tieuDe'] ?? 'Thông báo').toString();
                                  final noiDung = (item['noi_dung'] ?? item['noiDung'] ?? '').toString();
                                  final thoiGian = (item['thoi_gian_hien_thi'] ?? item['thoiGian'] ?? 'Vừa xong').toString();
                                  final daDoc = item['da_doc'] == true;

                                  return InkWell(
                                    onTap: () {
                                      if (item['id'] != null) {
                                        FirebaseServiceC1.danhDauDaDocThongBao(item['id'].toString());
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
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
                                              Expanded(
                                                child: Text(
                                                  tieuDe,
                                                  style: TextStyle(
                                                    color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if (!daDoc)
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
                                            noiDung,
                                            style: TextStyle(
                                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            thoiGian,
                                            style: TextStyle(
                                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return PopScope(
          canPop: _currentBottomNavIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // Nếu đang ở tab khác (Duyệt đơn, CSKH, Profile), bấm back sẽ quay về Trang chủ tab 0 mượt mà
            if (_currentBottomNavIndex != 0) {
              setState(() {
                _currentBottomNavIndex = 0;
              });
            }
          },
          child: Scaffold(
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
          ),
        );
      },
    );
  }

  // Nội dung body hiển thị tùy theo tab Bottom Navigation Bar
  Widget _buildBodyContent(bool isDark) {
    // Tab 1: Duyệt đơn (Hiển thị trang chọn khoa, chọn ngày và danh sách phòng để vào duyệt)
    if (_currentBottomNavIndex == 1) {
      return _buildTabDuyetDonTheoPhong(isDark);
    }

    // Tab 2: CSKH (Tin nhắn hỗ trợ bệnh nhân)
    if (_currentBottomNavIndex == 2) {
      return const CskhDanhsachTinnhanScreenC1();
    }

    // Tab 3: Profile CSKH
    if (_currentBottomNavIndex == 3) {
      return CskhProfileTabC1(
        onChuyenSangLeTan: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LeTanHomeScreenC1()),
            );
          }
        },
        onDangXuat: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        },
      );
    }

    // Mặc định: Giao diện Trang chủ & Duyệt đơn CSKH
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector chọn Khoa làm việc ở trên cùng (Lấy từ Bệnh viện nhân viên)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'KHOA HIỆN TẠI',
                            style: TextStyle(
                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Bệnh viện',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tenKhoaHienTai,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _moModalChonKhoa,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Đổi Khoa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Danh sách Phòng khám của Khoa đang chọn (ListView ngang / dạng thẻ cuộn)
          _buildDanhSachPhongCuaKhoa(isDark),
          const SizedBox(height: 16),

          // Banner lớn duyệt đơn hôm nay (Gradient xanh dương y tế)
          _buildBannerTongDon(),
          const SizedBox(height: 18),

          // Khối thống kê nhanh tình trạng đơn khám
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THỐNG KÊ LỊCH DUYỆT',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              InkWell(
                onTap: _chonNgay,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 5),
                      Text(
                        '${_ngayChon.day.toString().padLeft(2, '0')}/${_ngayChon.month.toString().padLeft(2, '0')}/${_ngayChon.year}',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          // Danh sách chuyên khoa (Lấy Realtime từ Firebase Firestore)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseServiceC1.streamDanhSachKhoa(DuLieuProfileMauC1.thongTinHienTai.benhVienId),
            builder: (context, snapshot) {
              // Trong lúc đang tải từ Firebase: Hiển thị hiệu ứng tải nhẹ, KHÔNG hiển thị danh sách mock cũ
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Đang tải danh sách khoa...',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Chưa có chuyên khoa nào được mở.',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              // Khi Firebase trả về danh sách khoa thật (như KHOA TIM phòng 110 trong database của bạn)
              final docs = snapshot.data!;

              // Thêm thẻ "Tất cả các khoa (Tổng)" lên đầu để CSKH duyệt toàn viện
              final cardTong = KhoaKhamModelC1(
                tenKhoa: 'Tất cả các khoa (Tổng)',
                moTaPhong: 'Toàn viện • Xem và duyệt đơn tất cả các khoa',
                soLuongDon: 'Toàn viện',
                icon: Icons.dashboard_customize_rounded,
                laKhoaDangChon: false,
                laDayDon: false,
              );

              final List<Widget> danhSachCards = [
                _buildCardKhoa(cardTong, isDark),
              ];

              danhSachCards.addAll(docs.map((item) {
                final tenKhoa = item['tenKhoa'] ?? 'Khoa Khám';
                final moTaPhong = item['moTaPhong'] ?? 'Phòng ${item['phongDau']}';
                final bool laKhoaDangMo = item['trangThai'] == 'dang_mo';

                // Tự động gán Icon phù hợp theo tên khoa
                IconData iconKhoa = Icons.local_hospital_outlined;
                final lower = tenKhoa.toString().toLowerCase();
                if (lower.contains('tim')) {
                  iconKhoa = Icons.favorite_border_rounded;
                } else if (lower.contains('nhi')) {
                  iconKhoa = Icons.child_care_rounded;
                } else if (lower.contains('răng') || lower.contains('rang')) {
                  iconKhoa = Icons.sentiment_satisfied_alt_rounded;
                } else if (lower.contains('mắt') || lower.contains('mat')) {
                  iconKhoa = Icons.remove_red_eye_outlined;
                }

                final khoaItem = KhoaKhamModelC1(
                  tenKhoa: tenKhoa,
                  moTaPhong: moTaPhong,
                  soLuongDon: 'Chi tiết',
                  icon: iconKhoa,
                  laKhoaDangChon: lower.contains('tim'),
                  laDayDon: !laKhoaDangMo,
                );

                return _buildCardKhoa(khoaItem, isDark);
              }));

              return Column(children: danhSachCards);
            },
          ),
          const SizedBox(height: 10),

          // Nút Báo cáo lỗi hệ thống
          _buildNutBaoCaoLoi(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Giao diện Tab 1: Duyệt đơn (Chọn khoa hiện tại/đã chọn, chọn ngày, và danh sách phòng khám)
  Widget _buildTabDuyetDonTheoPhong(bool isDark) {
    final bvid = DuLieuProfileMauC1.thongTinHienTai.benhVienId;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector chọn Khoa làm việc ở trên cùng (Mặc định là khoa đã chọn trước đó)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.4 : 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'KHOA ĐANG CHỌN',
                            style: TextStyle(
                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Đang làm việc',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tenKhoaHienTai,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _moModalChonKhoa,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Đổi Khoa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Thanh chọn Ngày duyệt đơn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NGÀY DUYỆT ĐƠN',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              InkWell(
                onTap: _chonNgay,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        '${_ngayChon.day.toString().padLeft(2, '0')}/${_ngayChon.month.toString().padLeft(2, '0')}/${_ngayChon.year}',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF0284C7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Tiêu đề danh sách phòng khám & Nút vào duyệt toàn viện
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DANH SÁCH PHÒNG KHÁM',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CskhDanhsachDonKhoaScreenC1(
                        tenKhoa: _tenKhoaHienTai,
                        phongKham: 'Toàn khoa',
                        caKham: 'Tất cả các ca',
                        tongDon: 0,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Duyệt toàn bộ khoa',
                    style: TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Danh sách các phòng khám dạng lưới / thẻ để ấn vào phòng thì duyệt đúng phòng đó
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseServiceC1.streamDanhSachKhoa(bvid),
            builder: (context, snapKhoa) {
              final dsKhoa = snapKhoa.data ?? [];
              Map<String, dynamic>? khoaDoc;
              for (var k in dsKhoa) {
                if (FirebaseServiceC1.laCungKhoa(k['tenKhoa']?.toString(), _tenKhoaHienTai)) {
                  khoaDoc = k;
                  break;
                }
              }

              final khoaId = _khoaIdHienTai ?? khoaDoc?['id']?.toString() ?? 'KHOA_MAC_DINH';
              final int soPhongKhoa = (khoaDoc?['soPhong'] as num?)?.toInt() ?? 1;
              final String phongDau = khoaDoc?['phongDau']?.toString() ?? '101';

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseServiceC1.streamDanhSachPhongTheoKhoa(
                  benhVienId: bvid,
                  khoaId: khoaId,
                  tenKhoa: _tenKhoaHienTai,
                  soPhongMacDinh: soPhongKhoa,
                  phongDau: phongDau,
                ),
                builder: (context, snapPhong) {
                  final dsPhong = snapPhong.data ?? [];

                  if (snapPhong.connectionState == ConnectionState.waiting && !snapPhong.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  if (dsPhong.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 40,
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khoa "$_tenKhoaHienTai" chưa có phòng khám nào.',
                            style: TextStyle(
                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dsPhong.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final phong = dsPhong[index];
                      final tenPhong = (phong['tenPhong'] ?? phong['soPhong'] ?? 'Phòng').toString();
                      final soPhong = (phong['soPhong'] ?? '').toString();
                      final bacSi = (phong['bacSi'] ?? 'BS. Trực ban').toString();
                      final trangThai = (phong['trangThai'] ?? 'san_sang').toString();
                      final bool isSanSang = trangThai == 'san_sang' || trangThai == 'dang_kham';

                      return InkWell(
                        onTap: () => _onSelectPhong(phong, _tenKhoaHienTai),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.door_sliding_outlined,
                                    color: const Color(0xFF0284C7),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          tenPhong,
                                          style: TextStyle(
                                            color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (soPhong.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'P.$soPhong',
                                              style: TextStyle(
                                                color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 13,
                                          color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            bacSi,
                                            style: TextStyle(
                                              color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSanSang
                                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                                          : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isSanSang ? 'Sẵn sàng' : 'Tạm đóng',
                                      style: TextStyle(
                                        color: isSanSang ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Duyệt đơn',
                                        style: TextStyle(
                                          color: Color(0xFF0284C7),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget hiển thị danh sách phòng khám của khoa đang chọn
  Widget _buildDanhSachPhongCuaKhoa(bool isDark) {
    final bvid = DuLieuProfileMauC1.thongTinHienTai.benhVienId;
    final laTong = FirebaseServiceC1.laCheDoTong(_tenKhoaHienTai);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseServiceC1.streamDanhSachKhoa(bvid),
      builder: (context, snapKhoa) {
        final dsKhoa = snapKhoa.data ?? [];
        Map<String, dynamic>? khoaDoc;
        for (var k in dsKhoa) {
          if (FirebaseServiceC1.laCungKhoa(k['tenKhoa']?.toString(), _tenKhoaHienTai)) {
            khoaDoc = k;
            break;
          }
        }

        final khoaId = _khoaIdHienTai ?? khoaDoc?['id']?.toString() ?? 'KHOA_MAC_DINH';
        final int soPhongKhoa = (khoaDoc?['soPhong'] as num?)?.toInt() ?? 1;
        final String phongDau = khoaDoc?['phongDau']?.toString() ?? '101';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseServiceC1.streamDanhSachPhongTheoKhoa(
            benhVienId: bvid,
            khoaId: khoaId,
            tenKhoa: _tenKhoaHienTai,
            soPhongMacDinh: soPhongKhoa,
            phongDau: phongDau,
          ),
          builder: (context, snapPhong) {
            final dsPhong = snapPhong.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 18,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          laTong ? 'PHÒNG KHÁM TIÊU BIỂU' : 'PHÒNG KHÁM THUỘC KHOA',
                          style: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF475569),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${dsPhong.length} phòng',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (dsPhong.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Khoa chưa có phòng khám nào được tạo.',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dsPhong.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final phong = dsPhong[index];
                        final tenPhong = (phong['tenPhong'] ?? phong['soPhong'] ?? 'Phòng').toString();
                        final soPhong = (phong['soPhong'] ?? '').toString();
                        final bacSi = (phong['bacSi'] ?? 'BS. Trực ban').toString();
                        final trangThai = (phong['trangThai'] ?? 'san_sang').toString();
                        final bool isSanSang = trangThai == 'san_sang' || trangThai == 'dang_kham';

                        return InkWell(
                          onTap: () => _onSelectPhong(phong, _tenKhoaHienTai),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 175,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        soPhong.isNotEmpty ? 'P.$soPhong' : 'Phòng',
                                        style: const TextStyle(
                                          color: Color(0xFF0284C7),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isSanSang ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenPhong,
                                      style: TextStyle(
                                        color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      bacSi,
                                      style: TextStyle(
                                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      'Ấn để duyệt',
                                      style: TextStyle(
                                        color: Color(0xFF0284C7),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
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
                    Expanded(
                      child: Text(
                        DuLieuProfileMauC1.thongTinHienTai.tenBenhVien.isNotEmpty
                            ? DuLieuProfileMauC1.thongTinHienTai.tenBenhVien
                            : 'Bệnh viện BV502',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Xin chào, Chuyên viên CSKH',
                  style: TextStyle(
                    color: subTextCol,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
    final bvid = DuLieuProfileMauC1.thongTinHienTai.benhVienId;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseServiceC1.streamDanhSachKhoa(bvid),
      builder: (context, snapshot) {
        final soLuongKhoa = snapshot.hasData ? snapshot.data!.length : 0;

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
                    'Theo thời gian thực',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                child: Text(
                  '$soLuongKhoa Chuyên khoa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Khối thống kê hôm nay (Đọc Realtime từ Firestore Firebase)
  Widget _buildThongKeNhanh(bool isDark) {
    final bvid = DuLieuProfileMauC1.thongTinHienTai.benhVienId;
    return StreamBuilder<Map<String, int>>(
      stream: FirebaseServiceC1.streamThongKeHomNay(
        tenKhoa: _tenKhoaHienTai,
        ngayChon: _ngayChon,
        benhVienId: bvid,
      ),
      builder: (context, snapshot) {
        final thongKe = snapshot.data ?? {
          'daTiepNhan': 0,
          'dangCho': 0,
          'daKham': 0,
          'tongSo': 0,
        };

        final dangCho = thongKe['dangCho'] ?? 0;
        final daDuyet = thongKe['daTiepNhan'] ?? 0;
        final tongSo = thongKe['tongSo'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildItemThongKe(
                soLuong: '$dangCho',
                nhanDe: 'Đang chờ',
                mauSo: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '$daDuyet',
                nhanDe: 'Đã phê duyệt',
                mauSo: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildItemThongKe(
                soLuong: '$tongSo',
                nhanDe: 'Tổng đơn hôm nay',
                mauSo: const Color(0xFF0284C7),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
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
