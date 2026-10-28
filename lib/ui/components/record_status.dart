import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class RecordStatus extends StatelessWidget {
  const RecordStatus({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Color background = AppTheme.amberBackground;
    Color foreground = AppTheme.amberText;
    if (label == 'Enviado') {
      background = AppTheme.greenBackground;
      foreground = AppTheme.assessedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: AppTheme.recordStatusText(foreground)),
    );
  }
}
