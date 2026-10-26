import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import '../../providers/auth_provider.dart';
import 'guiDonThanhCong_Screen.dart';

class GuiYeuCauHopTacScreen extends StatefulWidget {
  final String? initialTenBenhVien;
  final String? initialDiaChi;

  const GuiYeuCauHopTacScreen({
    super.key,
    this.initialTenBenhVien,
    this.initialDiaChi,
  });

  @override
  State<GuiYeuCauHopTacScreen> createState() => _GuiYeuCauHopTacScreenState();
}

class _GuiYeuCauHopTacScreenState extends State<GuiYeuCauHopTacScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenBenhVienCtrl;
  late final TextEditingController _maCoSoCtrl;
  late final TextEditingController _maSoThueCtrl;
  late final TextEditingController _diaChiCtrl;

  // ✅ SPINNER: Loại hình bệnh viện (thay thế checkbox)
  String _loaiHinh = 'Bệnh viện Công lập';

  // ✅ SPINNER: Tiếp nhận BHYT (thay thế checkbox)
  bool _coBhyt = true;

  // ✅ TỆP ĐÍNH KÈM: Cho phép mở thư mục tệp thiết bị
  String _tenFileDinhKem = 'giay_phep_hoat_dong_y_te.pdf';
  String _dungLuongFile = 'Chưa chọn tệp từ máy';
  // ignore: unused_field
  String? _filePath;

  // ✅ VỊ TRÍ: Kinh độ & Vĩ độ lưu vào collection BenhVien
  double? _viDo;
  double? _kinhDo;
  bool _dangLayViTri = false;
  String? _viTriStatus;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tenBv = widget.initialTenBenhVien ??
        auth.hospital?.tenBenhVien ??
        'Bệnh viện Đa Khoa An Bình';
    final diaChi = widget.initialDiaChi ??
        auth.hospital?.diaChi ??
        '146 An Bình, Phường 7, Quận 5, TP.HCM';

    // Tên bệnh viện cố định theo tài khoản đăng ký
    _tenBenhVienCtrl = TextEditingController(text: tenBv);
    _maCoSoCtrl = TextEditingController(text: 'BV-79-102');
    _maSoThueCtrl = TextEditingController(text: '0312891201');
    _diaChiCtrl = TextEditingController(text: diaChi);

    // Lấy tọa độ có sẵn từ model nếu có
    _viDo = auth.hospital?.viDo;
    _kinhDo = auth.hospital?.kinhDo;
    if (_viDo != null && _kinhDo != null) {
      _viTriStatus =
          'Đã có tọa độ: ${_viDo!.toStringAsFixed(5)}, ${_kinhDo!.toStringAsFixed(5)}';
    }

    // ✅ TỰ ĐỘNG YÊU CẦU LẤY VỊ TRÍ THIẾT BỊ NGAY KHI MỞ MÀN HÌNH
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _yeuCauLayViTri(showDialogPrompt: false);
    });
  }

  @override
  void dispose() {
    _tenBenhVienCtrl.dispose();
    _maCoSoCtrl.dispose();
    _maSoThueCtrl.dispose();
    _diaChiCtrl.dispose();
    super.dispose();
  }

  String _getHospitalUid() {
    final auth = context.read<AuthProvider>();
    if (auth.hospital?.maBenhVien != null &&
        auth.hospital!.maBenhVien!.isNotEmpty) {
      return auth.hospital!.maBenhVien!;
    }
    if (auth.hospital?.uid != null && auth.hospital!.uid!.isNotEmpty) {
      return auth.hospital!.uid!;
    }
    if (AppSession.benhVienId.isNotEmpty) {
      return AppSession.benhVienId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  /// ✅ HÀM YÊU CẦU LẤY VỊ TRÍ THIẾT BỊ (GPS)
  Future<void> _yeuCauLayViTri({bool showDialogPrompt = true}) async {
    if (!mounted) return;
    setState(() {
      _dangLayViTri = true;
      _viTriStatus = 'Đang yêu cầu và lấy tọa độ GPS...';
    });

    try {
      // 1. Kiểm tra dịch vụ định vị GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _dangLayViTri = false;
          _viTriStatus = 'Dịch vụ định vị GPS chưa bật trên thiết bị';
        });
        if (mounted && showDialogPrompt) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ định vị (GPS) trên thiết bị'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Yêu cầu quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _dangLayViTri = false;
            _viTriStatus = 'Quyền truy cập vị trí bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _dangLayViTri = false;
          _viTriStatus =
              'Quyền vị trí bị từ chối vĩnh viễn trong cài đặt thiết bị';
        });
        return;
      }

      // 3. Lấy vị trí GPS chính xác cao
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _viDo = position.latitude;
        _kinhDo = position.longitude;
        _dangLayViTri = false;
        _viTriStatus =
            'Đã lấy tọa độ: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });

      if (mounted && showDialogPrompt) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã lấy vị trí: Vĩ độ ${_viDo!.toStringAsFixed(5)}, Kinh độ ${_kinhDo!.toStringAsFixed(5)}',
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi lấy GPS: $e');
      if (!mounted) return;
      setState(() {
        _dangLayViTri = false;
        _viTriStatus = 'Không thể lấy GPS (Nhấn nút để thử lại)';
      });
    }
  }

  /// ✅ HÀM MỞ THƯ MỤC TỆP CỦA THIẾT BỊ ĐỂ TẢI LÊN
  Future<void> _chonTepTuThietBi() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final lengthBytes = (await file.length()) ?? file.lengthSync() ?? 0;
        final sizeKb = lengthBytes / 1024;
        final sizeText = sizeKb >= 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB • Đã tải lên'
            : '${sizeKb.toStringAsFixed(0)} KB • Đã tải lên';

        setState(() {
          _tenFileDinhKem = file.name;
          _dungLuongFile = sizeText;
          _filePath = file.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã chọn tệp: ${file.name}'),
              backgroundColor: const Color(0xFF0284C7),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi mở thư mục tệp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở thư mục tệp thiết bị: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guiYeuCau() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final hospitalUid = _getHospitalUid();
      final randSuffix = Random().nextInt(900) + 100;
      final maHoSo = '#HS-BV-2026$randSuffix';

      final coSoValue =
          _loaiHinh.contains('Công lập') ? 'Công lập' : 'Tư nhân';
      final bhytValue = _coBhyt ? 'Có BHYT' : 'Không BHYT';

      // ✅ Đầy đủ thông tin bao gồm tọa độ vị trí (vi_do, kinh_do)
      final dataToSave = {
        'uid': hospitalUid,
        'benh_vien_id': hospitalUid,
        'ma_benh_vien': hospitalUid,
        'ten_benh_vien': _tenBenhVienCtrl.text.trim(),
        'ma_co_so_byt': _maCoSoCtrl.text.trim(),
        'so_giay_phep': _maCoSoCtrl.text.trim(),
        'ma_so_thue': _maSoThueCtrl.text.trim(),
        'dia_chi': _diaChiCtrl.text.trim(),
        'loai_hinh': _loaiHinh,
        'co_so': coSoValue,
        'co_bhyt': _coBhyt,
        'bhyt': bhytValue,
        'file_giay_phep': _tenFileDinhKem,
        'ma_ho_so': maHoSo,
        'da_gui_don': true,
        'trang_thai_hop_tac_id': 1, // 1: Chờ duyệt
        'vi_do': _viDo,
        'kinh_do': _kinhDo,
        'ngay_gui_don': FieldValue.serverTimestamp(),
        'thoi_gian_gui_str': DateTime.now().toIso8601String(),
      };

      // 1. Lưu trực tiếp vào doc BenhVien/{uid} (chứa kinh_do, vi_do)
      await FirebaseFirestore.instance
          .collection('BenhVien')
          .doc(hospitalUid)
          .set(dataToSave, SetOptions(merge: true));

      // 2. Lưu vào collection YeuCauHopTac để Admin quản lý phê duyệt
      try {
        await FirebaseFirestore.instance
            .collection('YeuCauHopTac')
            .doc(hospitalUid)
            .set(dataToSave, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Lưu YeuCauHopTac: $e');
      }

      // Cập nhật AppSession
      AppSession.benhVienId = hospitalUid;

      if (!mounted) return;

      // 3. Chuyển sang màn hình Đã Gửi Đơn Thành Công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GuiDonThanhCongScreen(
            maHoSo: maHoSo,
            tenBenhVien: _tenBenhVienCtrl.text.trim(),
            loaiHinh: _loaiHinh,
            coBhyt: _coBhyt,
            hospitalUid: hospitalUid,
            extraData: dataToSave,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi hồ sơ lên hệ thống: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
        title: const Text(
          'Gửi Yêu Cầu Hợp Tác',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. TÊN BỆNH VIỆN (KHÔNG ĐƯỢC PHÉP THAY ĐỔI)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildLabelWithRequired('Tên bệnh viện'),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cố định theo tài khoản',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tenBenhVienCtrl,
                      readOnly: true, // ✅ KHÔNG CHO PHÉP THAY ĐỔI
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tên bệnh viện',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 2. VỊ TRÍ BỆNH VIỆN (TỌA ĐỘ GPS KINH ĐỘ & VĨ ĐỘ)
                    // ==========================================
                    _buildLocationSection(),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 3. MÃ CƠ SỞ (BYT) & MÃ SỐ THUẾ
                    // ==========================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 360) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelWithRequired('Mã cơ sở (BYT)'),
                              const SizedBox(height: 6),
                              _buildMaCoSoField(),
                              const SizedBox(height: 14),
                              _buildLabel('Mã số thuế'),
                              const SizedBox(height: 6),
                              _buildMaSoThueField(),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabelWithRequired('Mã cơ sở (BYT)'),
                                  const SizedBox(height: 6),
                                  _buildMaCoSoField(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Mã số thuế'),
                                  const SizedBox(height: 6),
                                  _buildMaSoThueField(),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 4. ĐỊA CHỈ TRỤ SỞ
                    // ==========================================
                    _buildLabelWithRequired('Địa chỉ trụ sở'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _diaChiCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Số nhà, đường, phường, quận, tỉnh/thành',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập địa chỉ trụ sở';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 5. LOẠI HÌNH BỆNH VIỆN (SPINNER / DROPDOWN)
                    // ==========================================
                    _buildLabelWithRequired('Loại hình bệnh viện'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _loaiHinh,
                      isExpanded: true,
                      decoration: _inputDecoration(hintText: 'Chọn loại hình'),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF0284C7),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bệnh viện Công lập',
                          child: Text(
                            'Bệnh viện Công lập',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Bệnh viện Tư lập',
                          child: Text(
                            'Bệnh viện Tư lập',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Phòng khám Đa khoa',
                          child: Text(
                            'Phòng khám Đa khoa',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Trung tâm Y tế',
                          child: Text(
                            'Trung tâm Y tế',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _loaiHinh = val);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 6. KHÁM CHỮA BỆNH BHYT (SPINNER / DROPDOWN)
                    // ==========================================
                    _buildLabelWithRequired('Tiếp nhận khám chữa bệnh BHYT'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _coBhyt ? 'Có BHYT' : 'Không BHYT',
                      isExpanded: true,
                      decoration:
                          _inputDecoration(hintText: 'Chọn chính sách BHYT'),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF0284C7),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Có BHYT',
                          child: Text(
                            'Có BHYT (Áp dụng BHYT toàn tuyến)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Không BHYT',
                          child: Text(
                            'Không BHYT (Khám chữa bệnh dịch vụ 100%)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _coBhyt = (val == 'Có BHYT'));
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // 7. GIẤY PHÉP HOẠT ĐỘNG (MỞ THƯ MỤC THIẾT BỊ)
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildLabel(
                            'Giấy phép hoạt động y tế (Đính kèm)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PDF, DOCX, Ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAttachedFileCard(),
                    const SizedBox(height: 28),

                    // Nút Gửi đơn xác nhận & Đăng ký
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaCoSoField() {
    return TextFormField(
      controller: _maCoSoCtrl,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        hintText: 'BV-79-102',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Nhập mã BYT';
        }
        return null;
      },
    );
  }

  Widget _buildMaSoThueField() {
    return TextFormField(
      controller: _maSoThueCtrl,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(
        hintText: '0312891201',
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _guiYeuCau,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.near_me_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Gửi Đơn Xác Nhận & Đăng Ký',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Khối hiển thị & lấy vị trí GPS
  Widget _buildLocationSection() {
    final coToaDo = _viDo != null && _kinhDo != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: coToaDo ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: coToaDo ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 20,
                color:
                    coToaDo ? const Color(0xFF16A34A) : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tọa độ GPS cơ sở y tế',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_dangLayViTri)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: () => _yeuCauLayViTri(showDialogPrompt: true),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          coToaDo
                              ? Icons.refresh_rounded
                              : Icons.my_location_rounded,
                          size: 15,
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coToaDo ? 'Lấy lại' : 'Lấy vị trí',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (coToaDo)
            Text(
              'Vĩ độ (Lat): ${_viDo!.toStringAsFixed(6)}  •  Kinh độ (Lng): ${_kinhDo!.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              _viTriStatus ??
                  'Nhấn nút để lấy vị trí GPS hiện tại của bệnh viện',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildLabelWithRequired(String label) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  /// Khối tệp đính kèm với nút mở thư mục tệp thiết bị
  Widget _buildAttachedFileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 22,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenFileDinhKem,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _dungLuongFile,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _chonTepTuThietBi,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Chọn tệp',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
