import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pending_hospital_detail_screen.dart';
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
  Future<Map<String, dynamic>?>? _hospitalDocsFuture;

  @override
  void initState() {
    super.initState();
    _loadHospitalDocs();
    AdminStore.instance.addListener(_refresh);
  }

  void _loadHospitalDocs() {
    _hospitalDocsFuture = _fetchHospitalDocs();
  }

  Future<Map<String, dynamic>?> _fetchHospitalDocs() async {
    final code = widget.hospital.code;
    if (code == null || code.isEmpty) return null;
    try {
      // 1. Tim trong BenhVien
      final bvSnap = await FirebaseFirestore.instance.collection('BenhVien').doc(code).get();
      if (bvSnap.exists && bvSnap.data() != null) {
        final data = bvSnap.data()!;
        if (data.containsKey('cccd_mat_truoc_base64') ||
            data.containsKey('cccd_mat_truoc_url') ||
            data.containsKey('file_giay_phep') ||
            data.containsKey('file_giay_phep_url') ||
            data.containsKey('ma_co_so_byt')) {
          return data;
        }
      }
      // 2. Tim trong YeuCauHopTac
      final ycSnap = await FirebaseFirestore.instance.collection('YeuCauHopTac').doc(code).get();
      if (ycSnap.exists && ycSnap.data() != null) {
        return ycSnap.data()!;
      }
      // 3. Neu van chua co, tra ve du lieu tu bvSnap neu co
      if (bvSnap.exists) return bvSnap.data();
    } catch (e) {
      debugPrint('Loi doc ho so giay to benh vien: ');
    }
    return null;
  }

  Uint8List? _decodeBase64(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      String clean = trimmed;
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  void _showImageDialog(BuildContext context, String title, {Uint8List? bytes, String? imageUrl}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65, minHeight: 220),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.contain)
                          : (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(imageUrl, fit: BoxFit.contain)
                              : const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    AdminStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _buildDeptCard(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: kSlate900,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: kSlate400),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: kSlate400),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12.5, color: kSlate500, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, color: kSlate900, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospital = widget.hospital;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  const BackCircle(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hồ Sơ Bệnh Viện',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: kSlate900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hospital.isUnpartnered ? kRedBg : kGreenLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hospital.isUnpartnered
                            ? kRed.withValues(alpha: 0.3)
                            : kGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hospital.isUnpartnered
                              ? Icons.link_off_rounded
                              : Icons.check_circle_rounded,
                          size: 13,
                          color: hospital.isUnpartnered ? kRed : kGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hospital.isUnpartnered ? 'Đã hủy hợp tác' : 'Đang hợp tác',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: hospital.isUnpartnered ? kRed : kGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditHospitalScreen(hospital: hospital),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                        boxShadow: kCardShadow,
                      ),
                      child: const Icon(Icons.edit_rounded, size: 18, color: kPrimary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Hero Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: kCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarBox(
                          text: hospital.initials,
                          bg: hospital.avatarBg,
                          fg: hospital.avatarText,
                          size: 56,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: kSlate900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hospital.type == 'Công lập' ? kPrimaryLight : kOrangeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hospital.type,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: hospital.type == 'Công lập' ? kPrimary : kAmber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    hospital.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: kSlate900,
                                    ),
                                  ),
                                  Text(
                                    ' (${hospital.totalReviews ?? 150} lượt)',
                                    style: const TextStyle(fontSize: 11, color: kSlate400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),

                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Địa chỉ',
                      hospital.address ?? 'Đang cập nhật địa chỉ',
                    ),
                    _buildInfoRow(
                      Icons.tag_rounded,
                      'Mã cơ sở',
                      hospital.code ?? 'BV-MEDICONNECT',
                    ),
                    _buildInfoRow(
                      Icons.medical_services_outlined,
                      'Bảo hiểm',
                      'Hỗ trợ thanh toán BHYT toàn quốc',
                    ),
                    _buildInfoRow(
                      Icons.people_outline_rounded,
                      'Đội ngũ',
                      '${hospital.doctors} bác sĩ và chuyên gia y tế',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Danh sách khoa trực thuộc
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CHUYÊN KHOA TRỰC THUỘC',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: kSlate500,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '${hospital.departments?.length ?? 2} khoa',
                    style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (hospital.departments != null && hospital.departments!.isNotEmpty)
                ...hospital.departments!.map(
                  (d) => _buildDeptCard(d, Icons.local_hospital_rounded),
                )
              else ...[
                _buildDeptCard('Khoa Khám Bệnh Đa Khoa · Tiếp nhận 24/7', Icons.local_hospital_rounded),
                _buildDeptCard('Khoa Cấp Cứu & Hồi Sức Tích Cực', Icons.emergency_rounded),
                _buildDeptCard('Khoa Nội Tổng Hợp', Icons.healing_rounded),
              ],

              const SizedBox(height: 16),

              // Nút xem đánh giá bệnh viện
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_outline_rounded, size: 20),
                  label: const Text('Xem Đánh Giá Bệnh Nhân (Live)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(hospital: hospital),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ============ PHẦN QUẢN LÝ THỎA THUẬN HỢP TÁC ============
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hospital.isUnpartnered ? const Color(0xFFFECACA) : kBorder,
                    width: hospital.isUnpartnered ? 1.5 : 1,
                  ),
                  boxShadow: kCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: hospital.isUnpartnered ? kRedBg : kPrimaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            hospital.isUnpartnered
                                ? Icons.link_off_rounded
                                : Icons.handshake_outlined,
                            color: hospital.isUnpartnered ? kRed : kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'QUẢN LÝ THỎA THUẬN HỢP TÁC',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: kSlate800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hospital.isUnpartnered
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hospital.isUnpartnered
                              ? const Color(0xFFFDA4AF)
                              : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hospital.isUnpartnered
                                ? Icons.link_off_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                            color: hospital.isUnpartnered ? kRed : kGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital.isUnpartnered
                                      ? 'ĐÃ HỦY HỢP TÁC'
                                      : 'Đang hợp tác với ứng dụng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: hospital.isUnpartnered ? kRed : kGreen,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hospital.isUnpartnered
                                      ? 'Bệnh viện không còn trong danh sách đối tác và không thể nhận lịch khám mới.'
                                      : 'Cơ sở đang hợp tác và có thể nhận lịch khám từ ứng dụng.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hospital.isUnpartnered
                                        ? const Color(0xFF9F1239)
                                        : const Color(0xFF166534),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ============ HỒ SƠ & GIẤY TỜ THỎA THUẬN HỢP TÁC ============
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 14),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _hospitalDocsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                            ),
                          );
                        }

                        final docsData = snapshot.data ?? {};
                        final maByt = docsData['ma_co_so_byt']?.toString() ?? docsData['ma_byt']?.toString() ?? widget.hospital.code ?? '';
                        final maThue = docsData['ma_so_thue']?.toString() ?? '';
                        final soGp = docsData['so_giay_phep']?.toString() ?? '';
                        final cccdTruoc = docsData['cccd_mat_truoc_base64']?.toString() ?? docsData['cccd_truoc_base64']?.toString() ?? '';
                        final cccdTruocUrl = docsData['cccd_mat_truoc_url']?.toString() ?? '';
                        final cccdSau = docsData['cccd_mat_sau_base64']?.toString() ?? docsData['cccd_sau_base64']?.toString() ?? '';
                        final cccdSauUrl = docsData['cccd_mat_sau_url']?.toString() ?? '';
                        final fileGp = docsData['file_giay_phep']?.toString() ?? 'giay_phep_byt.pdf';
                        final fileGpUrl = docsData['file_giay_phep_url']?.toString() ?? docsData['file_url']?.toString() ?? '';
                        final dungLuong = docsData['dung_luong_file']?.toString() ?? '';
                        final nguoiDaiDien = docsData['nguoi_dai_dien']?.toString() ?? '';

                        final cccdTruocBytes = _decodeBase64(cccdTruoc);
                        final cccdSauBytes = _decodeBase64(cccdSau);
                        final bool hasCccd = cccdTruocBytes != null || cccdTruocUrl.isNotEmpty || cccdSauBytes != null || cccdSauUrl.isNotEmpty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HỒ SƠ PHÁP LÝ & ĐỐI SOÁT HỢP TÁC',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kSlate700, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(Icons.pin_outlined, 'Mã cơ sở (BYT)', maByt.isNotEmpty ? maByt : 'Chưa cập nhật'),
                                  if (maThue.isNotEmpty) _buildInfoRow(Icons.receipt_long_outlined, 'Mã số thuế', maThue),
                                  if (soGp.isNotEmpty) _buildInfoRow(Icons.badge_outlined, 'Số giấy phép', soGp),
                                  if (nguoiDaiDien.isNotEmpty) _buildInfoRow(Icons.person_outline_rounded, 'Người đại diện', nguoiDaiDien),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Ảnh CCCD 2 mặt của người đại diện
                            const Text(
                              'Ảnh CCCD người đại diện cơ sở:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kSlate800),
                            ),
                            const SizedBox(height: 8),
                            if (hasCccd)
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showImageDialog(
                                        context,
                                        'Mặt trước CCCD',
                                        bytes: cccdTruocBytes,
                                        imageUrl: cccdTruocUrl,
                                      ),
                                      child: Container(
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: kBorder),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: cccdTruocBytes != null
                                            ? Image.memory(cccdTruocBytes, fit: BoxFit.cover)
                                            : (cccdTruocUrl.isNotEmpty
                                                ? Image.network(cccdTruocUrl, fit: BoxFit.cover)
                                                : const Center(child: Text('Mặt trước', style: TextStyle(fontSize: 11, color: kSlate400)))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showImageDialog(
                                        context,
                                        'Mặt sau CCCD',
                                        bytes: cccdSauBytes,
                                        imageUrl: cccdSauUrl,
                                      ),
                                      child: Container(
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: kBorder),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: cccdSauBytes != null
                                            ? Image.memory(cccdSauBytes, fit: BoxFit.cover)
                                            : (cccdSauUrl.isNotEmpty
                                                ? Image.network(cccdSauUrl, fit: BoxFit.cover)
                                                : const Center(child: Text('Mặt sau', style: TextStyle(fontSize: 11, color: kSlate400)))),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: kBorder),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.badge_outlined, size: 18, color: kSlate400),
                                    SizedBox(width: 8),
                                    Text('Cơ sở y tế này chưa cập nhật ảnh CCCD người đại diện.', style: TextStyle(fontSize: 12, color: kSlate500)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),

                            // Giấy phép hoạt động y tế
                            const Text(
                              'Giấy phép hoạt động y tế cơ sở:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kSlate800),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileGp,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: kSlate900),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          dungLuong.isNotEmpty ? dungLuong : 'Tài liệu thẩm định cơ sở y tế',
                                          style: const TextStyle(fontSize: 11, color: kSlate400),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bản nhúng xem trực tiếp tài liệu
                            EmbeddedDocumentViewer(
                              fileUrl: fileGpUrl.isNotEmpty ? fileGpUrl : fileGp,
                              docName: fileGp,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    // NÚT: HỦY HOẶC KHÔI PHỤC HỢP TÁC
                    if (hospital.isUnpartnered)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.handshake_outlined, size: 18),
                          label: const Text(
                            'Khôi Phục Thỏa Thuận Hợp Tác',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showRestoreDialog(context),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text(
                            'Hủy Thỏa Thuận Hợp Tác',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRed,
                            side: const BorderSide(
                                color: Color(0xFFFECACA), width: 1.2),
                            backgroundColor: const Color(0xFFFFF5F5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showCancelPartnershipDialog(context),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // NÚT: XÓA VĨNH VIỄN TÀI KHOẢN VÀ DỮ LIỆU
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_forever_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Xóa Vĩnh Viễn Bệnh Viện Khỏi Firebase',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showDeleteAccountDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HỘP THOẠI KHÔI PHỤC HỢP TÁC ---
  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.handshake_outlined, color: kGreen, size: 24),
            SizedBox(width: 8),
            Text('Khôi Phục Hợp Tác',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Khôi phục thỏa thuận hợp tác với ${widget.hospital.name}? Bệnh viện sẽ có thể nhận lịch khám trở lại.',
          style: const TextStyle(color: kSlate600, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: kSlate600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await AdminStore.instance.restoreHospitalPartnership(widget.hospital);
              if (mounted) setState(() {});
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã khôi phục hợp tác với ${widget.hospital.name}.'),
                  backgroundColor: kGreen,
                ),
              );
            },
            child: const Text('Khôi Phục'),
          ),
        ],
      ),
    );
  }

  // --- HỘP THOẠI HỦY HỢP TÁC ---
  void _showCancelPartnershipDialog(BuildContext context) {
    final reasonCtrl = TextEditingController(
      text: 'Chấm dứt hợp đồng hợp tác y tế theo quyết định của Quản trị hệ thống.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.link_off_rounded, color: kRed, size: 24),
            SizedBox(width: 8),
            Text('Hủy Hợp Tác',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bệnh viện ${widget.hospital.name} sẽ bị gỡ khỏi danh sách đối tác và ngừng toàn bộ giao dịch trên Mediconnect:',
              style: const TextStyle(color: kSlate600, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Lý do chấm dứt hợp tác',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ',
                style: TextStyle(color: kSlate600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);

              // 1. Đóng hộp thoại dialog ngay lập tức
              Navigator.pop(ctx);

              await AdminStore.instance.cancelHospitalPartnership(
                widget.hospital,
                reason.isEmpty ? 'Hủy hợp tác theo yêu cầu' : reason,
              );

              final emailNotice = widget.hospital.email != null && widget.hospital.email!.isNotEmpty
                  ? ' và gửi email tới ${widget.hospital.email}'
                  : '';
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã hủy thỏa thuận hợp tác với ${widget.hospital.name}$emailNotice.'),
                  backgroundColor: kSlate900,
                ),
              );

              // 2. Quay lại màn hình danh sách bệnh viện an toàn
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Xác nhận Hủy'),
          ),
        ],
      ),
    );
  }

  // --- HỘP THOẠI XÓA VĨNH VIỄN ---
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 8),
            Text('Xóa Bệnh Viện Này?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFDC2626))),
          ],
        ),
        content: Text(
          'CẢNH BÁO: Hành động này sẽ XÓA VĨNH VIỄN hồ sơ "${widget.hospital.name}" khỏi Firebase (bao gồm Firestore BenhVien và tài khoản đăng nhập trên Firebase Authentication). Không thể khôi phục sau khi xóa!',
          style: const TextStyle(color: kSlate700, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ lại',
                style: TextStyle(color: kSlate600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final emailNotice = widget.hospital.email != null && widget.hospital.email!.isNotEmpty
                  ? ' và gửi email tới ${widget.hospital.email}'
                  : '';

              // 1. Đóng hộp thoại dialog ngay lập tức
              Navigator.pop(ctx);

              await AdminStore.instance.deleteHospitalAccount(widget.hospital);

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Đã xóa vĩnh viễn ${widget.hospital.name}$emailNotice.'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );

              // 2. Quay lại màn hình danh sách bệnh viện an toàn
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Xóa Vĩnh Viễn'),
          ),
        ],
      ),
    );
  }
}
