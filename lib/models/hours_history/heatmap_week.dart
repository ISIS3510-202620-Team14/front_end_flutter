part of 'hours_history.dart';

class HeatmapWeek {
  final String label;
  final List<double> dailyHours;

  const HeatmapWeek({required this.label, required this.dailyHours})
    : assert(
        dailyHours.length == 5,
        'Cada semana debe traer horas para exactamente 5 días (L-V)',
      );
}
