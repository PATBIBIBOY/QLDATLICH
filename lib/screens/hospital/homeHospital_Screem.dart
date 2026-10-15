import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qldatlich/services/benhVien_service.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import 'listKhoaDieuTri.dart';

/// 1240 -> "1,240"
String _soCoDauPhay(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// "Bệnh Viện Đa Khoa TW" -> "BV"
String _chuVietTat(String ten) {
  final tu = ten.split(' ').where((e) => e.isNotEmpty).toList();
  if (tu.isEmpty) return 'BV';
  return tu.take(2).map((e) => e[0].toUpperCase()).join();
}

class HomeHospitalScreen extends StatefulWidget {
  const HomeHospitalScreen({super.key});

  @override
  State<HomeHospitalScreen> createState() => _HomeHospitalScreenState();
}

class _HomeHospitalScreenState extends State<HomeHospitalScreen> {
  // Chỉ tải tên bệnh viện một lần khi mở màn hình
  late final Future<String> _tenBenhVien = BenhVienService.layTen(
    AppSession.benhVienId,
  );

  void _moTatCaKhoa() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TatCaKhoaScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF5F7FB),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ===== Header: tên bệnh viện theo ID =====
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  child: FutureBuilder<String>(
                    future: _tenBenhVien,
                    builder: (context, snap) {
                      final dangTai =
                          snap.connectionState != ConnectionState.done;
                      final ten = snap.data ?? '';
                      final hienThi = dangTai
                          ? 'Đang tải...'
                          : (ten.isEmpty ? 'Bệnh viện' : ten);
                      return Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C7CC8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              dangTai ? 'BV' : _chuVietTat(hienThi),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BAN QUẢN LÝ',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  hienThi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF1F2937),
                              size: 20,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ===== 2 thẻ thống kê =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      // Tổng số khoa + khoa mới tháng này (đếm từ Firestore)
                      const Expanded(child: TongSoKhoaCard()),
                      const SizedBox(width: 12),
                      // Bệnh nhân hôm nay (đọc từ ThongKe/{id}/danh_sach/{ngày})
                      Expanded(
                        child:
                            StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: BenhVienService.thongKeHomNay(
                                AppSession.benhVienId,
                              ),
                              builder: (context, snap) {
                                final d = snap.data?.data();
                                final tong = ((d?['tongBenhNhan'] ?? 0) as num)
                                    .toInt();
                                final dang = ((d?['dangKham'] ?? 0) as num)
                                    .toInt();
                                return _StatCard(
                                  label: 'Bệnh nhân hôm nay',
                                  value: _soCoDauPhay(tong),
                                  subText: 'Đang khám: $dang lượt',
                                  primaryColor: const Color(0xFF1D89D1),
                                  secondaryColor: const Color(0xFF1E79C2),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ===== Nút thêm khoa =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.addClinic);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E87D8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Thêm Khoa Khám Mới',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ===== Danh sách khoa (có "Xem tất cả") =====
                const Expanded(child: ListKhoaDieuTri()),

                // ===== Thanh điều hướng dưới =====
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const _BottomNavItem(
                        icon: Icons.home_rounded,
                        label: 'Trang chủ',
                        active: true,
                      ),
                      _BottomNavItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Khoa khám',
                        active: false,
                        onTap: _moTatCaKhoa,
                      ),
                      const _BottomNavItem(
                        icon: Icons.people_alt_rounded,
                        label: 'Nhân viên',
                        active: false,
                      ),
                      const _BottomNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Cài đặt',
                        active: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subText,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String label;
  final String value;
  final String subText;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mau = active ? const Color(0xFF1D7BFF) : const Color(0xFF7A8196);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: mau, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: mau,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
