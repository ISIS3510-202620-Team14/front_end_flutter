import 'package:flutter/material.dart';
import '../models/group.dart';
import '../theme/app_theme.dart';


class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onView;
  final VoidCallback? onEdit;

  const GroupCard({
    super.key,
    required this.group,
    this.onView,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: textTheme.headlineLarge
                      ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: AppTheme.softInk,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppTheme.softInk,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),

         
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.softInk),
              const SizedBox(width: 6),
              Text(
                '${group.childrenCount} '
                '${group.childrenCount == 1 ? 'niño' : 'niños'}',
                style: textTheme.bodyLarge?.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),

          .
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 16, color: AppTheme.softInk),
              const SizedBox(width: 6),
              Text(
                group.teacherLabel,
                style: textTheme.bodyLarge?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}