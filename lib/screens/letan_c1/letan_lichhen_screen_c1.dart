import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_design_system_c1.dart';
import '../../models/letan_c1/letan_lichhen_model_c1.dart';
import '../../models/letan_c1/letan_ui_components_c1.dart';

class LetanLichhenScreenC1 extends StatefulWidget {
  final String tuKhoaBanDau;
  final bool laTab;

  const LetanLichhenScreenC1({
    super.key,
    this.tuKhoaBanDau = '',
    this.laTab = true,
  });

  @override
  State<LetanLichhenScreenC1> createState() => _LetanLichhenScreenC1State();
}

class _LetanLichhenScreenC1State extends State<LetanLichhenScreenC1> {
  late TextEditingController _timKiemController;
  String _boLocHienTai = 'Tất cả'; // Tất cả, Đang chờ, Đã khám, Vắng
  String _tuKhoa = '';
  bool _dangTaiLamMoi = false;

  final List<String> _danhSachBoLoc = ['Tất cả', 'Đang chờ', 'Đã khám', 'Vắng'];

  Future<void> _xuLyLamMoiDuLieu() async {
    AppDesignSystemC1.hapticLight();
    setState(() {
      _dangTaiLamMoi = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _dangTaiLamMoi = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tuKhoa = widget.tuKhoaBanDau;
    _timKiemController = TextEditingController(text: widget.tuKhoaBanDau);
  }

  @override
  void dispose() {
    _timKiemController.dispose();
    super.dispose();
  }

  List<LichHenItemC1> get _danhSachLoc {
    return DuLieuMauLichHenC1.danhSachLichHen.where((item) {
      // Lọc theo từ khóa tìm kiếm (tên hoặc SĐT)
      final khopTuKhoa = _tuKhoa.isEmpty ||
          item.ten.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
          item.sdt.contains(_tuKhoa);

      if (!khopTuKhoa) return false;

      // Lọc theo Tab trạng thái
      if (_boLocHienTai == 'Tất cả') return true;
      if (_boLocHienTai == 'Đang chờ') {
        return item.trangThai == 'Đang chờ' || item.trangThai == 'Tiếp theo';
      }
      return item.trangThai == _boLocHienTai;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final danhSach = _danhSachLoc;

    final content = Column(
      children: [
        // Thanh tiêu đề khi ở dạng Tab
        if (widget.laTab)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: const Text(
              'Lịch hẹn hôm nay',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        // Thanh tìm kiếm trực tiếp theo Tên hoặc SĐT
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _timKiemController,
                onChanged: (val) {
                  setState(() {
                    _tuKhoa = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc số điện thoại...',
                  hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                  suffixIcon: _tuKhoa.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF8E8E93), size: 18),
                          onPressed: () {
                            _timKiemController.clear();
                            setState(() {
                              _tuKhoa = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Dòng hiển thị Ngày và Tổng số lịch hẹn
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    DuLieuMauLichHenC1.ngayHienTai,
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${danhSach.length}/${DuLieuMauLichHenC1.tongSoLichHen} lịch hẹn',
                    style: const TextStyle(
                      color: Color(0xFFFF9500),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Bộ lọc 4 tab phong cách Segmented Button chuẩn M3
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                  borderRadius: AppDesignSystemC1.borderRadMedium,
                ),
                child: Row(
                  children: _danhSachBoLoc.map((tab) {
                    final bool isSelected = _boLocHienTai == tab;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          AppDesignSystemC1.hapticLight();
                          setState(() {
                            _boLocHienTai = tab;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected ? AppDesignSystemC1.primary : AppDesignSystemC1.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Danh sách lịch hẹn với Pull-to-refresh và Empty state
            Expanded(
              child: _dangTaiLamMoi
                  ? const SkeletonLichHenListC1()
                  : RefreshIndicator(
                      color: AppDesignSystemC1.primary,
                      onRefresh: _xuLyLamMoiDuLieu,
                      child: danhSach.isEmpty
                          ? EmptyStateWidgetC1(
                              title: _tuKhoa.isNotEmpty ? 'Không Tìm Thấy Bệnh Nhân' : 'Chưa Có Lịch Hẹn Nào',
                              message: _tuKhoa.isNotEmpty
                                  ? 'Không có kết quả trùng khớp với từ khóa "$_tuKhoa". Vui lòng kiểm tra lại.'
                                  : 'Hiện tại chưa có bệnh nhân nào trong danh mục "$_boLocHienTai".',
                              onRetry: () {
                                setState(() {
                                  _tuKhoa = '';
                                  _timKiemController.clear();
                                  _boLocHienTai = 'Tất cả';
                                });
                              },
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: danhSach.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildItemLichHen(danhSach[index]);
                              },
                            ),
                    ),
            ),
          ],
        );

    if (widget.laTab) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch hẹn hôm nay',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _buildItemLichHen(LichHenItemC1 item) {
    Color badgeBg;
    Color badgeText;
    Color avatarBg;
    Color avatarText;

    if (item.trangThai == 'Tiếp theo' || item.trangThai == 'Đang chờ') {
      badgeBg = item.trangThai == 'Tiếp theo' ? const Color(0xFFE8F8EF) : const Color(0xFFE8F4FD);
      badgeText = item.trangThai == 'Tiếp theo' ? const Color(0xFF34C759) : const Color(0xFF007AFF);
      avatarBg = badgeBg;
      avatarText = badgeText;
    } else if (item.trangThai == 'Đã khám') {
      badgeBg = const Color(0xFFE8F8EF);
      badgeText = const Color(0xFF34C759);
      avatarBg = const Color(0xFFE8F8EF);
      avatarText = const Color(0xFF34C759);
    } else if (item.trangThai == 'Vắng') {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFEF4444);
      avatarBg = const Color(0xFFFEE2E2);
      avatarText = const Color(0xFFEF4444);
    } else {
      // Chưa đến
      badgeBg = const Color(0xFFF2F2F7);
      badgeText = const Color(0xFF8E8E93);
      avatarBg = const Color(0xFFF2F2F7);
      avatarText = const Color(0xFF8E8E93);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar viết tắt
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              item.avatarInitials,
              style: TextStyle(
                color: avatarText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin Tên, Khoa, Giờ, SĐT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ten,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 13, color: Color(0xFF007AFF)),
                    const SizedBox(width: 4),
                    Text(
                      item.sdt,
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.khoa,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.gioKham,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Nhãn trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.trangThai,
              style: TextStyle(
                color: badgeText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
