import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class HoursDifferenceNotice extends StatelessWidget {
  const HoursDifferenceNotice({super.key, required this.differenceHours});

  final int differenceHours;

  @override
  Widget build(BuildContext context) {
    
    if (differenceHours <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.amberBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Diferencia: $differenceHours h no realizadas.',
        style: const TextStyle(
          color: AppTheme.amberText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
