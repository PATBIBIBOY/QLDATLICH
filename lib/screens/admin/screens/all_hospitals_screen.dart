import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'hospital_detail_screen.dart';
import 'pending_approval_screen.dart';

// ===================================================
// MÀN 10: TẤT CẢ BỆNH VIỆN TRONG HỆ THỐNG
// ===================================================
class AllHospitalsScreen extends StatefulWidget {
  final int initialSort; // 0 = mặc định, 1 = thấp→cao, 2 = cao→thấp
  final bool isEmbedded; // Khi hiển thị trong Tab của MainShell

  const AllHospitalsScreen({
    super.key,
    this.initialSort = 0,
    this.isEmbedded = false,
  });

  @override
  State<AllHospitalsScreen> createState() => _AllHospitalsScreenState();
}

class _AllHospitalsScreenState extends State<AllHospitalsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  late int _sort;
  String _selectedType = 'all'; // 'all', 'Công lập', 'Tư nhân'

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    AdminStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AdminStore.instance.removeListener(_refresh);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _buildFilterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? kPrimary : kBorder,
            width: 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : kCardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : kSlate600,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalItem(BuildContext context, Hospital h) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            AvatarBox(
              text: h.initials,
              bg: h.avatarBg,
              fg: h.avatarText,
              size: 46,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: kSlate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: h.type == 'Công lập' ? kPrimaryLight : kOrangeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          h.type,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: h.type == 'Công lập' ? kPrimary : kAmber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        h.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kSlate800,
                        ),
                      ),
                      if (h.totalReviews != null && h.totalReviews! > 0)
                        Text(
                          ' (${h.totalReviews})',
                          style: const TextStyle(fontSize: 11, color: kSlate400),
                        ),
                      const Spacer(),
                      Icon(
                        h.isBlocked
                            ? Icons.lock_person_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: h.isBlocked ? kRed : kGreen,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        h.isBlocked ? 'Bị chặn' : 'Hoạt động',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: h.isBlocked ? kRed : kGreen,
                        ),
                      ),
                    ],
                  ),
                  if (h.address != null && h.address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: kSlate400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            h.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: kSlate500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kSlate400, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final q = _query.trim().toLowerCase();

    // 1. Lọc theo từ khóa
    List<Hospital> filtered = store.hospitals.where((h) {
      if (q.isEmpty) return true;
      final matchName = h.name.toLowerCase().contains(q);
      final matchInitials = h.initials.toLowerCase().contains(q);
      final matchCode = (h.code ?? '').toLowerCase().contains(q);
      final matchAddress = (h.address ?? '').toLowerCase().contains(q);
      return matchName || matchInitials || matchCode || matchAddress;
    }).toList();

    // 2. Lọc theo loại hình
    if (_selectedType != 'all') {
      filtered = filtered.where((h) => h.type.contains(_selectedType)).toList();
    }

    // 3. Sắp xếp
    if (_sort == 1) {
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
    } else if (_sort == 2) {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ============ HEADER ============
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (!widget.isEmbedded) ...[
                        const BackCircle(),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danh Sách Bệnh Viện',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: kSlate900,
                              ),
                            ),
                            Text(
                              '${store.totalBV} cơ sở y tế đang kết nối Firebase',
                              style: const TextStyle(fontSize: 12, color: kSlate500),
                            ),
                          ],
                        ),
                      ),
                      const LiveSyncBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Thanh tìm kiếm
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: kSlate400),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            style: const TextStyle(fontSize: 13.5, color: kSlate900),
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo tên, địa chỉ, mã bệnh viện...',
                              hintStyle: TextStyle(fontSize: 13, color: kSlate400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.cancel_rounded, size: 18, color: kSlate400),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chip bộ lọc
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả (${store.totalBV})', _selectedType == 'all', () {
                          setState(() => _selectedType = 'all');
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Công lập', _selectedType == 'Công lập', () {
                          setState(() => _selectedType = 'Công lập');
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('Tư nhân', _selectedType == 'Tư nhân', () {
                          setState(() => _selectedType = 'Tư nhân');
                        }),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 20, color: kBorder),
                        const SizedBox(width: 8),
                        _buildFilterChip('★ Cao nhất', _sort == 2, () {
                          setState(() => _sort = (_sort == 2 ? 0 : 2));
                        }),
                        const SizedBox(width: 8),
                        _buildFilterChip('★ Thấp nhất', _sort == 1, () {
                          setState(() => _sort = (_sort == 1 ? 0 : 1));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============ KẾT QUẢ DANH SÁCH ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Hiển thị ${filtered.length} kết quả',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: kSlate600,
                    ),
                  ),
                  if (store.pendingTotal > 0) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pending_actions, size: 14, color: kAmber),
                          const SizedBox(width: 4),
                          Text(
                            '${store.pendingTotal} chờ duyệt',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 36, color: kPrimary),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Không tìm thấy bệnh viện phù hợp',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kSlate900),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hãy thử thay đổi từ khóa hoặc bộ lọc tìm kiếm',
                            style: TextStyle(fontSize: 13, color: kSlate500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildHospitalItem(context, filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
