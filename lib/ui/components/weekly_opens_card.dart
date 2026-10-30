import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/teacher/home/weekly_opens_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/enad_progress.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Opens of the week against the goal, the same card as AperturasSemanaCard in Kotlin. */
class WeeklyOpensCard extends StatelessWidget {
  const WeeklyOpensCard({super.key, required this.viewModel});
  final WeeklyOpensViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? child) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        return EnadPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Uso de la app esta semana',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${viewModel.count}/${WeeklyOpensViewModel.goal}',
                    style: textTheme.titleLarge?.copyWith(color: AppTheme.red),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              EnadProgress(
                fraction: viewModel.count / WeeklyOpensViewModel.goal,
                color: AppTheme.red,
              ),
              if (!viewModel.reachedGoal) ...[
                const SizedBox(height: 8),
                Text(
                  'Vuelve a abrir la app esta semana para mantener al día el progreso de tus estudiantes.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
