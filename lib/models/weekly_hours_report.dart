
class WeeklyHoursReport {
  final int year;
  final String month;
  final String weekLabel; 
  final int scheduledHours;
  final int completedHours;
  final bool hadPendingHoursFromPreviousWeeks;
  final String reason;

  const WeeklyHoursReport({
    required this.year,
    required this.month,
    required this.weekLabel,
    required this.scheduledHours,
    required this.completedHours,
    this.hadPendingHoursFromPreviousWeeks = false,
    this.reason = '',
  });

  
  int get hoursDifference => scheduledHours - completedHours;

  
  bool get hasUncompletedHours => hoursDifference > 0;

 
  WeeklyHoursReport copyWith({
    int? year,
    String? month,
    String? weekLabel,
    int? scheduledHours,
    int? completedHours,
    bool? hadPendingHoursFromPreviousWeeks,
    String? reason,
  }) {
    return WeeklyHoursReport(
      year: year ?? this.year,
      month: month ?? this.month,
      weekLabel: weekLabel ?? this.weekLabel,
      scheduledHours: scheduledHours ?? this.scheduledHours,
      completedHours: completedHours ?? this.completedHours,
      hadPendingHoursFromPreviousWeeks:
          hadPendingHoursFromPreviousWeeks ??
              this.hadPendingHoursFromPreviousWeeks,
      reason: reason ?? this.reason,
    );
  }

  @override
  String toString() {
    return 'WeeklyHoursReport(year: $year, month: $month, week: $weekLabel, '
        'scheduled: $scheduledHours, completed: $completedHours, '
        'pendingFromBefore: $hadPendingHoursFromPreviousWeeks, reason: $reason)';
  }
}
