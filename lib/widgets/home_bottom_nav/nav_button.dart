part of 'home_bottom_nav.dart';

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
    final Color labelColor;
    if (selected) {
      labelColor = AppTheme.red;
    } else {
      labelColor = AppTheme.ink;
    }

    final Color? indicatorColor;
    if (selected) {
      indicatorColor = AppTheme.red.withAlpha(38);
    } else {
      indicatorColor = null;
    }
    final Color iconColor;
    if (selected) {
      iconColor = Colors.white;
    } else {
      iconColor = AppTheme.ink;
    }
    final FontWeight labelWeight;
    if (selected) {
      labelWeight = FontWeight.w700;
    } else {
      labelWeight = FontWeight.w500;
    }
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
              color: indicatorColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(item.icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: labelWeight,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
