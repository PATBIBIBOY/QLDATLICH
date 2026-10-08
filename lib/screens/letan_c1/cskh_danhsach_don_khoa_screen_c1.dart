import 'package:flutter/material.dart';

import '../../mock/mock_c1/dulieu_mau_cskh_c1.dart';
import '../../models/letan_c1/cskh_model_c1.dart';
import '../../models/letan_c1/letan_design_system_c1.dart';

/// MÀN HÌNH 2: DANH SÁCH ĐƠN KHÁM CẦN DUYỆT (KHOA TIM MẠCH / KHOA KHÁM)
/// Dữ liệu kết nối tập trung qua DuLieuCskhKhoaC1, hỗ trợ chuyển lên Firebase Firestore cực kỳ thuận tiện.
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
  late List<DonKhamKhoaModelC1> _danhSachDon;

  @override
  void initState() {
    super.initState();
    // Đọc từ lớp mock dữ liệu tập trung
    _danhSachDon = DuLieuCskhKhoaC1.layDanhSachDonKhamTheoKhoa(widget.tenKhoa);
  }

  // Duyệt đơn
  void _duyetDon(DonKhamKhoaModelC1 don) {
    AppDesignSystemC1.hapticLight();
    setState(() {
      don.trangThai = 'da_duyet';
      don.lyDoTuChoi = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Đã duyệt đơn của ${don.hoTen} (STT ${don.stt})'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mở Popup chọn lý do từ chối đơn khám (Figma 15.1)
  void _moPopupTuChoiDon(DonKhamKhoaModelC1 don) {
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
                                'MÃ ĐẶT LỊCH: ${don.maDon}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                don.hoTen,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${widget.tenKhoa} • ${don.khungGio}',
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
                                  don.stt < 10 ? '0${don.stt}' : '${don.stt}',
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
                              onPressed: () {
                                final lyDoChon = lyDoDangChon == 3 && lyDoKhacController.text.trim().isNotEmpty
                                    ? lyDoKhacController.text.trim()
                                    : cacLyDo[lyDoDangChon];

                                setState(() {
                                  don.trangThai = 'tu_choi';
                                  don.lyDoTuChoi = lyDoChon;
                                });
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✕ Đã từ chối đơn của ${don.hoTen}: $lyDoChon'),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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

  // Duyệt hết toàn bộ đơn
  void _duyetHetTatCa() {
    AppDesignSystemC1.hapticLight();
    setState(() {
      for (var don in _danhSachDon) {
        don.trangThai = 'da_duyet';
        don.lyDoTuChoi = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Đã phê duyệt tất cả các đơn khám!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Từ chối toàn bộ các đơn đang chờ
  void _tuChoiHetTatCa() {
    AppDesignSystemC1.hapticLight();
    setState(() {
      for (var don in _danhSachDon) {
        if (don.laChoDuyet) {
          don.trangThai = 'tu_choi';
          don.lyDoTuChoi = 'Phòng khám đã đủ số lượng tiếp nhận tối đa';
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✕ Đã cập nhật không duyệt hết các đơn chờ!'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppDesignSystemC1.isDarkMode,
      builder: (context, isDark, child) {
        final soDonDaDuyet = _danhSachDon.where((e) => e.laDaDuyet).length;
        final soDonChoDuyet = _danhSachDon.where((e) => e.laChoDuyet).length;

        return Scaffold(
          backgroundColor: isDark ? AppDesignSystemC1.darkBackground : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildBannerTienDo(isDark, soDonDaDuyet, soDonChoDuyet),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: _danhSachDon.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _danhSachDon[index];
                      return _buildCardDonKham(item, isDark);
                    },
                  ),
                ),
                _buildBottomActionButtons(isDark),
              ],
            ),
          ),
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

  // Banner tiến độ duyệt đơn
  Widget _buildBannerTienDo(bool isDark, int daDuyet, int choDuyet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Text(
            'Tiến độ: $choDuyet/${widget.tongDon} đơn chờ duyệt',
            style: TextStyle(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
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

  // Từng Card bệnh nhân trong danh sách
  Widget _buildCardDonKham(DonKhamKhoaModelC1 item, bool isDark) {
    Color cardBg;
    Color borderCard;
    Widget badgeTrangThai;

    if (item.laDaDuyet) {
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
    } else if (item.laTuChoi) {
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
                    color: item.laDaDuyet
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: item.laDaDuyet ? Colors.white : const Color(0xFF059669),
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
                    color: item.laTuChoi
                        ? const Color(0xFFEF4444)
                        : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEF2F2)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Center(
                    child: Text(
                      '✕',
                      style: TextStyle(
                        color: item.laTuChoi ? Colors.white : const Color(0xFFDC2626),
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
                  'STT ${item.stt}: ${item.hoTen}',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextPrimary : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.khungGio} • ${item.gioiTinh}, ${item.tuoi}t',
                  style: TextStyle(
                    color: isDark ? AppDesignSystemC1.darkTextSecondary : const Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                if (item.lyDoTuChoi != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Lý do: ${item.lyDoTuChoi}',
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

  // Thanh 2 nút điều khiển dưới đáy theo Figma: "Không duyệt hết" & "Duyệt hết (25)"
  Widget _buildBottomActionButtons(bool isDark) {
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
                onPressed: _tuChoiHetTatCa,
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
                onPressed: _duyetHetTatCa,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Duyệt hết (${_danhSachDon.length})',
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
