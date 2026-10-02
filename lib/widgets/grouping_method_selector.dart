import 'package:flutter/material.dart';
import '../services/grouping_analytics_service.dart';
import '../theme/app_theme.dart';

class GroupingMethodSelector extends StatelessWidget {
  final GroupingMethod selected;
  final GroupingRecommendation? recommendation;
  final ValueChanged<GroupingMethod> onChanged;

  const GroupingMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de agrupación',
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        _MethodOption(
          icon: Icons.auto_awesome,
          title: 'Automática',
          subtitle: 'La app distribuye los niños según su nivel',
          isSelected: selected == GroupingMethod.automatic,
          isRecommended: recommendation?.hasEnoughData == true &&
              recommendation?.recommended == GroupingMethod.automatic,
          confidence: recommendation?.recommended == GroupingMethod.automatic
              ? recommendation?.confidence
              : null,
          onTap: () => onChanged(GroupingMethod.automatic),
        ),
        const SizedBox(height: 8),
        _MethodOption(
          icon: Icons.pan_tool_outlined,
          title: 'Manual',
          subtitle: 'Tú eliges qué niños van en cada grupo',
          isSelected: selected == GroupingMethod.manual,
          isRecommended: recommendation?.hasEnoughData == true &&
              recommendation?.recommended == GroupingMethod.manual,
          confidence: recommendation?.recommended == GroupingMethod.manual
              ? recommendation?.confidence
              : null,
          onTap: () => onChanged(GroupingMethod.manual),
        ),
      ],
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isRecommended;
  final double? confidence;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = isSelected ? AppTheme.green : AppTheme.line;
    final bgColor = isSelected ? AppTheme.greenBackground : AppTheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24,
                color: isSelected ? AppTheme.green : AppTheme.softInk),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        _RecommendedBadge(confidence: confidence),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: isSelected ? AppTheme.green : AppTheme.line,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  final double? confidence;

  const _RecommendedBadge({this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = confidence != null ? '${(confidence! * 100).round()}%' : '';
    final label = pct.isNotEmpty ? 'Recomendado · $pct' : 'Recomendado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              size: 12, color: AppTheme.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.green,
            ),
          ),
        ],
      ),
    );
  }
}
