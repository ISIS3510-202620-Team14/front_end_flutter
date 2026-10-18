import 'package:flutter/material.dart';

import '../models/hours_history.dart';
import '../theme/app_theme.dart';


class HoursHeatmap extends StatelessWidget {
  const HoursHeatmap({super.key, required this.history});

  final HoursHistory history;

  static const List<String> _dayLabels = ['L', 'M', 'M', 'J', 'V'];

  @override
  Widget build(BuildContext context) {

    
    final maxHours = history.weeks
        .expand((week) => week.dailyHours)
        .fold<double>(0, (max, hours) => hours > max ? hours : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas 12 semanas',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${history.totalCompletedHours.toStringAsFixed(1)} h realizadas de '
          '${history.totalScheduledHours.toStringAsFixed(1)} h programadas. '
          'Toca un día para registrar horas de ejemplo.',
          style: const TextStyle(color: AppTheme.softInk, fontSize: 13),
        ),
        const SizedBox(height: 12),
        // Una fila por día de la semana (L-V); cada fila recorre las
        // 12 semanas para pintar una celda por semana.
        for (var dayIndex = 0; dayIndex < _dayLabels.length; dayIndex++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    _dayLabels[dayIndex],
                    style:
                        const TextStyle(color: AppTheme.softInk, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                for (final week in history.weeks)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _HeatCell(
                      hours: week.dailyHours[dayIndex],
                      maxHours: maxHours,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Menos',
                style: TextStyle(color: AppTheme.softInk, fontSize: 12)),
            const SizedBox(width: 6),
            for (final step in [0.0, 0.25, 0.5, 0.75, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.12 + step * 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Text('Más',
                style: TextStyle(color: AppTheme.softInk, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.hours, required this.maxHours});

  final double hours;
  final double maxHours;

  @override
  Widget build(BuildContext context) {
    final intensity = maxHours == 0 ? 0.0 : (hours / maxHours).clamp(0.0, 1.0);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: 0.12 + intensity * 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
