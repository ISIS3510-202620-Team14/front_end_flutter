import 'package:flutter/material.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
part 'method_option.dart';
part 'recommended_badge.dart';

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

    final double? automaticConfidence;
    if (recommendation?.recommended == GroupingMethod.automatic) {
      automaticConfidence = recommendation?.confidence;
    } else {
      automaticConfidence = null;
    }
    final double? manualConfidence;
    if (recommendation?.recommended == GroupingMethod.manual) {
      manualConfidence = recommendation?.confidence;
    } else {
      manualConfidence = null;
    }
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
          isRecommended:
              recommendation?.hasEnoughData == true &&
              recommendation?.recommended == GroupingMethod.automatic,
          confidence: automaticConfidence,
          onTap: () {
            return onChanged(GroupingMethod.automatic);
          },
        ),
        const SizedBox(height: 8),
        _MethodOption(
          icon: Icons.pan_tool_outlined,
          title: 'Manual',
          subtitle: 'Tú eliges qué niños van en cada grupo',
          isSelected: selected == GroupingMethod.manual,
          isRecommended:
              recommendation?.hasEnoughData == true &&
              recommendation?.recommended == GroupingMethod.manual,
          confidence: manualConfidence,
          onTap: () {
            return onChanged(GroupingMethod.manual);
          },
        ),
      ],
    );
  }
}
