import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../config/app_session.dart';

class GuiDonThanhCongScreen extends StatelessWidget {
  final String maHoSo;
  final String tenBenhVien;
  final String loaiHinh;
  final bool coBhyt;
  final String? hospitalUid;
  final Map<String, dynamic>? extraData;

  const GuiDonThanhCongScreen({
    super.key,
    required this.maHoSo,
    required this.tenBenhVien,
    required this.loaiHinh,
    required this.coBhyt,
    this.hospitalUid,
    this.extraData,
  });

  void _xemChiTiet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chi Tiết Hồ Sơ Đăng Ký Hợp Tác',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _rowChiTiet('Mã hồ sơ', maHoSo),
            _rowChiTiet('Tên cơ sở', tenBenhVien),
            _rowChiTiet('Loại hình', loaiHinh),
            _rowChiTiet('Khám BHYT', coBhyt ? 'Có áp dụng BHYT' : 'Không BHYT'),
            if (extraData?['ma_co_so_byt'] != null)
              _rowChiTiet('Mã cơ sở (BYT)', extraData!['ma_co_so_byt'].toString()),
            if (extraData?['ma_so_thue'] != null)
              _rowChiTiet('Mã số thuế', extraData!['ma_so_thue'].toString()),
            if (extraData?['dia_chi'] != null)
              _rowChiTiet('Địa chỉ trụ sở', extraData!['dia_chi'].toString()),
            if (extraData?['file_giay_phep'] != null)
              _rowChiTiet('Giấy phép hoạt động', extraData!['file_giay_phep'].toString()),
            if (extraData?['vi_do'] != null && extraData?['kinh_do'] != null)
              _rowChiTiet('Tọa độ GPS', '${extraData!['vi_do']}, ${extraData!['kinh_do']}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowChiTiet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Biểu tượng đồng hồ cát / chờ duyệt với vầng hào quang vàng cam
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tiêu đề
                  const Text(
                    'Đã Gửi Đơn Thành Công!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Phụ đề mô tả
                  const Text(
                    'Hồ sơ hợp tác của bệnh viện đang được Quản trị\nviên (Admin) thẩm định & xét duyệt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Khung tóm tắt thông tin hồ sơ hợp tác
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng tiêu đề thẻ & badge trạng thái
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'HỒ SƠ HỢP TÁC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFC2410C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Đang chờ Admin duyệt',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Tên bệnh viện
                        Text(
                          tenBenhVien,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Đường kẻ đứt quãng
                        _buildDottedDivider(),
                        const SizedBox(height: 14),

                        // Dòng: Mã hồ sơ
                        _buildInfoRow(
                          label: 'Mã hồ sơ:',
                          valueWidget: Text(
                            maHoSo,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dòng: Loại hình
                        _buildInfoRow(
                          label: 'Loại hình:',
                          valueWidget: Text(
                            loaiHinh,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dòng: Khám BHYT
                        _buildInfoRow(
                          label: 'Khám BHYT:',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              coBhyt ? 'Có áp dụng BHYT' : 'Không BHYT',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dòng: Thời gian duyệt
                        _buildInfoRow(
                          label: 'Thời gian duyệt:',
                          valueWidget: const Text(
                            '24h - 48h làm việc',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Nút 1: Quay Về Trang Chủ (Xanh dương)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.hospitalDashboard,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_outlined, size: 20),
                      label: const Text(
                        'Quay Về Trang Chủ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút 2: Xem Chi Tiết Đơn Đã Gửi (Trắng viền)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _xemChiTiet(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Xem Chi Tiết Đơn Đã Gửi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nút DEV: Admin duyệt ngay để vào Dashboard phát triển chức năng
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final uid = hospitalUid ??
                            (AppSession.benhVienId.isNotEmpty
                                ? AppSession.benhVienId
                                : (FirebaseAuth.instance.currentUser?.uid ?? ''));

                        await FirebaseFirestore.instance
                            .collection('BenhVien')
                            .doc(uid)
                            .set({
                          'trang_thai_hop_tac_id': 10,
                          'da_gui_don': true,
                        }, SetOptions(merge: true));

                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.hospitalDashboard,
                          (r) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: Color(0xFF16A34A),
                      ),
                      label: const Text(
                        '⚡ [DEV] Phê duyệt ngay để mở khóa Dashboard',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        valueWidget,
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
              ),
            );
          }),
        );
      },
    );
  }
}
