import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CourseChips extends StatelessWidget {
  const CourseChips({
    super.key,
    required this.courses,
    required this.selected,
    required this.onChanged,
  });

  final List<String> courses;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final course in courses)
          _CourseChip(
            label: course,
            selected: course == selected,
            onTap: () => onChanged(course),
          ),
      ],
    );
  }
}

class _CourseChip extends StatelessWidget {
  const _CourseChip({
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

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}