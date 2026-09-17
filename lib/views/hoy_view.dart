import 'package:flutter/material.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/subject_progress_card.dart';

class HoyView extends StatelessWidget {
  final HomeViewModel viewModel;

  const HoyView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
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
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final subject in viewModel.subjects) ...[
            SubjectProgressCard(data: subject),
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
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
