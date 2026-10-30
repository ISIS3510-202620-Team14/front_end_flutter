// lib/screens/admin/report_row.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.label,
    required this.detail,
    required this.value,
  });
  final String label;
  final String detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.labelMedium),
                    Text(detail),
                  ],
                ),
              ),
              Text(value, style: text.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
