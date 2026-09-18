import 'package:flutter/material.dart';
import '../viewmodels/grupos_viewmodel.dart';
import '../widgets/create_group_card.dart';
import '../widgets/empty_groups_state.dart';
import '../widgets/group_card.dart';
import '../widgets/pending_children_notice.dart';
import '../widgets/subject_tab_bar.dart';


class GruposView extends StatelessWidget {
  final GruposViewModel viewModel;

  const GruposView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final groups = viewModel.currentGroups;

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
                viewModel.sectionSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),

              SubjectTabBar(
                labels: viewModel.subjectLabels,
                selectedIndex: viewModel.selectedSubjectIndex,
                onChanged: viewModel.selectSubject,
              ),
              const SizedBox(height: 16),

              if (groups.isEmpty)
                EmptyGroupsState(
                  subjectLabel:
                      viewModel.isMathSelected ? 'matemáticas' : 'lectura',
                  onCreateGroup: viewModel.createGroup,
                )
              else ...[
                for (final group in groups) ...[
                  GroupCard(group: group, onView: () {}, onEdit: () {}),
                  const SizedBox(height: 12),
                ],
                PendingChildrenNotice(count: viewModel.pendingChildrenCount),
                const SizedBox(height: 8),
                CreateGroupCard(onTap: viewModel.createGroup),
              ],
            ],
          ),
        );
      },
    );
  }
}
