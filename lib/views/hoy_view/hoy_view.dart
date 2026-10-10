import 'package:flutter/material.dart';
import 'package:front_end_flutter/viewmodels/home_viewmodel/home_viewmodel.dart';
import 'package:front_end_flutter/widgets/quick_action_card/quick_action_card.dart';
import 'package:front_end_flutter/widgets/subject_progress_card/subject_progress_card.dart';
import 'package:front_end_flutter/models/quick_action/quick_action.dart';
import 'package:front_end_flutter/views/classification_view/classification_view.dart';
import 'package:front_end_flutter/views/activities_view/activities_view.dart';

class HoyView extends StatelessWidget {
  const HoyView({
    super.key,
    required this.viewModel,
    required this.onStudents,
    required this.onHours,
  });
  final HomeViewModel viewModel;
  final VoidCallback onStudents;
  final VoidCallback onHours;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              viewModel.sectionTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            if (viewModel.studentsViewModel.loading)
              const LinearProgressIndicator(),
            if (viewModel.studentsViewModel.error != null) ...[
              Text(viewModel.studentsViewModel.error!),
              TextButton(
                onPressed: viewModel.studentsViewModel.reload,
                child: const Text('Reintentar'),
              ),
            ],
            for (final subject in viewModel.subjects) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return ClassificationView(
                          title: subject.title,
                          studentsViewModel: viewModel.studentsViewModel,
                        );
                      },
                    ),
                  );
                },
                child: SubjectProgressCard(data: subject),
              ),
              const SizedBox(height: 16),
            ],
            QuickActionCard(
              action: const QuickAction(
                icon: Icons.access_time,
                title: 'Planear horas',
                subtitle: 'Registra tus horas por día',
              ),
              onTap: onHours,
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              action: const QuickAction(
                icon: Icons.document_scanner_outlined,
                title: 'Mi lista y escáner',
                subtitle: 'Importa estudiantes y toma asistencia',
              ),
              onTap: onStudents,
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              action: const QuickAction(
                icon: Icons.menu_book_outlined,
                title: 'Planear actividades',
                subtitle: 'Usa la biblioteca o crea las tuyas',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const ActivitiesView(
                        subjects: HomeViewModel.subjectTitles,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
