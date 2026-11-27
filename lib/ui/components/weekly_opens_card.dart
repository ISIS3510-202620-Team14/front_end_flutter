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
        final bool ready = viewModel.loaded;
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
                    ready
                        ? '${viewModel.count}/${WeeklyOpensViewModel.goal}'
                        : '…',
                    style: textTheme.titleLarge?.copyWith(color: AppTheme.red),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              EnadProgress(
                fraction: ready
                    ? viewModel.count / WeeklyOpensViewModel.goal
                    : 0,
                color: AppTheme.red,
              ),
              const SizedBox(height: 8),
              Text(
                ready ? viewModel.message : 'Contando tus aperturas…',
                style: textTheme.bodyMedium,
              ),
              if (ready && viewModel.pending > 0) ...[
                const SizedBox(height: 8),
                Text(
                  viewModel.pending == 1
                      ? '1 apertura está guardada en tu teléfono y se enviará cuando haya conexión.'
                      : '${viewModel.pending} aperturas están guardadas en tu teléfono y se enviarán cuando haya conexión.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.softInk,
                  ),
                ),
                TextButton(
                  onPressed: viewModel.retrySync,
                  child: const Text('Enviar ahora'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
