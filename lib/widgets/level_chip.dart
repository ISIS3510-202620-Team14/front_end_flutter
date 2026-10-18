import 'package:flutter/material.dart';
import '../models/level.dart';

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
    final Color background =
        selected ? level.color : level.color.withValues(alpha: 0.12);
    final Color textColor = selected ? Colors.white : level.color;

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
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}