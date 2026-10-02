import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/grupos_viewmodel.dart';
import '../widgets/create_group_card.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/empty_groups_state.dart';
import '../widgets/group_card.dart';
import '../widgets/pending_children_notice.dart';
import '../widgets/subject_tab_bar.dart';

class GruposView extends StatelessWidget {
  final GruposViewModel viewModel;

  const GruposView({super.key, required this.viewModel});

  void _openCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateGroupDialog(
        initialSubject: viewModel.currentSubjectKey,
        estimatedClassSize: viewModel.totalStudentsInSubject,
        analyticsService: viewModel.analyticsService,
        onConfirm: ({
          required String name,
          required String subject,
          required method,
        }) =>
            viewModel.createGroupOnBackend(
          name: name,
          subject: subject,
          method: method,
        ),
      ),
    );
  }

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

              if (viewModel.error != null)
                _ErrorBanner(
                  message: viewModel.error!,
                  onRetry: () => viewModel.loadGroups(),
                ),

              if (viewModel.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groups.isEmpty)
                EmptyGroupsState(
                  subjectLabel:
                      viewModel.isMathSelected ? 'matemáticas' : 'lectura',
                  onCreateGroup: () => _openCreateGroupDialog(context),
                )
              else ...[
                for (final group in groups) ...[
                  GroupCard(group: group, onView: () {}, onEdit: () {}),
                  const SizedBox(height: 12),
                ],
                PendingChildrenNotice(count: viewModel.pendingChildrenCount),
                const SizedBox(height: 8),
                CreateGroupCard(onTap: () => _openCreateGroupDialog(context)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amberBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: AppTheme.amberText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 13, color: AppTheme.amberText),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: const Icon(Icons.refresh, size: 20, color: AppTheme.amberText),
          ),
        ],
      ),
    );
  }
}
