import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeNavItem {
  final IconData icon;
  final String label;

  const HomeNavItem({required this.icon, required this.label});
}

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  static const items = [
    HomeNavItem(icon: Icons.calendar_today, label: 'Hoy'),
    HomeNavItem(icon: Icons.list_alt, label: 'Mi lista'),
    HomeNavItem(icon: Icons.groups_outlined, label: 'Grupos'),
    HomeNavItem(icon: Icons.calendar_month_outlined, label: 'Horas'),
    HomeNavItem(icon: Icons.person_outline, label: 'Mis datos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final HomeNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? AppTheme.red : AppTheme.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppTheme.red.withAlpha(38) : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              item.icon,
              color: selected ? Colors.white : AppTheme.ink,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
