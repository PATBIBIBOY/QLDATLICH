import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'approve_confirm_screen.dart';
import 'reject_screen.dart';

// ================= MÀN 6: BỆNH VIỆN CHỜ DUYỆT =================
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});
  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
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

  Widget pendingCard(BuildContext context, Map<String, String> h) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBox(
                  text: h['tag']!,
                  bg: const Color(0xFFDBEAFE),
                  fg: kPrimary,
                  size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h['name']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${h['type']} · ${h['bs']}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: kOrangeBg, borderRadius: BorderRadius.circular(20)),
            child: const Text('⏳ Chờ duyệt',
                style: TextStyle(
                    fontSize: 11,
                    color: kAmber,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          Text(h['time']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ApproveConfirmScreen(hospital: h))),
                    child: const Text('✓ Duyệt',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kRed,
                      side: const BorderSide(color: kRed, width: 1.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RejectScreen(hospital: h))),
                    child: const Text('✕ Từ chối',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                      const Text('Bệnh viện chờ duyệt',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(
                          '${AdminStore.instance.pendingTotal} bệnh viện đang chờ xác nhận',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: kOrangeBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    'Chờ duyệt · ${AdminStore.instance.pendingText}',
                    style: TextStyle(
                        fontSize: 12,
                        color: kAmber,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              if (AdminStore.instance.pending.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    children: [
                      Text('🎉',
                          style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('Đã xử lý hết!',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Không còn bệnh viện chờ duyệt.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...AdminStore.instance.pending
                    .map((h) => pendingCard(context, h)),
            ],
          ),
        ),
      ),
    );
  }
}
