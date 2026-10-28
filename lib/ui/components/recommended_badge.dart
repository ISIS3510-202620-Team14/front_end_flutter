part of 'grouping_method_selector.dart';

class _RecommendedBadge extends StatelessWidget {
  final double? confidence;

  const _RecommendedBadge({this.confidence});

  @override
  Widget build(BuildContext context) {
    final String pct;
    if (confidence != null) {
      pct = '${(confidence! * 100).round()}%';
    } else {
      pct = '';
    }
    final String label;
    if (pct.isNotEmpty) {
      label = 'Recomendado · $pct';
    } else {
      label = 'Recomendado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tips_and_updates_outlined,
            size: 12,
            color: AppTheme.green,
          ),
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
