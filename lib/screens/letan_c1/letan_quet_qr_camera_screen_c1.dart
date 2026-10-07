import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_qr_model_c1.dart';
import 'letan_ketqua_qr_screen_c1.dart';

class LetanQuetQrCameraScreenC1 extends StatefulWidget {
  const LetanQuetQrCameraScreenC1({super.key});

  @override
  State<LetanQuetQrCameraScreenC1> createState() => _LetanQuetQrCameraScreenC1State();
}

class _LetanQuetQrCameraScreenC1State extends State<LetanQuetQrCameraScreenC1> {
  bool _batDenFlash = false;

  void _moManHinhKetQua(KetQuaQuetQrC1 ketQua) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetanKetquaQrScreenC1(
          ketQua: ketQua,
          onQuetTiep: () {
            // Khi chọn quét tiếp, ở lại màn hình quét này
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Quét Mã QR Bệnh Nhân',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _batDenFlash ? Icons.flash_on : Icons.flash_off,
              color: _batDenFlash ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _batDenFlash = !_batDenFlash;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Hướng camera về phía mã QR trên ứng dụng bệnh nhân',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Khung quét QR mô phỏng
            Expanded(
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0284C7), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tia quét mô phỏng
                      Container(
                        width: 240,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.qr_code_2,
                        size: 140,
                        color: Colors.white12,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Khu vực bấm giả lập test các trường hợp quét
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CHỌN TÌNH HUỐNG TEST QUÉT MÃ QR:',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Trường hợp 1: Thành công (Mockup chuẩn)
                  ElevatedButton.icon(
                    onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.thanhCongMockup),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text('Trường hợp 1: Quét Hợp Lệ (STT: 14)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Trường hợp 2A: Đã quét trước đó
                  ElevatedButton.icon(
                    onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.daXacThucTruocDo),
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text('Trường hợp 2A: Mã Đã Tiếp Đón Trước'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Trường hợp 2B: Mã lỗi / Sai khoa
                  ElevatedButton.icon(
                    onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.maKhongHopLe),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: const Text('Trường hợp 2B: Mã Sai / Không Hợp Lệ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
