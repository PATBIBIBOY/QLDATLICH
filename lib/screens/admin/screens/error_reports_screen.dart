import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ================= MÀN 7: XEM CÁC BÁO CÁO LỖI & SỰ CỐ =================
class ErrorReportsScreen extends StatefulWidget {
  final bool isEmbedded;
  const ErrorReportsScreen({super.key, this.isEmbedded = false});

  @override
  State<ErrorReportsScreen> createState() => _ErrorReportsScreenState();
}

class _ErrorReportsScreenState extends State<ErrorReportsScreen> {
  int _filter = 0; // 0 = tất cả, 1 = đặt lịch, 2 = qr

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

  Widget _buildChip(String label, int index, IconData icon) {
    final bool active = _filter == index;
    return GestureDetector(
      onTap: () => setState(() => _filter = index),
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
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? Colors.white : kSlate500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : kSlate600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ErrorReport r) {
    final bool isQR = r.kind == 'qr';
    final Color badgeColor = isQR ? kRed : kOrange;
    final Color badgeBg = isQR ? kRedBg : kOrangeBg;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isQR ? Icons.qr_code_scanner_rounded : Icons.calendar_today_rounded,
                  size: 16,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                text: r.badge,
                color: badgeColor,
                bg: badgeBg,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: kSlate400),
                  const SizedBox(width: 4),
                  Text(
                    r.time,
                    style: const TextStyle(fontSize: 11, color: kSlate400, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: kSlate900,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: kSlate400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  r.sender,
                  style: const TextStyle(fontSize: 12, color: kSlate500),
                ),
              ),
            ],
          ),
          if (r.desc != null && r.desc!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                r.desc!,
                style: const TextStyle(fontSize: 12.5, color: kSlate800, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              label: const Text(
                'Đã xử lý & Đóng sự cố',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreenLight,
                foregroundColor: kGreen,
                elevation: 0,
                side: BorderSide(color: kGreen.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                AdminStore.instance.resolveReport(r.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật giải quyết xong sự cố: ${r.title}'),
                    backgroundColor: kGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final list = store.filteredReports(_filter);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              'Báo Cáo Sự Cố & Khiếu Nại',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: kSlate900,
                              ),
                            ),
                            Text(
                              '${store.reports.length} sự cố đang chờ phản hồi trên Firebase',
                              style: const TextStyle(fontSize: 12, color: kSlate500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kRedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${store.reports.length} Cần sửa',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: kRed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip('Tất cả (${store.reports.length})', 0, Icons.list_alt_rounded),
                      const SizedBox(width: 8),
                      _buildChip('Lỗi đặt lịch', 1, Icons.calendar_month_rounded),
                      const SizedBox(width: 8),
                      _buildChip('Lỗi QR Check-in', 2, Icons.qr_code_scanner_rounded),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: kGreenLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 44, color: kGreen),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Hệ thống đang hoạt động ổn định',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: kSlate900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Không còn báo cáo sự cố chưa xử lý trong danh mục này.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: kSlate500),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(context, list[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
