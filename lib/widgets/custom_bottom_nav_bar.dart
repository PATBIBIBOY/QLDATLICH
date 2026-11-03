import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Dữ liệu một mục trên thanh điều hướng.
class _NavItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItemData(this.activeIcon, this.inactiveIcon, this.label);
}

// Thanh điều hướng phong cách Y tế hiện đại: Kính mờ sáng, tinh tế, chuyên nghiệp.
class MedicalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;
  final int chatCount;

  // Mục nổi bật (VD: nút "Đặt lịch nhanh" ở giữa). 
  // Nếu không cần, để null.
  final int? highlightIndex;

  // Ứng dụng y tế NÊN hiển thị nhãn để rõ ràng.
  final bool showLabels;

  // 🎨 BẢNG MÀU Y TẾ
  static const Color _primary = Color(0xFF2563EB); // Xanh dương y tế tin cậy
  static const Color _primaryLight = Color(0xFFDBEAFE); // Xanh nhạt cho nền active
  static const Color _textInactive = Color(0xFF94A3B8); // Xám xanh dịu mắt
  static const Color _glassBg = Color(0xFFFFFFFF); // Nền kính trắng sáng
  static const Color _badge = Color(0xFFEF4444); // Đỏ珊瑚 cho thông báo (dịu hơn đỏ gắt)

  static const double _barHeight = 72; // Cao hơn một chút để chứa label
  static const double _barRadius = 24; // Bo góc mềm mại, hiện đại

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
    _NavItemData(Icons.calendar_today_rounded, Icons.calendar_today_outlined, 'Lịch khám'),
    _NavItemData(Icons.chat_rounded, Icons.chat_bubble_outline_rounded, 'Hỗ trợ'),
    _NavItemData(Icons.notifications_rounded, Icons.notifications_none_rounded, 'Thông báo'),
    _NavItemData(Icons.person_rounded, Icons.person_outline_rounded, 'Cá nhân'),
  ];

  const MedicalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    this.chatCount = 0,
    this.highlightIndex,
    this.showLabels = true, // Mặc định bật label cho app y tế
  });

  @override
  Widget build(BuildContext context) {
    final count = _items.length;
    final index = currentIndex < 0 ? 0 : (currentIndex >= count ? count - 1 : currentIndex);
    final hidePill = highlightIndex != null && index == highlightIndex;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_barRadius),
            // Shadow màu xanh rất nhẹ tạo cảm giác nổi khối sạch sẽ
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_barRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: _barHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: _glassBg.withOpacity(0.85), // Nền trắng mờ
                  borderRadius: BorderRadius.circular(_barRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5), // Viền kính sáng
                ),
                child: Stack(
                  children: [
                    // 🟢 Ô nền trượt mượt mà (Pill)
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(-1 + 2 * index / (count - 1), 0),
                      child: AnimatedOpacity(
                        opacity: hidePill ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: FractionallySizedBox(
                          widthFactor: 1 / count,
                          heightFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _primaryLight.withOpacity(0.7), // Nền xanh nhạt dịu mắt
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Các mục điều hướng
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        count,
                        (i) => Expanded(child: _buildItem(i, index)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int i, int activeIndex) {
    final item = _items[i];
    final isActive = i == activeIndex;
    final isHighlight = highlightIndex != null && i == highlightIndex;
    final badge = i == 2 ? chatCount : (i == 3 ? notificationCount : 0);

    final Widget icon = isHighlight
        ? _HighlightButton(icon: item.activeIcon, active: isActive)
        : AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              isActive ? item.activeIcon : item.inactiveIcon,
              size: 26,
              color: isActive ? _primary : _textInactive,
            ),
          );

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact(); // Rung nhẹ tinh tế hơn
          onTap(i);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                icon,
                if (badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _Badge(count: badge),
                  ),
              ],
            ),
            if (showLabels) ...[
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _primary : _textInactive,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Nút nổi bật (VD: cho mục "Đặt lịch nhanh" hoặc "Khẩn cấp")
class _HighlightButton extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _HighlightButton({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)], // Gradient xanh dương chuyên nghiệp
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 26, color: Colors.white),
      ),
    );
  }
}

// Huy hiệu số đỏ tinh tế, có viền trắng để nổi bật trên nền sáng
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MedicalBottomNavBar._badge,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5), // Viền trắng giúp nổi bật
        boxShadow: [
          BoxShadow(
            color: MedicalBottomNavBar._badge.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}