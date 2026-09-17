import 'package:flutter/material.dart';
import '../models/quick_action.dart';
import '../theme/app_theme.dart';

class QuickActionCard extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const QuickActionCard({super.key, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCircle = action.shape == QuickActionShape.circle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(10),
                border: Border.all(color: AppTheme.red, width: 1.5),
              ),
              child: Icon(action.icon, color: AppTheme.red, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.softInk),
          ],
        ),
      ),
    );
  }
}
