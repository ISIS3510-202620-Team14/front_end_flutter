import 'package:front_end_flutter/feature/tutorials/task_tutorial_controller.dart';
import 'package:front_end_flutter/ui/components/brand_heading.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/teacher/home/home_viewmodel.dart';
import 'package:front_end_flutter/ui/components/quick_action_card.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/evaluation_menu_view.dart';
import 'package:front_end_flutter/domain/model/quick_action.dart';
import 'package:front_end_flutter/feature/actividad/activities_view.dart';
import 'package:front_end_flutter/screens/teacher/home/weekly_opens_viewmodel.dart';
import 'package:front_end_flutter/ui/components/weekly_opens_card.dart';
import 'package:front_end_flutter/domain/model/day_moment.dart';
import 'package:front_end_flutter/screens/teacher/home/day_context_viewmodel.dart';
import 'package:front_end_flutter/ui/components/day_moment_card.dart';
import 'package:front_end_flutter/ui/components/session_context_card.dart';

class HoyView extends StatelessWidget {
  const HoyView({
    super.key,
    required this.viewModel,
    required this.onStudents,
    required this.onHours,
    this.schools = const [],
    this.tutorial,
    this.opensViewModel,
    this.contextViewModel,
  });
  final HomeViewModel viewModel;
  final WeeklyOpensViewModel? opensViewModel;
  final DayContextViewModel? contextViewModel;
  final TaskTutorialController? tutorial;
  final List<Map<String, dynamic>> schools;
  final VoidCallback onStudents;
  final VoidCallback onHours;
  Future<void> _openEvaluation(BuildContext context) async {
    tutorial?.advance('evaluation', 0);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return EvaluationMenuView(
            tutorial: tutorial,
            viewModel: viewModel,
            schools: schools,
          );
        },
      ),
    );
    if (tutorial?.flow == 'evaluation') {
      tutorial?.stop();
    }
    contextViewModel?.refreshMoment();
  }

  Future<void> _openActivities(BuildContext context) async {
    tutorial?.advance('activities', 0);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ActivitiesView(
            tutorial: tutorial,
            subjects: HomeViewModel.subjectTitles,
          );
        },
      ),
    );
    if (tutorial?.flow == 'activities') {
      tutorial?.stop();
    }
  }

  void _onMomentAction(BuildContext context, SuggestedAction action) {
    switch (action) {
      case SuggestedAction.attendance:
        onStudents();
      case SuggestedAction.evaluation:
        _openEvaluation(context);
      case SuggestedAction.hours:
        onHours();
      case SuggestedAction.activities:
        _openActivities(context);
      case SuggestedAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DayContextViewModel? dayContext = contextViewModel;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, ?dayContext]),
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            BrandHeading(title: viewModel.sectionTitle),
            const SizedBox(height: 24),
            if (dayContext != null) ...[
              // Context-aware: el siguiente paso según la hora, el horario y lo ya registrado hoy.
              if (dayContext.moment != null) ...[
                DayMomentCard(
                  moment: dayContext.moment,
                  summary: dayContext.summary,
                  onAction: (SuggestedAction action) {
                    _onMomentAction(context, action);
                  },
                ),
                const SizedBox(height: 16),
              ],
              // F11: sugerencia de institución y grupo según ubicación y horario.
              SessionContextCard(viewModel: dayContext),
              const SizedBox(height: 16),
            ],
            if (opensViewModel != null) ...[
              WeeklyOpensCard(viewModel: opensViewModel!),
              const SizedBox(height: 16),
            ],
            if (viewModel.studentsViewModel.loading)
              const LinearProgressIndicator(),
            if (viewModel.studentsViewModel.error != null) ...[
              Text(viewModel.studentsViewModel.error!),
              TextButton(
                onPressed: viewModel.studentsViewModel.reload,
                child: const Text('Reintentar'),
              ),
            ],
            QuickActionCard(
              key: tutorial?.keyFor('hours', 0),
              action: const QuickAction(
                icon: Icons.access_time,
                title: 'Reportar horas',
                subtitle: 'Registra las horas de tu semana',
              ),
              onTap: onHours,
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              key: tutorial?.keyFor('attendance', 0),
              action: const QuickAction(
                icon: Icons.fact_check_outlined,
                title: 'Reportar asistencia',
                subtitle: 'Registra quiénes asistieron a la sesión',
              ),
              onTap: onStudents,
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              key: tutorial?.keyFor('evaluation', 0),
              action: const QuickAction(
                icon: Icons.assessment_outlined,
                title: 'Evaluación formativa',
                subtitle: 'Elige Lectura o Matemáticas',
              ),
              onTap: () {
                _openEvaluation(context);
              },
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              key: tutorial?.keyFor('activities', 0),
              action: const QuickAction(
                icon: Icons.menu_book_outlined,
                title: 'Planear actividades',
                subtitle: 'Elige actividades de la biblioteca',
              ),
              onTap: () {
                _openActivities(context);
              },
            ),
          ],
        );
      },
    );
  }
}
