import 'package:flutter/material.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/subject_progress_card.dart';
import 'classification_view.dart';
 
class HoyView extends StatelessWidget {
  final HomeViewModel viewModel;
 
  const HoyView({super.key, required this.viewModel});
 
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
 