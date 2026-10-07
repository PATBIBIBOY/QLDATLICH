import 'package:flutter/material.dart';

import 'letan_lichhen_screen_c1.dart';

class LetanTimkiemScreenC1 extends StatefulWidget {
  const LetanTimkiemScreenC1({super.key});

  @override
  State<LetanTimkiemScreenC1> createState() => _LetanTimkiemScreenC1State();
}

class _LetanTimkiemScreenC1State extends State<LetanTimkiemScreenC1> {
  final TextEditingController _controller = TextEditingController();

  void _thucHienTimKiem(String tuKhoa) {
    final query = tuKhoa.trim();
    if (query.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LetanLichhenScreenC1(
          tuKhoaBanDau: query,
          laTab: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm Bệnh Nhân',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nhập Tên hoặc Số Điện Thoại',
                style: TextStyle(
                  color: Color(0xFF1C1C1E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống sẽ tra cứu hồ sơ và chuyển thẳng đến danh sách lịch hẹn của bệnh nhân.',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Ô nhập liệu
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _thucHienTimKiem,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 0901234567 hoặc Nguyễn Văn An...',
                  hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF007AFF)),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nút tìm kiếm
              ElevatedButton.icon(
                onPressed: () => _thucHienTimKiem(_controller.text),
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  'Tìm Kiếm Ngay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Gợi ý nhanh
              const Text(
                'GỢI Ý TÌM NHANH:',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChipGoiY('0901234567 (An)'),
                  _buildChipGoiY('0912345678 (Hoa)'),
                  _buildChipGoiY('Nguyễn Văn An'),
                  _buildChipGoiY('Lê Minh'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipGoiY(String text) {
    final tuKhoa = text.split(' ')[0];
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12.5)),
      backgroundColor: const Color(0xFFF2F2F7),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _controller.text = tuKhoa;
        _thucHienTimKiem(tuKhoa);
      },
    );
  }
}
