import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ================= MÀN 3: ĐÁNH GIÁ BỆNH VIỆN =================
class ReviewScreen extends StatelessWidget {
  final Hospital hospital;
  const ReviewScreen({super.key, required this.hospital});

  Widget reviewCard(String name, String content, String date, String dept) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              const Text('★★★★★',
                  style: TextStyle(color: kOrange, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text('$date · $dept',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              const Row(
                children: [
                  BackCircle(),
                  SizedBox(width: 12),
                  Text('Đánh giá bệnh viện',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    AvatarBox(
                        text: hospital.initials,
                        bg: hospital.avatarBg,
                        fg: hospital.avatarText,
                        size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hospital.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('★★★★★ 4.9 (1.248 đánh giá)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: kAmber,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: kGreenLight,
                    borderRadius: BorderRadius.circular(14)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng quan đánh giá',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    SizedBox(height: 6),
                    Text('Chất lượng khám: 4.9 · Thái độ NV: 4.8',
                        style: TextStyle(fontSize: 12)),
                    SizedBox(height: 2),
                    Text('Cơ sở vật chất: 4.7 · Thời gian chờ: 4.6',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Đánh giá gần đây',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              reviewCard(
                  'Nguyễn Văn A',
                  'Bác sĩ tận tâm, khám nhanh, giải thích rõ ràng. Rất hài lòng!',
                  '18/09/2026',
                  'Khoa Tim mạch'),
              reviewCard(
                  'Trần Thị Bích',
                  'Chờ hơi lâu nhưng bác sĩ khám kỹ, kết quả chính xác.',
                  '17/09/2026',
                  'Khoa Nội'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kRed,
                          side: const BorderSide(color: kRed, width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final messenger =
                              ScaffoldMessenger.of(context);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              title:
                                  const Text('Xóa hợp tác?'),
                              content: Text(
                                  'Ngừng hợp tác với ${hospital.name}? Bệnh viện sẽ bị gỡ khỏi hệ thống.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text('Hủy')),
                                ElevatedButton(
                                  style:
                                      ElevatedButton.styleFrom(
                                          backgroundColor: kRed,
                                          foregroundColor:
                                              Colors.white),
                                  onPressed: () {
                                    AdminStore.instance
                                        .unpartnerHospital(hospital);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    messenger.showSnackBar(SnackBar(
                                        content: Text(
                                            'Đã xóa hợp tác với ${hospital.name}')));
                                  },
                                  child:
                                      const Text('Xóa hợp tác'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Xóa hợp tác',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tiếp tục hợp tác ✓')));
                        },
                        child: const Text('Tiếp tục hợp tác',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('Xem tất cả đánh giá'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
