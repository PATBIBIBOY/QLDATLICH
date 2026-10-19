import 'package:flutter/material.dart';

import 'CapTK_Scream.dart';
import 'danhSachTaiKhoanDaTao_Screen.dart';

class NhanVienModel {
  final String id;
  final String hoTen;
  final String maNv;
  final String vaiTro;
  final String khoa;
  final String soDienThoai;
  final String email;
  final bool dangHoatDong;

  const NhanVienModel({
    required this.id,
    required this.hoTen,
    required this.maNv,
    required this.vaiTro,
    required this.khoa,
    required this.soDienThoai,
    required this.email,
    this.dangHoatDong = true,
  });
}

class NhanSuScreen extends StatefulWidget {
  final bool isTab;
  const NhanSuScreen({super.key, this.isTab = true});

  @override
  State<NhanSuScreen> createState() => _NhanSuScreenState();
}

class _NhanSuScreenState extends State<NhanSuScreen> {
  String _tuKhoa = '';
  String _filterRole = 'Tất cả';

  // Danh sách dữ liệu nhân sự mẫu (Hardcode đẹp chuẩn bị sẵn kết nối Firebase)
  final List<NhanVienModel> _danhSachNhanSu = const [
    NhanVienModel(
      id: '1',
      hoTen: 'Trần Thị Mai',
      maNv: 'LT_TM_01',
      vaiTro: 'Lễ tân',
      khoa: 'Khoa Tim Mạch',
      soDienThoai: '0908 123 456',
      email: 'mai.tran@benhvien.vn',
      dangHoatDong: true,
    ),
    NhanVienModel(
      id: '2',
      hoTen: 'Nguyễn Văn An',
      maNv: 'LT_TM_02',
      vaiTro: 'Lễ tân',
      khoa: 'Khoa Tim Mạch',
      soDienThoai: '0912 345 678',
      email: 'an.nguyen@benhvien.vn',
      dangHoatDong: true,
    ),
    NhanVienModel(
      id: '3',
      hoTen: 'Lê Hoàng Đức',
      maNv: 'BS_MT_01',
      vaiTro: 'Hỗ trợ bác sĩ',
      khoa: 'Khoa Mắt',
      soDienThoai: '0933 221 100',
      email: 'duc.le@benhvien.vn',
      dangHoatDong: true,
    ),
    NhanVienModel(
      id: '4',
      hoTen: 'Phạm Thanh Hằng',
      maNv: 'BS_NH_01',
      vaiTro: 'Hỗ trợ bác sĩ',
      khoa: 'Khoa Nhi',
      soDienThoai: '0988 776 655',
      email: 'hang.pham@benhvien.vn',
      dangHoatDong: true,
    ),
    NhanVienModel(
      id: '5',
      hoTen: 'Võ Quốc Huy',
      maNv: 'SP_CS_01',
      vaiTro: 'Support',
      khoa: 'Khoa Tiếp Đón',
      soDienThoai: '0977 112 233',
      email: 'huy.vo@benhvien.vn',
      dangHoatDong: true,
    ),
    NhanVienModel(
      id: '6',
      hoTen: 'Đặng Thùy Trang',
      maNv: 'LT_MT_01',
      vaiTro: 'Lễ tân',
      khoa: 'Khoa Mắt',
      soDienThoai: '0944 556 677',
      email: 'trang.dang@benhvien.vn',
      dangHoatDong: false,
    ),
  ];

  List<NhanVienModel> get _filteredList {
    return _danhSachNhanSu.where((nv) {
      final matchKeyword = nv.hoTen.toLowerCase().contains(_tuKhoa) ||
          nv.maNv.toLowerCase().contains(_tuKhoa) ||
          nv.khoa.toLowerCase().contains(_tuKhoa);
      final matchRole = _filterRole == 'Tất cả' || nv.vaiTro == _filterRole;
      return matchKeyword && matchRole;
    }).toList();
  }

  Color _getRoleBgColor(String vaiTro) {
    switch (vaiTro) {
      case 'Lễ tân':
        return const Color(0xFFE0F2FE);
      case 'Hỗ trợ bác sĩ':
        return const Color(0xFFDCFCE7);
      case 'Support':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getRoleTextColor(String vaiTro) {
    switch (vaiTro) {
      case 'Lễ tân':
        return const Color(0xFF0284C7);
      case 'Hỗ trợ bác sĩ':
        return const Color(0xFF16A34A);
      case 'Support':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        // 1. Thống kê nhanh & Nút cấp tài khoản
        _buildTopActions(context),

        // 2. Ô tìm kiếm & Bộ lọc vai trò
        _buildSearchAndFilters(),

        // 3. Danh sách nhân sự
        Expanded(
          child: _filteredList.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: _filteredList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildStaffCard(_filteredList[i]),
                ),
        ),
      ],
    );

    if (widget.isTab) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Quản lý nhân sự',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: bodyContent,
    );
  }

  Widget _buildTopActions(BuildContext context) {
    final tongNv = _danhSachNhanSu.length;
    final leTanCount = _danhSachNhanSu.where((e) => e.vaiTro == 'Lễ tân').length;
    final bsCount = _danhSachNhanSu.where((e) => e.vaiTro == 'Hỗ trợ bác sĩ').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Thẻ tóm tắt số liệu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tổng nhân sự', '$tongNv', const Color(0xFF0F172A)),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                _buildStatItem('Lễ tân', '$leTanCount', const Color(0xFF0284C7)),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                _buildStatItem('Hỗ trợ BS', '$bsCount', const Color(0xFF16A34A)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // CẶP NÚT HÀNH ĐỘNG: CẤP TÀI KHOẢN & XEM TK VỪA TẠO
          Row(
            children: [
              Expanded(
                flex: 11,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CapTaiKhoanNhanVienScreen(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text(
                      'Cấp Tài Khoản',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DanhSachTaiKhoanDaTaoScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.vpn_key_rounded, size: 17, color: Color(0xFF16A34A)),
                    label: const Text(
                      'Xem TK Vừa Tạo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      side: const BorderSide(color: Color(0xFF86EFAC), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // THẺ THÔNG BÁO ĐỢT CẤP TÀI KHOẢN GẦN NHẤT
          _buildRecentBatchCard(context),
        ],
      ),
    );
  }

  Widget _buildRecentBatchCard(BuildContext context) {
    final batch = StaffAccountStore.dotCapGanNhat;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DanhSachTaiKhoanDaTaoScreen(
              tenKhoa: batch.tenKhoa,
              vaiTro: batch.vaiTro,
              soLuong: batch.soLuong,
              danhSachTaiKhoan: batch.danhSachTaiKhoan,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Đợt vừa tạo',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${batch.soLuong} TK',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${batch.vaiTro} • ${batch.tenKhoa}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Chạm để xem mã đăng nhập & mật khẩu',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Ô tìm kiếm
          TextField(
            onChanged: (v) => setState(() => _tuKhoa = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, mã NV hoặc khoa...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            ),
          ),
          const SizedBox(height: 8),

          // Thanh lọc vai trò
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                'Tất cả',
                'Lễ tân',
                'Hỗ trợ bác sĩ',
                'Support',
              ].map((role) {
                final isSelected = _filterRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filterRole = role),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(NhanVienModel nv) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getRoleBgColor(nv.vaiTro),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              nv.hoTen.isNotEmpty ? nv.hoTen.split(' ').last[0] : 'NV',
              style: TextStyle(
                color: _getRoleTextColor(nv.vaiTro),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin nhân sự
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nv.hoTen,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getRoleBgColor(nv.vaiTro),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        nv.vaiTro,
                        style: TextStyle(
                          color: _getRoleTextColor(nv.vaiTro),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      nv.maNv,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nv.khoa,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'SĐT: ${nv.soDienThoai}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Không tìm thấy nhân sự phù hợp',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}
