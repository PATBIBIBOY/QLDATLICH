import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/letan_c1/letan_qr_model_c1.dart';
import '../../services/letan_c1/letan_firebase_service_c1.dart';
import 'letan_ketqua_qr_screen_c1.dart';

/// MÀN HÌNH QUÉT MÃ QR TIẾP ĐÓN BỆNH NHÂN (HYBRID)
/// - Chạy trên Phone: Mở trực tiếp Camera phần cứng quét mã QR thật (MobileScanner)
/// - Hỗ trợ song song: Bật/Tắt Flash, Lật Camera Trước/Sau, và nút Giả lập Test nhanh khi demo
class LetanQuetQrCameraScreenC1 extends StatefulWidget {
  const LetanQuetQrCameraScreenC1({super.key});

  @override
  State<LetanQuetQrCameraScreenC1> createState() => _LetanQuetQrCameraScreenC1State();
}

class _LetanQuetQrCameraScreenC1State extends State<LetanQuetQrCameraScreenC1> {
  late final MobileScannerController _scannerController;
  bool _batDenFlash = false;
  bool _dangXuLyMa = false;
  bool _hienThiCheDoCamera = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Khi camera nhận diện được mã QR thực tế
  Future<void> _xuLyKhiQuetDuocMa(BarcodeCapture capture) async {
    if (_dangXuLyMa) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _dangXuLyMa = true);

    try {
      // 1. Phân tích mã QR từ FirebaseServiceC1
      final res = await FirebaseServiceC1.xuLyMaQrTiepNhan(rawValue);

      final ketQua = KetQuaQuetQrC1(
        thanhCong: res['thanh_cong'] == true,
        thongBao: (res['thong_bao'] ?? 'Xác thực QR').toString(),
        chiTietLoi: (res['chi_tiet_loi'] ?? '').toString(),
        soThuTu: res['so_thu_tu'] as int?,
        gioKhamDuKien: res['gio_kham']?.toString(),
        hoTen: res['ho_ten']?.toString(),
        maBenhNhan: res['ma_benh_nhan']?.toString(),
        namSinhGioiTinh: res['nam_sinh']?.toString(),
        cccd: res['cccd']?.toString(),
        bhyt: res['bhyt']?.toString(),
        khoaKham: res['khoa']?.toString(),
        phongKham: res['phong']?.toString(),
        bacSi: res['bac_si']?.toString(),
      );

      if (!mounted) return;
      _moManHinhKetQua(ketQua);
    } finally {
      // Cho phép quét tiếp sau 1.5 giây
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _dangXuLyMa = false);
      });
    }
  }

  void _moManHinhKetQua(KetQuaQuetQrC1 ketQua) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LetanKetquaQrScreenC1(
          ketQua: ketQua,
          onQuetTiep: () {
            if (mounted) setState(() => _dangXuLyMa = false);
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
          // Nút đổi camera trước / sau
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Đổi camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
          // Nút bật/tắt đèn Flash
          IconButton(
            icon: Icon(
              _batDenFlash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _batDenFlash ? Colors.amber : Colors.white,
            ),
            tooltip: 'Đèn Flash',
            onPressed: () {
              setState(() => _batDenFlash = !_batDenFlash);
              _scannerController.toggleTorch();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Hướng camera điện thoại về phía mã QR trên app bệnh nhân',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // KHUNG CAMERA QUÉT THẬT TÍCH HỢP MOBILE_SCANNER
            Expanded(
              child: Center(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0284C7), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder Camera thật từ thiết bị
                        if (_hienThiCheDoCamera)
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: _xuLyKhiQuetDuocMa,
                            errorBuilder: (context, error) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam_off_rounded, color: Color(0xFFEF4444), size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Không mở được camera (${error.errorCode.name})',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          const Center(
                            child: Icon(Icons.qr_code_2, size: 140, color: Colors.white12),
                          ),

                        // Khung tia quét trang trí & loading
                        if (_dangXuLyMa)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 3),
                                  SizedBox(height: 10),
                                  Text('Đang xác thực thông tin...', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        else
                          // Tia quét laser trang trí
                          Positioned(
                            top: 130,
                            child: Container(
                              width: 240,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // NÚT CHUYỂN ĐỔI / GIẢ LẬP PHÒNG TRƯỜNG HỢP DEMO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TÌNH HUỐNG TEST NHANH (DEMO):',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _hienThiCheDoCamera = !_hienThiCheDoCamera),
                        child: Text(
                          _hienThiCheDoCamera ? 'Tắt camera' : 'Bật camera',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // Test TH1
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.thanhCongMockup),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text('Hợp Lệ (STT: 14)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Test TH2A
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.daXacThucTruocDo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text('Đã Tiếp Đón', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Test TH2B
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _moManHinhKetQua(DuLieuQuetQrMauC1.maKhongHopLe),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text('Sai Khoa / Lỗi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
