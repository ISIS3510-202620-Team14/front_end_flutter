part of 'grouping_method_selector.dart';

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isRecommended;
  final double? confidence;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color borderColor;
    if (isSelected) {
      borderColor = AppTheme.green;
    } else {
      borderColor = AppTheme.line;
    }
    final Color bgColor;
    if (isSelected) {
      bgColor = AppTheme.greenBackground;
    } else {
      bgColor = AppTheme.surface;
    }

    final double borderWidth;
    if (isSelected) {
      borderWidth = 2.0;
    } else {
      borderWidth = 1.0;
    }
    final Color iconBackground;
    if (isSelected) {
      iconBackground = AppTheme.green;
    } else {
      iconBackground = AppTheme.softInk;
    }
    final IconData selectionIcon;
    if (isSelected) {
      selectionIcon = Icons.radio_button_checked;
    } else {
      selectionIcon = Icons.radio_button_unchecked;
    }
    final Color selectionColor;
    if (isSelected) {
      selectionColor = AppTheme.green;
    } else {
      selectionColor = AppTheme.line;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconBackground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        _RecommendedBadge(confidence: confidence),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(selectionIcon, size: 22, color: selectionColor),
          ],
        ),
      ),
    );
  }
}
