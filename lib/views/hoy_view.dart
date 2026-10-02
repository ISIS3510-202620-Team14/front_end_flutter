import 'package:flutter/material.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/subject_progress_card.dart';
import 'classification_view.dart';
import 'scanner_view.dart';
import 'activities_view.dart';
import '../services/analytics_service.dart';
import '../models/quick_action.dart';
 
class HoyView extends StatelessWidget {
  final HomeViewModel viewModel;
 
  const HoyView({super.key, required this.viewModel});
 
  Future<void> _openScanner(BuildContext context) async {
    final rows = await showStudentScanner(context);
    if (rows == null || !context.mounted) return;

    final added = viewModel.importScanned([
      for (final r in rows) (name: r.name, sex: r.sex),
    ]);
    AnalyticsService.instance.log(AnalyticsEvents.studentsScanned, {
      'detected': rows.length,
      'imported': added,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'Esos estudiantes ya estaban en la lista.'
          : 'Se importaron $added estudiantes.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.sectionTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${viewModel.studentName} · ${viewModel.grade}',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              for (final subject in viewModel.subjects) ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClassificationView(
                        title: subject.title,
                        studentsViewModel: viewModel.studentsViewModel,
                      ),
                    ),
                  ),
                  child: SubjectProgressCard(data: subject),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
              for (final action in viewModel.actions) ...[
                QuickActionCard(action: action),
                const SizedBox(height: 16),
              ],
              QuickActionCard(
                action: const QuickAction(
                  icon: Icons.document_scanner_outlined,
                  title: 'Escanear lista',
                  subtitle: 'Importa estudiantes con la cámara',
                  shape: QuickActionShape.roundedSquare,
                ),
                onTap: () => _openScanner(context),
              ),
              const SizedBox(height: 16),
              QuickActionCard(
                action: const QuickAction(
                  icon: Icons.menu_book_outlined,
                  title: 'Planear actividades',
                  subtitle: 'Usa la biblioteca o crea las tuyas',
                  shape: QuickActionShape.roundedSquare,
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ActivitiesView(
                    subjects: HomeViewModel.subjectTitles,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              Text(
                viewModel.demoNote,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
 