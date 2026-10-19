import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'hospital_detail_screen.dart';
import 'pending_approval_screen.dart';

// ===================================================
// MÀN 10: TẤT CẢ BỆNH VIỆN (mở từ thẻ "Tổng BV")
// ===================================================
class AllHospitalsScreen extends StatefulWidget {
  final int initialSort; // 0 = mặc định, 1 = thấp→cao, 2 = cao→thấp
  const AllHospitalsScreen({super.key, this.initialSort = 0});
  @override
  State<AllHospitalsScreen> createState() => _AllHospitalsScreenState();
}

class _AllHospitalsScreenState extends State<AllHospitalsScreen> {
  String query = '';
  late int sort;

  @override
  void initState() {
    super.initState();
    sort = widget.initialSort;
    AdminStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AdminStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Widget sortChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  active ? kPrimary : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? kPrimary : Colors.grey)),
      ),
    );
  }

  Widget verifiedCard(BuildContext context, Hospital h) {
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

  Widget pendingRow(BuildContext context, Map<String, String> h) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            AvatarBox(
                text: h['tag']!,
                bg: const Color(0xFFDBEAFE),
                fg: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h['name']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${h['type']} · ${h['bs']}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: kOrangeBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('⏳ Chờ duyệt',
                        style: TextStyle(
                            fontSize: 11,
                            color: kAmber,
                            fontWeight: FontWeight.w700)),
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
    final store = AdminStore.instance;
    final q = query.trim().toLowerCase();
    final verified = store.hospitals.where((h) {
      if (q.isEmpty) return true;
      return h.name.toLowerCase().contains(q) ||
          h.initials.toLowerCase().contains(q) ||
          (h.code ?? '').toLowerCase().contains(q);
    }).toList();
    final pend = store.pending.where((h) {
      if (q.isEmpty) return true;
      return (h['name'] ?? '').toLowerCase().contains(q) ||
          (h['tag'] ?? '').toLowerCase().contains(q) ||
          (h['code'] ?? '').toLowerCase().contains(q);
    }).toList();
    if (sort == 1) {
      verified.sort((a, b) => a.rating.compareTo(b.rating));
    } else if (sort == 2) {
      verified.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BackCircle(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tất cả bệnh viện',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      Text('${store.totalBV} cơ sở trong hệ thống',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tên hoặc mã bệnh viện...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  sortChip('Mặc định', sort == 0,
                      () => setState(() => sort = 0)),
                  const SizedBox(width: 8),
                  sortChip('★ Thấp → Cao', sort == 1,
                      () => setState(() => sort = 1)),
                  const SizedBox(width: 8),
                  sortChip('★ Cao → Thấp', sort == 2,
                      () => setState(() => sort = 2)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (verified.isEmpty && pend.isEmpty)
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: const Column(
                            children: [
                              Text('🔍',
                                  style:
                                      TextStyle(fontSize: 40)),
                              SizedBox(height: 8),
                              Text('Không tìm thấy',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                  'Thử từ khóa khác nhé.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey)),
                            ],
                          ),
                        )
                      else ...[
                        if (verified.isNotEmpty) ...[
                          Text(
                              'Đã xác nhận (${verified.length})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          const SizedBox(height: 10),
                          ...verified.map((h) =>
                              verifiedCard(context, h)),
                          const SizedBox(height: 6),
                        ],
                        if (pend.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                  'Chờ duyệt (${pend.length})',
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 15)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const PendingApprovalScreen())),
                                child: const Text(
                                    'Xem tất cả',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: kPrimary,
                                        fontWeight:
                                            FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...pend.map((h) =>
                              pendingRow(context, h)),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
