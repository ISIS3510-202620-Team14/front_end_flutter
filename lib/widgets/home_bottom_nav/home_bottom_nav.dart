import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'home_nav_item.dart';
part 'nav_button.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final int pendingCount;
  final ValueChanged<int> onSelect;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    this.pendingCount = 0,
    required this.onSelect,
  });

  static const items = [
    HomeNavItem(icon: Icons.calendar_today, label: 'Hoy'),
    HomeNavItem(icon: Icons.list_alt, label: 'Asistencia'),
    HomeNavItem(icon: Icons.groups_outlined, label: 'Grupos'),
    HomeNavItem(icon: Icons.calendar_month_outlined, label: 'Horas'),
    HomeNavItem(icon: Icons.person_outline, label: 'Mis datos'),
  ];

  int _pendingFor(int index) {
    if (index == 1) {
      return pendingCount;
    }
    return 0;
  }

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
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    pendingCount: _pendingFor(i),
                    selected: i == currentIndex,
                    onTap: () {
                      onSelect(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
