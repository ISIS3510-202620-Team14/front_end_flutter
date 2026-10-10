import 'package:front_end_flutter/views/group_detail_view/group_detail_view.dart';
import 'package:front_end_flutter/models/group/group.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/viewmodels/grupos_viewmodel/grupos_viewmodel.dart';
import 'package:front_end_flutter/widgets/create_group_card/create_group_card.dart';
import 'package:front_end_flutter/widgets/create_group_dialog/create_group_dialog.dart';
import 'package:front_end_flutter/widgets/empty_groups_state/empty_groups_state.dart';
import 'package:front_end_flutter/widgets/group_card/group_card.dart';
import 'package:front_end_flutter/widgets/pending_children_notice/pending_children_notice.dart';
import 'package:front_end_flutter/widgets/subject_tab_bar/subject_tab_bar.dart';
part 'error_banner.dart';

class GruposView extends StatelessWidget {
  final GruposViewModel viewModel;
  final List<Map<String, dynamic>> schools;

  const GruposView({super.key, required this.viewModel, required this.schools});

  void _openCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return CreateGroupDialog(
          initialSubject: viewModel.currentSubjectKey,
          estimatedClassSize: viewModel.totalStudentsInSubject,
          recommendationLoader: viewModel.recommend,
          onConfirm:
              ({
                required String name,
                required String subject,
                required method,
              }) {
                return viewModel.createGroupOnBackend(
                  name: name,
                  subject: subject,
                  method: method,
                );
              },
        );
      },
    );
  }

  void _openDetail(BuildContext context, Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return GroupDetailView(group: group, groups: viewModel);
        },
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
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: viewModel.selectedSchoolId,
                decoration: const InputDecoration(labelText: 'Institución'),
                items: [
                  for (final school in schools)
                    DropdownMenuItem(
                      value: school['id'] as String,
                      child: Text(school['name'] as String),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    viewModel.selectSchool(value);
                  }
                },
              ),
              SubjectTabBar(
                labels: viewModel.subjectLabels,
                selectedIndex: viewModel.selectedSubjectIndex,
                onChanged: viewModel.selectSubject,
              ),
              const SizedBox(height: 16),

              if (viewModel.error != null)
                _ErrorBanner(
                  message: viewModel.error!,
                  onRetry: () {
                    viewModel.loadGroups();
                  },
                ),

              if (viewModel.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groups.isEmpty)
                EmptyGroupsState(
                  subjectLabel: _subjectLabel(),
                  onCreateGroup: () {
                    return _openCreateGroupDialog(context);
                  },
                )
              else ...[
                for (final group in groups) ...[
                  GroupCard(
                    group: group,
                    onView: () {
                      _openDetail(context, group);
                    },
                    onEdit: () {
                      _openDetail(context, group);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                PendingChildrenNotice(count: viewModel.pendingChildrenCount),
                const SizedBox(height: 8),
                CreateGroupCard(
                  onTap: () {
                    return _openCreateGroupDialog(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _subjectLabel() {
    if (viewModel.isMathSelected) {
      return 'matemáticas';
    } else {
      return 'lectura';
    }
  }
}
