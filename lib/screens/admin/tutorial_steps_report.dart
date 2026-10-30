// lib/screens/admin/tutorial_steps_report.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/screens/admin/report_format.dart';
import 'package:front_end_flutter/screens/admin/report_section.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** With fewer runs than this the report draws no conclusion for a guide, like Kotlin. */
const _minRuns = 5;

/** Where teachers leave each Help guide and which optional steps they skip. */
class TutorialStepsReport extends StatelessWidget {
  const TutorialStepsReport({super.key, this.reports});
  final ReportsRepository? reports;

  @override
  Widget build(BuildContext context) {
    return ReportSection(
      reports: reports,
      description: 'En qué paso dejan los docentes cada guía y qué pasos opcionales se saltan (últimas 8 semanas).',
      load: (ReportsRepository repository, {bool force = false}) {
        return repository.tutorialSteps(force: force);
      },
      isEmpty: (report) {
        return (report['tutorials'] as List).every((guide) {
          return guide is! Map || (guide['runs'] as num? ?? 0) == 0;
        });
      },
      emptyText: 'Todavía nadie ha usado las guías en este periodo.',
      builder: (context, report) {
        return [
          for (final guide in report['tutorials'] as List)
            if (guide is Map) _guide(context, guide),
        ];
      },
    );
  }

  Widget _guide(BuildContext context, Map guide) {
    final text = Theme.of(context).textTheme;
    final String id = '${guide['id']}';
    final int runs = (guide['runs'] as num? ?? 0).toInt();
    final Map platforms = guide['byPlatform'] as Map? ?? const {};
    final List<Map> abandoned = [
      for (final step in guide['abandonedAtStep'] as List? ?? const [])
        if (step is Map) step,
    ];
    final List<Map> skipped = [
      for (final step in guide['skippedSteps'] as List? ?? const [])
        if (step is Map) step,
    ];
    final TextStyle? conclusion = text.labelLarge?.copyWith(
      color: AppTheme.red,
    );
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TaskTutorialController.labels[id] ?? id,
            style: text.titleMedium,
          ),
          Text(
            '$runs iniciada(s), ${guide['completed']} terminada(s) '
            '(${adminPercentage(guide['completionRate'] as num?)})',
          ),
          Text(
            'Kotlin ${platforms['kotlin'] ?? 0} · Flutter ${platforms['flutter'] ?? 0}',
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          if (runs < _minRuns)
            const Text(
              'Todavía no hay datos suficientes para sacar una conclusión.',
            )
          else ...[
            // The answer of the BQ: the step where most leave and the one most skipped.
            Text(
              abandoned.isEmpty
                  ? 'Nadie la dejó a la mitad.'
                  : 'Donde más la dejan: ${_step(id, abandoned.first)}.',
              style: conclusion,
            ),
            if (skipped.isNotEmpty)
              Text(
                'El paso que más se salta: ${_step(id, skipped.first)}.',
                style: conclusion,
              ),
            for (final step in abandoned.take(3))
              _row(id, step, 'la dejaron aquí', runs),
            for (final step in skipped.take(3))
              _row(id, step, 'lo saltaron', runs),
          ],
        ],
      ),
    );
  }

  String _step(String id, Map step) {
    return TaskTutorialController.stepName(
      id,
      (step['step'] as num? ?? 0).toInt(),
    );
  }

  Widget _row(String id, Map step, String action, int runs) {
    final int count = (step['runs'] as num? ?? 0).toInt();
    return ReportRow(
      label: _step(id, step),
      detail: '$count corrida(s) $action',
      value: adminPercentage((count * 1000 / runs).round() / 10),
    );
  }
}
