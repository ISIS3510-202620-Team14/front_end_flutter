import 'package:front_end_flutter/ui/theme/level_palette.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/level.dart';

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
  BorderSide _border() {
    if (selected) {
      return const BorderSide(color: Color(0xFF1D1D1B), width: 2);
    }
    return BorderSide(color: level.color);
  }

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(level.name),
      selected: selected,
      backgroundColor: level.color,
      selectedColor: level.color,
      labelStyle: LevelPalette.label(Theme.of(context).textTheme, level.color),
      checkmarkColor: LevelPalette.foreground(level.color),
      side: _border(),
      onSelected: (bool value) {
        onTap();
      },
    );
  }
}
