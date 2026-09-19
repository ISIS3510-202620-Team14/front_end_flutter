import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class HoursTogglePill extends StatelessWidget {
  const HoursTogglePill({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillOption(
          label: 'Sí',
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 12),
        _PillOption(
          label: 'No',
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

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
    final Color borderColor = selected ? AppTheme.red : AppTheme.line;
    final Color textColor = selected ? AppTheme.red : AppTheme.softInk;
    final Color backgroundColor =
        selected ? AppTheme.red.withValues(alpha: 0.12) : AppTheme.surface;

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
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
