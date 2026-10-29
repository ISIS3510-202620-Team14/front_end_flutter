import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';
import 'package:front_end_flutter/screens/teacher/home/day_context_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

const _subjectLabels = <String, String>{
  'matematicas': 'Matemáticas',
  'lectura': 'Lectura',
};

/** Light confirmation of the day's context: suggestion, manual choice or the group already chosen. */
class SessionContextCard extends StatelessWidget {
  const SessionContextCard({super.key, required this.viewModel});
  final DayContextViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final GroupOfDay? suggestion = viewModel.suggestion;
    if (viewModel.loading) {
      return const Text(
        'Buscando tu institución…',
        style: TextStyle(fontSize: 13, color: AppTheme.softInk),
      );
    }
    if (viewModel.choosing) return _choose(context);
    if (suggestion != null) return _suggestion(context, suggestion);
    if (viewModel.confirmed != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: viewModel.change,
          child: const Text('Cambiar grupo'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _suggestion(BuildContext context, GroupOfDay group) {
    final String detail = [
      if (group.school != null) 'Estás en ${group.school}',
      if (group.plannedHours != null)
        'hoy ${formatHours(group.plannedHours!)} h planeadas',
    ].join(' · ');
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Iniciar sesión con ${group.name}?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: const TextStyle(fontSize: 13, color: AppTheme.softInk),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: viewModel.acceptSuggestion,
                  child: const Text('Sí, iniciar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: viewModel.change,
                  child: const Text('Cambiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choose(BuildContext context) {
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Con qué grupo trabajas hoy?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final GroupOfDay group in viewModel.groups) ...[
            const SizedBox(height: 10),
            Material(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  viewModel.choose(group);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        [
                          _subjectLabels[group.subject] ?? group.subject,
                          ?group.school,
                          if (group.plannedHours != null)
                            'hoy ${formatHours(group.plannedHours!)} h',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.softInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
