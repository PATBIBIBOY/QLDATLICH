import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;
  final int chatCount;

  static const Color _primary = Color(0xFF1E78E0);
  static const Color _grey = Color(0xFF94A3B8);
  static const Color _danger = Color(0xFFEF4444);

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    this.chatCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, activeIcon: Icons.home, inactiveIcon: Icons.home_outlined, label: 'Trang chủ'),
              _buildNavItem(index: 1, activeIcon: Icons.calendar_today, inactiveIcon: Icons.calendar_today_outlined, label: 'Lịch khám'),
              _buildNavItem(index: 2, activeIcon: Icons.chat_bubble, inactiveIcon: Icons.chat_bubble_outline, label: 'Chat', badgeCount: chatCount),
              _buildNavItem(index: 3, activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Thông báo', badgeCount: notificationCount),
              _buildNavItem(index: 4, activeIcon: Icons.person, inactiveIcon: Icons.person_outline, label: 'Cá nhân'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : inactiveIcon, color: isActive ? _primary : _grey, size: 26),
                if (badgeCount > 0)
                  Positioned(
                    right: -6, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: _danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(badgeCount > 9 ? '9+' : '$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? _primary : _grey)),
          ],
        ),
      ),
    );
  }
}