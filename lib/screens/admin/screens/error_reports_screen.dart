import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ================= MÀN 7: XEM CÁC BÁO CÁO LỖI =================
class ErrorReportsScreen extends StatefulWidget {
  const ErrorReportsScreen({super.key});
  @override
  State<ErrorReportsScreen> createState() => _ErrorReportsScreenState();
}

class _ErrorReportsScreenState extends State<ErrorReportsScreen> {
  int filter = 0;

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

  Widget chip(String label, int i) {
    final bool active = filter == i;
    return GestureDetector(
      onTap: () => setState(() => filter = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? kPrimary : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? kPrimary : Colors.grey)),
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
                  const Text('Xem các báo cáo lỗi',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: kOrangeBg,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        '${AdminStore.instance.errorTotal} Lỗi',
                        style: TextStyle(
                            fontSize: 12,
                            color: kAmber,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  chip('Tất cả', 0),
                  const SizedBox(width: 8),
                  chip('Lỗi đặt lịch', 1),
                  const SizedBox(width: 8),
                  chip('Lỗi QR', 2),
                ],
              ),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                final list =
                    AdminStore.instance.filteredReports(filter);
                if (list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Column(
                      children: [
                        Text('🎉',
                            style: TextStyle(fontSize: 40)),
                        SizedBox(height: 8),
                        Text('Không có báo cáo nào',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Tất cả sự cố đã được xử lý.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: list.map((r) {
                    final bool isQR = r.kind == 'qr';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppBadge(
                                text: r.badge,
                                color: isQR ? kRed : kAmber,
                                bg: isQR
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFFEF3C7),
                              ),
                              const Spacer(),
                              Text(r.time,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(r.sender,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey)),
                          if (r.desc != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF8FAFC),
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              child: Text(r.desc!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87)),
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFE8EEF7),
                                foregroundColor:
                                    Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            10)),
                              ),
                              onPressed: () {
                                AdminStore.instance
                                    .resolveReport(r.id);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Đã xử lý báo cáo ✓')));
                              },
                              child: const Text(
                                  'Xử lý sự cố ngay',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
