import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class PendingChildrenNotice extends StatelessWidget {
  final int count;

  const PendingChildrenNotice({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final String pendingLabel;
    if (count == 1) {
      pendingLabel = '$count estudiante todavía sin grupo.';
    } else {
      pendingLabel = '$count estudiantes todavía sin grupo.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppTheme.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pendingLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
