import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_qr_model_c1.dart';

class LetanKetquaQrScreenC1 extends StatelessWidget {
  final KetQuaQuetQrC1 ketQua;
  final VoidCallback? onQuetTiep;

  const LetanKetquaQrScreenC1({
    super.key,
    required this.ketQua,
    this.onQuetTiep,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF334155), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết Quả Quét QR',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF334155)),
            onPressed: () {
              if (onQuetTiep != null) {
                Navigator.pop(context);
                onQuetTiep!();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ketQua.thanhCong
                    ? _buildGiaoDienThanhCong(context)
                    : _buildGiaoDienThatBai(context),
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  // TRƯỜNG HỢP 1: XÁC THỰC THÀNH CÔNG (THEO ĐÚNG MOCKUP)
  Widget _buildGiaoDienThanhCong(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thẻ thông báo xanh lá: Xác thực QR thành công
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ketQua.thongBao,
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ketQua.chiTietLoi,
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Thẻ gradient xanh dương: SỐ THỨ TỰ KHÁM
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'SỐ THỨ TỰ KHÁM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${ketQua.soThuTu ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Ca sáng: Dự kiến khám lúc '),
                    TextSpan(
                      text: ketQua.gioKhamDuKien ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Thẻ trắng: Thông tin bệnh nhân chi tiết
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDF2F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header thẻ + badge BHYT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông tin bệnh nhân',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ketQua.bhyt ?? 'BHYT',
                      style: const TextStyle(
                        color: Color(0xFF0369A1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Các dòng thông tin chi tiết
              _buildRowInfo('Họ và tên:', ketQua.hoTen ?? '', isBold: true, isUpper: true),
              _buildRowInfo('Mã bệnh nhân:', ketQua.maBenhNhan ?? '', colorValue: const Color(0xFF0284C7), isBold: true),
              _buildRowInfo('Năm sinh / Giới tính:', ketQua.namSinhGioiTinh ?? '', isBold: true),
              _buildRowInfo('CCCD:', ketQua.cccd ?? '', isBold: true),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFE2E8F0), height: 1),
              ),

              _buildRowInfo('Khoa khám:', ketQua.khoaKham ?? '', isBold: true),
              _buildRowInfo('Phòng khám:', ketQua.phongKham ?? '', isBold: true),
              _buildRowInfo('Bác sĩ phụ trách:', ketQua.bacSi ?? '', isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  // TRƯỜNG HỢP 2: ĐÃ XÁC THỰC HOẶC MÃ QR KHÔNG HỢP LỆ
  Widget _buildGiaoDienThatBai(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thẻ thông báo đỏ/cam lỗi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ketQua.thongBao,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ketQua.chiTietLoi,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Thẻ chi tiết nếu có thông tin bệnh nhân cũ
        if (ketQua.hoTen != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin ghi nhận trước đó:',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRowInfo('Bệnh nhân:', ketQua.hoTen ?? ''),
                _buildRowInfo('Mã bệnh nhân:', ketQua.maBenhNhan ?? ''),
                _buildRowInfo('Khoa tiếp nhận:', ketQua.khoaKham ?? ''),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: const Column(
              children: [
                Icon(Icons.qr_code_2, size: 64, color: Color(0xFF94A3B8)),
                SizedBox(height: 12),
                Text(
                  'Vui lòng yêu cầu bệnh nhân mở lại mã QR trên ứng dụng hoặc chuyển sang tìm kiếm bằng CCCD / SĐT.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRowInfo(String label, String value, {bool isBold = false, bool isUpper = false, Color? colorValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            isUpper ? value.toUpperCase() : value,
            style: TextStyle(
              color: colorValue ?? const Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 2 Nút bấm cuối màn hình: Quét Tiếp Mã Khác & Trở Về Trang Chủ
  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Quét tiếp mã khác
          InkWell(
            onTap: () {
              Navigator.pop(context);
              if (onQuetTiep != null) {
                onQuetTiep!();
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Quét Tiếp Mã Khác',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút Trở về trang chủ
          InkWell(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, color: Color(0xFF334155), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Trở Về Trang Chủ',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
