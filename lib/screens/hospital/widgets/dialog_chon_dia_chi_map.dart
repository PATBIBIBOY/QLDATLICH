import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/geocoding_service.dart';

/// Màn hình Bản đồ toàn diện chọn vị trí cơ sở y tế
class DialogChonDiaChiMap extends StatefulWidget {
  final String initialAddress;

  const DialogChonDiaChiMap({
    super.key,
    required this.initialAddress,
  });

  /// Mở màn hình bản đồ toàn diện (Fullscreen) mượt mà trên cả Mobile & Web
  static Future<DiaChiMapItem?> show(
    BuildContext context, {
    String initialAddress = '',
  }) {
    return Navigator.of(context).push<DiaChiMapItem>(
      MaterialPageRoute(
        builder: (ctx) => DialogChonDiaChiMap(initialAddress: initialAddress),
      ),
    );
  }

  @override
  State<DialogChonDiaChiMap> createState() => _DialogChonDiaChiMapState();
}

class _DialogChonDiaChiMapState extends State<DialogChonDiaChiMap> {
  MapController? _mapController;
  late final TextEditingController _inputDiaChiCtrl;

  // Tọa độ ghim trên bản đồ (Mặc định: 11 Linh Trung, Thủ Đức, TP.HCM)
  LatLng _viTriGhim = const LatLng(10.86012, 106.77234);
  double _currentZoom = 16.0;

  String _diaChiHienThi =
      '11 Đường Linh Trung, Phường Linh Trung, TP. Thủ Đức, TP. Hồ Chí Minh';
  String _tenNgan = '11 Linh Trung, Thủ Đức';
  bool _isGeocoding = false;
  bool _isLocating = false;
  bool _xemCheDoDanhSach = false;
  Timer? _debounceTimer;

  // Danh sách các cơ sở y tế / khu vực gợi ý phổ biến tại Việt Nam
  static const List<Map<String, dynamic>> _goiYList = [
    {
      'ten': '11 Linh Trung, Thủ Đức',
      'diaChi':
          '11 Đường Linh Trung, Phường Linh Trung, Thành phố Thủ Đức, TP. Hồ Chí Minh',
      'lat': 10.86012,
      'lon': 106.77234,
    },
    {
      'ten': 'BV Chợ Rẫy (Q.5)',
      'diaChi': '201 Nguyễn Chí Thanh, Phường 12, Quận 5, TP. Hồ Chí Minh',
      'lat': 10.75782,
      'lon': 106.65985,
    },
    {
      'ten': 'BV Đại học Y Dược TP.HCM',
      'diaChi': '215 Hồng Bàng, Phường 11, Quận 5, TP. Hồ Chí Minh',
      'lat': 10.75545,
      'lon': 106.66092,
    },
    {
      'ten': 'BV Nhân Dân Gia Định',
      'diaChi': '1 Nơ Trang Long, Phường 7, Quận Bình Thạnh, TP. Hồ Chí Minh',
      'lat': 10.80386,
      'lon': 106.69485,
    },
    {
      'ten': 'BV Da Liễu TP.HCM',
      'diaChi':
          '29 Nguyễn Thị Diệu, Phường Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh',
      'lat': 10.77665,
      'lon': 106.68832,
    },
    {
      'ten': 'BV Bạch Mai (Hà Nội)',
      'diaChi': '78 Giải Phóng, Phường Phương Mai, Quận Đống Đa, Hà Nội',
      'lat': 20.99965,
      'lon': 105.84152,
    },
    {
      'ten': 'BV Đà Nẵng',
      'diaChi':
          '124 Hải Phòng, Phường Thạch Thang, Quận Hải Châu, TP. Đà Nẵng',
      'lat': 16.07231,
      'lon': 108.21654,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final init = widget.initialAddress.trim();
    _inputDiaChiCtrl = TextEditingController(text: init);

    if (init.isNotEmpty) {
      _diaChiHienThi = init;
      _tenNgan = init.contains(',') ? init.split(',').first.trim() : init;
    }

    // Tra cứu tọa độ địa chỉ ban đầu sau khi widget đã mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (init.isNotEmpty && mounted) {
        _traCuuDiaChiKhoiDau(init);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputDiaChiCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _traCuuDiaChiKhoiDau(String address) async {
    try {
      final items = await GeocodingService.timKiemDiaChi(address);
      if (items.isNotEmpty && mounted) {
        final first = items.first;
        setState(() {
          _viTriGhim = LatLng(first.viDo, first.kinhDo);
          _diaChiHienThi = first.diaChiDayDu;
          _tenNgan = first.tenNgan;
        });
      }
    } catch (_) {}
  }

  /// Hộp thoại hỏi người dùng cho phép mở định vị GPS
  Future<bool> _hienThiDialogHoiMoDinhVi() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF0284C7),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cho phép định vị GPS?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ứng dụng cần sử dụng vị trí thiết bị để tự động ghim vị trí cơ sở y tế trên bản đồ và nhận diện địa chỉ chính xác nhất.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '• Tự động điền số nhà, tên đường, phường/xã\n• Giúp người bệnh dễ dàng tìm đường đến khám',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Để sau',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Bật định vị',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Kích hoạt định vị GPS (có hỏi người dùng trước)
  Future<void> _kichHoatDinhViGPS({bool showDialogHoi = true}) async {
    if (showDialogHoi) {
      final dongY = await _hienThiDialogHoiMoDinhVi();
      if (!dongY) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chạm bản đồ hoặc nhập địa chỉ để chọn vị trí cơ sở y tế.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        _thongBaoNhacBatDichVuGPS();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        _thongBaoBiTuChoiQuyen();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final newLatLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _viTriGhim = newLatLng;
      });

      _traNguocToaDo(newLatLng.latitude, newLatLng.longitude);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Đã định vị thành công vị trí của bạn!'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy tọa độ GPS: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _thongBaoNhacBatDichVuGPS() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dịch vụ định vị đang tắt'),
        content: const Text(
          'Vui lòng bật tính năng Định vị vị trí (GPS) trên thiết bị của bạn để ứng dụng xác định vị trí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Mở cài đặt vị trí'),
          ),
        ],
      ),
    );
  }

  void _thongBaoBiTuChoiQuyen() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quyền định vị bị từ chối. Bạn có thể tự ghim trên bản đồ.'),
        backgroundColor: const Color(0xFFD97706),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cài đặt',
          textColor: Colors.white,
          onPressed: () => Geolocator.openAppSettings(),
        ),
      ),
    );
  }

  void _onMapTapped(LatLng point) {
    if (!mounted) return;
    setState(() {
      _viTriGhim = point;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _traNguocToaDo(point.latitude, point.longitude);
    });
  }

  Future<void> _traNguocToaDo(double lat, double lon) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final item = await GeocodingService.traNguocToaDo(lat, lon);
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        if (item != null) {
          _diaChiHienThi = item.diaChiDayDu;
          _tenNgan = item.tenNgan;
          _inputDiaChiCtrl.text = item.diaChiDayDu;
        } else {
          _diaChiHienThi =
              'Tọa độ: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
          _tenNgan = 'Vị trí đã chọn';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _apDungDiaChiNhap(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final results = await GeocodingService.timKiemDiaChi(q);
      if (!mounted) return;
      setState(() => _isGeocoding = false);

      if (results.isNotEmpty) {
        final first = results.first;
        final target = LatLng(first.viDo, first.kinhDo);

        setState(() {
          _viTriGhim = target;
          _diaChiHienThi = first.diaChiDayDu;
          _tenNgan = first.tenNgan;
        });
      } else {
        setState(() {
          _diaChiHienThi = q;
          _tenNgan = q.contains(',') ? q.split(',').first.trim() : q;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _moGoogleMapsNgoai() async {
    final query = _inputDiaChiCtrl.text.trim().isNotEmpty
        ? _inputDiaChiCtrl.text.trim()
        : _diaChiHienThi;
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn vị trí cơ sở y tế',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Chạm bản đồ hoặc nhập địa chỉ để đặt ghim',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _xemCheDoDanhSach ? 'Xem Bản đồ' : 'Xem Danh sách gợi ý',
            icon: Icon(
              _xemCheDoDanhSach
                  ? Icons.map_rounded
                  : Icons.format_list_bulleted_rounded,
              color: const Color(0xFF0284C7),
            ),
            onPressed: () {
              setState(() {
                _xemCheDoDanhSach = !_xemCheDoDanhSach;
              });
            },
          ),
          IconButton(
            tooltip: 'Mở ứng dụng Google Maps ngoài',
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: _moGoogleMapsNgoai,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. THANH NHẬP ĐỊA CHỈ & TÌM KIẾM CỐ ĐỊNH Ở ĐẦU
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ô nhập địa chỉ tìm kiếm
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0284C7),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _inputDiaChiCtrl,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Nhập số nhà, tên đường, khu vực cần tìm...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: _apDungDiaChiNhap,
                          ),
                        ),
                        if (_inputDiaChiCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _inputDiaChiCtrl.clear();
                              setState(() {});
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ElevatedButton(
                            onPressed: _isGeocoding
                                ? null
                                : () =>
                                    _apDungDiaChiNhap(_inputDiaChiCtrl.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              elevation: 0,
                            ),
                            child: _isGeocoding
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Tìm',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Danh sách chip gợi ý ngang cuộn nhanh
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Chip Định vị vị trí (Có hỏi xác nhận)
                        InkWell(
                          onTap: _isLocating
                              ? null
                              : () => _kichHoatDinhViGPS(showDialogHoi: true),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isLocating
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0284C7),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        size: 13,
                                        color: Color(0xFF0284C7),
                                      ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Định vị của tôi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Các gợi ý bệnh viện / khu vực phổ biến
                        ..._goiYList.map((item) {
                          return InkWell(
                            onTap: () {
                              final point = LatLng(
                                item['lat'] as double,
                                item['lon'] as double,
                              );
                              _inputDiaChiCtrl.text = item['diaChi'].toString();
                              _onMapTapped(point);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                item['ten'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. PHẦN BẢN ĐỒ CHIẾM TOÀN BỘ PHẦN Ở GIỮA
            Expanded(
              child: _xemCheDoDanhSach
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _goiYList.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final item = _goiYList[idx];
                        final point = LatLng(
                            item['lat'] as double, item['lon'] as double);
                        final isSelected =
                            (_viTriGhim.latitude == point.latitude &&
                                _viTriGhim.longitude == point.longitude);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE0F2FE)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          title: Text(
                            item['ten'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            item['diaChi'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 22,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _xemCheDoDanhSach = false;
                            });
                            _inputDiaChiCtrl.text = item['diaChi'].toString();
                            _onMapTapped(point);
                          },
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFE2E8F0),
                      child: Stack(
                        children: [
                          FlutterMap(
                            key: ValueKey(
                              'map_full_${_viTriGhim.latitude}_${_viTriGhim.longitude}_$_currentZoom',
                            ),
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _viTriGhim,
                              initialZoom: _currentZoom,
                              minZoom: 4,
                              maxZoom: 19,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                              ),
                              onTap: (tapPosition, point) =>
                                  _onMapTapped(point),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                fallbackUrl:
                                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _viTriGhim,
                                    width: 140,
                                    height: 70,
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _tenNgan,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 42,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Nút Zoom (+ / -) và Nút Định vị GPS nhanh góc phải (dùng Material sạch sẽ)
                          Positioned(
                            right: 14,
                            bottom: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Nút GPS vị trí của tôi
                                Material(
                                  color: const Color(0xFF0284C7),
                                  shape: const CircleBorder(),
                                  elevation: 3,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _kichHoatDinhViGPS(showDialogHoi: true),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: _isLocating
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Nút Zoom In (+)
                                Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 3,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() {
                                        _currentZoom =
                                            (_currentZoom + 1).clamp(4.0, 19.0);
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Nút Zoom Out (-)
                                Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 3,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() {
                                        _currentZoom =
                                            (_currentZoom - 1).clamp(4.0, 19.0);
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Hướng dẫn chạm bản đồ góc dưới bên trái
                          Positioned(
                            left: 14,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Chạm bản đồ để dời ghim',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // 3. KHUNG XEM & XÁC NHẬN VỊ TRÍ CỐ ĐỊNH Ở ĐÁY MÀN HÌNH
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tenNgan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            _isGeocoding
                                ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Đang phân giải tên đường...',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _diaChiHienThi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                      height: 1.3,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(
                        DiaChiMapItem(
                          diaChiDayDu: _diaChiHienThi,
                          tenNgan: _tenNgan,
                          viDo: _viTriGhim.latitude,
                          kinhDo: _viTriGhim.longitude,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Xác nhận vị trí cơ sở này',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
