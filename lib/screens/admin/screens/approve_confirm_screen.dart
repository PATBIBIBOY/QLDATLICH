import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ================= MÀN 8: XÁC NHẬN DUYỆT =================
class ApproveConfirmScreen extends StatelessWidget {
  final Map<String, String> hospital;
  const ApproveConfirmScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  BackCircle(),
                  SizedBox(width: 12),
                  Text('Xác nhận duyệt',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                          color: kGreenBg, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.check, color: kGreen, size: 44),
                    ),
                    const SizedBox(height: 14),
                    const Text('Xác nhận duyệt bệnh viện?',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 8),
                    const Text(
                        'Bệnh viện sẽ được thêm vào hệ thống\nvà cấp tài khoản để bắt đầu hoạt động.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          AvatarBox(
                              text: hospital['tag']!,
                              bg: const Color(0xFFDBEAFE),
                              fg: kPrimary,
                              size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(hospital['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                Text(
                                    '${hospital['type']} · ${hospital['bs']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey)),
                                Text('Mã số: ${hospital['code']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
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
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          AdminStore.instance
                              .approveHospital(hospital);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Đã duyệt ${hospital['name']} ✓'),
                                  backgroundColor: kGreen));
                        },
                        child: const Text('✓ Xác nhận duyệt',
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
