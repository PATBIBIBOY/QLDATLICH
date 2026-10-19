import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'hospital_detail_screen.dart';
import 'pending_approval_screen.dart';
import 'error_reports_screen.dart';
import 'all_hospitals_screen.dart';

// ================= MÀN 1: TRANG CHỦ =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _refresh() => setState(() {});

  void _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String doneMessage,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy bỏ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(doneMessage)));
            },
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );
  }

  Widget lowRatedRow(Hospital h) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HospitalDetailScreen(hospital: h))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            AvatarBox(
                text: h.initials,
                bg: h.avatarBg,
                fg: h.avatarText,
                size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${h.type} · ${h.doctors} bác sĩ',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('★ ${h.rating}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: kAmber,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            InkWell(
              onTap: () => _confirmDelete(
                title: 'Xác nhận xóa bệnh viện?',
                message:
                    '${h.name} sẽ bị gỡ khỏi hệ thống cùng toàn bộ lịch đặt khám.',
                onConfirm: () =>
                    AdminStore.instance.unpartnerHospital(h),
                doneMessage:
                    'Đã xóa ${h.name} khỏi hệ thống',
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: kRedBg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline,
                    size: 20, color: kRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget violationMiniCard(Map<String, String> v) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kRedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kRed,
                        fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(v['complaints'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: kRed,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(v['location'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _confirmDelete(
                title: 'Xác nhận xóa bệnh viện?',
                message:
                    'Toàn bộ tài khoản và danh sách đặt lịch của ${v['name']} sẽ bị hủy ngay lập tức.',
                onConfirm: () =>
                    AdminStore.instance.deleteViolation(v),
                doneMessage:
                    'Đã xóa ${v['name']} khỏi hệ thống',
              ),
              child: const Text('Xóa cơ sở này',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard(
      String num, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(num,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget hospitalCard(BuildContext context, Hospital h) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HospitalDetailScreen(hospital: h))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            AvatarBox(text: h.initials, bg: h.avatarBg, fg: h.avatarText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${h.type} · ★ ${h.rating} · ${h.doctors} bác sĩ',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 13, color: kGreen),
                      SizedBox(width: 4),
                      Text('Đã xác nhận',
                          style: TextStyle(
                              fontSize: 12,
                              color: kGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chào mừng admin',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 2),
                    Text('Quản trị viên Admin 👋',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ErrorReportsScreen())),
                  child: const BellButton(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                statCard(AdminStore.instance.totalBVText, 'Tổng BV',
                    kPrimary, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllHospitalsScreen()));
                }),
                const SizedBox(width: 12),
                statCard(AdminStore.instance.pendingText, 'Chờ duyệt',
                    Colors.black87, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PendingApprovalScreen()));
                }),
                const SizedBox(width: 12),
                statCard(AdminStore.instance.errorText, 'Báo lỗi', kRed,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ErrorReportsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('Listview các bệnh viện',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllHospitalsScreen())),
                  child: const Text('Nhấn vào xem chi tiết',
                      style: TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AdminStore.instance.hospitals.take(4).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: hospitalCard(context, h),
                )),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PendingApprovalScreen())),
                child: const Text('Duyệt bệnh viện',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                    width: 90,
                    height: 22,
                    decoration: BoxDecoration(
                        color: kGreenBg,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(width: 12),
                Container(
                    width: 110,
                    height: 22,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('⚠️ Bệnh viện đánh giá thấp',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AllHospitalsScreen(
                                  initialSort: 1))),
                  child: const Text('Xem tất cả',
                      style: TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final lowest =
                  ([...AdminStore.instance.hospitals]
                        ..sort((a, b) =>
                            a.rating.compareTo(b.rating)))
                      .take(5)
                      .toList();
              return Column(
                children:
                    lowest.map((h) => lowRatedRow(h)).toList(),
              );
            }),
            if (AdminStore.instance.violations.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                  '🚨 Cơ sở vi phạm (${AdminStore.instance.violations.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 10),
              ...AdminStore.instance.violations
                  .map(violationMiniCard),
            ],
          ],
        ),
      ),
    );
  }
}
