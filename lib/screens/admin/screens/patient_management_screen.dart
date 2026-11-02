import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

class PatientManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const PatientManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _statusFilter = 0; // 0: Tất cả, 1: Hoạt động, 2: Bị khóa
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AdminStore.instance.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    AdminStore.instance.removeListener(_onStoreUpdate);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  List<AdminPatient> _getFilteredPatients() {
    final list = AdminStore.instance.patients;
    return list.where((p) {
      // 1. Lọc theo trạng thái
      if (_statusFilter == 1 && !p.isActive) return false;
      if (_statusFilter == 2 && p.isActive) return false;

      // 2. Lọc theo từ khóa tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.hoTen.toLowerCase().contains(q);
        final codeMatch = p.maBenhNhan.toLowerCase().contains(q);
        final emailMatch = (p.email ?? '').toLowerCase().contains(q);
        final phoneMatch = (p.soDienThoai ?? '').contains(q);
        return nameMatch || codeMatch || emailMatch || phoneMatch;
      }
      return true;
    }).toList();
  }

  // ================= DIALOG KHÓA TÀI KHOẢN =================
  void _showBlockDialog(AdminPatient patient) {
    final reasonCtrl = TextEditingController(text: 'Vi phạm quy định đặt lịch khám');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kRedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.block_rounded, color: kRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Khóa tài khoản bệnh nhân',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đang thực hiện tạm khóa tài khoản của bệnh nhân ${patient.hoTen} (${patient.maBenhNhan}).',
                style: const TextStyle(color: kSlate600, fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              const Text(
                'Lý do tạm khóa:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kSlate800),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do khóa tài khoản...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kRed),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Spam đặt lịch hủy nhiều lần',
                  'Thông tin giả mạo',
                  'Vi phạm quy định sử dụng',
                ].map((preset) => ActionChip(
                  label: Text(preset, style: const TextStyle(fontSize: 11)),
                  backgroundColor: kSlate100,
                  onPressed: () => reasonCtrl.text = preset,
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: kSlate600)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Xác nhận khóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final reason = reasonCtrl.text.trim().isEmpty
                  ? 'Vi phạm quy chế sử dụng hệ thống'
                  : reasonCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await AdminStore.instance.blockPatient(patient, reason);
              final emailNotice = patient.email != null && patient.email!.isNotEmpty
                  ? ' và gửi email thông báo tới ${patient.email}'
                  : '';
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Đã khóa tài khoản bệnh nhân ${patient.hoTen}$emailNotice.'),
                  backgroundColor: kRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= DIALOG MỞ KHÓA TÀI KHOẢN =================
  void _showUnblockDialog(AdminPatient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Color(0xFF16A34A), size: 24),
            SizedBox(width: 10),
            Text('Mở khóa tài khoản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Kích hoạt lại tài khoản cho bệnh nhân ${patient.hoTen} (${patient.maBenhNhan})? Bệnh nhân sẽ có thể đăng nhập và đặt lịch khám trở lại bình thường.',
          style: const TextStyle(color: kSlate600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: kSlate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await AdminStore.instance.unblockPatient(patient);
              final emailNotice = patient.email != null && patient.email!.isNotEmpty
                  ? ' và gửi email thông báo tới ${patient.email}'
                  : '';
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Đã mở khóa tài khoản cho ${patient.hoTen}$emailNotice.'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
            child: const Text('Mở khóa ngay'),
          ),
        ],
      ),
    );
  }

  // ================= DIALOG XÓA TÀI KHOẢN =================
  void _showDeleteDialog(AdminPatient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kRed, size: 24),
            SizedBox(width: 10),
            Text('Xóa vĩnh viễn tài khoản?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động này sẽ xóa hoàn toàn hồ sơ của bệnh nhân ${patient.hoTen} (${patient.maBenhNhan}) khỏi cơ sở dữ liệu Firebase. Dữ liệu này không thể phục hồi!',
              style: const TextStyle(color: kSlate600, fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: kSlate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final emailNotice = patient.email != null && patient.email!.isNotEmpty
                  ? ' và gửi email thông báo tới ${patient.email}'
                  : '';
              await AdminStore.instance.deletePatientAccount(patient);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Đã xóa tài khoản bệnh nhân ${patient.hoTen}$emailNotice.'),
                  backgroundColor: kSlate900,
                ),
              );
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  // ================= CHI TIẾT BỆNH NHÂN (BOTTOM SHEET) =================
  void _showPatientDetails(AdminPatient patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: AdminStore.instance,
          // Lấy patient mới nhất từ store mỗi khi store thay đổi
          builder: (context, _) {
            final updatedPatient = AdminStore.instance.patients
                .firstWhere((p) => p.uid == patient.uid, orElse: () => patient);
            return _buildPatientDetailSheet(ctx, updatedPatient);
          },
        );
      },
    );
  }

  Widget _buildPatientDetailSheet(BuildContext ctx, AdminPatient patient) {
    return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Thanh kéo
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kSlate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: patient.avatarBg,
                      child: Text(
                        patient.initials,
                        style: TextStyle(
                          color: patient.avatarText,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  patient.hoTen,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: kSlate900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  patient.maBenhNhan,
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: patient.isActive ? const Color(0xFF16A34A) : kRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                patient.isActive ? 'Tài khoản hoạt động' : 'Tài khoản bị tạm khóa',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: patient.isActive ? const Color(0xFF16A34A) : kRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kSlate400),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kBorder),

              // Nội dung chi tiết cuộn được
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Cảnh báo nếu bị khóa
                    if (!patient.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kRedBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: kRed, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tài khoản đang bị chặn đăng nhập',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: kRed,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    patient.blockReason ?? 'Không có lý do cụ thể.',
                                    style: const TextStyle(fontSize: 12, color: kSlate700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Card thông tin cá nhân
                    _buildSectionHeader('Thông tin liên hệ & Hồ sơ', Icons.person_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Email',
                            patient.email ?? 'Chưa đăng ký email',
                            trailing: patient.daXacThucEmail
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                      SizedBox(width: 4),
                                      Text('Đã xác thực', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w700)),
                                    ],
                                  )
                                : const Text('Chưa xác thực', style: TextStyle(color: kAmber, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow('Số điện thoại', patient.soDienThoai ?? 'Chưa cập nhật'),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow('Giới tính', patient.gioiTinh ?? 'Chưa xác định'),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow(
                            'Ngày sinh',
                            patient.ngaySinh != null
                                ? '${patient.ngaySinh!.day}/${patient.ngaySinh!.month}/${patient.ngaySinh!.year}'
                                : 'Chưa cập nhật',
                          ),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow('Địa chỉ', patient.diaChi ?? 'Chưa cập nhật'),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow(
                            'Ngày tham gia',
                            patient.ngayTao != null
                                ? '${patient.ngayTao!.day}/${patient.ngayTao!.month}/${patient.ngayTao!.year}'
                                : 'Mới tham gia',
                          ),
                          const Divider(height: 16, color: kBorder),
                          _buildDetailRow('UID hệ thống', patient.uid, isMonospace: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lịch hẹn khám từ Firebase
                    _buildSectionHeader('Lịch sử đặt lịch khám', Icons.calendar_month_outlined),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: AdminStore.instance.getPatientAppointments(patient.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final appointments = snapshot.data ?? [];
                        if (appointments.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'Bệnh nhân chưa có lịch hẹn khám nào trên hệ thống.',
                                style: TextStyle(color: kSlate500, fontSize: 12.5),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: appointments.take(5).map((app) {
                            final code = app['id']?.toString() ?? 'LH';
                            final hospital = app['ten_benh_vien']?.toString() ??
                                'Cơ sở y tế ID: ${app['benh_vien_id'] ?? ''}';
                            final dept = app['ten_khoa']?.toString() ??
                                app['khoa_id']?.toString() ??
                                '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kPrimaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.event_note, color: kPrimary, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hospital,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: kSlate900,
                                          ),
                                        ),
                                        if (dept.isNotEmpty)
                                          Text(
                                            dept,
                                            style: const TextStyle(fontSize: 11, color: kSlate500),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: kSlate100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      code,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: kSlate600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // CÁC THAO TÁC QUẢN TRỊ
                    _buildSectionHeader('Tác vụ quản lý tài khoản', Icons.admin_panel_settings_outlined),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: patient.isActive
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.block_rounded, size: 16),
                                  label: const Text('Khóa tài khoản'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kRedBg,
                                    foregroundColor: kRed,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: kRed),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showBlockDialog(patient);
                                  },
                                )
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                                  label: const Text('Mở khóa tài khoản'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showUnblockDialog(patient);
                                  },
                                ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever_rounded, size: 16),
                          label: const Text('Xóa TK'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSlate100,
                            foregroundColor: kRed,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showDeleteDialog(patient);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: kSlate800,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing, bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: kSlate500, fontSize: 12.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: kSlate900,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final filtered = _getFilteredPatients();
    final activeCount = store.patients.where((p) => p.isActive).length;
    final blockedCount = store.patients.where((p) => !p.isActive).length;

    return Scaffold(
      backgroundColor: kBg,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: kSlate900),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Quản lý Bệnh nhân',
                style: TextStyle(
                  color: kSlate900,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              centerTitle: true,
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: LiveSyncBadge(),
                ),
              ],
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await AdminStore.instance.syncNow();
            if (mounted) setState(() {});
          },
          child: Column(
            children: [
              // HEADER KHI EMBEDDED
              if (widget.isEmbedded)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUẢN TRỊ NGƯỜI DÙNG',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Quản lý Bệnh nhân',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kSlate900,
                            ),
                          ),
                        ],
                      ),
                      LiveSyncBadge(),
                    ],
                  ),
                ),

              // THANH TÌM KIẾM & THỐNG KÊ NHANH
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Ô tìm kiếm
                    SearchBox(
                      controller: _searchCtrl,
                      hint: 'Tìm theo tên, mã BN, SĐT, email...',
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab(0, 'Tất cả (${store.totalPatients})'),
                          const SizedBox(width: 8),
                          _buildFilterTab(1, 'Đang hoạt động ($activeCount)'),
                          const SizedBox(width: 8),
                          _buildFilterTab(2, 'Bị tạm khóa ($blockedCount)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: kBorder),

              // DANH SÁCH BỆNH NHÂN
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: kSlate100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 36, color: kSlate400),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Không tìm thấy bệnh nhân nào',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kSlate700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                              style: TextStyle(fontSize: 12.5, color: kSlate500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final patient = filtered[i];
                          return _buildPatientCard(patient);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final active = _statusFilter == index;
    return InkWell(
      onTap: () => setState(() => _statusFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kPrimary : kSlate100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : kSlate700,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(AdminPatient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: patient.isActive ? kBorder : kRed.withValues(alpha: 0.4),
          width: patient.isActive ? 1 : 1.5,
        ),
        boxShadow: kCardShadow,
      ),
      child: InkWell(
        onTap: () => _showPatientDetails(patient),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng thông tin chính
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: patient.avatarBg,
                    child: Text(
                      patient.initials,
                      style: TextStyle(
                        color: patient.avatarText,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                patient.hoTen,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kSlate900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kPrimaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                patient.maBenhNhan,
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          patient.email ?? 'Chưa đăng ký email',
                          style: const TextStyle(fontSize: 12, color: kSlate500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badge trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: patient.isActive ? const Color(0xFFDCFCE7) : kRedBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: patient.isActive
                            ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                            : kRed.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      patient.isActive ? 'Hoạt động' : 'Bị khóa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: patient.isActive ? const Color(0xFF16A34A) : kRed,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: kBorder),
              const SizedBox(height: 10),

              // Thông tin phụ: Số điện thoại + ngày tham gia
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 13, color: kSlate400),
                  const SizedBox(width: 4),
                  Text(
                    patient.soDienThoai ?? 'Chưa có SĐT',
                    style: const TextStyle(fontSize: 11.5, color: kSlate600, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined, size: 12, color: kSlate400),
                  const SizedBox(width: 4),
                  Text(
                    patient.ngayTao != null
                        ? '${patient.ngayTao!.day}/${patient.ngayTao!.month}/${patient.ngayTao!.year}'
                        : 'Mới',
                    style: const TextStyle(fontSize: 11.5, color: kSlate600),
                  ),
                ],
              ),

              // Lý do khóa nếu bị khóa
              if (!patient.isActive && patient.blockReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kRedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: kRed),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lý do: ${patient.blockReason}',
                          style: const TextStyle(fontSize: 11, color: kRed, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Hàng nút hành động nhanh
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kSlate700,
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showPatientDetails(patient),
                      child: const Text('Xem hồ sơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (patient.isActive)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.block_rounded, size: 14),
                      label: const Text('Khóa TK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRedBg,
                        foregroundColor: kRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: kRed.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _showBlockDialog(patient),
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open_rounded, size: 14),
                      label: const Text('Mở khóa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _showUnblockDialog(patient),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
