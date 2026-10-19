import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';
import 'review_screen.dart';
import 'edit_hospital_screen.dart';

// ================= MÀN 2: CHI TIẾT BỆNH VIỆN =================
class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;
  const HospitalDetailScreen({super.key, required this.hospital});
  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
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

  Widget deptRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text('♥  $text',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospital = widget.hospital;
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
                  const Text('Chi tiết bệnh viện',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: kGreenBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Hoạt động',
                        style: TextStyle(
                            fontSize: 12,
                            color: kGreen,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditHospitalScreen(hospital: hospital))),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit,
                          size: 18, color: kPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    AvatarBox(
                        text: hospital.initials,
                        bg: hospital.avatarBg,
                        fg: hospital.avatarText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hospital.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                              '${hospital.type} · ★ ${hospital.rating} · Xác thực uy tín',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                              hospital.address ??
                                  '78 Giải Phóng, Đống Đa, Hà Nội',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('DANH SÁCH KHOA TRỰC THUỘC',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey)),
              const SizedBox(height: 10),
              deptRow('Khoa Tim Mạch · 18 BS'),
              deptRow('Khoa Nhi Tiêu Hóa · 24 BS'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary, width: 1.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ReviewScreen(hospital: hospital))),
                  child: const Text('Xem đánh giá bệnh viện',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                            const Text('Xóa bệnh viện?'),
                        content: Text(
                            '${hospital.name} sẽ bị gỡ khỏi hệ thống cùng toàn bộ lịch đặt khám.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child:
                                  const Text('Hủy bỏ')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kRed,
                                foregroundColor:
                                    Colors.white),
                            onPressed: () {
                              AdminStore.instance
                                  .unpartnerHospital(
                                      hospital);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              messenger.showSnackBar(SnackBar(
                                  content: Text(
                                      'Đã xóa ${hospital.name} khỏi hệ thống')));
                            },
                            child:
                                const Text('Xác nhận Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Xóa bệnh viện',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
