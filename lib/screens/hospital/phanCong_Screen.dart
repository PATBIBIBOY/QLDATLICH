import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_session.dart';
import '../../models/nhan_vien_model.dart';
import '../../services/khoa_service.dart';

/// Thông tin phòng khám hiển thị trên màn phân công
class PhongItemPhanCong {
  final String id;
  final String tenPhong;
  final String gioMoCua;
  final String gioDongCua;
  final int soBenhNhanToiDa;
  final String thoiGianKham;

  const PhongItemPhanCong({
    required this.id,
    required this.tenPhong,
    required this.gioMoCua,
    required this.gioDongCua,
    required this.soBenhNhanToiDa,
    required this.thoiGianKham,
  });

  String get thoiGianVaDiaDiem {
    final gio = (gioMoCua.isNotEmpty && gioDongCua.isNotEmpty)
        ? '$gioMoCua - $gioDongCua'
        : '07:30 - 17:00';
    return '$gio · Tối đa $soBenhNhanToiDa BN/ca';
  }
}

/// Màn hình Phân Công Trực - Đồng bộ 100% Firebase Firestore (Không dùng hashcode)
class PhanCongScreen extends StatefulWidget {
  final bool isTab;
  final String? benhVienId;

  const PhanCongScreen({
    super.key,
    this.isTab = true,
    this.benhVienId,
  });

  @override
  State<PhanCongScreen> createState() => _PhanCongScreenState();
}

class _PhanCongScreenState extends State<PhanCongScreen> {
  late String _bvid;
  DateTime _ngayDuocChon = DateTime.now();
  String? _selectedKhoaId;

  String get _ngayStr =>
      '${_ngayDuocChon.year}-${_ngayDuocChon.month.toString().padLeft(2, '0')}-${_ngayDuocChon.day.toString().padLeft(2, '0')}';

  String _getHospitalId() {
    if (widget.benhVienId != null && widget.benhVienId!.trim().isNotEmpty) {
      return widget.benhVienId!.trim();
    }
    if (AppSession.benhVienId.isNotEmpty) {
      return AppSession.benhVienId;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _bvid = _getHospitalId();
    _khoiTao();
  }

  Future<void> _khoiTao() async {
    if (!_bvid.startsWith('BV')) {
      final chuan = await KhoaService().chuanHoaBenhVienId(_bvid);
      if (chuan.isNotEmpty && chuan != _bvid && mounted) {
        setState(() {
          _bvid = chuan;
        });
        AppSession.benhVienId = chuan;
      }
    }
  }

  String _dinhDangThuNgay(DateTime dt) {
    const listThu = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final thu = listThu[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$thu, $d/$m/$y';
  }

  void _doiNgay(int offsetDays) {
    setState(() {
      _ngayDuocChon = _ngayDuocChon.add(Duration(days: offsetDays));
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NV';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Color _getAvatarBg(String id) {
    final colors = [
      const Color(0xFFEFF6FF),
      const Color(0xFFFEF3C7),
      const Color(0xFFFFEDD5),
      const Color(0xFFDCFCE7),
      const Color(0xFFF3E8FF),
      const Color(0xFFFCE7F3),
    ];
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  Color _getAvatarTextColor(String id) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFD97706),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFF9333EA),
      const Color(0xFFDB2777),
    ];
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  /// Mở Bottom Sheet chọn nhân viên trực theo chuyên khoa và bệnh viện
  void _moSheetChonNhanVien({
    required PhongItemPhanCong phong,
    required String khoaId,
    required String tenKhoa,
    required String prefixKhoa,
    required List<NhanVienModel> tatCaNhanVienBv,
    required Map<String, Map<String, dynamic>> phanCongTrongNgay,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChonNhanVienModal(
        benhVienId: _bvid,
        ngayStr: _ngayStr,
        ngayHienThi: _dinhDangThuNgay(_ngayDuocChon),
        phong: phong,
        khoaId: khoaId,
        tenKhoa: tenKhoa,
        prefixKhoa: prefixKhoa,
        tatCaNhanVienBv: tatCaNhanVienBv,
        phanCongTrongNgay: phanCongTrongNgay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Phân Công Trực
            _buildHeader(),

            // Stream danh sách khoa của bệnh viện
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Khoa')
                    .doc(_bvid)
                    .collection('danh_sach')
                    .snapshots(),
                builder: (context, khoaSnap) {
                  if (khoaSnap.hasError) {
                    return Center(
                      child: Text('Lỗi tải dữ liệu khoa: ${khoaSnap.error}'),
                    );
                  }
                  if (!khoaSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final dsKhoaDocs = khoaSnap.data!.docs;
                  if (dsKhoaDocs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bệnh viện chưa tạo khoa khám nào.\nVui lòng thêm khoa khám trước khi phân công.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                        ),
                      ),
                    );
                  }

                  // Tự động chọn khoa đầu tiên nếu chưa chọn hoặc khoa cũ bị xóa
                  QueryDocumentSnapshot<Map<String, dynamic>> khoaHienTaiDoc =
                      dsKhoaDocs.first;
                  for (final d in dsKhoaDocs) {
                    if (d.id == _selectedKhoaId) {
                      khoaHienTaiDoc = d;
                      break;
                    }
                  }
                  final currentKhoaId = khoaHienTaiDoc.id;
                  final khoaData = khoaHienTaiDoc.data();
                  final tenKhoaHienTai = (khoaData['tenKhoa'] ??
                          khoaData['ten_khoa'] ??
                          'Khoa khám')
                      .toString();
                  final prefixKhoaHienTai = (khoaData['prefixKhoa'] ??
                          khoaData['prefix_khoa'] ??
                          '')
                      .toString();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    // Stream toàn bộ phân công của bệnh viện trong ngày được chọn
                    stream: FirebaseFirestore.instance
                        .collection('PhanCong')
                        .doc(_bvid)
                        .collection('danh_sach')
                        .where('ngay', isEqualTo: _ngayStr)
                        .snapshots(),
                    builder: (context, phanCongSnap) {
                      final phanCongTrongNgay = <String, Map<String, dynamic>>{};
                      if (phanCongSnap.hasData) {
                        for (final doc in phanCongSnap.data!.docs) {
                          final data = doc.data();
                          final pId = (data['phong_id'] ?? data['ten_phong'] ?? '')
                              .toString();
                          if (pId.isNotEmpty) {
                            phanCongTrongNgay[pId] = data;
                          }
                        }
                      }

                      // Stream nhân viên của bệnh viện
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('NhanVien')
                            .doc(_bvid)
                            .collection('danh_sach')
                            .snapshots(),
                        builder: (context, nvSnap) {
                          final dsNhanVien = <NhanVienModel>[];
                          if (nvSnap.hasData) {
                            for (final d in nvSnap.data!.docs) {
                              final nv = NhanVienModel.fromDoc(d);
                              // Chỉ lấy tài khoản nhân sự đã kích hoạt theo yêu cầu
                              if (nv.daKichHoat) {
                                dsNhanVien.add(nv);
                              }
                            }
                          }

                          // Stream phòng khám của khoa hiện tại
                          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('Khoa')
                                .doc(_bvid)
                                .collection('danh_sach')
                                .doc(currentKhoaId)
                                .collection('phongKham')
                                .snapshots(),
                            builder: (context, phongSnap) {
                              final dsPhong = <PhongItemPhanCong>[];
                              if (phongSnap.hasData) {
                                for (final d in phongSnap.data!.docs) {
                                  final p = d.data();
                                  final ten = (p['tenPhong'] ??
                                          p['ten_phong'] ??
                                          p['id'] ??
                                          d.id)
                                      .toString();
                                  dsPhong.add(PhongItemPhanCong(
                                    id: d.id,
                                    tenPhong: ten,
                                    gioMoCua: (p['gioMoCua'] ?? p['gio_mo_cua'] ?? '')
                                        .toString(),
                                    gioDongCua: (p['gioDongCua'] ?? p['gio_dong_cua'] ?? '')
                                        .toString(),
                                    soBenhNhanToiDa: (p['soBenhNhanToiDa'] ??
                                            p['so_benh_nhan_toi_da'] ??
                                            45) as int,
                                    thoiGianKham: (p['thoiGianKham'] ??
                                            p['thoi_gian_kham'] ??
                                            '15')
                                        .toString(),
                                  ));
                                }
                              }

                              dsPhong.sort((a, b) => a.tenPhong.compareTo(b.tenPhong));

                              // Đếm số phòng đã được phân công trực
                              final soPhongDaPhanCong = dsPhong
                                  .where((p) => phanCongTrongNgay.containsKey(p.tenPhong))
                                  .length;
                              final tongSoPhong = dsPhong.length;
                              final phongChuaPhanCong = dsPhong
                                  .where((p) => !phanCongTrongNgay.containsKey(p.tenPhong))
                                  .toList();

                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Chọn ngày trực
                                    const Text(
                                      'Chọn ngày trực',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Thanh điều hướng chọn ngày
                                    _buildDatePickerBar(),

                                    const SizedBox(height: 16),

                                    // Thanh chuyển khoa (Chuyên khoa)
                                    const Text(
                                      'Chuyên khoa',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildKhoaSelector(
                                      dsKhoaDocs: dsKhoaDocs,
                                      currentKhoaId: currentKhoaId,
                                    ),

                                    const SizedBox(height: 20),

                                    // Tiêu đề Khoa và số phòng đã phân công
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tenKhoaHienTai,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$soPhongDaPhanCong/$tongSoPhong phòng đã phân công',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: soPhongDaPhanCong == tongSoPhong &&
                                                    tongSoPhong > 0
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Danh sách các phòng
                                    if (dsPhong.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Khoa này chưa có phòng khám nào.',
                                            style: TextStyle(color: Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      )
                                    else
                                      ...dsPhong.map(
                                        (p) => _buildCardPhong(
                                          phong: p,
                                          phanCong: phanCongTrongNgay[p.tenPhong],
                                          khoaId: currentKhoaId,
                                          tenKhoa: tenKhoaHienTai,
                                          prefixKhoa: prefixKhoaHienTai,
                                          tatCaNhanVienBv: dsNhanVien,
                                          phanCongTrongNgay: phanCongTrongNgay,
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // Banner thông báo nếu còn phòng chưa có người trực
                                    if (phongChuaPhanCong.isNotEmpty) ...[
                                      _buildWarningBanner(phongChuaPhanCong),
                                      const SizedBox(height: 16),
                                    ],

                                    // Khung Lưu ý phân công
                                    _buildNoteBox(),

                                    const SizedBox(height: 20),

                                    // Nút Lưu Phân Công
                                    _buildSaveButton(
                                      soPhongDaPhanCong: soPhongDaPhanCong,
                                      tongSoPhong: tongSoPhong,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGETS CON ====================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (!widget.isTab) ...[
            InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Phân Công Trực',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mỗi phòng khám 1 người trực theo chuyên khoa',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isTab) const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildDatePickerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _doiNgay(-1),
            icon: const Icon(Icons.chevron_left_rounded,
                color: Color(0xFF475569)),
            splashRadius: 20,
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _ngayDuocChon,
                firstDate: DateTime(2025),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() => _ngayDuocChon = picked);
              }
            },
            child: Text(
              _dinhDangThuNgay(_ngayDuocChon),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _doiNgay(1),
            icon: const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF475569)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildKhoaSelector({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> dsKhoaDocs,
    required String currentKhoaId,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: dsKhoaDocs.map((doc) {
          final isSelected = doc.id == currentKhoaId;
          final data = doc.data();
          final ten = (data['tenKhoa'] ?? data['ten_khoa'] ?? doc.id).toString();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedKhoaId = doc.id;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x332563EB),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  ten,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardPhong({
    required PhongItemPhanCong phong,
    required Map<String, dynamic>? phanCong,
    required String khoaId,
    required String tenKhoa,
    required String prefixKhoa,
    required List<NhanVienModel> tatCaNhanVienBv,
    required Map<String, Map<String, dynamic>> phanCongTrongNgay,
  }) {
    final daPhanCong = phanCong != null;

    if (!daPhanCong) {
      // Card viền nét đứt màu cam (Phòng chưa phân công)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0xFFF59E0B),
            strokeWidth: 1.5,
            radius: 18,
            dashWidth: 6,
            dashSpace: 4,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Icon phòng khám (Cam)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.table_restaurant_outlined,
                      color: Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tên phòng & giờ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phong.tenPhong,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phong.thoiGianVaDiaDiem,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút + Phân công
                InkWell(
                  onTap: () => _moSheetChonNhanVien(
                    phong: phong,
                    khoaId: khoaId,
                    tenKhoa: tenKhoa,
                    prefixKhoa: prefixKhoa,
                    tatCaNhanVienBv: tatCaNhanVienBv,
                    phanCongTrongNgay: phanCongTrongNgay,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '+ Phân công',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
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

    // Card phòng đã phân công (Viền xám nhẹ, nền trắng)
    final maNv = (phanCong['nhan_vien_id'] ?? phanCong['ma_nhan_vien'] ?? '').toString();
    final tenNv = (phanCong['ten_nhan_vien'] ?? 'Nhân viên trực').toString();
    final vaiTroNv = (phanCong['vai_tro'] ?? 'Hỗ trợ bác sĩ').toString();
    final initials = _getInitials(tenNv);
    final avBg = _getAvatarBg(maNv);
    final avTxt = _getAvatarTextColor(maNv);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _moSheetChonNhanVien(
          phong: phong,
          khoaId: khoaId,
          tenKhoa: tenKhoa,
          prefixKhoa: prefixKhoa,
          tatCaNhanVienBv: tatCaNhanVienBv,
          phanCongTrongNgay: phanCongTrongNgay,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon phòng (Xanh dương)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.table_restaurant_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thông tin phòng
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phong.tenPhong,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phong.thoiGianVaDiaDiem,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Nhân viên trực
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: avBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: avTxt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tenNv,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Đã phân công',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$vaiTroNv ($maNv)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner(List<PhongItemPhanCong> danhSachChuaCo) {
    final tenPhongChua = danhSachChuaCo.map((p) => p.tenPhong).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.priority_high_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Còn ${danhSachChuaCo.length} phòng chưa có người trực',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tenPhongChua hiện chưa được phân công',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quy định phân công:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Nhân viên của bệnh viện nào chỉ hoạt động và phân công tại bệnh viện đó.\n'
            '• Nhân viên chỉ được phân công vào các phòng khám thuộc đúng chuyên khoa của mình.\n'
            '• Mỗi phòng khám phân công 1 người trực bấm số xuyên suốt ca trực trong ngày.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton({
    required int soPhongDaPhanCong,
    required int tongSoPhong,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dữ liệu phân công trực ngày $_ngayStr đã được lưu hoàn tất ($soPhongDaPhanCong/$tongSoPhong phòng).',
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Lưu Phân Công',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet chọn nhân viên trực (Chỉ lấy nhân viên đúng bệnh viện & đúng chuyên khoa)
class _ChonNhanVienModal extends StatefulWidget {
  final String benhVienId;
  final String ngayStr;
  final String ngayHienThi;
  final PhongItemPhanCong phong;
  final String khoaId;
  final String tenKhoa;
  final String prefixKhoa;
  final List<NhanVienModel> tatCaNhanVienBv;
  final Map<String, Map<String, dynamic>> phanCongTrongNgay;

  const _ChonNhanVienModal({
    required this.benhVienId,
    required this.ngayStr,
    required this.ngayHienThi,
    required this.phong,
    required this.khoaId,
    required this.tenKhoa,
    required this.prefixKhoa,
    required this.tatCaNhanVienBv,
    required this.phanCongTrongNgay,
  });

  @override
  State<_ChonNhanVienModal> createState() => _ChonNhanVienModalState();
}

class _ChonNhanVienModalState extends State<_ChonNhanVienModal> {
  String _tuKhoa = '';
  NhanVienModel? _nhanVienDuocChon;
  bool _isSaving = false;

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'NV';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Color _getAvatarBg(String id) {
    final colors = [
      const Color(0xFFEFF6FF),
      const Color(0xFFFEF3C7),
      const Color(0xFFFFEDD5),
      const Color(0xFFDCFCE7),
      const Color(0xFFF3E8FF),
      const Color(0xFFFCE7F3),
    ];
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  Color _getAvatarTextColor(String id) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFD97706),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFF9333EA),
      const Color(0xFFDB2777),
    ];
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  @override
  void initState() {
    super.initState();
    final pcHienTai = widget.phanCongTrongNgay[widget.phong.tenPhong];
    if (pcHienTai != null) {
      final curNvId = (pcHienTai['nhan_vien_id'] ?? pcHienTai['ma_nhan_vien'] ?? '')
          .toString();
      for (final nv in widget.tatCaNhanVienBv) {
        if (nv.maNv == curNvId || nv.id == curNvId) {
          _nhanVienDuocChon = nv;
          break;
        }
      }
    }
  }

  /// Lọc danh sách nhân viên:
  /// 1. Phải thuộc đúng bệnh viện (benhVienId)
  /// 2. Phải thuộc đúng chuyên khoa được phân công (tenKhoa hoặc prefixKhoa)
  List<NhanVienModel> _locNhanVienTheoChuyenKhoa() {
    final tenKhoaChuan = widget.tenKhoa.trim().toLowerCase();
    final prefixChuan = widget.prefixKhoa.trim().toLowerCase();

    return widget.tatCaNhanVienBv.where((nv) {
      // 0. Phải là nhân sự đã kích hoạt (yêu cầu từ người dùng)
      if (!nv.daKichHoat) return false;

      // 1. Kiểm tra bệnh viện
      if (nv.benhVienId.isNotEmpty &&
          widget.benhVienId.isNotEmpty &&
          nv.benhVienId != widget.benhVienId) {
        return false;
      }

      // 2. Kiểm tra chuyên khoa được phân công lúc tạo
      final nvKhoa = nv.khoa.trim().toLowerCase();
      final matchKhoa = nvKhoa.isNotEmpty &&
          (nvKhoa == tenKhoaChuan ||
              nvKhoa.contains(tenKhoaChuan) ||
              tenKhoaChuan.contains(nvKhoa));

      final matchPrefix = prefixChuan.isNotEmpty &&
          (nv.maNv.toLowerCase().contains('_${prefixChuan}_') ||
              nv.id.toLowerCase().contains('_${prefixChuan}_') ||
              nv.maNv.toLowerCase().endsWith('_$prefixChuan') ||
              nv.id.toLowerCase().endsWith('_$prefixChuan'));

      if (!matchKhoa && !matchPrefix) {
        return false;
      }

      // 3. Tìm kiếm theo từ khóa
      if (_tuKhoa.isNotEmpty) {
        final matchTen = nv.hoTen.toLowerCase().contains(_tuKhoa.toLowerCase());
        final matchMa = nv.maNv.toLowerCase().contains(_tuKhoa.toLowerCase());
        return matchTen || matchMa;
      }

      return true;
    }).toList();
  }

  /// Lưu phân công trực vào Firestore (Không hashcode, cập nhật trạng thái 16 "đã phân công" trực tiếp vào nhân viên)
  Future<void> _xacNhanPhanCong(NhanVienModel nv) async {
    setState(() => _isSaving = true);
    try {
      final docId = '${widget.ngayStr}_${widget.phong.tenPhong}';
      final batch = FirebaseFirestore.instance.batch();

      // 0. Nếu phòng này trước đó đã có người trực khác, chuyển trạng thái người cũ về 15 ("chờ")
      final pcHienTai = widget.phanCongTrongNgay[widget.phong.tenPhong];
      if (pcHienTai != null) {
        final oldNvId = (pcHienTai['nhan_vien_id'] ?? pcHienTai['ma_nhan_vien'] ?? '').toString();
        if (oldNvId.isNotEmpty && oldNvId != nv.maNv) {
          final oldNvRef = FirebaseFirestore.instance
              .collection('NhanVien')
              .doc(widget.benhVienId)
              .collection('danh_sach')
              .doc(oldNvId);
          batch.set(oldNvRef, {
            'trang_thai_id': 15,
            'trang_thai': 'chờ',
            'trang_thai_phan_cong': FieldValue.delete(),
            'trang_thai_phan_cong_id': FieldValue.delete(),
            'ngay_phan_cong': null,
            'phong_phan_cong': null,
            'khoa_phan_cong': null,
            'lich_phan_cong': {
              widget.ngayStr: {
                'trang_thai_id': 15,
                'trang_thai': 'chờ',
                'ngay': widget.ngayStr,
                'ngay_cap_nhat': FieldValue.serverTimestamp(),
              }
            },
          }, SetOptions(merge: true));
        }
      }

      // 1. Cập nhật nhân viên được phân công vào NhanVien/{bvid}/danh_sach/{maNv}
      // Trạng thái: id = 16, ten_trang_thai = "đã phân công" (khớp collection TrangThai doc 16)
      final nvDocId = nv.id.isNotEmpty ? nv.id : nv.maNv;
      final nvRef = FirebaseFirestore.instance
          .collection('NhanVien')
          .doc(widget.benhVienId)
          .collection('danh_sach')
          .doc(nvDocId);

      batch.set(nvRef, {
        'trang_thai_id': 16,
        'trang_thai': 'đã phân công',
        'trang_thai_phan_cong': FieldValue.delete(),
        'trang_thai_phan_cong_id': FieldValue.delete(),
        'ngay_phan_cong': widget.ngayStr,
        'phong_phan_cong': widget.phong.tenPhong,
        'khoa_phan_cong': widget.tenKhoa,
        'lich_phan_cong': {
          widget.ngayStr: {
            'trang_thai_id': 16,
            'trang_thai': 'đã phân công',
            'phong': widget.phong.tenPhong,
            'khoa': widget.tenKhoa,
            'ngay': widget.ngayStr,
            'ngay_cap_nhat': FieldValue.serverTimestamp(),
          }
        },
      }, SetOptions(merge: true));

      // 2. Lưu vào collection chuẩn PhanCong/{benhVienId}/danh_sach/{docId}
      final pcRef = FirebaseFirestore.instance
          .collection('PhanCong')
          .doc(widget.benhVienId)
          .collection('danh_sach')
          .doc(docId);

      batch.set(pcRef, {
        'id': docId,
        'ngay': widget.ngayStr,
        'benh_vien_id': widget.benhVienId,
        'khoa_id': widget.khoaId,
        'ten_khoa': widget.tenKhoa,
        'prefix_khoa': widget.prefixKhoa,
        'phong_id': widget.phong.tenPhong,
        'ten_phong': widget.phong.tenPhong,
        'nhan_vien_id': nv.maNv,
        'ma_nhan_vien': nv.maNv,
        'ten_nhan_vien': nv.hoTen,
        'vai_tro': nv.vaiTro,
        'trang_thai_id': 16,
        'trang_thai': 'đã phân công',
        'ngay_cap_nhat': FieldValue.serverTimestamp(),
      });

      // 3. Cập nhật nhan_vien_id trong subcollection Khoa/.../phongKham
      final subPkRef = FirebaseFirestore.instance
          .collection('Khoa')
          .doc(widget.benhVienId)
          .collection('danh_sach')
          .doc(widget.khoaId)
          .collection('phongKham')
          .doc(widget.phong.tenPhong);

      batch.set(subPkRef, {
        'nhan_vien_id': nv.maNv,
        'nhanVienId': nv.maNv,
        'ten_nhan_vien': nv.hoTen,
        'vai_tro_nhan_vien': nv.vaiTro,
      }, SetOptions(merge: true));

      // 4. Cập nhật nhan_vien_id trong root collection PhongKham
      final pkDocId = '${widget.benhVienId}_${widget.khoaId}_${widget.phong.tenPhong}';
      final rootPkRef =
          FirebaseFirestore.instance.collection('PhongKham').doc(pkDocId);

      batch.set(rootPkRef, {
        'nhan_vien_id': nv.maNv,
        'nhanVienId': nv.maNv,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã phân công ${nv.hoTen} (${nv.maNv}) trực ${widget.phong.tenPhong}!',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi phân công: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  /// Hủy phân công trực phòng này (chuyển trạng thái nhân viên về 15 "chờ")
  Future<void> _huyPhanCong() async {
    setState(() => _isSaving = true);
    try {
      final docId = '${widget.ngayStr}_${widget.phong.tenPhong}';
      final batch = FirebaseFirestore.instance.batch();

      // Cập nhật nhân viên đang trực về trạng thái 15 ("chờ")
      final pcHienTai = widget.phanCongTrongNgay[widget.phong.tenPhong];
      if (pcHienTai != null) {
        final curNvId = (pcHienTai['nhan_vien_id'] ?? pcHienTai['ma_nhan_vien'] ?? '').toString();
        if (curNvId.isNotEmpty) {
          final nvRef = FirebaseFirestore.instance
              .collection('NhanVien')
              .doc(widget.benhVienId)
              .collection('danh_sach')
              .doc(curNvId);

          batch.set(nvRef, {
            'trang_thai_id': 15,
            'trang_thai': 'chờ',
            'trang_thai_phan_cong': FieldValue.delete(),
            'trang_thai_phan_cong_id': FieldValue.delete(),
            'ngay_phan_cong': null,
            'phong_phan_cong': null,
            'khoa_phan_cong': null,
            'lich_phan_cong': {
              widget.ngayStr: {
                'trang_thai_id': 15,
                'trang_thai': 'chờ',
                'ngay': widget.ngayStr,
                'ngay_cap_nhat': FieldValue.serverTimestamp(),
              }
            },
          }, SetOptions(merge: true));
        }
      }

      final pcRef = FirebaseFirestore.instance
          .collection('PhanCong')
          .doc(widget.benhVienId)
          .collection('danh_sach')
          .doc(docId);
      batch.delete(pcRef);

      final subPkRef = FirebaseFirestore.instance
          .collection('Khoa')
          .doc(widget.benhVienId)
          .collection('danh_sach')
          .doc(widget.khoaId)
          .collection('phongKham')
          .doc(widget.phong.tenPhong);
      batch.set(subPkRef, {
        'nhan_vien_id': null,
        'nhanVienId': null,
        'ten_nhan_vien': null,
        'vai_tro_nhan_vien': null,
      }, SetOptions(merge: true));

      final pkDocId = '${widget.benhVienId}_${widget.khoaId}_${widget.phong.tenPhong}';
      final rootPkRef =
          FirebaseFirestore.instance.collection('PhongKham').doc(pkDocId);
      batch.set(rootPkRef, {
        'nhan_vien_id': null,
        'nhanVienId': null,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy phân công trực cho ${widget.phong.tenPhong}.'),
          backgroundColor: const Color(0xFF475569),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hủy phân công: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listNhanVienPhuHop = _locNhanVienTheoChuyenKhoa();
    final daCoPhanCong =
        widget.phanCongTrongNgay.containsKey(widget.phong.tenPhong);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo trên cùng
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề & nút đóng X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn nhân viên trực',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.phong.tenPhong} · ${widget.tenKhoa} · ${widget.ngayHienThi}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ô tìm kiếm nhân viên
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _tuKhoa = val.trim()),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc mã nhân viên...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Nhãn nhóm chuyên khoa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NHÂN VIÊN ${widget.tenKhoa.toUpperCase()} (${listNhanVienPhuHop.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                'Mã: ${widget.prefixKhoa}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Danh sách nhân viên
          Flexible(
            child: listNhanVienPhuHop.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có nhân viên nào thuộc ${widget.tenKhoa}.\nHãy cấp tài khoản nhân viên cho khoa này trong tab Nhân sự.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: listNhanVienPhuHop.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final nv = listNhanVienPhuHop[index];
                      final isSelected = _nhanVienDuocChon?.maNv == nv.maNv;

                      // Kiểm tra xem nhân viên này đã được phân công ở phòng nào khác trong ngày chưa
                      String? phongDangTrucKhac;
                      widget.phanCongTrongNgay.forEach((phongId, pcData) {
                        final assignedNvId = (pcData['nhan_vien_id'] ??
                                pcData['ma_nhan_vien'] ??
                                '')
                            .toString();
                        if (assignedNvId == nv.maNv &&
                            phongId != widget.phong.tenPhong) {
                          phongDangTrucKhac = phongId;
                        }
                      });

                      final isCurrentlyThisRoom = isSelected && daCoPhanCong;
                      final isBusyOtherRoom = phongDangTrucKhac != null;
                      final isAvailable = !isBusyOtherRoom;

                      final initials = _getInitials(nv.hoTen);
                      final avBg = _getAvatarBg(nv.maNv);
                      final avTxt = _getAvatarTextColor(nv.maNv);

                      final String trangThaiText;
                      final Color trangThaiBg;
                      final Color trangThaiTxt;

                      if (isCurrentlyThisRoom) {
                        trangThaiText = 'Đã phân công (16)';
                        trangThaiBg = const Color(0xFFDCFCE7);
                        trangThaiTxt = const Color(0xFF16A34A);
                      } else if (isBusyOtherRoom) {
                        trangThaiText = 'Đã phân công ($phongDangTrucKhac)';
                        trangThaiBg = const Color(0xFFEFF6FF);
                        trangThaiTxt = const Color(0xFF2563EB);
                      } else {
                        trangThaiText = 'Chờ (15)';
                        trangThaiBg = const Color(0xFFFEF3C7);
                        trangThaiTxt = const Color(0xFFD97706);
                      }

                      return InkWell(
                        onTap: isAvailable
                            ? () => setState(() => _nhanVienDuocChon = nv)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: avBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: avTxt,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Tên, Mã nhân viên & Vai trò
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nv.hoTen,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isAvailable
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${nv.vaiTro}  •  ${nv.maNv}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Trạng thái (Đang rảnh / Đang có ca khác)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: trangThaiBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  trangThaiText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: trangThaiTxt,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Checkbox / Radio
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                )
                              else if (isAvailable)
                                const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 22,
                                )
                              else
                                const SizedBox(width: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Nút xác nhận phân công
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nhanVienDuocChon != null && !_isSaving
                  ? () => _xacNhanPhanCong(_nhanVienDuocChon!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác nhận phân công',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          // Nút Hủy phân công nếu phòng này đã có người trực
          if (daCoPhanCong) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _huyPhanCong,
                icon: const Icon(Icons.person_remove_rounded,
                    size: 18, color: Color(0xFFDC2626)),
                label: const Text(
                  'Hủy phân công phòng này',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ],

          // Nút Đóng
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ viền nét đứt (Dashed Border) cho phòng chưa phân công
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
