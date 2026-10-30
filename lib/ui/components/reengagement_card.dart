import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/teacher/home/weekly_opens_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Type 5 BQ: shown on Hoy only when the weekly opens dropped, to bring the teacher back. */
class ReengagementCard extends StatelessWidget {
  const ReengagementCard({
    super.key,
    required this.viewModel,
    required this.onAttendance,
  });
  final WeeklyOpensViewModel viewModel;
  final VoidCallback onAttendance;

  String _times(num value) {
    final String number = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return value == 1 ? '$number vez' : '$number veces';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? child) {
        if (!viewModel.showsRisk) return const SizedBox.shrink();
        final TextTheme text = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EnadPanel(
            color: AppTheme.amberBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Has entrado menos que antes', style: text.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'La semana pasada abriste la app ${_times(viewModel.risk.lastWeek)}; '
                  'antes lo hacías unas ${_times(viewModel.risk.usualWeek)} por semana. '
                  'Con unos minutos hoy dejas al día la asistencia de tus estudiantes.',
                  style: text.bodyMedium?.copyWith(color: AppTheme.amberText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          viewModel.acceptRisk();
                          onAttendance();
                        },
                        child: const Text('Reportar asistencia'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: viewModel.dismissRisk,
                      child: const Text('Ahora no'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
