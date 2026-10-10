part of 'hours_toggle_pill.dart';

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (selected) {
      borderColor = AppTheme.red;
    } else {
      borderColor = AppTheme.line;
    }
    final Color textColor;
    if (selected) {
      textColor = AppTheme.red;
    } else {
      textColor = AppTheme.softInk;
    }
    final Color backgroundColor;
    if (selected) {
      backgroundColor = AppTheme.red.withValues(alpha: 0.12);
    } else {
      backgroundColor = AppTheme.surface;
    }

    // Material + InkWell (en vez de GestureDetector) para dar el
    // feedback táctil (ripple) esperado en un target de este tamaño.
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999), // pills: radio infinito
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
