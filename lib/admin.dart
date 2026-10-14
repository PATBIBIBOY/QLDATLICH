import 'package:flutter/material.dart';

const primaryBlue = Color(0xFF2580F8);
const pageBg = Color(0xFFF3F5F8);
const successGreen = Color(0xFF2DBB65);
const dangerRed = Color(0xFFFF4545);
const warningOrange = Color(0xFFFFA323);

class Hospital {
  Hospital({
    required this.name,
    required this.code,
    required this.type,
    required this.doctors,
    this.status = 'Chờ duyệt',
    this.address = '78 Giải Phóng, Đống Đa, Hà Nội',
    this.rating = 4.9,
    this.complaints = 0,
    this.reason = '',
    this.departments = const ['Khoa Tim Mạch', 'Khoa Nhi Tiêu Hóa'],
  });

  final String name;
  final String code;
  final String type;
  final int doctors;
  final String address;
  final double rating;
  final List<String> departments;
  String status;
  int complaints;
  String reason;
}

final List<Hospital> hospitals = [
  Hospital(
    name: 'Bệnh viện Bạch Mai',
    code: 'BM',
    type: 'Công lập',
    doctors: 120,
    status: 'Đã xác nhận',
  ),
  Hospital(
    name: 'BV Đa khoa Tâm Anh',
    code: 'TA',
    type: 'Tư nhân',
    doctors: 85,
    status: 'Đã xác nhận',
  ),
  Hospital(
    name: 'BV Đa khoa Hồng Ngọc',
    code: 'HN',
    type: 'Tư nhân',
    doctors: 60,
  ),
  Hospital(name: 'BV Việt Đức', code: 'VD', type: 'Công lập', doctors: 150),
  Hospital(
    name: 'PK Đa khoa An Khang',
    code: 'AK',
    type: 'Tư nhân',
    doctors: 25,
    complaints: 3,
    address: 'Cầu Giấy, Hà Nội',
    reason: 'Giấy phép hoạt động hết hạn.',
  ),
];

// ============================================================
// MAIN SCREEN
// ============================================================

class HospitalAdminScreen extends StatelessWidget {
  const HospitalAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell();
  }
}

// ============================================================
// COMMON WIDGETS
// ============================================================

void notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

Widget hospitalAvatar(Hospital hospital, {double size = 44}) {
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFE4EDFF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      hospital.code,
      style: TextStyle(
        color: primaryBlue,
        fontSize: size * 0.28,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

Widget statusBadge(String status) {
  final color = status == 'Đã xác nhận'
      ? successGreen
      : status == 'Từ chối'
      ? dangerRed
      : warningOrange;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

Widget hospitalCard(
  BuildContext context,
  Hospital hospital,
  VoidCallback refresh, {
  bool approvalActions = false,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Row(
          children: [
            hospitalAvatar(hospital),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${hospital.type} · ★ ${hospital.rating} · '
                    '${hospital.doctors} bác sĩ',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  statusBadge(hospital.status),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HospitalDetailScreen(
                      hospital: hospital,
                      onChanged: refresh,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
        if (approvalActions && hospital.status == 'Chờ duyệt') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    hospital.status = 'Đã xác nhận';
                    refresh();
                    notify(context, 'Đã duyệt bệnh viện.');
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Duyệt'),
                  style: FilledButton.styleFrom(backgroundColor: successGreen),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RejectHospitalScreen(hospital: hospital),
                      ),
                    );
                    if (result == true) refresh();
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerRed,
                    side: const BorderSide(color: dangerRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    ),
  );
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onChanged: refresh),
      HospitalListScreen(onChanged: refresh),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        backgroundColor: Colors.white,
        indicatorColor: primaryBlue.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryBlue),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital, color: primaryBlue),
            label: 'Quản lý',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber, color: primaryBlue),
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 1. DASHBOARD
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void refresh() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final pending = hospitals.where((h) => h.status == 'Chờ duyệt').length;
    final approved = hospitals.where((h) => h.status == 'Đã xác nhận').length;
    final errors = hospitals.fold<int>(0, (sum, h) => sum + h.complaints);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào mừng admin',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Quản trị viên Admin 👋',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => notify(context, 'Không có thông báo mới.'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: statCard('Tổng BV', hospitals.length, primaryBlue)),
            const SizedBox(width: 9),
            Expanded(child: statCard('Chờ duyệt', pending, successGreen)),
            const SizedBox(width: 9),
            Expanded(child: statCard('Báo lỗi', errors, dangerRed)),
          ],
        ),
        const SizedBox(height: 22),
        sectionTitle('Danh sách bệnh viện'),
        ...hospitals
            .where((h) => h.status != 'Từ chối')
            .take(3)
            .map((h) => hospitalCard(context, h, refresh)),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApprovalScreen(onChanged: refresh),
                ),
              );
            },
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Duyệt bệnh viện'),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeleteHospitalScreen(onChanged: refresh),
              ),
            );
          },
          icon: const Icon(Icons.delete_outline, color: dangerRed),
          label: const Text(
            'Xóa bệnh viện',
            style: TextStyle(color: dangerRed),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$approved bệnh viện đã được xác nhận',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget statCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

// ============================================================
// 2. HOSPITAL LIST + SEARCH
// ============================================================

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  final controller = TextEditingController();
  String filter = 'Tất cả';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = hospitals.where((h) {
      final matchesName = h.name.toLowerCase().contains(
        controller.text.toLowerCase(),
      );
      final matchesStatus = filter == 'Tất cả' || h.status == filter;
      return matchesName && matchesStatus;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Quản lý bệnh viện ⚙️',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tìm kiếm và quản lý thông tin cơ sở y tế.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tìm tên bệnh viện...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in [
                'Tất cả',
                'Chờ duyệt',
                'Đã xác nhận',
                'Từ chối',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: filter == item,
                    onSelected: (_) => setState(() => filter = item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        sectionTitle('Danh sách (${list.length})'),
        if (list.isEmpty)
          const Center(child: Text('Không tìm thấy bệnh viện.')),
        ...list.map(
          (h) => hospitalCard(context, h, () {
            setState(() {});
            widget.onChanged();
          }),
        ),
      ],
    );
  }
}

// ============================================================
// 3. HOSPITAL DETAIL
// ============================================================

class HospitalDetailScreen extends StatelessWidget {
  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    required this.onChanged,
  });

  final Hospital hospital;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bệnh viện')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                hospitalAvatar(hospital, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${hospital.type} · ★ ${hospital.rating}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      statusBadge(hospital.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('THÔNG TIN CƠ SỞ'),
          infoTile('Địa chỉ', hospital.address),
          infoTile('Số bác sĩ', '${hospital.doctors} bác sĩ'),
          infoTile('Mã cơ sở', hospital.code),
          const SizedBox(height: 20),
          sectionTitle('DANH SÁCH KHOA TRỰC THUỘC'),
          ...hospital.departments.map(
            (department) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(department)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(hospital: hospital),
                ),
              );
            },
            child: const Text('Xem đánh giá bệnh viện'),
          ),
          if (hospital.status == 'Chờ duyệt')
            FilledButton(
              onPressed: () {
                hospital.status = 'Đã xác nhận';
                onChanged();
                Navigator.pop(context);
                notify(context, 'Đã duyệt bệnh viện.');
              },
              style: FilledButton.styleFrom(backgroundColor: successGreen),
              child: const Text('Duyệt bệnh viện'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeleteHospitalScreen(
                    selectedHospital: hospital,
                    onChanged: onChanged,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: dangerRed),
            label: const Text(
              'Xóa bệnh viện',
              style: TextStyle(color: dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. APPROVAL
// ============================================================

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  void refresh() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final pending = hospitals.where((h) => h.status == 'Chờ duyệt').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bệnh viện chờ duyệt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${pending.length} bệnh viện đang chờ xác nhận',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          if (pending.isEmpty)
            const Center(child: Text('Không còn hồ sơ chờ duyệt.')),
          ...pending.map(
            (h) => hospitalCard(context, h, refresh, approvalActions: true),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. REJECT
// ============================================================

class RejectHospitalScreen extends StatefulWidget {
  const RejectHospitalScreen({super.key, required this.hospital});

  final Hospital hospital;

  @override
  State<RejectHospitalScreen> createState() => _RejectHospitalScreenState();
}

class _RejectHospitalScreenState extends State<RejectHospitalScreen> {
  String? reason;
  final noteController = TextEditingController();

  final reasons = [
    'Thiếu giấy phép hoạt động',
    'Thông tin chưa đầy đủ',
    'Không đạt tiêu chuẩn',
    'Trùng bệnh viện đã có',
  ];

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Từ chối duyệt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          hospitalCard(context, widget.hospital, () {}),
          const SizedBox(height: 20),
          const Icon(Icons.error_outline, size: 44, color: dangerRed),
          const SizedBox(height: 10),
          const Text(
            'Vui lòng chọn lý do từ chối',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...reasons.map(
            (item) => RadioListTile<String>(
              value: item,
              groupValue: reason,
              onChanged: (value) => setState(() => reason = value),
              title: Text(item, style: const TextStyle(fontSize: 13)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'GHI CHÚ CHI TIẾT (TÙY CHỌN)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Nhập lý do chi tiết...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dangerRed),
            onPressed: () {
              if (reason == null) {
                notify(context, 'Vui lòng chọn lý do từ chối.');
                return;
              }
              widget.hospital.status = 'Từ chối';
              widget.hospital.reason = '$reason. ${noteController.text.trim()}';
              Navigator.pop(context, true);
            },
            child: const Text('Gửi từ chối'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 6. DELETE HOSPITAL
// ============================================================

class DeleteHospitalScreen extends StatefulWidget {
  const DeleteHospitalScreen({
    super.key,
    this.selectedHospital,
    this.onChanged,
  });

  final Hospital? selectedHospital;
  final VoidCallback? onChanged;

  @override
  State<DeleteHospitalScreen> createState() => _DeleteHospitalScreenState();
}

class _DeleteHospitalScreenState extends State<DeleteHospitalScreen> {
  final controller = TextEditingController();
  Hospital? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedHospital;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = hospitals.where((h) {
      return h.name.toLowerCase().contains(controller.text.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Xóa bệnh viện')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm cơ sở cần xóa...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: list.map((h) {
                  return Card(
                    color: selected == h
                        ? const Color(0xFFE8F1FF)
                        : Colors.white,
                    child: ListTile(
                      leading: hospitalAvatar(h, size: 40),
                      title: Text(h.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(h.address),
                      trailing: selected == h
                          ? const Icon(Icons.check_circle, color: primaryBlue)
                          : null,
                      onTap: () => setState(() => selected = h),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (selected != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: dangerRed),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: warningOrange,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Xác nhận xóa bệnh viện?',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(selected!.name, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => selected = null),
                            child: const Text('Hủy bỏ'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: dangerRed,
                            ),
                            onPressed: () => confirmDelete(context),
                            child: const Text('Xác nhận xóa'),
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

  Future<void> confirmDelete(BuildContext context) async {
    final hospital = selected;
    if (hospital == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bệnh viện'),
        content: Text('Xóa "${hospital.name}" khỏi danh sách demo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dangerRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      hospitals.remove(hospital);
      selected = null;
    });
    widget.onChanged?.call();

    if (mounted) {
      notify(context, 'Đã xóa bệnh viện khỏi dữ liệu demo.');
    }
  }
}

// ============================================================
// 7. REVIEWS
// ============================================================

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    final reviews = [
      (
        'Nguyễn Văn A',
        '★★★★★',
        'Bác sĩ tận tâm, khám nhanh, giải thích rõ ràng. Rất hài lòng.',
        '18/09/2026 · Khoa Tim mạch',
      ),
      (
        'Trần Thị Bích',
        '★★★★☆',
        'Chờ hơi lâu nhưng bác sĩ khám kỹ, kết quả chính xác.',
        '17/09/2026 · Khoa Nhi',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá bệnh viện')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                hospitalAvatar(hospital),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '★★★★★ ${hospital.rating} · 1.248 đánh giá',
                        style: const TextStyle(
                          color: warningOrange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan đánh giá',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text('Chất lượng khám: 4.9 · Thái độ NV: 4.8'),
                SizedBox(height: 5),
                Text('Cơ sở vật chất: 4.7 · Thời gian chờ: 4.6'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          sectionTitle('Đánh giá gần đây'),
          ...reviews.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.$1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(r.$2, style: const TextStyle(color: warningOrange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.$3),
                  const SizedBox(height: 10),
                  Text(
                    r.$4,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 8. ERROR REPORTS
// ============================================================

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String filter = 'Tất cả';

  final List<Map<String, dynamic>> reports = [
    {
      'type': 'Lỗi Check-in QR',
      'time': '10 phút trước',
      'title': 'Quét QR không auto điền form tiếp nhận',
      'detail':
          'Người gửi: BV Tâm Anh. Mã QR hợp lệ nhưng không tự điền thông tin.',
      'category': 'Lỗi QR',
      'done': false,
    },
    {
      'type': 'Lỗi Đặt lịch',
      'time': '1 giờ trước',
      'title': 'Trùng ca khám buổi sáng',
      'detail': 'Người gửi: Bệnh nhân Trần Mai Lan.',
      'category': 'Lỗi đặt lịch',
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final list = reports.where((r) {
      if (filter == 'Tất cả') return true;
      if (filter == 'Chưa xử lý') return r['done'] == false;
      if (filter == 'Đã xử lý') return r['done'] == true;
      return r['category'] == filter;
    }).toList();

    final pending = reports.where((r) => r['done'] == false).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Xem các báo cáo lỗi',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
            ),
            statusBadge('$pending lỗi'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final item in [
              'Tất cả',
              'Chưa xử lý',
              'Đã xử lý',
              'Lỗi QR',
              'Lỗi đặt lịch',
            ])
              ChoiceChip(
                label: Text(item),
                selected: filter == item,
                onSelected: (_) => setState(() => filter = item),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          const Center(child: Text('Không có báo cáo phù hợp.')),
        ...list.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['type'],
                        style: const TextStyle(
                          color: warningOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      r['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['title'],
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  r['detail'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (r['done'])
                  statusBadge('Đã xử lý')
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => resolveReport(r),
                      child: const Text('Xử lý sự cố ngay'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> resolveReport(Map<String, dynamic> report) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xử lý báo cáo'),
        content: Text('Xác nhận xử lý "${report['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => report['done'] = true);
      notify(context, 'Đã cập nhật báo cáo.');
    }
  }
}
