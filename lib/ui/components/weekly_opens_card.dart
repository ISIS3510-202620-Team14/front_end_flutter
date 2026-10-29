import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';
import 'package:front_end_flutter/screens/teacher/home/weekly_opens_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';

/** Shows the opens of the week, the goal and a reminder while the teacher is below it. */
class WeeklyOpensCard extends StatelessWidget {
  const WeeklyOpensCard({super.key, required this.viewModel});
  final WeeklyOpensViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, Widget? child) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        final Color color = viewModel.reachedGoal
            ? AppTheme.green
            : AppTheme.amber;
        return EnadPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Aperturas de la semana',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${viewModel.count} de ${WeeklyOpensViewModel.goal}',
                    style: textTheme.titleMedium?.copyWith(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (viewModel.count / WeeklyOpensViewModel.goal).clamp(
                  0.0,
                  1.0,
                ),
                minHeight: 8,
                color: color,
                backgroundColor: AppTheme.line,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              Text(viewModel.message, style: textTheme.bodyMedium),
              if (viewModel.pending > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sin enviar al servidor: ${viewModel.pending}',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: viewModel.retrySync,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
