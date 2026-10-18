import 'package:flutter/foundation.dart';

import '../models/hours_history.dart';
import '../models/weekly_hours_report.dart';


class HorasViewModel extends ChangeNotifier {
  HorasViewModel({
    WeeklyHoursReport? initialReport,
    HoursHistory? initialHistory,
  })  : _report = initialReport ?? _defaultReport(),
        _history = initialHistory ?? _defaultHistory();

  WeeklyHoursReport _report;
  final HoursHistory _history;

  WeeklyHoursReport get report => _report;
  HoursHistory get history => _history;


  static const List<int> yearOptions = [2024, 2025, 2026];
  static const List<String> monthOptions = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static const List<String> weekOptions = [
    'Semana 1 · 1–7',
    'Semana 2 · 8–14',
    'Semana 3 · 15–21',
    'Semana 4 · 22–28',
  ];

  void selectYear(int year) {
    _report = _report.copyWith(year: year);
    notifyListeners();
  }

  void selectMonth(String month) {
    _report = _report.copyWith(month: month);
    notifyListeners();
  }

  void selectWeek(String weekLabel) {
    _report = _report.copyWith(weekLabel: weekLabel);
    notifyListeners();
  }


  void updateScheduledHours(String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return;
    _report = _report.copyWith(scheduledHours: parsed);
    notifyListeners();
  }

  void updateCompletedHours(String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return;
    _report = _report.copyWith(completedHours: parsed);
    notifyListeners();
  }

  void setHadPendingHoursFromPreviousWeeks(bool value) {
    _report = _report.copyWith(hadPendingHoursFromPreviousWeeks: value);
    notifyListeners();
  }

  void updateReason(String value) {
    _report = _report.copyWith(reason: value);
    notifyListeners();
  }

  void submitReport() {
    // TODO: Conect with backend once it's ready. For now, just print the report to the console.
    debugPrint('Reporte enviado: $_report');
  }

  static WeeklyHoursReport _defaultReport() {
    return const WeeklyHoursReport(
      year: 2025,
      month: 'Septiembre',
      weekLabel: 'Semana 1 · 1–7',
      scheduledHours: 6,
      completedHours: 5,
      hadPendingHoursFromPreviousWeeks: true,
      reason: '',
    );
  }

  static HoursHistory _defaultHistory() {

    return HoursHistory(
      totalCompletedHours: 59.9,
      totalScheduledHours: 68.5,
      weeks: List.generate(12, (weekIndex) {
        return HeatmapWeek(
          label: 'S${weekIndex + 1}',
          dailyHours: List.generate(5, (dayIndex) {
            final seed = (weekIndex * 5 + dayIndex) % 7;
            return seed.toDouble();
          }),
        );
      }),
    );
  }
}
