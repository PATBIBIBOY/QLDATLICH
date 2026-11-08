import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../models/family_profile_model.dart';
import '../../providers/family_profile_provider.dart';

const Color _kPrimary = Color(0xFF2563EB);
const Color _kText = Color(0xFF0F172A);
const Color _kGrey = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE6EBF2);

const List<Color> _palette = [
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF0EA5E9),
];

Color profileColor(FamilyProfileModel p) =>
    p.isSelf ? _kPrimary : _palette[p.id.hashCode.abs() % _palette.length];

/// Avatar tròn: ảnh (nếu có) hoặc chữ cái đầu.
class ProfileAvatar extends StatelessWidget {
  final FamilyProfileModel profile;
  final double size;
  final bool selected;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 52,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = profileColor(profile);
    final hasPhoto = profile.anhDaiDien.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.22), color.withOpacity(0.08)],
        ),
        border: Border.all(
          color: selected ? color : color.withOpacity(0.25),
          width: selected ? 3 : 1.5,
        ),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(profile.anhDaiDien),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                profile.initials,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
    );
  }
}

/// Hàng avatar ngang "Khám cho ai?" dùng ở màn đặt lịch.
class ProfileChipsRow extends StatelessWidget {
  final String title;
  final List<FamilyProfileModel> profiles;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const ProfileChipsRow({
    super.key,
    this.title = 'Khám cho ai?',
    required this.profiles,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.familyProfiles),
                child: const Text(
                  'Quản lý',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final p = profiles[i];
                final sel = p.id == selectedId;
                return GestureDetector(
                  onTap: () => onSelected(p.id),
                  child: SizedBox(
                    width: 66,
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProfileAvatar(profile: p, size: 56, selected: sel),
                            if (sel)
                              const Positioned(
                                right: -2,
                                bottom: -2,
                                child: CircleAvatar(
                                  radius: 9,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                            color: sel ? _kPrimary : _kText,
                          ),
                        ),
                        Text(
                          p.isSelf ? 'Chính chủ' : p.quanHe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: _kGrey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet đổi hồ sơ đang xem (gọi từ Home / bất kỳ đâu).
Future<void> showProfileSwitcherSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      final fp = ctx.watch<FamilyProfileProvider>();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đổi hồ sơ đang xem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 10),
              ...fp.profiles.map((p) {
                final sel = p.id == fp.currentId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileAvatar(profile: p, size: 46, selected: sel),
                  title: Text(
                    p.hoTen.isEmpty ? 'Chưa có tên' : p.hoTen,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                  subtitle: Text(
                    p.isSelf ? 'Chính chủ' : p.quanHe,
                    style: const TextStyle(color: _kGrey),
                  ),
                  trailing: sel
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981))
                      : null,
                  onTap: () {
                    ctx.read<FamilyProfileProvider>().select(p.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(Icons.manage_accounts_rounded, color: _kPrimary),
                ),
                title: const Text(
                  'Quản lý người thân',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.familyProfiles);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}