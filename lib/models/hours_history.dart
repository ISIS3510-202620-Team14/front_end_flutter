
class HeatmapWeek {
  final String label; 
  final List<double> dailyHours; 

  const HeatmapWeek({
    required this.label,
    required this.dailyHours,
  }) : assert(
          dailyHours.length == 5,
          'Cada semana debe traer horas para exactamente 5 días (L-V)',
        );
}


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
