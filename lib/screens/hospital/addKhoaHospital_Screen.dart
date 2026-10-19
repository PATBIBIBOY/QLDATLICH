import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qldatlich/services/khoa_service.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';

const _xanh = Color(0xFF1E88E5);

String _gio(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ===================== MÀN HÌNH THÊM KHOA MỚI =====================
class ThemKhoaScreen extends StatefulWidget {
  final String benhVienId;
  const ThemKhoaScreen({super.key, required this.benhVienId});

  @override
  State<ThemKhoaScreen> createState() => _ThemKhoaScreenState();
}

class _ThemKhoaScreenState extends State<ThemKhoaScreen> {
  String get _currentBenhVienId {
    if (widget.benhVienId.isNotEmpty &&
        widget.benhVienId != 'dFmZHBjFNUT1eRzJjXp5') {
      return widget.benhVienId;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return AppSession.benhVienId;
  }

  final _ten = TextEditingController();
  final _soBuoi = TextEditingController(text: '2');
  final _slMoiBuoi = TextEditingController(text: '45');
  final List<TextEditingController> _phong = [TextEditingController()];
  final Set<int> _ngay = {2, 3, 4, 5, 6, 7};
  final List<List<TimeOfDay>> _khung = [
    [
      const TimeOfDay(hour: 7, minute: 30),
      const TimeOfDay(hour: 11, minute: 30),
    ],
    [
      const TimeOfDay(hour: 13, minute: 30),
      const TimeOfDay(hour: 17, minute: 0),
    ],
  ];
  bool _dangLuu = false;

  @override
  void dispose() {
    _ten.dispose();
    _soBuoi.dispose();
    _slMoiBuoi.dispose();
    for (final c in _phong) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _chonGio(int i) async {
    final bd = await showTimePicker(
      context: context,
      initialTime: _khung[i][0],
      helpText: 'GIỜ BẮT ĐẦU',
    );
    if (bd == null || !mounted) return;
    final kt = await showTimePicker(
      context: context,
      initialTime: _khung[i][1],
      helpText: 'GIỜ KẾT THÚC',
    );
    if (kt == null) return;
    setState(() => _khung[i] = [bd, kt]);
  }

  void _loi(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _luu() async {
    final ten = _ten.text.trim();
    final soBuoi = int.tryParse(_soBuoi.text.trim());
    final sl = int.tryParse(_slMoiBuoi.text.trim());
    final phong = _phong
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (ten.isEmpty) return _loi('Vui lòng nhập tên khoa khám');
    if (soBuoi == null || soBuoi <= 0) return _loi('Số buổi khám không hợp lệ');
    if (sl == null || sl <= 0) {
      return _loi('Số lượng khám mỗi buổi không hợp lệ');
    }
    if (_ngay.isEmpty) return _loi('Chọn ít nhất 1 ngày làm việc');
    if (phong.isEmpty) return _loi('Thêm ít nhất 1 phòng khám');

    setState(() => _dangLuu = true);
    try {
      final hospitalId = _currentBenhVienId;
      final ketQua = await KhoaService().themKhoa(
        benhVienId: hospitalId,
        tenKhoa: ten,
        soCaMoiNgay: soBuoi,
        gioiHanBenhNhan: sl,
        khungGio: _khung.map((k) => KhungGio(_gio(k[0]), _gio(k[1]))).toList(),
        ngayLamViec: _ngay.toList(),
        phongKham: phong,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ThanhCongScreen(khoa: ketQua, benhVienId: hospitalId),
        ),
      );
    } catch (e) {
      _loi('Lỗi khi lưu: $e');
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  Widget _nhan(String t, {String? phu}) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (phu != null)
          Text(phu, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    ),
  );

  InputDecoration _deco({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const tenNgay = {
      2: 'Thứ\n2',
      3: 'Thứ\n3',
      4: 'Thứ\n4',
      5: 'Thứ\n5',
      6: 'Thứ\n6',
      7: 'Thứ\n7',
      8: 'Chủ\nCN',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Thêm Khoa Mới',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _nhan('Tên khoa khám *'),
          TextField(
            controller: _ten,
            decoration: _deco(
              hint: 'VD: Khoa Mắt Kỹ Thuật Cao',
            ).copyWith(prefixIcon: const Icon(Icons.person_outline)),
          ),

          // Số buổi + SL mỗi buổi
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nhan('Số buổi khám / ngày'),
                    TextField(
                      controller: _soBuoi,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: _deco(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nhan('SL khám mỗi buổi'),
                    TextField(
                      controller: _slMoiBuoi,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: _deco(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          _nhan('Thời gian khám', phu: 'Ca sáng & Chiều'),
          Row(
            children: [
              for (var i = 0; i < _khung.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _chonGio(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${_gio(_khung[i][0])} - ${_gio(_khung[i][1])}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          _nhan('Khám các ngày trong tuần', phu: 'Chọn ngày làm việc'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in tenNgay.keys)
                GestureDetector(
                  onTap: () => setState(
                    () => _ngay.contains(d) ? _ngay.remove(d) : _ngay.add(d),
                  ),
                  child: Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _ngay.contains(d) ? _xanh : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _ngay.contains(d) ? _xanh : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      tenNgay[d]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _ngay.contains(d) ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _ngay.isEmpty
                      ? ''
                      : '✓ Đã chọn: ${taoLichLamViec(_ngay.toList())}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _ngay
                      ..clear()
                      ..addAll([2, 3, 4, 5, 6, 7, 8]),
                  ),
                  child: const Text('Chọn cả tuần'),
                ),
              ],
            ),
          ),

          _nhan('Vị trí phòng khám', phu: 'Có thể thêm nhiều phòng'),
          for (var i = 0; i < _phong.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _phong[i],
                decoration:
                    _deco(
                      hint: 'VD: Phòng 405 - Tầng 4 Nhà Điều Trị KTC',
                    ).copyWith(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: _xanh,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      suffixIcon: _phong.length > 1
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() {
                                _phong.removeAt(i).dispose();
                              }),
                            )
                          : null,
                    ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _phong.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: const Text('Thêm phòng khám'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _dangLuu ? null : _luu,
            style: ElevatedButton.styleFrom(
              backgroundColor: _xanh,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _dangLuu
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Thêm Khoa Khám',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

// ===================== MÀN HÌNH THÀNH CÔNG =====================
class ThanhCongScreen extends StatelessWidget {
  final KhoaVuaTao khoa;
  final String benhVienId;
  const ThanhCongScreen({
    super.key,
    required this.khoa,
    required this.benhVienId,
  });

  Widget _dong(String nhan, Widget giaTri) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nhan, style: const TextStyle(color: Colors.grey)),
        giaTri,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bold = const TextStyle(fontWeight: FontWeight.w700);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đã Thêm Khoa Thành Công!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khoa mới đã được kích hoạt trên hệ thống lấy số tự động và phân luồng khám bệnh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KHOA VỪA KHỞI TẠO',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      khoa.tenKhoa,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Divider(height: 24),
                    _dong(
                      'Số ca khám:',
                      Text('${khoa.soCaMoiNgay} ca / ngày', style: bold),
                    ),
                    _dong(
                      'Số lượng BN tối đa:',
                      Text(
                        '${khoa.gioiHanBenhNhan} bệnh nhân / ca',
                        style: bold,
                      ),
                    ),
                    _dong(
                      'Thời gian:',
                      Text(
                        khoa.khungGio.map((e) => e.text).join(' | '),
                        style: bold,
                      ),
                    ),
                    _dong(
                      'Lịch khám:',
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEEFB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          khoa.lichLamViec,
                          style: const TextStyle(
                            color: Color(0xFF0B5CAD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.hospitalDashboard,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Trở Về Trang Chủ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _xanh,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ThemKhoaScreen(benhVienId: benhVienId),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tiếp tục thêm khoa khác'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
