import 'package:flutter/material.dart';

class JaibBottomBar extends StatelessWidget {
  const JaibBottomBar({
    super.key,
    required this.index,
    required this.onTap,
  });

  final int index;
  final ValueChanged<int> onTap;

  static const primary = Color(0xFF0C4A40);
  static const phosphor = Color(0xFFD4E157);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: Colors.white,
      elevation: 10,
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.home_rounded, 'الرئيسية', 0),
          _buildItem(Icons.receipt_long_rounded, 'عملياتي', 1),
          const SizedBox(width: 48),
          _buildItem(Icons.notifications_none_rounded, 'إشعارات', 2),
          _buildItem(Icons.person_rounded, 'حسابي', 3),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int itemIndex) {
    return BottomNavIcon(
      icon: icon,
      label: label,
      selected: index == itemIndex,
      onTap: () => onTap(itemIndex),
    );
  }
}

class BottomNavIcon extends StatelessWidget {
  const BottomNavIcon({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? JaibBottomBar.primary : Colors.grey.shade500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 54,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JaibFab extends StatelessWidget {
  const JaibFab({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: JaibBottomBar.phosphor, width: 3),
        boxShadow: [
          BoxShadow(
            color: JaibBottomBar.phosphor.withOpacity(.75),
            blurRadius: 18,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Color(0x330C4A40),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: JaibBottomBar.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 26),
      ),
    );
  }
}
