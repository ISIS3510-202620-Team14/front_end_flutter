part 'heatmap_week.dart';

class HoursHistory {
  final double totalCompletedHours;
  final double totalScheduledHours;
  final List<HeatmapWeek> weeks;

  const HoursHistory({
    required this.totalCompletedHours,
    required this.totalScheduledHours,
    required this.weeks,
  });
}
