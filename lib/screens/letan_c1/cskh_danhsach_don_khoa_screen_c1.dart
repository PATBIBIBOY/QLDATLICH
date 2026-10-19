import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_cskh_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../services/letan_c1/letan_firebase_service_c1.dart';

/// MÀN HÌNH 2: DANH SÁCH ĐƠN KHÁM CẦN DUYỆT (KHOA HOẶC TỔNG THỂ TOÀN VIỆN)
/// Kết nối thời gian thực với Firestore, hỗ trợ duyệt/từ chối lưu trực tiếp lên database.
class CskhDanhsachDonKhoaScreenC1 extends StatefulWidget {
  final String tenKhoa;
  final String phongKham;
  final String caKham;
  final int tongDon;

  const CskhDanhsachDonKhoaScreenC1({
    super.key,
    this.tenKhoa = 'Khoa Tim Mạch',
    this.phongKham = 'Phòng 201',
    this.caKham = 'Ca sáng',
    this.tongDon = 25,
  });

  @override
  State<CskhDanhsachDonKhoaScreenC1> createState() => _CskhDanhsachDonKhoaScreenC1State();
}

class _CskhDanhsachDonKhoaScreenC1State extends State<CskhDanhsachDonKhoaScreenC1> {
  DateTime _ngayChon = DateTime(2026, 10, 25);

  Future<void> _chonNgayLichHen() async {
    AppDesignSystemC1.hapticLight();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayChon,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'CHỌN NGÀY DUYỆT ĐƠN KHÁM',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked != null && picked != _ngayChon) {
      setState(() {
        _ngayChon = picked;
      });
    }
  }

  // Duyệt đơn và lưu trực tiếp lên Firestore
  void _duyetDon(Map<String, dynamic> don) async {
    AppDesignSystemC1.hapticLight();
    final appointmentId = don['id'];
    final docPath = don['docPath'];
    if (appointmentId != null) {
      await FirebaseServiceC1.capNhatTrangThaiLichHen(
        appointmentId: appointmentId,
        docPath: docPath,
        trangThaiMoi: 'da_duyet',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Đã duyệt đơn của ${don['hoTen']} (STT ${don['stt']})'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Mở Popup chọn lý do từ chối đơn khám (Figma 15.1) và lưu lên Firestore
  void _moPopupTuChoiDon(Map<String, dynamic> don) {
    AppDesignSystemC1.hapticLight();
    final isDark = AppDesignSystemC1.laCheDoToi;
    int lyDoDangChon = 0;
    final lyDoKhacController = TextEditingController();
    final cacLyDo = DuLieuCskhKhoaC1.danhSachLyDoTuChoi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 14,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppDesignSystemC1.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh kéo xám
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card tóm tắt bệnh nhân bị từ chối
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MÃ ĐẶT LỊCH: ${don['maBenhNhan'] ?? don['id']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (don['hoTen'] ?? 'Bệnh nhân').toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${don['tenKhoa']} • ${don['gioKham']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'STT',
                                  style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  (don['stt'] ?? '1').toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Lý do không duyệt đơn khám',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vui lòng chọn lý do từ chối để hệ thống gửi thông báo và hướng dẫn bệnh nhân chọn khung giờ hoặc khoa khác:',
                      style: TextStyle(
                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Danh sách lý do từ chối
                    ...List.generate(cacLyDo.length, (index) {
                      final isSelected = lyDoDangChon == index;
                      final lyDoText = cacLyDo[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setSheetState(() {
                              lyDoDangChon = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.6) : const Color(0xFFFEF2F2))
                                  : (isDark ? AppDesignSystemC1.darkSurface : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? const Color(0xFFEF4444) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(Icons.circle, color: Colors.white, size: 8),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lyDoText,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFDC2626)
                                          : (isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1E293B)),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    if (lyDoDangChon == 3) ...[
                      TextField(
                        controller: lyDoKhacController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Nhập chi tiết lý do từ chối gửi cho bệnh nhân...',
                          hintStyle: TextStyle(
                            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF94A3B8),
                            fontSize: 12.5,
                          ),
                          filled: true,
                          fillColor: isDark ? AppDesignSystemC1.darkSurface : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 8),

                    // Hai nút hành động: Hủy / Xác nhận từ chối
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppDesignSystemC1.darkSurface : const Color(0xFFF1F5F9),
                                foregroundColor: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF475569),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () async {
                                final lyDoChon = lyDoDangChon == 3 && lyDoKhacController.text.trim().isNotEmpty
                                    ? lyDoKhacController.text.trim()
                                    : cacLyDo[lyDoDangChon];

                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final appointmentId = don['id'];
                                final docPath = don['docPath'];
                                Navigator.pop(ctx);
                                if (appointmentId != null) {
                                  await FirebaseServiceC1.capNhatTrangThaiLichHen(
                                    appointmentId: appointmentId,
                                    docPath: docPath,
                                    trangThaiMoi: 'tu_choi',
                                    lyDoTuChoi: lyDoChon,
                                  );
                                }

                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('✕ Đã từ chối đơn của ${don['hoTen']}: $lyDoChon'),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Xác nhận từ chối', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
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
  }

  // Duyệt hết toàn bộ đơn đang chờ trên Firestore
  void _duyetHetTatCa(List<Map<String, dynamic>> danhSach) async {
    AppDesignSystemC1.hapticLight();
    for (var don in danhSach) {
      final trangThai = (don['rawTrangThai'] ?? '').toString();
      if (trangThai != 'da_duyet' && trangThai != 'da_kham') {
        final id = don['id'];
        final docPath = don['docPath'];
        if (id != null) {
          await FirebaseServiceC1.capNhatTrangThaiLichHen(
            appointmentId: id,
            docPath: docPath,
            trangThaiMoi: 'da_duyet',
          );
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Đã phê duyệt tất cả các đơn khám!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Từ chối toàn bộ các đơn đang chờ trên Firestore
  void _tuChoiHetTatCa(List<Map<String, dynamic>> danhSach) async {
    AppDesignSystemC1.hapticLight();
    for (var don in danhSach) {
      final trangThai = (don['rawTrangThai'] ?? '').toString();
      if (trangThai != 'da_duyet' && trangThai != 'da_kham') {
        final id = don['id'];
        final docPath = don['docPath'];
        if (id != null) {
          await FirebaseServiceC1.capNhatTrangThaiLichHen(
            appointmentId: id,
            docPath: docPath,
            trangThaiMoi: 'tu_choi',
            lyDoTuChoi: 'Phòng khám đã đủ số lượng tiếp nhận tối đa',
          );
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✕ Đã cập nhật không duyệt hết các đơn chờ!'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseServiceC1.streamDanhSachLichHen(
            tenKhoa: widget.tenKhoa,
            ngayChon: _ngayChon,
          ),
          builder: (context, snapshot) {
            final danhSach = snapshot.data ?? [];
            final soDonDaDuyet = danhSach.where((e) => e['rawTrangThai'] == 'da_duyet' || e['trangThai'] == 'Đã duyệt').length;
            final soDonChoDuyet = danhSach.where((e) => e['rawTrangThai'] == 'dang_cho' || e['rawTrangThai'] == 'cho_duyet' || e['trangThai'] == 'Đang chờ').length;
            final tong = danhSach.length;

            return Scaffold(
              backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(isDark),
                    _buildBannerTienDo(isDark, soDonDaDuyet, soDonChoDuyet, tong),
                    Expanded(
                      child: danhSach.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có đơn khám nào cần duyệt',
                                style: TextStyle(
                                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              itemCount: danhSach.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = danhSach[index];
                                return _buildCardDonKhamMap(item, isDark);
                              },
                            ),
                    ),
                    _buildBottomActionButtons(isDark, danhSach),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Header màn hình duyệt đơn khoa
  Widget _buildHeader(bool isDark) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF1E293B),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.tenKhoa,
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.phongKham} • ${widget.caKham}',
                style: TextStyle(
                  color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C2444) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.tongDon} Đơn',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner tiến độ duyệt đơn kèm chọn ngày khám
  Widget _buildBannerTienDo(bool isDark, int daDuyet, int choDuyet, int tong) {
    final String ngayHienThi = '${_ngayChon.day.toString().padLeft(2, '0')}/${_ngayChon.month.toString().padLeft(2, '0')}/${_ngayChon.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFF0F9FF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF075985) : const Color(0xFFBAE6FD),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _chonNgayLichHen,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        ngayHienThi,
                        style: TextStyle(
                          color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0369A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF0369A1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Chờ: $choDuyet/$tong',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            '✓ = Duyệt • ✕ = Từ chối',
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

  // Từng Card bệnh nhân trong danh sách đọc từ Firestore Map
  Widget _buildCardDonKhamMap(Map<String, dynamic> item, bool isDark) {
    Color cardBg;
    Color borderCard;
    Widget badgeTrangThai;

    final rawTrangThai = (item['rawTrangThai'] ?? '').toString();
    final bool laDaDuyet = rawTrangThai == 'da_duyet' || item['trangThai'] == 'Đã duyệt';
    final bool laTuChoi = rawTrangThai == 'tu_choi' || item['trangThai'] == 'Không duyệt';

    if (laDaDuyet) {
      cardBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
      borderCard = const Color(0xFF10B981);
      badgeTrangThai = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✓ Đã duyệt',
          style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    } else if (laTuChoi) {
      cardBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2);
      borderCard = const Color(0xFFEF4444);
      badgeTrangThai = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '✕ Không duyệt',
          style: TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    } else {
      cardBg = isDark ? AppDesignSystemC1.darkSurface : Colors.white;
      borderCard = isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFE2E8F0);
      badgeTrangThai = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Chờ duyệt',
          style: TextStyle(
            color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCard),
      ),
      child: Row(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => _duyetDon(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: laDaDuyet
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: laDaDuyet ? Colors.white : const Color(0xFF059669),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _moPopupTuChoiDon(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: laTuChoi
                        ? const Color(0xFFEF4444)
                        : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Center(
                    child: Text(
                      '✕',
                      style: TextStyle(
                        color: laTuChoi ? Colors.white : const Color(0xFFDC2626),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STT ${item['stt']}: ${item['hoTen']}',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['gioKham']} • ${item['gioiTinh']}, ${item['namSinh']} • ${item['tenKhoa']}',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                if (item['lyDoTuChoi'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Lý do: ${item['lyDoTuChoi']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          badgeTrangThai,
        ],
      ),
    );
  }

  // Thanh 2 nút điều khiển dưới đáy theo Figma: "Không duyệt hết" & "Duyệt hết"
  Widget _buildBottomActionButtons(bool isDark, List<Map<String, dynamic>> danhSach) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystemC1.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppDesignSystemC1.darkBorder : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _tuChoiHetTatCa(danhSach),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'Không duyệt hết',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFF87171)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _duyetHetTatCa(danhSach),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Duyệt hết (${danhSach.length})',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
