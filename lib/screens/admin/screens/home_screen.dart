import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'hospital_detail_screen.dart';
import 'pending_approval_screen.dart';
import 'error_reports_screen.dart';
import 'all_hospitals_screen.dart';

// ================= MÀN 1: TRANG CHỦ QUẢN TRỊ VIÊN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllViolations = false;

  @override
  void initState() {
    super.initState();
    AdminStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AdminStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String doneMessage,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(message, style: const TextStyle(color: kSlate600, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy bỏ', style: TextStyle(color: kSlate600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(doneMessage), backgroundColor: kSlate900),
              );
            },
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: kSlate400),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: kSlate900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: kSlate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Hospital h) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)),
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            AvatarBox(
              text: h.initials,
              bg: h.avatarBg,
              fg: h.avatarText,
              size: 48,
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
                      const Icon(Icons.check_circle_rounded, size: 14, color: kGreen),
                      const SizedBox(width: 3),
                      const Text(
                        'Đã duyệt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kGreen,
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

  Widget _buildLowRatedRow(Hospital h) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEE2E2)),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            AvatarBox(
              text: h.initials,
              bg: const Color(0xFFFEE2E2),
              fg: kRed,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kSlate900),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${h.type} · ',
                        style: const TextStyle(fontSize: 11.5, color: kSlate500),
                      ),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEF4444)),
                      Text(
                        ' ${h.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: kRedBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Cần rà soát',
                          style: TextStyle(fontSize: 10, color: kRed, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: kRed, size: 20),
              tooltip: 'Ngừng hợp tác',
              onPressed: () => _confirmDelete(
                title: 'Ngừng hợp tác bệnh viện?',
                message: '${h.name} sẽ bị tạm ngừng hợp tác và ẩn khỏi hệ thống đặt lịch.',
                onConfirm: () => AdminStore.instance.unpartnerHospital(h),
                doneMessage: 'Đã tạm dừng hợp tác với ${h.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationCard(Map<String, String> v) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: kRedBg, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded, color: kRed, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  v['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kRed,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kRedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  v['complaints'] ?? '',
                  style: const TextStyle(fontSize: 10.5, color: kRed, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            v['reason'] ?? '',
            style: const TextStyle(fontSize: 12, color: kSlate600, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            v['location'] ?? '',
            style: const TextStyle(fontSize: 11, color: kSlate400),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.block, size: 16),
              label: const Text('Khóa & Xóa cơ sở này', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _confirmDelete(
                title: 'Khóa cơ sở y tế vi phạm?',
                message: 'Tài khoản và hồ sơ của ${v['name']} sẽ bị khóa ngay lập tức.',
                onConfirm: () => AdminStore.instance.deleteViolation(v),
                doneMessage: 'Đã khóa cơ sở vi phạm thành công',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await AdminStore.instance.syncNow();
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============ TOP BAR ============
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CỔNG QUẢN TRỊ Y TẾ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: kPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Mediconnect Admin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: kSlate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LiveSyncBadge(),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ErrorReportsScreen()),
                    ),
                    child: BellButton(count: store.reports.length),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ============ HERO BANNER ============
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Quản Trị Hệ Thống Toàn Diện',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const HeroRealtimeBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Xin chào Quản trị viên 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hệ thống đang quản lý ${store.totalBV} bệnh viện và tiếp nhận ${store.pendingTotal} hồ sơ chờ duyệt.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        label: Text(
                          'Duyệt ${store.pendingTotal} hồ sơ mới ngay',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: kPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ============ 3 THẺ THỐNG KÊ NHANH ============
              Row(
                children: [
                  _buildStatCard(
                    count: store.totalBVText,
                    label: 'Tổng BV',
                    subtitle: 'Cơ sở y tế',
                    icon: Icons.local_hospital_rounded,
                    color: kPrimary,
                    bgColor: kPrimaryLight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllHospitalsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    count: store.pendingText,
                    label: 'Chờ duyệt',
                    subtitle: 'Hồ sơ BYT',
                    icon: Icons.hourglass_top_rounded,
                    color: kAmber,
                    bgColor: kOrangeBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    count: store.errorText,
                    label: 'Báo lỗi',
                    subtitle: 'Sự cố cần sửa',
                    icon: Icons.bug_report_rounded,
                    color: kRed,
                    bgColor: kRedBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ErrorReportsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ============ DANH SÁCH BỆNH VIỆN TIÊU BIỂU ============
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cơ sở y tế trong hệ thống',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: kSlate900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllHospitalsScreen()),
                    ),
                    child: const Text(
                      'Xem tất cả →',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: kPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...store.hospitals.take(4).map((h) => _buildHospitalCard(context, h)),

              const SizedBox(height: 14),

              // ============ BỆNH VIỆN CÓ ĐÁNH GIÁ THẤP ============
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Cần kiểm định chất lượng',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: kSlate900,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllHospitalsScreen(initialSort: 1),
                      ),
                    ),
                    child: const Text(
                      'Lọc theo sao',
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Builder(builder: (context) {
                final lowest = ([...store.hospitals]
                      ..sort((a, b) => a.rating.compareTo(b.rating)))
                    .take(3)
                    .toList();
                return Column(
                  children: lowest.map((h) => _buildLowRatedRow(h)).toList(),
                );
              }),

              // ============ CƠ SỞ VI PHẠM (NẾU CÓ) ============
              if (store.violations.isNotEmpty) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: kRed, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Hồ sơ vi phạm quy chế (${store.violations.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: kRed,
                      ),
                    ),
                    const Spacer(),
                    if (store.violations.length > 2)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllViolations = !_showAllViolations;
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              _showAllViolations ? 'Thu gọn' : 'Xem tất cả',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: kRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _showAllViolations
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: kRed,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...(_showAllViolations
                        ? store.violations
                        : store.violations.take(2))
                    .map(_buildViolationCard),
                if (store.violations.length > 2) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _showAllViolations
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.visibility_rounded,
                        size: 16,
                        color: kRed,
                      ),
                      label: Text(
                        _showAllViolations
                            ? 'Thu gọn danh sách vi phạm'
                            : 'Xem tất cả ${store.violations.length} hồ sơ vi phạm',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kRed,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFFECACA), width: 1.2),
                        backgroundColor: const Color(0xFFFFF5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllViolations = !_showAllViolations;
                        });
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
