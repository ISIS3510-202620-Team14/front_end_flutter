part of 'hours_heatmap.dart';

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.hours, required this.maxHours});

  final double hours;
  final double maxHours;

  @override
  Widget build(BuildContext context) {
    final double intensity;
    if (maxHours == 0) {
      intensity = 0.0;
    } else {
      intensity = (hours / maxHours).clamp(0.0, 1.0);
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: 0.12 + intensity * 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
