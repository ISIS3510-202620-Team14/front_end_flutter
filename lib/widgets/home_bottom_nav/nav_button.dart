part of 'home_bottom_nav.dart';

class _NavButton extends StatelessWidget {
  final HomeNavItem item;
  final int pendingCount;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.pendingCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? indicatorColor;
    Color iconColor = AppTheme.ink;
    if (selected) {
      indicatorColor = AppTheme.ink;
      iconColor = AppTheme.surface;
    }
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Badge(
                isLabelVisible: pendingCount > 0,
                backgroundColor: AppTheme.ink,
                textColor: AppTheme.surface,
                label: Text('$pendingCount'),
                child: Icon(item.icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
