import 'package:flutter/material.dart';
import '../core/theme.dart';

// ============ AVATAR CHỮ (BM / TA / HN...) ============
class AvatarBox extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  const AvatarBox({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 14)),
    );
  }
}

// ============ NÚT BACK TRÒN ============
class BackCircle extends StatelessWidget {
  const BackCircle({super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.chevron_left, size: 24),
      ),
    );
  }
}

// ============ NÚT CHUÔNG CAM ============
class BellButton extends StatelessWidget {
  const BellButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.notifications, color: kOrange, size: 22),
    );
  }
}

// ============ BADGE NHỎ (Lỗi QR / Lỗi đặt lịch...) ============
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const AppBadge(
      {super.key, required this.text, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ============ THANH ĐIỀU HƯỚNG DƯỚI ============
class AdminBottomBar extends StatelessWidget {
  final int current;
  final Function(int) onTap;
  const AdminBottomBar(
      {super.key, required this.current, required this.onTap});

  Widget item(int i, String label, IconData icon) {
    final bool isLogout = i == 1;
    final bool active = i == current;
    final Color color =
        isLogout ? kRed : (active ? kPrimary : Colors.grey);
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            item(0, 'Trang chủ', Icons.home_filled),
            item(1, 'Đăng xuất', Icons.logout),
          ],
        ),
      ),
    );
  }
}

// ============ Ô TÌM KIẾM DÙNG CHUNG ============
class SearchBox extends StatelessWidget {
  final String hint;
  const SearchBox({super.key, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          icon: const Icon(Icons.search, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
}
