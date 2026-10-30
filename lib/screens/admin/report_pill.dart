// lib/screens/admin/report_pill.dart
import 'package:flutter/material.dart';

/** Small rounded label, like Etiqueta in the Kotlin portal. */
class ReportPill extends StatelessWidget {
  const ReportPill({
    super.key,
    required this.text,
    required this.background,
    required this.color,
  });
  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
