import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/level/level.dart';

class LevelChip extends StatelessWidget {
  const LevelChip({
    super.key,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final Level level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    if (selected) {
      background = level.color;
    } else {
      background = level.color.withValues(alpha: 0.12);
    }
    final Color textColor;
    if (selected) {
      textColor = Colors.white;
    } else {
      textColor = level.color;
    }

    final FontWeight labelWeight;
    if (selected) {
      labelWeight = FontWeight.w700;
    } else {
      labelWeight = FontWeight.w500;
    }
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: level.color),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            level.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: labelWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
