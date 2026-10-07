import 'package:flutter/material.dart';

import '../../models/letan_c1/letan_design_system_c1.dart';

class LetanBaocaoloiScreenC1 extends StatefulWidget {
  final String tenKhoa;

  const LetanBaocaoloiScreenC1({
    super.key,
    this.tenKhoa = 'Khoa Tim Mạch',
  });

  @override
  State<LetanBaocaoloiScreenC1> createState() => _LetanBaocaoloiScreenC1State();
}

class _LetanBaocaoloiScreenC1State extends State<LetanBaocaoloiScreenC1> {
  final _moTaController = TextEditingController(
    text: 'Số đang gọi trên màn hình là 11 nhưng bệnh nhân số 12 đã vào phòng...',
  );
  String _loaiLoiDuocChon = 'Số thứ tự hiển thị sai';
  String _mucDoUuTien = 'Cao'; // 'Cao', 'Trung bình', 'Thấp'
  bool _coDinhKemAnh = false;

  final List<String> _danhSachLoaiLoi = [
    'Số thứ tự hiển thị sai',
    'Không quét được mã QR bệnh nhân',
    'Hệ thống phản hồi chậm / đơ',
    'Sai thông tin lịch hẹn hôm nay',
    'Lỗi kết nối máy in phiếu số',
    'Lỗi khác...',
  ];

  @override
  void dispose() {
    _moTaController.dispose();
    super.dispose();
  }

  void _guiBaoCao() {
    AppDesignSystemC1.hapticSuccess();
    AppDesignSystemC1.showCustomSnackBar(
      context,
      message: 'Đã gửi báo cáo lỗi đến kỹ thuật thành công!',
      isSuccess: true,
      icon: Icons.check_circle_rounded,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () {
            AppDesignSystemC1.hapticLight();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Báo cáo lỗi',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header cảnh báo lỗi
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠ Mô tả lỗi hệ thống hoặc thao tác sai',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Báo cáo sẽ được gửi đến bộ phận kỹ thuật',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Loại lỗi
              const Text(
                'Loại lỗi',
                style: TextStyle(
                  color: Color(0xFF3A3A3C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _loaiLoiDuocChon,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E8E93)),
                    items: _danhSachLoaiLoi.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _loaiLoiDuocChon = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Mô tả chi tiết
              const Text(
                'Mô tả chi tiết',
                style: TextStyle(
                  color: Color(0xFF3A3A3C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _moTaController,
                  maxLines: 4,
                  style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập chi tiết lỗi sự cố bạn gặp phải...',
                    hintStyle: TextStyle(color: Color(0xFFAEAEB2), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Mức độ ưu tiên
              const Text(
                'Mức độ ưu tiên',
                style: TextStyle(
                  color: Color(0xFF3A3A3C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMucDoItem('Cao', const Color(0xFFFF3B30)),
                  const SizedBox(width: 10),
                  _buildMucDoItem('Trung bình', const Color(0xFFFF9500)),
                  const SizedBox(width: 10),
                  _buildMucDoItem('Thấp', const Color(0xFF34C759)),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Đính kèm ảnh (nếu có)
              const Text(
                'Đính kèm ảnh (nếu có)',
                style: TextStyle(
                  color: Color(0xFF3A3A3C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    AppDesignSystemC1.hapticLight();
                    setState(() {
                      _coDinhKemAnh = !_coDinhKemAnh;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _coDinhKemAnh ? const Color(0xFFE0F2FE) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _coDinhKemAnh ? const Color(0xFF0284C7) : const Color(0xFFE5E5EA),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _coDinhKemAnh
                        ? const Icon(Icons.check, color: Color(0xFF0284C7), size: 28)
                        : const Text(
                            '+',
                            style: TextStyle(
                              color: Color(0xFFC7C7CC),
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Inter',
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 6. Nút Gửi báo cáo lỗi
              InkWell(
                onTap: _guiBaoCao,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Gửi báo cáo lỗi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 7. Nút Hủy
              InkWell(
                onTap: () {
                  AppDesignSystemC1.hapticLight();
                  Navigator.pop(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Hủy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMucDoItem(String label, Color activeColor) {
    final bool isSelected = _mucDoUuTien == label;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppDesignSystemC1.hapticLight();
          setState(() {
            _mucDoUuTien = label;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF3A3A3C),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
