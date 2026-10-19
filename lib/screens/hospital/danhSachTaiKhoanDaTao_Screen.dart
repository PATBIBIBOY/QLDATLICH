import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_routes.dart';

class TaiKhoanItem {
  final String maTk;
  final String matKhau;
  final String trangThai;

  const TaiKhoanItem({
    required this.maTk,
    required this.matKhau,
    this.trangThai = 'Chưa kích hoạt',
  });
}

class DotCapTaiKhoan {
  final String id;
  final String tenKhoa;
  final String vaiTro;
  final int soLuong;
  final List<TaiKhoanItem> danhSachTaiKhoan;
  final DateTime thoiGian;

  DotCapTaiKhoan({
    String? id,
    required this.tenKhoa,
    required this.vaiTro,
    required this.soLuong,
    required this.danhSachTaiKhoan,
    DateTime? thoiGian,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       thoiGian = thoiGian ?? DateTime.now();
}

class StaffAccountStore {
  // Mật khẩu mặc định chung cho toàn bộ tài khoản nhân viên được cấp
  static const String matKhauMacDinh = '123456';

  // Dữ liệu mẫu mặc định với mật khẩu dùng chung, chỉ đổi mã nhân sự
  static DotCapTaiKhoan dotCapGanNhat = DotCapTaiKhoan(
    tenKhoa: 'Khoa Tim Mạch',
    vaiTro: 'Lễ tân',
    soLuong: 5,
    danhSachTaiKhoan: const [
      TaiKhoanItem(maTk: 'LT_TM_01', matKhau: matKhauMacDinh),
      TaiKhoanItem(maTk: 'LT_TM_02', matKhau: matKhauMacDinh),
      TaiKhoanItem(maTk: 'LT_TM_03', matKhau: matKhauMacDinh),
      TaiKhoanItem(maTk: 'LT_TM_04', matKhau: matKhauMacDinh),
      TaiKhoanItem(maTk: 'LT_TM_05', matKhau: matKhauMacDinh),
    ],
  );

  static final List<DotCapTaiKhoan> lichSuCacDot = [dotCapGanNhat];

  static void luuDotCap(DotCapTaiKhoan dot) {
    dotCapGanNhat = dot;
    lichSuCacDot.removeWhere((d) => d.id == dot.id);
    lichSuCacDot.insert(0, dot);
  }
}

class DanhSachTaiKhoanDaTaoScreen extends StatefulWidget {
  final String? tenKhoa;
  final String? vaiTro;
  final int? soLuong;
  final List<TaiKhoanItem>? danhSachTaiKhoan;

  const DanhSachTaiKhoanDaTaoScreen({
    super.key,
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
  late DotCapTaiKhoan _selectedBatch;

  @override
  void initState() {
    super.initState();
    if (widget.danhSachTaiKhoan != null &&
        widget.danhSachTaiKhoan!.isNotEmpty) {
      _selectedBatch = DotCapTaiKhoan(
        tenKhoa: widget.tenKhoa ?? StaffAccountStore.dotCapGanNhat.tenKhoa,
        vaiTro: widget.vaiTro ?? StaffAccountStore.dotCapGanNhat.vaiTro,
        soLuong: widget.soLuong ?? widget.danhSachTaiKhoan!.length,
        danhSachTaiKhoan: widget.danhSachTaiKhoan!,
      );
    } else {
      _selectedBatch = StaffAccountStore.dotCapGanNhat;
    }
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

  void _saoChepTatCa(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln(
      '=== DANH SÁCH TÀI KHOẢN ${_selectedBatch.vaiTro} - ${_selectedBatch.tenKhoa} ===',
    );
    buffer.writeln('Mật khẩu chung: ${StaffAccountStore.matKhauMacDinh}');
    for (int i = 0; i < _selectedBatch.danhSachTaiKhoan.length; i++) {
      final item = _selectedBatch.danhSachTaiKhoan[i];
      buffer.writeln('${i + 1}. TK: ${item.maTk} | MK: ${item.matKhau}');
    }
    _saoChep(
      context,
      buffer.toString(),
      'Đã sao chép toàn bộ danh sách tài khoản!',
    );
  }

  void _hienThiLichSuCacDot() {
    final cacDot = StaffAccountStore.lichSuCacDot;
    if (cacDot.length <= 1) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử các đợt cấp tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cacDot.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final dot = cacDot[index];
                      final isSelected = dot.id == _selectedBatch.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFF1F5F9),
                          child: Icon(
                            Icons.group_rounded,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          '${dot.soLuong} tài khoản ${dot.vaiTro}',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${dot.tenKhoa} • ${dot.thoiGian.hour.toString().padLeft(2, '0')}:${dot.thoiGian.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF0284C7),
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedBatch = dot;
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _veTrangNhanSu(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.hospitalDashboard,
        (route) => false,
        arguments: 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Header chuẩn
                _buildHeader(context),

                // Nội dung danh sách
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hộp thông báo xanh lá
                        _buildSuccessBanner(),
                        const SizedBox(height: 16),

                        // Tiêu đề & nút Sao chép tất cả
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chi tiết tài khoản & Mật khẩu',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mật khẩu khởi tạo chung: ${StaffAccountStore.matKhauMacDinh}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _saoChepTatCa(context),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Sao chép tất cả',
                                  style: TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Danh sách thẻ tài khoản
                        for (
                          int i = 0;
                          i < _selectedBatch.danhSachTaiKhoan.length;
                          i++
                        ) ...[
                          _buildAccountCard(
                            context,
                            i + 1,
                            _selectedBatch.danhSachTaiKhoan[i],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),

                // Các nút dưới đáy
                _buildBottomButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _veTrangNhanSu(context),
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
          const Text(
            'Danh Sách Tài Khoản Đã Tạo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              if (StaffAccountStore.lichSuCacDot.length > 1) ...[
                InkWell(
                  onTap: _hienThiLichSuCacDot,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đang chuẩn bị file danh sách tài khoản...',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    size: 20,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
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
                  'Đã tạo thành công ${_selectedBatch.soLuong} tài khoản',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedBatch.tenKhoa} • Vai trò: ${_selectedBatch.vaiTro}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (StaffAccountStore.lichSuCacDot.length > 1) ...[
            InkWell(
              onTap: _hienThiLichSuCacDot,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Đổi đợt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, int index, TaiKhoanItem item) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$index. ${item.maTk}',
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.trangThai,
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Mật khẩu: ',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
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
                    child: Text(
                      'Chép',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đang xuất danh sách tài khoản ra file Excel / PDF...',
                    ),
                    backgroundColor: Color(0xFF0284C7),
                  ),
                );
              },
              icon: const Icon(Icons.file_download_outlined, size: 20),
              label: const Text(
                'Xuất File / In Danh Sách',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
              onPressed: () => _veTrangNhanSu(context),
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
