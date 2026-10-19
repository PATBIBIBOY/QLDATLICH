import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/admin_store.dart';
import '../widgets/shared_widgets.dart';

// ===================================================
// MÀN 11: SỬA THÔNG TIN BỆNH VIỆN
// ===================================================
class EditHospitalScreen extends StatefulWidget {
  final Hospital hospital;
  const EditHospitalScreen({super.key, required this.hospital});
  @override
  State<EditHospitalScreen> createState() => _EditHospitalScreenState();
}

class _EditHospitalScreenState extends State<EditHospitalScreen> {
  late final TextEditingController nameCtrl;
  late final TextEditingController addrCtrl;
  late final TextEditingController doctorsCtrl;
  late String type;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.hospital.name);
    addrCtrl = TextEditingController(text: widget.hospital.address ?? '');
    doctorsCtrl =
        TextEditingController(text: widget.hospital.doctors.toString());
    type = widget.hospital.type;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addrCtrl.dispose();
    doctorsCtrl.dispose();
    super.dispose();
  }

  Widget field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: lines,
            style: const TextStyle(fontSize: 14),
            decoration:
                const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  BackCircle(),
                  SizedBox(width: 12),
                  Text('Sửa thông tin bệnh viện',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    AvatarBox(
                        text: widget.hospital.initials,
                        bg: widget.hospital.avatarBg,
                        fg: widget.hospital.avatarText,
                        size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(widget.hospital.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(
                              '${widget.hospital.type} · ★ ${widget.hospital.rating}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              field('TÊN BỆNH VIỆN', nameCtrl),
              const SizedBox(height: 12),
              const Text('LOẠI HÌNH',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'Công lập',
                        child: Text('Công lập')),
                    DropdownMenuItem(
                        value: 'Tư nhân',
                        child: Text('Tư nhân')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => type = v);
                  },
                ),
              ),
              const SizedBox(height: 12),
              field('ĐỊA CHỈ', addrCtrl, lines: 2),
              const SizedBox(height: 12),
              field('SỐ BÁC SĨ', doctorsCtrl,
                  keyboard: TextInputType.number),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(
                              color: Color(0xFFE5E7EB)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final doctors = int.tryParse(
                                  doctorsCtrl.text.trim()) ??
                              widget.hospital.doctors;
                          AdminStore.instance.updateHospital(
                            widget.hospital,
                            name: nameCtrl.text.trim(),
                            type: type,
                            address: addrCtrl.text.trim(),
                            doctors: doctors,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Đã lưu thay đổi ✓')));
                        },
                        child: const Text('Lưu thay đổi',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
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
