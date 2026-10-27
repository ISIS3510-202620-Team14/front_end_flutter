import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/quick_action.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

class QuickActionCard extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const QuickActionCard({super.key, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.panelRadius),
          side: const BorderSide(color: AppTheme.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  ),
                  child: Icon(action.icon, color: AppTheme.red, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: AppTheme.softInk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
