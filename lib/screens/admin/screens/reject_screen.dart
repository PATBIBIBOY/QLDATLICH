import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ================= MÀN 9: TỪ CHỐI DUYỆT =================
class RejectScreen extends StatefulWidget {
  final Map<String, String> hospital;
  const RejectScreen({super.key, required this.hospital});
  @override
  State<RejectScreen> createState() => _RejectScreenState();
}

class _RejectScreenState extends State<RejectScreen> {
  int selected = 0;
  final reasons = [
    'Thiếu giấy phép hoạt động',
    'Thông tin chưa đầy đủ',
    'Không đạt tiêu chuẩn',
    'Trùng bệnh viện đã có',
  ];
  final ctrl = TextEditingController(
      text:
          'Giấy phép hoạt động đã hết hạn từ 01/2026. Vui lòng bổ sung giấy phép mới trước khi gửi lại yêu cầu.');

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
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
              const Row(
                children: [
                  BackCircle(),
                  SizedBox(width: 12),
                  Text('Từ chối duyệt',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    AvatarBox(
                        text: widget.hospital['tag']!,
                        bg: const Color(0xFFDBEAFE),
                        fg: kPrimary,
                        size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.hospital['name']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(
                              '${widget.hospital['type']} · ${widget.hospital['bs']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
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
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Text('!',
                          style: TextStyle(
                              color: kRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 24)),
                    ),
                    SizedBox(height: 10),
                    Text('Vui lòng chọn lý do từ chối',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Lý do sẽ được gửi đến bệnh viện',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(reasons.length, (i) {
                  final bool active = i == selected;
                  return GestureDetector(
                    onTap: () => setState(() => selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? kRedBg : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active
                                ? kRed
                                : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(reasons[i],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? kRed : Colors.black87)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('GHI CHÚ CHI TIẾT (TÙY CHỌN)',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRed, width: 1.2),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: ctrl,
                      maxLines: 3,
                      maxLength: 300,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Text('98/300',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '⚠ Bệnh viện sẽ nhận được lý do này và có thể gửi lại yêu cầu sau khi khắc phục.',
                style: TextStyle(fontSize: 11, color: kRed),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          AdminStore.instance.rejectHospital(
                              widget.hospital);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Đã từ chối ${widget.hospital['name']}'),
                                  backgroundColor: kRed));
                        },
                        child: const Text('✕ Gửi từ chối',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
