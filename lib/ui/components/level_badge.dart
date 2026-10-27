import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/level_palette.dart';

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final Color color = LevelPalette.forName(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: LevelPalette.label(Theme.of(context).textTheme, color),
      ),
    );
  }
}
