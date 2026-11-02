import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_session.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/benhVien_service.dart';
import '../../services/email_service.dart';
import 'guiDonThanhCong_Screen.dart';
import 'guiYeuCauHopTac_Screen.dart';
import 'listKhoaDieuTri.dart';
import 'nhanSu_Screen.dart';

/// 1240 -> "1,240"
String _soCoDauPhay(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// "Bệnh Viện Đa Khoa An Bình" -> "AB"
String _chuVietTat(String ten) {
  final tu = ten.split(' ').where((e) => e.isNotEmpty).toList();
  if (tu.isEmpty) return 'AB';
  if (tu.length == 1) return tu[0].substring(0, 1).toUpperCase();
  return (tu.first[0] + tu.last[0]).toUpperCase();
}

class HomeHospitalScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeHospitalScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeHospitalScreen> createState() => _HomeHospitalScreenState();
}

class _HomeHospitalScreenState extends State<HomeHospitalScreen> {
  late int _currentBottomNavIndex;
  bool _dangGuiDon = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _yeuCauHopTacSub;
  String? _currentListeningBvId;
  int? _trangThaiTuYeuCauHopTac;

  @override
  void initState() {
    super.initState();
    _currentBottomNavIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.hospital == null) {
        auth.fetchCurrentUser(preferredRole: 'benh_vien');
      }
      _quetVaChuanHoaBenhVienDaGuiDon();
    });
  }

  @override
  void dispose() {
    _yeuCauHopTacSub?.cancel();
    super.dispose();
  }

  /// Lắng nghe realtime từ YeuCauHopTac: khi thay đổi trạng thái tại YeuCauHopTac (trên Firebase Console hoặc Admin)
  /// thì cập nhật ngay lập tức vào state của bệnh viện và đồng bộ sang BenhVien/{bvid}
  void _khoiTaoLangNgheYeuCauHopTac(String bvid) {
    if (bvid.isEmpty) return;

    _yeuCauHopTacSub?.cancel();
    _yeuCauHopTacSub = FirebaseFirestore.instance
        .collection('YeuCauHopTac')
        .doc(bvid)
        .snapshots()
        .listen((snap) {
          if (snap.exists && snap.data() != null) {
            final data = snap.data()!;
            final rawStatus = data['trang_thai_hop_tac_id'];
            if (rawStatus != null) {
              final int newStatus = rawStatus is int
                  ? rawStatus
                  : int.tryParse(rawStatus.toString()) ?? 1;

              if (_trangThaiTuYeuCauHopTac != newStatus) {
                if (mounted) {
                  setState(() {
                    _trangThaiTuYeuCauHopTac = newStatus;
                  });
                }
              }

              // Nếu trạng thái là 9 (Hủy / Từ chối) và chưa gửi mail thông báo
              if (newStatus == TrangThaiId.huyHopTac) {
                final bool daGuiMail = data['da_gui_mail_tu_choi'] == true;
                if (!daGuiMail) {
                  final String emailNhan = (data['email'] ??
                          FirebaseAuth.instance.currentUser?.email ??
                          '')
                      .toString();
                  final String tenBv =
                      (data['ten_benh_vien'] ?? 'Bệnh viện').toString();
                  if (emailNhan.isNotEmpty) {
                    EmailService.guiEmailTuChoiHopTac(
                      emailNguoiNhan: emailNhan,
                      tenBenhVien: tenBv,
                      maBenhVien: bvid,
                      lyDo: data['ly_do_tu_choi']?.toString(),
                    );
                    snap.reference.set(
                      {'da_gui_mail_tu_choi': true},
                      SetOptions(merge: true),
                    );
                  }
                }
              }

              // Tự động đồng bộ ngay sang BenhVien/{bvid} nếu khác nhau
              FirebaseFirestore.instance
                  .collection('BenhVien')
                  .doc(bvid)
                  .get()
                  .then((bvDoc) {
                    if (bvDoc.exists) {
                      final currentBvStatus = bvDoc
                          .data()?['trang_thai_hop_tac_id'];
                      if (currentBvStatus != newStatus) {
                        bvDoc.reference.set({
                          'trang_thai_hop_tac_id': newStatus,
                          'da_gui_don': newStatus != TrangThaiId.huyHopTac,
                          if (newStatus == TrangThaiId.huyHopTac)
                            'da_bi_tu_choi': true,
                        }, SetOptions(merge: true));
                      }
                    }
                  })
                  .catchError((_) {});
            }
          }
        });
  }

  void _chuanHoaDuLieuFirebaseNeuThieu(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return;
    final bool canCapNhat = data['bhyt'] == null ||
        data['co_so'] == null ||
        data['chuyen_khoa_ids'] == null;
    if (canCapNhat) {
      final updates = <String, dynamic>{};
      if (data['bhyt'] == null) {
        final coBhyt = data['co_bhyt'];
        updates['bhyt'] = (coBhyt == false) ? 'Khong_BHYT' : 'Co_BHYT';
      }
      if (data['co_so'] == null) {
        final loaiHinh = (data['loai_hinh'] ?? '').toString().toLowerCase();
        updates['co_so'] =
            (loaiHinh.contains('công') || loaiHinh.contains('cong'))
                ? 'Cong_lap'
                : 'Tu_nhan';
      }
      if (data['chuyen_khoa_ids'] == null) {
        updates['chuyen_khoa_ids'] = <String>[];
      }
      doc.reference.update(updates).catchError((_) {});
      try {
        FirebaseFirestore.instance
            .collection('YeuCauHopTac')
            .doc(doc.id)
            .set(updates, SetOptions(merge: true))
            .catchError((_) {});
      } catch (_) {}
    }
  }

  Future<void> _quetVaChuanHoaBenhVienDaGuiDon() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Quét và đồng bộ 2 chiều trạng thái giữa YeuCauHopTac và BenhVien
      final snapYeuCau = await firestore.collection('YeuCauHopTac').get();
      for (final doc in snapYeuCau.docs) {
        final data = doc.data();
        final rawStatus = data['trang_thai_hop_tac_id'];
        if (rawStatus != null) {
          final int statusId = rawStatus is int
              ? rawStatus
              : int.tryParse(rawStatus.toString()) ?? 1;

          final targetId = doc.id;
          final bvDocRef = firestore.collection('BenhVien').doc(targetId);
          final bvSnap = await bvDocRef.get();
          if (bvSnap.exists) {
            final currentBvStatus = bvSnap.data()?['trang_thai_hop_tac_id'];
            if (currentBvStatus != statusId) {
              await bvDocRef.set({
                'trang_thai_hop_tac_id': statusId,
                'da_gui_don': statusId != TrangThaiId.huyHopTac,
              }, SetOptions(merge: true));
            }
          }
        }
      }

      // 2. Chuẩn hóa co_so, bhyt, chuyen_khoa_ids
      final snapBv = await firestore
          .collection('BenhVien')
          .where('da_gui_don', isEqualTo: true)
          .get();
      for (final doc in snapBv.docs) {
        _chuanHoaDuLieuFirebaseNeuThieu(doc);
      }
    } catch (_) {}
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> _getHospitalStream(
    BuildContext context,
  ) {
    final auth = context.watch<AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final maBv =
        auth.hospital?.maBenhVien ?? auth.hospital?.uid ?? AppSession.benhVienId;

    if (maBv.isNotEmpty && maBv.startsWith('BV')) {
      return FirebaseFirestore.instance
          .collection('BenhVien')
          .doc(maBv)
          .snapshots();
    }

    if (user != null) {
      return FirebaseFirestore.instance
          .collection('BenhVien')
          .where('auth_uid', isEqualTo: user.uid)
          .limit(1)
          .snapshots()
          .asyncMap((q) async {
        if (q.docs.isNotEmpty) {
          final doc = q.docs.first;
          if (doc.id.startsWith('BV') && AppSession.benhVienId != doc.id) {
            AppSession.benhVienId = doc.id;
          }
          return doc;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          final qEmail = await FirebaseFirestore.instance
              .collection('BenhVien')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();
          if (qEmail.docs.isNotEmpty) {
            final doc = qEmail.docs.first;
            if (doc.id.startsWith('BV') && AppSession.benhVienId != doc.id) {
              AppSession.benhVienId = doc.id;
            }
            return doc;
          }
        }
        return await FirebaseFirestore.instance
            .collection('BenhVien')
            .doc(user.uid)
            .get();
      });
    }

    return const Stream.empty();
  }

  String _getHospitalUid(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.hospital?.maBenhVien != null && auth.hospital!.maBenhVien!.isNotEmpty) {
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

  // ignore: unused_element
  void _moModalGuiDon({
    required BuildContext context,
    required String hospitalUid,
    required String tenBenhVien,
    Map<String, dynamic>? currentData,
  }) {
    final giayPhepCtrl = TextEditingController(
      text: (currentData?['so_giay_phep'] ?? '').toString(),
    );
    final sdtCtrl = TextEditingController(
      text: (currentData?['so_dien_thoai_lh'] ??
              currentData?['so_dien_thoai'] ??
              '')
          .toString(),
    );
    String loaiHinh = (currentData?['loai_hinh'] ?? 'Bệnh viện đa khoa tư nhân')
        .toString();
    bool coBhyt = currentData?['co_bhyt'] ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Color(0xFF0284C7),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn Xác Nhận Hợp Tác',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gửi hồ sơ pháp lý đến Admin hệ thống',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Số giấy phép hoạt động khám chữa bệnh *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: giayPhepCtrl,
                    decoration: InputDecoration(
                      hintText: 'VD: 123/BYT-GPHĐ',
                      prefixIcon: const Icon(Icons.verified_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Số điện thoại đại diện liên hệ *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sdtCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'VD: 0912 345 678',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loại hình cơ sở y tế',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: loaiHinh,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Bệnh viện đa khoa tư nhân',
                        child: Text(
                          'Bệnh viện đa khoa tư nhân',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bệnh viện công lập',
                        child: Text(
                          'Bệnh viện công lập',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Phòng khám đa khoa quốc tế',
                        child: Text(
                          'Phòng khám đa khoa quốc tế',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => loaiHinh = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Có tiếp nhận khám Bảo hiểm Y tế (BHYT)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: coBhyt,
                    onChanged: (v) => setModalState(() => coBhyt = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _dangGuiDon
                          ? null
                          : () async {
                              final soGiayPhep = giayPhepCtrl.text.trim();
                              final sdt = sdtCtrl.text.trim();
                              if (soGiayPhep.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng nhập số giấy phép hoạt động',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => _dangGuiDon = true);
                              try {
                                final dataToSave = {
                                  'so_giay_phep': soGiayPhep,
                                  'so_dien_thoai_lh': sdt,
                                  'loai_hinh': loaiHinh,
                                  'co_bhyt': coBhyt,
                                  'da_gui_don': true,
                                  'da_bi_tu_choi': false,
                                  'da_gui_mail_tu_choi': false,
                                  if (FirebaseAuth.instance.currentUser?.email != null)
                                    'email': FirebaseAuth.instance.currentUser!.email,
                                  'ngay_gui_don': FieldValue.serverTimestamp(),
                                  'trang_thai_hop_tac_id': TrangThaiId.choDuyet,
                                };

                                // 1. Lưu trực tiếp vào doc BenhVien/{uid}
                                await FirebaseFirestore.instance
                                    .collection('BenhVien')
                                    .doc(hospitalUid)
                                    .set(
                                      dataToSave,
                                      SetOptions(merge: true),
                                    );

                                // 2. Lưu vào collection YeuCauHopTac để Admin truy vấn danh sách duyệt
                                await FirebaseFirestore.instance
                                    .collection('YeuCauHopTac')
                                    .doc(hospitalUid)
                                    .set({
                                      'benh_vien_id': hospitalUid,
                                      'ten_benh_vien': tenBenhVien,
                                      ...dataToSave,
                                    }, SetOptions(merge: true));

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã lưu hồ sơ lên Firebase và gửi đến Admin thành công!',
                                    ),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => _dangGuiDon = false);
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi khi gửi hồ sơ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _dangGuiDon
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Xác Nhận Gửi Hồ Sơ Lên Hệ Thống',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _thongBaoChuaKichHoat(String chucNang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chức năng "$chucNang" sẽ được mở sau khi Admin phê duyệt đơn hợp tác.',
        ),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalUid = _getHospitalUid(context);

    // Lắng nghe dữ liệu realtime từ Firestore của đúng tài khoản bệnh viện này
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: _getHospitalStream(context),
      builder: (context, snapshot) {
        final authProvider = context.watch<AuthProvider>();
        final data = snapshot.data?.data();

        final realId = snapshot.data?.id ?? hospitalUid;
        if (realId.startsWith('BV')) {
          if (AppSession.benhVienId != realId) {
            AppSession.benhVienId = realId;
          }
          if (_currentListeningBvId != realId) {
            _currentListeningBvId = realId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _khoiTaoLangNgheYeuCauHopTac(realId);
              }
            });
          }
        }

        // Tên bệnh viện động từ Firestore / AuthProvider / fallback
        final tenBenhVien = data?['ten_benh_vien'] ??
            data?['tenBenhVien'] ??
            authProvider.hospital?.tenBenhVien ??
            FirebaseAuth.instance.currentUser?.displayName ??
            'Bệnh viện';

        // Trạng thái hợp tác: 1 = Chờ duyệt, 9 = Hủy/Từ chối hợp tác, 10 = Hợp tác
        final rawTrangThaiId = _trangThaiTuYeuCauHopTac ??
            data?['trang_thai_hop_tac_id'] ??
            authProvider.hospital?.trangThaiHopTacId ??
            1;
        final int trangThaiId = (rawTrangThaiId is int)
            ? rawTrangThaiId
            : int.tryParse(rawTrangThaiId.toString()) ?? 1;

        // Trạng thái 9: Bị từ chối hoặc hủy hợp tác
        final bool isBiTuChoiHoacHuy = (trangThaiId == TrangThaiId.huyHopTac);

        // Bệnh viện đã gửi đơn hay chưa
        // Khi hủy hoặc từ chối hợp tác (trạng thái 9) thì màn hình chính của bệnh viện LUÔN nằm ở phần gửi hợp tác lại từ đầu
        final bool daGuiDon = !isBiTuChoiHoacHuy &&
            ((_trangThaiTuYeuCauHopTac != null &&
                    _trangThaiTuYeuCauHopTac != TrangThaiId.huyHopTac) ||
                (data?['da_gui_don'] == true) ||
                (data?['so_giay_phep'] != null &&
                    data!['so_giay_phep'].toString().isNotEmpty));

        // Đã được Admin phê duyệt hợp tác hay chưa (10: Hợp tác theo Firebase, hoặc 2: Đã xác nhận)
        final bool daXacThuc =
            (trangThaiId == 10 || trangThaiId == 2) && !isBiTuChoiHoacHuy;

        final String hospitalEmail = (data?['email'] ??
                authProvider.hospital?.email ??
                FirebaseAuth.instance.currentUser?.email ??
                '')
            .toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    // Header chuẩn theo tài khoản đang đăng nhập
                    _buildHeader(
                      hospitalUid: hospitalUid,
                      tenBenhVien: tenBenhVien,
                      daGuiDon: daGuiDon,
                      daXacThuc: daXacThuc,
                      trangThaiId: trangThaiId,
                      email: hospitalEmail,
                    ),

                    // Body: Nếu đã xác thực -> Hiện theo Tab được chọn; Nếu chưa -> Hiện màn hình Chào mừng & Gửi đơn
                    Expanded(
                      child: daXacThuc
                          ? _buildBodyForCurrentTab(hospitalUid: hospitalUid)
                          : _buildUnverifiedBody(
                              hospitalUid: hospitalUid,
                              tenBenhVien: tenBenhVien,
                              daGuiDon: daGuiDon,
                              trangThaiId: trangThaiId,
                              data: data,
                            ),
                    ),

                    // Thanh điều hướng 4 nút
                    _buildBottomNav(daXacThuc: daXacThuc),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== GIAO DIỆN KHI CHƯA GỬI ĐƠN / CHỜ ADMIN DUYỆT / BỊ TỪ CHỐI ====================
  Widget _buildUnverifiedBody({
    required String hospitalUid,
    required String tenBenhVien,
    required bool daGuiDon,
    required int trangThaiId,
    Map<String, dynamic>? data,
  }) {
    final bool isBiTuChoiHoacHuy = (trangThaiId == TrangThaiId.huyHopTac);
    final String emailDangKy = (data?['email'] ??
            FirebaseAuth.instance.currentUser?.email ??
            '')
        .toString();
    final String lyDoTuChoi = (data?['ly_do_tu_choi'] ??
            'Hồ sơ pháp lý chưa đầy đủ hoặc cơ sở y tế đã chấm dứt hợp tác.')
        .toString();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 36),

          // Icon tài liệu / Cảnh báo hủy hợp tác
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isBiTuChoiHoacHuy
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: (isBiTuChoiHoacHuy
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0284C7))
                      .withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isBiTuChoiHoacHuy
                  ? Icons.cancel_outlined
                  : Icons.description_outlined,
              size: 46,
              color: isBiTuChoiHoacHuy
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 22),

          // Tiêu đề
          Text(
            isBiTuChoiHoacHuy
                ? 'Yêu Cầu Hợp Tác Bị Từ Chối / Đã Hủy'
                : 'Chào mừng Bệnh viện mới!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Dòng mô tả
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              isBiTuChoiHoacHuy
                  ? 'Yêu cầu hợp tác của bệnh viện đã bị từ chối hoặc hủy bỏ.\nThông báo chi tiết đã được gửi về email của người đăng ký.\nQuý viện có thể nộp lại đơn yêu cầu hợp tác mới từ đầu.'
                  : 'Trang chủ chưa có dữ liệu. Bệnh viện cần gửi\nđơn xác nhận hợp tác để kích hoạt các tính năng\nquản lý khoa và phân luồng tiếp đón.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),

          // Box thông báo gửi email khi bị từ chối / hủy
          if (isBiTuChoiHoacHuy) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mark_email_read_rounded,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã gửi thông báo giải thích về email:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (emailDangKy.isNotEmpty)
                          Text(
                            emailDangKy,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF7F1D1D),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Lý do: $lyDoTuChoi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Card Quy trình 3 bước kích hoạt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quy trình 3 bước kích hoạt:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepRow(
                  stepNumber: '1',
                  title: isBiTuChoiHoacHuy
                      ? 'Điền lại thông tin pháp lý & gửi lại hồ sơ'
                      : 'Điền thông tin pháp lý & loại hình cơ sở',
                  isActive: true,
                  isDone: daGuiDon && !isBiTuChoiHoacHuy,
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  stepNumber: '2',
                  title: 'Admin đối soát giấy phép & phê duyệt',
                  isActive: daGuiDon && !isBiTuChoiHoacHuy,
                  isDone: false,
                ),
                const SizedBox(height: 14),
                _buildStepRow(
                  stepNumber: '3',
                  title: 'Kích hoạt tạo khoa, phân luồng & cấp tài khoản',
                  isActive: false,
                  isDone: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Nút Gửi đơn xác nhận hợp tác / Gửi lại từ đầu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (daGuiDon && !isBiTuChoiHoacHuy) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuiDonThanhCongScreen(
                        maHoSo: (data?['ma_ho_so'] ?? '#HS-BV-202688').toString(),
                        tenBenhVien: tenBenhVien,
                        loaiHinh: (data?['loai_hinh'] ?? 'Bệnh viện Tư lập').toString(),
                        coBhyt: data?['co_bhyt'] ?? true,
                        hospitalUid: hospitalUid,
                        extraData: data,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuiYeuCauHopTacScreen(
                        initialTenBenhVien: tenBenhVien,
                        initialDiaChi: data?['dia_chi']?.toString(),
                      ),
                    ),
                  );
                }
              },
              icon: Icon(
                (daGuiDon && !isBiTuChoiHoacHuy)
                    ? Icons.hourglass_top_rounded
                    : Icons.assignment_outlined,
                size: 20,
              ),
              label: Text(
                isBiTuChoiHoacHuy
                    ? 'Gửi Lại Yêu Cầu Hợp Tác Từ Đầu'
                    : (daGuiDon
                        ? 'Đã Gửi Đơn - Chờ Admin Phê Duyệt'
                        : 'Gửi Đơn Xác Nhận Hợp Tác'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (daGuiDon && !isBiTuChoiHoacHuy)
                    ? const Color(0xFFD97706)
                    : const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== GIAO DIỆN THEO TAB ====================
  Widget _buildBodyForCurrentTab({required String hospitalUid}) {
    switch (_currentBottomNavIndex) {
      case 1:
        // Tab "Khoa khám": Hiển thị tất cả các khoa khám hiện có
        return const TatCaKhoaTab();
      case 2:
        // Tab "Nhân sự": Danh sách nhân sự & nút Cấp tài khoản
        return NhanSuScreen(benhVienId: hospitalUid);
      case 3:
        // Tab "Cài đặt": Thông tin & Đăng xuất
        return _buildSettingsTab(hospitalUid: hospitalUid);
      case 0:
      default:
        // Tab "Trang chủ"
        return _buildVerifiedDashboard(hospitalUid: hospitalUid);
    }
  }

  Widget _buildSettingsTab({required String hospitalUid}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt tài khoản Bệnh viện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.business_rounded, color: Color(0xFF0284C7)),
                  title: const Text('Thông tin cơ sở y tế'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang hoàn thiện.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7)),
                  title: const Text('Đổi mật khẩu & Bảo mật'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang hoàn thiện.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GIAO DIỆN KHI ĐÃ ĐƯỢC ADMIN DUYỆT ====================
  Widget _buildVerifiedDashboard({required String hospitalUid}) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Expanded(child: TongSoKhoaCard()),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: BenhVienService.thongKeHomNay(hospitalUid),
                  builder: (context, snap) {
                    final d = snap.data?.data();
                    final tong = ((d?['tongBenhNhan'] ?? 0) as num).toInt();
                    final dang = ((d?['dangKham'] ?? 0) as num).toInt();
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1D89D1), Color(0xFF1E79C2)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bệnh nhân hôm nay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _soCoDauPhay(tong),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đang khám: $dang lượt',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                AppSession.benhVienId = hospitalUid;
                Navigator.pushNamed(context, AppRoutes.addClinic);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Thêm Khoa Khám Mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E87D8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListKhoaDieuTri(
            onXemTatCa: () => setState(() => _currentBottomNavIndex = 1),
          ),
        ),
      ],
    );
  }

  // Header hiển thị tên Bệnh viện và huy hiệu xác thực
  Widget _buildHeader({
    required String hospitalUid,
    required String tenBenhVien,
    required bool daGuiDon,
    required bool daXacThuc,
    required int trangThaiId,
    String? email,
  }) {
    String badgeText = 'Chưa xác thực';
    Color badgeBg = const Color(0xFFFFFBEB);
    Color badgeTextColor = const Color(0xFFD97706);
    Color badgeBorder = const Color(0xFFFDE68A);

    if (trangThaiId == TrangThaiId.huyHopTac) {
      badgeText = 'Hủy / Từ chối hợp tác';
      badgeBg = const Color(0xFFFEF2F2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeBorder = const Color(0xFFFECACA);
    } else if (daXacThuc) {
      badgeText = 'Đã hợp tác';
      badgeBg = const Color(0xFFECFDF5);
      badgeTextColor = const Color(0xFF059669);
      badgeBorder = const Color(0xFFA7F3D0);
    } else if (daGuiDon) {
      badgeText = 'Đang chờ duyệt';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      badgeBorder = const Color(0xFFFCD34D);
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _chuVietTat(tenBenhVien),
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenBenhVien,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeBorder, width: 0.8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nút DEV: Mở menu đổi trạng thái (1 - Chờ duyệt, 9 - Hủy/Từ chối & Gửi Mail, 10 - Hợp tác)
          InkWell(
            onTap: () => _hienThiMenuDev(
              context: context,
              hospitalUid: hospitalUid,
              tenBenhVien: tenBenhVien,
              email: email ?? '',
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: daXacThuc
                    ? const Color(0xFFF1F5F9)
                    : (trangThaiId == TrangThaiId.huyHopTac
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFDCFCE7)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: daXacThuc
                      ? const Color(0xFFCBD5E1)
                      : (trangThaiId == TrangThaiId.huyHopTac
                          ? const Color(0xFFFECACA)
                          : const Color(0xFF86EFAC)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    daXacThuc
                        ? Icons.lock_open_rounded
                        : (trangThaiId == TrangThaiId.huyHopTac
                            ? Icons.cancel_outlined
                            : Icons.bolt_rounded),
                    size: 15,
                    color: daXacThuc
                        ? const Color(0xFF64748B)
                        : (trangThaiId == TrangThaiId.huyHopTac
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'DEV ($trangThaiId)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: daXacThuc
                          ? const Color(0xFF64748B)
                          : (trangThaiId == TrangThaiId.huyHopTac
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF334155),
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không có thông báo mới.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required bool isActive,
    required bool isDone,
  }) {
    Color circleColor = const Color(0xFFE2E8F0);
    Widget circleChild = Text(
      stepNumber,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );

    if (isDone) {
      circleColor = const Color(0xFF16A34A);
      circleChild = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isActive) {
      circleColor = const Color(0xFF0284C7);
      circleChild = Text(
        stepNumber,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: circleChild,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: (isActive || isDone)
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF475569),
              fontWeight:
                  (isActive || isDone) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav({required bool daXacThuc}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Trang chủ',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.grid_view_rounded,
            activeIcon: Icons.grid_view_rounded,
            label: 'Khoa khám',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Khoa khám'),
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Nhân sự',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Nhân sự'),
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Cài đặt',
            onTapBlocked: daXacThuc
                ? null
                : () => _thongBaoChuaKichHoat('Cài đặt'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    VoidCallback? onTapBlocked,
  }) {
    final isSelected = _currentBottomNavIndex == index;
    final color =
        isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        if (onTapBlocked != null) {
          onTapBlocked();
          return;
        }
        setState(() => _currentBottomNavIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hienThiMenuDev({
    required BuildContext context,
    required String hospitalUid,
    required String tenBenhVien,
    required String email,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚡ Bảng Điều Khiển DEV - Trạng Thái Hợp Tác',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bệnh viện: $tenBenhVien | Email: ${email.isNotEmpty ? email : "Chưa có"}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 28,
                  ),
                  title: const Text('10 - Hợp Tác (Duyệt hồ sơ)'),
                  subtitle: const Text('Mở khóa toàn bộ dashboard bệnh viện'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _capNhatTrangThaiDev(10, hospitalUid, tenBenhVien, email);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFFD97706),
                    size: 28,
                  ),
                  title: const Text('1 - Chờ Duyệt'),
                  subtitle: const Text('Hồ sơ đang chờ Admin xem xét'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _capNhatTrangThaiDev(1, hospitalUid, tenBenhVien, email);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                  title: const Text('9 - Hủy / Từ Chối Hợp Tác'),
                  subtitle: const Text('Gửi email thông báo & màn hình quay về gửi lại từ đầu'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _capNhatTrangThaiDev(9, hospitalUid, tenBenhVien, email);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _capNhatTrangThaiDev(
    int newStatus,
    String hospitalUid,
    String tenBenhVien,
    String email,
  ) async {
    final targetId = AppSession.benhVienId.isNotEmpty
        ? AppSession.benhVienId
        : hospitalUid;

    if (newStatus == TrangThaiId.huyHopTac) {
      await EmailService.tuChoiHoacHuyHopTac(
        benhVienId: targetId,
        tenBenhVien: tenBenhVien,
        email: email,
        lyDo: 'Hồ sơ pháp lý chưa hợp lệ / Quyết định hủy hợp tác từ Quản trị viên.',
      );

      if (hospitalUid != targetId) {
        try {
          await EmailService.tuChoiHoacHuyHopTac(
            benhVienId: hospitalUid,
            tenBenhVien: tenBenhVien,
            email: email,
            lyDo: 'Hồ sơ pháp lý chưa hợp lệ / Quyết định hủy hợp tác từ Quản trị viên.',
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _trangThaiTuYeuCauHopTac = TrangThaiId.huyHopTac;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Đã chuyển sang Trạng thái 9 (Hủy Hợp Tác) & Gửi email thông báo về $email!',
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final updateData = <String, dynamic>{
      'trang_thai_hop_tac_id': newStatus,
      'da_gui_don': true,
      'da_bi_tu_choi': false,
      'da_gui_mail_tu_choi': false,
    };

    await FirebaseFirestore.instance
        .collection('BenhVien')
        .doc(targetId)
        .set(updateData, SetOptions(merge: true));

    try {
      await FirebaseFirestore.instance
          .collection('YeuCauHopTac')
          .doc(targetId)
          .set(updateData, SetOptions(merge: true));
    } catch (_) {}

    if (hospitalUid != targetId) {
      try {
        await FirebaseFirestore.instance
            .collection('BenhVien')
            .doc(hospitalUid)
            .set(updateData, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('YeuCauHopTac')
            .doc(hospitalUid)
            .set(updateData, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _trangThaiTuYeuCauHopTac = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 10
                ? '⚡ [DEV] Đã duyệt (10 - Hợp tác): Mở full Dashboard!'
                : '⏳ [DEV] Đã chuyển về: 1 - Chờ duyệt!',
          ),
          backgroundColor: newStatus == 10
              ? const Color(0xFF16A34A)
              : const Color(0xFFD97706),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
