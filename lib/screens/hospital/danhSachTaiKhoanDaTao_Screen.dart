import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/app_session.dart';
import '../../config/app_routes.dart';
import '../../models/nhan_vien_model.dart';
import '../../services/nhan_vien_service.dart';
import '../../services/xuat_pdf_service.dart';
import 'CapTK_Scream.dart';

export '../../models/nhan_vien_model.dart' show TaiKhoanItem, DotCapTaiKhoan;

class StaffAccountStore {
  // Mật khẩu mặc định chung cho toàn bộ tài khoản nhân viên được cấp
  static const String matKhauMacDinh = '123456';

  // Lưu đợt cấp vừa tạo trong bộ nhớ phiên làm việc
  static DotCapTaiKhoan? dotCapGanNhat;
  static final List<DotCapTaiKhoan> lichSuCacDot = [];

  static void luuDotCap(DotCapTaiKhoan dot) {
    dotCapGanNhat = dot;
    lichSuCacDot.removeWhere((d) => d.id == dot.id);
    lichSuCacDot.insert(0, dot);
  }
}

class DanhSachTaiKhoanDaTaoScreen extends StatefulWidget {
  final String? benhVienId;
  final String? tenKhoa;
  final String? vaiTro;
  final int? soLuong;
  final List<TaiKhoanItem>? danhSachTaiKhoan;

  const DanhSachTaiKhoanDaTaoScreen({
    super.key,
    this.benhVienId,
    this.tenKhoa,
    this.vaiTro,
    this.soLuong,
    this.danhSachTaiKhoan,
  });

  @override
  State<DanhSachTaiKhoanDaTaoScreen> createState() =>
      _DanhSachTaiKhoanDaTaoScreenState();
}

class _DanhSachTaiKhoanDaTaoScreenState
    extends State<DanhSachTaiKhoanDaTaoScreen> {
  final NhanVienService _nhanVienService = NhanVienService();

  // Tab 0: Đợi kích hoạt, Tab 1: Đã kích hoạt
  int _selectedTabIndex = 0;

  // Bộ lọc vai trò: 'Tất cả' hoặc vai trò cụ thể (Bác sĩ, Lễ tân, CSKH...)
  String _selectedRoleFilter = 'Tất cả';

  // Danh sách toàn bộ tài khoản
  List<TaiKhoanItem> _allAccounts = [];
  bool _isLoading = true;
  String _tenBenhVien = 'Bệnh viện';

  // Đợt vừa tạo từ màn hình trước (nếu có)
  DotCapTaiKhoan? _vuaTaoBatch;

  String _getBenhVienId() {
    if (widget.benhVienId != null && widget.benhVienId!.isNotEmpty) {
      return widget.benhVienId!;
    }
    if (AppSession.benhVienId.isNotEmpty) {
      return AppSession.benhVienId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _khoiTaoDuLieu();
  }

  Future<void> _khoiTaoDuLieu() async {
    setState(() => _isLoading = true);

    // 1. Nếu có đợt vừa tạo truyền qua constructor
    if (widget.danhSachTaiKhoan != null && widget.danhSachTaiKhoan!.isNotEmpty) {
      _vuaTaoBatch = DotCapTaiKhoan(
        tenKhoa: widget.tenKhoa ?? 'Khoa',
        vaiTro: widget.vaiTro ?? 'Nhân viên',
        soLuong: widget.danhSachTaiKhoan!.length,
        danhSachTaiKhoan: widget.danhSachTaiKhoan!,
      );
      StaffAccountStore.luuDotCap(_vuaTaoBatch!);
    } else if (StaffAccountStore.dotCapGanNhat != null) {
      _vuaTaoBatch = StaffAccountStore.dotCapGanNhat;
    }

    // 2. Tải toàn bộ tài khoản từ Firestore
    try {
      final bvid = _getBenhVienId();
      final accounts = await _nhanVienService.layTatCaTaiKhoan(bvid);

      // Nếu có danh sách từ constructor nhưng Firestore chưa kịp sync hết, gộp vào
      if (widget.danhSachTaiKhoan != null && widget.danhSachTaiKhoan!.isNotEmpty) {
        for (final item in widget.danhSachTaiKhoan!) {
          if (!accounts.any((a) => a.maTk == item.maTk)) {
            accounts.add(item);
          }
        }
      }

      // Lấy tên bệnh viện
      String tenBv = '';
      try {
        tenBv = await _nhanVienService.layTenBenhVien(bvid);
      } catch (_) {}
      if (tenBv.isEmpty) {
        try {
          final authUser = FirebaseAuth.instance.currentUser;
          if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
            tenBv = authUser.displayName!;
          }
        } catch (_) {}
      }
      if (tenBv.isEmpty) tenBv = 'Bệnh viện MediConnect';

      if (mounted) {
        setState(() {
          _allAccounts = accounts;
          _tenBenhVien = tenBv;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi tải danh sách tài khoản: $e');
      if (mounted) {
        setState(() {
          _allAccounts = widget.danhSachTaiKhoan ?? [];
          _isLoading = false;
        });
      }
    }
  }

  // Danh sách tài khoản đợi kích hoạt
  List<TaiKhoanItem> get _danhSachDoiKichHoat {
    return _allAccounts.where((tk) => !tk.daKichHoat).toList();
  }

  // Danh sách tài khoản đã kích hoạt
  List<TaiKhoanItem> get _danhSachDaKichHoat {
    return _allAccounts.where((tk) => tk.daKichHoat).toList();
  }

  // Tập hợp danh sách các vai trò có trong danh sách hiện tại để hiển thị bộ lọc
  List<String> _layDanhSachVaiTro(List<TaiKhoanItem> sourceList) {
    final setRoles = <String>{};
    for (final item in sourceList) {
      if (item.vaiTro.isNotEmpty) {
        setRoles.add(item.vaiTro.trim());
      }
    }
    // Các vai trò phổ biến nếu danh sách chưa có đầy đủ
    const defaultRoles = ['Bác sĩ', 'Điều dưỡng', 'Dược sĩ', 'Lễ tân', 'CSKH'];
    for (final r in defaultRoles) {
      if (!setRoles.contains(r)) {
        setRoles.add(r);
      }
    }

    return ['Tất cả', ...setRoles];
  }

  // Lọc theo vai trò và SẮP XẾP TỪ MỚI ĐẾN CŨ
  List<TaiKhoanItem> _locVaSapXep(List<TaiKhoanItem> sourceList) {
    var filtered = sourceList;

    // 1. Lọc theo vai trò
    if (_selectedRoleFilter != 'Tất cả') {
      filtered = filtered.where((item) {
        final r = item.vaiTro.toLowerCase();
        final filter = _selectedRoleFilter.toLowerCase();
        if (r == filter) return true;
        if (filter == 'bác sĩ' && (r.contains('bác sĩ') || item.role == 'doctor')) return true;
        if (filter == 'điều dưỡng' && (r.contains('điều dưỡng') || item.role == 'nurse')) return true;
        if (filter == 'dược sĩ' && (r.contains('dược') || item.role == 'pharmacist')) return true;
        if (filter == 'lễ tân' && (r.contains('lễ tân') || item.role == 'receptionist')) return true;
        if (filter == 'cskh' && (r.contains('cskh') || item.role == 'customerSupport')) return true;
        return false;
      }).toList();
    }

    // 2. Sắp xếp thứ tự TỪ MỚI ĐẾN CŨ
    final result = List<TaiKhoanItem>.from(filtered);
    result.sort((a, b) {
      // Ưu tiên ngày tạo mới nhất lên đầu
      if (a.ngayTao != null && b.ngayTao != null) {
        final cmp = b.ngayTao!.compareTo(a.ngayTao!);
        if (cmp != 0) return cmp;
      } else if (a.ngayTao != null) {
        return -1;
      } else if (b.ngayTao != null) {
        return 1;
      }

      // Nếu không có ngày tạo, sắp xếp theo số đuôi trong mã tài khoản giảm dần
      final numA = _extractTrailingNumber(a.maTk);
      final numB = _extractTrailingNumber(b.maTk);
      if (numA != null && numB != null) {
        return numB.compareTo(numA);
      }

      return b.maTk.compareTo(a.maTk);
    });

    return result;
  }

  int? _extractTrailingNumber(String code) {
    final match = RegExp(r'(\d+)$').firstMatch(code);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _saoChep(BuildContext context, String text, String thongBao) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(thongBao),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saoChepTatCa(BuildContext context, List<TaiKhoanItem> list) {
    if (list.isEmpty) return;

    final tabName = _selectedTabIndex == 0 ? 'ĐỢI KÍCH HOẠT' : 'ĐÃ KÍCH HOẠT';
    final buffer = StringBuffer();
    buffer.writeln('=== DANH SÁCH TÀI KHOẢN $tabName ($_selectedRoleFilter) ===');
    buffer.writeln('Bệnh viện: $_tenBenhVien');
    buffer.writeln('Mật khẩu khởi tạo: ${StaffAccountStore.matKhauMacDinh}');
    buffer.writeln('Tổng số: ${list.length} tài khoản\n');

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      final vaiTroStr = item.vaiTro.isNotEmpty ? item.vaiTro : 'Nhân viên';
      final khoaStr = item.khoa.isNotEmpty ? ' • ${item.khoa}' : '';
      buffer.writeln(
        '${i + 1}. TK: ${item.maTk} | MK: ${item.matKhau} | $vaiTroStr$khoaStr',
      );
    }

    _saoChep(
      context,
      buffer.toString(),
      'Đã sao chép toàn bộ ${list.length} tài khoản!',
    );
  }

  Future<void> _xoaTaiKhoan(TaiKhoanItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận xóa tài khoản?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài khoản ${item.maTk} không? Tài khoản sẽ bị xóa hoàn toàn khỏi hệ thống.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _nhanVienService.xoaNhanVien(item.id ?? item.maTk, _getBenhVienId());

      if (!mounted) return;

      setState(() {
        _allAccounts.removeWhere((tk) => tk.maTk == item.maTk);
        if (_vuaTaoBatch != null) {
          final newBatchList = _vuaTaoBatch!.danhSachTaiKhoan
              .where((tk) => tk.maTk != item.maTk)
              .toList();
          _vuaTaoBatch = DotCapTaiKhoan(
            id: _vuaTaoBatch!.id,
            tenKhoa: _vuaTaoBatch!.tenKhoa,
            vaiTro: _vuaTaoBatch!.vaiTro,
            soLuong: newBatchList.length,
            danhSachTaiKhoan: newBatchList,
            thoiGian: _vuaTaoBatch!.thoiGian,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa tài khoản ${item.maTk} thành công'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa tài khoản: $e'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Xuất file PDF danh sách tài khoản thực sự
  Future<void> _xuatFilePdf(List<TaiKhoanItem> listToExport) async {
    if (listToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có tài khoản nào trong danh sách để xuất file PDF.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tabTitle = _selectedTabIndex == 0
        ? 'Danh Sách Tài Khoản Đợi Kích Hoạt'
        : 'Danh Sách Tài Khoản Đã Kích Hoạt';

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 10),
              Text('Đang tạo và chuẩn bị tệp PDF...'),
            ],
          ),
          backgroundColor: Color(0xFF0284C7),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await XuatPdfService.xuatVaInPdf(
        tenBenhVien: _tenBenhVien,
        tieuDeTrang: tabTitle,
        vaiTroDangLoc: _selectedRoleFilter,
        danhSach: listToExport,
      );
    } catch (e) {
      debugPrint('⚠️ Lỗi xuất file PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xuất file PDF: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0284C7)),
              SizedBox(height: 12),
              Text(
                'Đang tải danh sách tài khoản...',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    // Chọn danh sách nguồn theo Tab
    final currentSourceList =
        _selectedTabIndex == 0 ? _danhSachDoiKichHoat : _danhSachDaKichHoat;

    // Lọc theo vai trò và sắp xếp TỪ MỚI ĐẾN CŨ
    final displayedList = _locVaSapXep(currentSourceList);

    // Danh sách vai trò có sẵn trong tab hiện tại
    final availableRoles = _layDanhSachVaiTro(currentSourceList);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // 1. Header AppBar
                _buildHeader(context, displayedList),

                // 2. Thanh 2 Tab: [Đợi kích hoạt] & [Đã kích hoạt]
                _buildTabSelector(),

                // 3. Thanh lọc vai trò ("xắp sếp theo vai trò nào thì xem vai trò đó")
                _buildRoleFilterBar(availableRoles),

                // 4. Nội dung danh sách tài khoản
                Expanded(
                  child: displayedList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _khoiTaoDuLieu,
                          color: const Color(0xFF0284C7),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            children: [
                              // Hộp thông báo nếu vừa tạo đợt tài khoản mới
                              if (_selectedTabIndex == 0 &&
                                  _vuaTaoBatch != null &&
                                  _vuaTaoBatch!.danhSachTaiKhoan.isNotEmpty)
                                _buildSuccessBanner(_vuaTaoBatch!),

                              const SizedBox(height: 12),

                              // Tiêu đề & Nút Sao chép tất cả
                              _buildSubHeader(displayedList),

                              const SizedBox(height: 10),

                              // Danh sách các thẻ tài khoản (sắp xếp từ mới đến cũ)
                              for (int i = 0; i < displayedList.length; i++) ...[
                                _buildAccountCard(context, i + 1, displayedList[i]),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                        ),
                ),

                // 5. Nút Xuất File PDF & Quay lại trang Nhân sự
                _buildBottomButtons(context, displayedList),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<TaiKhoanItem> displayedList) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Danh Sách Tài Khoản Đã Tạo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          // Nút xuất file PDF nhanh trên AppBar
          Tooltip(
            message: 'Xuất file PDF danh sách tài khoản',
            child: InkWell(
              onTap: () => _xuatFilePdf(displayedList),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 20,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ chuyển đổi 2 phần lịch sử: [1. Đợi kích hoạt] & [2. Đã kích hoạt]
  Widget _buildTabSelector() {
    final doiCount = _danhSachDoiKichHoat.length;
    final daCount = _danhSachDaKichHoat.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Tab 1: Đợi kích hoạt
            Expanded(
              child: InkWell(
                onTap: () {
                  if (_selectedTabIndex != 0) {
                    setState(() {
                      _selectedTabIndex = 0;
                      _selectedRoleFilter = 'Tất cả';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _selectedTabIndex == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: _selectedTabIndex == 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đợi kích hoạt ($doiCount)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTabIndex == 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _selectedTabIndex == 0
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab 2: Đã kích hoạt
            Expanded(
              child: InkWell(
                onTap: () {
                  if (_selectedTabIndex != 1) {
                    setState(() {
                      _selectedTabIndex = 1;
                      _selectedRoleFilter = 'Tất cả';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: _selectedTabIndex == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: _selectedTabIndex == 1
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đã kích hoạt ($daCount)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _selectedTabIndex == 1
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
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
    );
  }

  /// Thanh chọn vai trò: "xắp sếp theo vai trò nào thì xem vai trò đó"
  Widget _buildRoleFilterBar(List<String> roles) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF0284C7)),
                  SizedBox(width: 4),
                  Text(
                    'Xem theo vai trò:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                'Mới nhất trước',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: roles.map((role) {
                final isSelected = _selectedRoleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRoleFilter = role;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(List<TaiKhoanItem> displayedList) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _selectedTabIndex == 0
                      ? 'Chi tiết tài khoản & Mật khẩu'
                      : 'Tài khoản nhân sự đang hoạt động',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${displayedList.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _selectedTabIndex == 0
                  ? 'Mật khẩu khởi tạo chung: ${StaffAccountStore.matKhauMacDinh}'
                  : 'Sắp xếp thứ tự từ mới nhất đến cũ nhất',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => _saoChepTatCa(context, displayedList),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_all_rounded, size: 15, color: Color(0xFF0284C7)),
                SizedBox(width: 3),
                Text(
                  'Sao chép tất cả',
                  style: TextStyle(
                    color: Color(0xFF0284C7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner(DotCapTaiKhoan batch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã tạo thành công ${batch.danhSachTaiKhoan.length} tài khoản mới',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${batch.tenKhoa} • Vai trò: ${batch.vaiTro} (Đợi kích hoạt)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, int index, TaiKhoanItem item) {
    final bool isActivated = item.daKichHoat;
    final vaiTroStr = item.vaiTro.isNotEmpty ? item.vaiTro : 'Nhân viên';
    final khoaStr = item.khoa.isNotEmpty ? item.khoa : 'Toàn viện';
    final ngayTaoStr = item.ngayTao != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(item.ngayTao!)
        : 'Mới tạo';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: STT, Mã tài khoản, Badge trạng thái và Thùng rác
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$index. ',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        item.maTk,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActivated
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActivated ? 'Đã kích hoạt' : 'Đợi kích hoạt',
                      style: TextStyle(
                        color: isActivated
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Nút xóa (chỉ hiển thị cho tài khoản chưa kích hoạt để tránh xóa nhầm tài khoản đang trực)
                  if (!isActivated)
                    InkWell(
                      onTap: () => _xoaTaiKhoan(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 17,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Dòng 2: Thông tin vai trò, khoa & ngày tạo (Mới đến cũ)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vaiTroStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• $khoaStr',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text(
                ngayTaoStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dòng 3: Khung mật khẩu & nút Chép
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Mật khẩu khởi tạo: ',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item.matKhau,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _saoChep(
                    context,
                    item.matKhau,
                    'Đã sao chép mật khẩu: ${item.matKhau}',
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 13, color: Color(0xFF0284C7)),
                        SizedBox(width: 3),
                        Text(
                          'Chép',
                          style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDoi = _selectedTabIndex == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDoi ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
              size: 52,
              color: isDoi ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              isDoi
                  ? (_selectedRoleFilter == 'Tất cả'
                      ? 'Không có tài khoản đợi kích hoạt'
                      : 'Không có tài khoản $_selectedRoleFilter đợi kích hoạt')
                  : (_selectedRoleFilter == 'Tất cả'
                      ? 'Chưa có tài khoản nào được kích hoạt'
                      : 'Chưa có tài khoản $_selectedRoleFilter nào kích hoạt'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isDoi
                  ? 'Tất cả tài khoản nhân sự đã được kích hoạt hoặc chưa có đợt cấp mới.'
                  : 'Các tài khoản sẽ chuyển sang mục này khi nhân viên đăng nhập lần đầu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CapTaiKhoanNhanVienScreen(benhVienId: _getBenhVienId()),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Cấp Thêm Tài Khoản Mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, List<TaiKhoanItem> displayedList) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Xuất File PDF thực sự hoạt động
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _xuatFilePdf(displayedList),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                'Xuất File PDF / In Danh Sách (${displayedList.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.NhanSuScreen,
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Quay lại trang Nhân sự',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
