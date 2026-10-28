import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class EnadPanel extends StatelessWidget {
  const EnadPanel({
    super.key,
    required this.child,
    this.color = AppTheme.surface,
  });
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.panelRadius),
          side: const BorderSide(color: AppTheme.line),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}
