import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const GroupCard({super.key, required this.group, this.onView, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String childrenLabel;
    if (group.childrenCount == 1) {
      childrenLabel = 'estudiante';
    } else {
      childrenLabel = 'estudiantes';
    }
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.panelRadius),
      child: InkWell(
        onTap: onView ?? onEdit,
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.panelRadius),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(group.name, style: textTheme.titleMedium),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.red),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${group.childrenCount} '
                    '$childrenLabel',
                    style: textTheme.bodyLarge?.copyWith(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: AppTheme.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.teacherLabel,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
