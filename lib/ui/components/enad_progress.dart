import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Thin rounded progress bar, the same as EnadProgress in the Kotlin app (4 dp, line color track). */
class EnadProgress extends StatelessWidget {
  const EnadProgress({super.key, required this.fraction, this.color});
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0).toDouble(),
        minHeight: 4,
        color: color ?? AppTheme.ink,
        backgroundColor: AppTheme.line,
      ),
    );
  }
}
