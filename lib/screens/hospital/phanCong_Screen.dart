import 'package:flutter/material.dart';

/// Model nhân viên cho màn hình phân công trực
class NhanVienTrucItem {
  final String id;
  final String hoTen;
  final String tenRutGon;
  final String initials;
  final String vaiTro;
  final String trangThai; // 'Đang rảnh' hoặc 'Đang có ca khác'
  final bool isAvailable;
  final Color avatarBg;
  final Color avatarTextColor;

  const NhanVienTrucItem({
    required this.id,
    required this.hoTen,
    required this.tenRutGon,
    required this.initials,
    required this.vaiTro,
    required this.trangThai,
    required this.isAvailable,
    required this.avatarBg,
    required this.avatarTextColor,
  });
}

/// Model phòng khám trực
class PhongKhamTrucItem {
  final String maPhong;
  final String tenPhong;
  final String thoiGianVaDiaDiem;
  NhanVienTrucItem? nhanVienPhanCong;

  PhongKhamTrucItem({
    required this.maPhong,
    required this.tenPhong,
    required this.thoiGianVaDiaDiem,
    this.nhanVienPhanCong,
  });
}

class PhanCongScreen extends StatefulWidget {
  final bool isTab;
  final String? benhVienId;

  const PhanCongScreen({
    super.key,
    this.isTab = true,
    this.benhVienId,
  });

  @override
  State<PhanCongScreen> createState() => _PhanCongScreenState();
}

class _PhanCongScreenState extends State<PhanCongScreen> {
  DateTime _ngayDuocChon = DateTime(2026, 9, 21); // 21/09/2026 như trong hình

  // Danh sách nhân viên mẫu (hardcode theo thiết kế)
  final List<NhanVienTrucItem> _danhSachNhanVien = const [
    NhanVienTrucItem(
      id: 'NV01',
      hoTen: 'Nguyễn Thị Lan',
      tenRutGon: 'Ng. Thị Lan',
      initials: 'NL',
      vaiTro: 'Hỗ trợ bác sĩ',
      trangThai: 'Đang có ca khác',
      isAvailable: false,
      avatarBg: Color(0xFFF1F5F9),
      avatarTextColor: Color(0xFF64748B),
    ),
    NhanVienTrucItem(
      id: 'NV02',
      hoTen: 'Phạm Văn Hùng',
      tenRutGon: 'Phạm Văn Hùng',
      initials: 'PH',
      vaiTro: 'Hỗ trợ bác sĩ',
      trangThai: 'Đang rảnh',
      isAvailable: true,
      avatarBg: Color(0xFF3B82F6),
      avatarTextColor: Colors.white,
    ),
    NhanVienTrucItem(
      id: 'NV03',
      hoTen: 'Đỗ Thị Mai',
      tenRutGon: 'Đỗ Thị Mai',
      initials: 'DM',
      vaiTro: 'Hỗ trợ bác sĩ',
      trangThai: 'Đang rảnh',
      isAvailable: true,
      avatarBg: Color(0xFFFEF3C7),
      avatarTextColor: Color(0xFFD97706),
    ),
    NhanVienTrucItem(
      id: 'NV04',
      hoTen: 'Vũ Quang Huy',
      tenRutGon: 'Vũ Quang Huy',
      initials: 'VH',
      vaiTro: 'Hỗ trợ bác sĩ',
      trangThai: 'Đang rảnh',
      isAvailable: true,
      avatarBg: Color(0xFFFFEDD5),
      avatarTextColor: Color(0xFFEA580C),
    ),
  ];

  // Danh sách phòng khám (hardcode mẫu theo hình)
  late List<PhongKhamTrucItem> _danhSachPhong;

  @override
  void initState() {
    super.initState();
    _khoiTaoDuLieuMau();
  }

  void _khoiTaoDuLieuMau() {
    _danhSachPhong = [
      PhongKhamTrucItem(
        maPhong: '405',
        tenPhong: 'Phòng 405',
        thoiGianVaDiaDiem: '07:30 - 17:00 · Tầng 4 NĐT KTC',
        nhanVienPhanCong: const NhanVienTrucItem(
          id: 'NV01',
          hoTen: 'Nguyễn Thị Lan',
          tenRutGon: 'Ng. Thị Lan',
          initials: 'NL',
          vaiTro: 'Hỗ trợ bác sĩ',
          trangThai: 'Đang trực ca này',
          isAvailable: true,
          avatarBg: Color(0xFFE0F2FE),
          avatarTextColor: Color(0xFF0284C7),
        ),
      ),
      PhongKhamTrucItem(
        maPhong: '406',
        tenPhong: 'Phòng 406',
        thoiGianVaDiaDiem: '07:30 - 17:00 · Tầng 4 NĐT KTC',
        nhanVienPhanCong: const NhanVienTrucItem(
          id: 'NV_TB',
          hoTen: 'Trần Văn Bình',
          tenRutGon: 'Trần Văn Bình',
          initials: 'TB',
          vaiTro: 'Hỗ trợ bác sĩ',
          trangThai: 'Đang trực ca này',
          isAvailable: true,
          avatarBg: Color(0xFFE0F2FE),
          avatarTextColor: Color(0xFF0284C7),
        ),
      ),
      PhongKhamTrucItem(
        maPhong: '407',
        tenPhong: 'Phòng 407',
        thoiGianVaDiaDiem: '07:30 - 17:00 · Tầng 4 NĐT KTC',
        nhanVienPhanCong: null, // Chưa phân công như trong hình
      ),
      PhongKhamTrucItem(
        maPhong: '408',
        tenPhong: 'Phòng 408',
        thoiGianVaDiaDiem: '07:30 - 17:00 · Tầng 4 NĐT KTC',
        nhanVienPhanCong: const NhanVienTrucItem(
          id: 'NV_LH',
          hoTen: 'Lê Thị Hoa',
          tenRutGon: 'Lê Thị Hoa',
          initials: 'LH',
          vaiTro: 'Hỗ trợ bác sĩ',
          trangThai: 'Đang trực ca này',
          isAvailable: true,
          avatarBg: Color(0xFFE0F2FE),
          avatarTextColor: Color(0xFF0284C7),
        ),
      ),
    ];
  }

  String _dinhDangThuNgay(DateTime dt) {
    const listThu = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final thu = listThu[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$thu, $d/$m/$y';
  }

  void _doiNgay(int offsetDays) {
    setState(() {
      _ngayDuocChon = _ngayDuocChon.add(Duration(days: offsetDays));
    });
  }

  /// Mở Bottom Sheet chọn nhân viên trực (như Hình 2)
  void _moSheetChonNhanVien(PhongKhamTrucItem phong) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChonNhanVienModal(
        phong: phong,
        danhSachNhanVien: _danhSachNhanVien,
        nhanVienHienTai: phong.nhanVienPhanCong,
        onXacNhan: (nhanVienMoi) {
          setState(() {
            phong.nhanVienPhanCong = nhanVienMoi;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã phân công ${nhanVienMoi.hoTen} trực ${phong.tenPhong}!',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soPhongDaPhanCong =
        _danhSachPhong.where((p) => p.nhanVienPhanCong != null).length;
    final tongSoPhong = _danhSachPhong.length;
    final phongChuaPhanCong =
        _danhSachPhong.where((p) => p.nhanVienPhanCong == null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Phân Công Trực
            _buildHeader(),

            // Thân nội dung có thể cuộn
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chọn ngày trực
                    const Text(
                      'Chọn ngày trực',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Thanh điều hướng chọn ngày
                    _buildDatePickerBar(),

                    const SizedBox(height: 20),

                    // Tiêu đề Khoa và số phòng đã phân công
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Khoa Mắt Kỹ Thuật Cao',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '$soPhongDaPhanCong/$tongSoPhong phòng đã phân công',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Danh sách các phòng
                    ..._danhSachPhong.map((p) => _buildCardPhong(p)),

                    const SizedBox(height: 16),

                    // Banner thông báo nếu còn phòng chưa có người trực
                    if (phongChuaPhanCong.isNotEmpty) ...[
                      _buildWarningBanner(phongChuaPhanCong),
                      const SizedBox(height: 16),
                    ],

                    // Khung Lưu ý phân công
                    _buildNoteBox(),

                    const SizedBox(height: 20),

                    // Nút Lưu Phân Công
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGETS CON ====================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Phân Công Trực',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mỗi phòng khám 1 người trực bấm số',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 38), // Cân xứng với nút back bên trái
        ],
      ),
    );
  }

  Widget _buildDatePickerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _doiNgay(-1),
            icon: const Icon(Icons.chevron_left_rounded,
                color: Color(0xFF475569)),
            splashRadius: 20,
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _ngayDuocChon,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _ngayDuocChon = picked);
              }
            },
            child: Text(
              _dinhDangThuNgay(_ngayDuocChon),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _doiNgay(1),
            icon: const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF475569)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCardPhong(PhongKhamTrucItem phong) {
    final daPhanCong = phong.nhanVienPhanCong != null;

    if (!daPhanCong) {
      // Card viền nét đứt màu cam (Phòng chưa phân công)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0xFFF59E0B),
            strokeWidth: 1.5,
            radius: 18,
            dashWidth: 6,
            dashSpace: 4,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Icon phòng khám (Cam)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.table_restaurant_outlined,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tên phòng & giờ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phong.tenPhong,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phong.thoiGianVaDiaDiem,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút + Phân công
                InkWell(
                  onTap: () => _moSheetChonNhanVien(phong),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+ Phân công',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Card phòng đã phân công (Viền xám nhẹ, nền trắng)
    final nv = phong.nhanVienPhanCong!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _moSheetChonNhanVien(phong),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon phòng (Xanh dương)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.table_restaurant_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin phòng
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phong.tenPhong,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phong.thoiGianVaDiaDiem,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Nhân viên trực
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: nv.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        nv.initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: nv.avatarTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nv.tenRutGon,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        nv.vaiTro,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner(List<PhongKhamTrucItem> danhSachChuaCo) {
    final tenPhongChua =
        danhSachChuaCo.map((p) => p.tenPhong).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.priority_high_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Còn ${danhSachChuaCo.length} phòng chưa có người trực',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tenPhongChua hiện chưa được phân công',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lưu ý phân công:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Mỗi phòng khám chỉ phân công 1 người trực bấm số xuyên suốt ca làm việc trong ngày.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Đã lưu dữ liệu phân công trực thành công!'),
                ],
              ),
              backgroundColor: Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Lưu Phân Công',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet chọn nhân viên trực (như Hình 2)
class _ChonNhanVienModal extends StatefulWidget {
  final PhongKhamTrucItem phong;
  final List<NhanVienTrucItem> danhSachNhanVien;
  final NhanVienTrucItem? nhanVienHienTai;
  final ValueChanged<NhanVienTrucItem> onXacNhan;

  const _ChonNhanVienModal({
    required this.phong,
    required this.danhSachNhanVien,
    required this.nhanVienHienTai,
    required this.onXacNhan,
  });

  @override
  State<_ChonNhanVienModal> createState() => _ChonNhanVienModalState();
}

class _ChonNhanVienModalState extends State<_ChonNhanVienModal> {
  String _tuKhoa = '';
  NhanVienTrucItem? _nhanVienDuocChon;

  @override
  void initState() {
    super.initState();
    _nhanVienDuocChon = widget.nhanVienHienTai ??
        widget.danhSachNhanVien.firstWhere((nv) => nv.isAvailable,
            orElse: () => widget.danhSachNhanVien[1]);
  }

  @override
  Widget build(BuildContext context) {
    final listLoc = widget.danhSachNhanVien.where((nv) {
      if (_tuKhoa.isEmpty) return true;
      return nv.hoTen.toLowerCase().contains(_tuKhoa.toLowerCase());
    }).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo trên cùng
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề & nút đóng X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn nhân viên trực',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.phong.tenPhong} · Ca chiều (13:30 - 17:00)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ô tìm kiếm nhân viên
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _tuKhoa = val.trim()),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên nhân viên...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nhãn nhóm nhân viên
          Text(
            'NHÂN VIÊN HỖ TRỢ BÁC SĨ (${listLoc.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách nhân viên
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listLoc.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final nv = listLoc[index];
                final isSelected = _nhanVienDuocChon?.id == nv.id;
                final isAvailable = nv.isAvailable;

                return InkWell(
                  onTap: isAvailable
                      ? () => setState(() => _nhanVienDuocChon = nv)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: nv.avatarBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              nv.initials,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: nv.avatarTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Tên & Vai trò
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nv.hoTen,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isAvailable
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nv.vaiTro,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trạng thái (Đang rảnh / Đang có ca khác)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            nv.trangThai,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Checkbox / Radio
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          )
                        else if (isAvailable)
                          const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: Color(0xFFCBD5E1),
                            size: 22,
                          )
                        else
                          const SizedBox(width: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Nút xác nhận phân công
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nhanVienDuocChon != null &&
                      _nhanVienDuocChon!.isAvailable
                  ? () {
                      widget.onXacNhan(_nhanVienDuocChon!);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xác nhận phân công',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Nút Hủy
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ viền nét đứt (Dashed Border) cho phòng chưa phân công
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
