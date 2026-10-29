/** Where a value came from: suggested by the app or chosen/typed by the teacher. */
class ValueOrigin {
  static const String suggested = 'suggested';
  static const String manual = 'manual';
}

/** Weekly schedule of a group as the backend sends it: [{day: 1..7, plannedHours}]. */
class WeeklySchedule {
  /** Planned hours for that ISO weekday (Monday = 1), or null when the group has no class. */
  static double? hoursOn(Object? schedule, int weekday) {
    if (schedule is! List) return null;
    for (final item in schedule) {
      if (item is Map &&
          item['day'] == weekday &&
          item['plannedHours'] is num) {
        return (item['plannedHours'] as num).toDouble();
      }
    }
    return null;
  }
}

/** One group of the teacher seen from a given day, with the name of its school. */
class GroupOfDay {
  const GroupOfDay({
    required this.id,
    required this.name,
    required this.subject,
    required this.schoolId,
    this.school,
    this.plannedHours,
  });
  final String id;
  final String name;
  final String subject;
  final String schoolId;
  final String? school;
  final double? plannedHours;
}

/** Hours suggested for a day. Never more than the time spent at the school. */
class HoursSuggestion {
  const HoursSuggestion({required this.hours, required this.stayHours});
  final double hours;
  final double stayHours;

  /**
   * Being at the school is not teaching: hours are suggested only with presence and attendance
   * that day, rounded down to half hours and capped by the planned hours.
   */
  static HoursSuggestion? from({
    required double planned,
    required double? stayHours,
    required int attendanceMarks,
  }) {
    if (planned <= 0 || stayHours == null || attendanceMarks == 0) return null;
    final double capped = stayHours < planned ? stayHours : planned;
    final double hours = (capped * 2).floor() / 2;
    if (hours <= 0) return null;
    return HoursSuggestion(hours: hours, stayHours: stayHours);
  }
}

/** What the teacher has done today. Everything comes from the phone, so it works offline. */
class DaySummary {
  const DaySummary({
    required this.group,
    required this.plannedHours,
    required this.attendanceMarks,
    required this.hoursReported,
    required this.stayHours,
    this.scheduleDownloaded = true,
  });
  final String? group;
  final double plannedHours;
  final int attendanceMarks;
  final bool hoursReported;
  // From the first to the last time the teacher was seen at the school; null = no data.
  final double? stayHours;
  // false = the schedule was never downloaded (first use offline): we cannot tell if there is class.
  final bool scheduleDownloaded;
}

/** Next step the Hoy card proposes to the teacher. */
enum SuggestedAction { attendance, evaluation, hours, activities, none }

/** Where the teacher's day is. It changes with the time, the schedule and what was already recorded. */
enum DayMoment {
  noSchedule(SuggestedAction.none),
  noClass(SuggestedAction.activities),
  start(SuggestedAction.attendance),
  inClass(SuggestedAction.evaluation),
  wrapUp(SuggestedAction.hours),
  missedAttendance(SuggestedAction.attendance),
  done(SuggestedAction.none);

  const DayMoment(this.action);
  final SuggestedAction action;

  /** From this hour the day is over even without data from the school. */
  static const int endOfDayHour = 17;

  /**
   * Context-aware, same rules as MomentoDelDia in Kotlin:
   * - Without a downloaded schedule we cannot know if there is class.
   * - No planned hours today: no class.
   * - No attendance: at the start ask for it; at the end of the day warn that it was missed.
   * - Attendance but no hours: in class until the planned time at the school passes
   *   (or the day ends), then ask for the hours.
   * - Attendance and hours: the day is done.
   */
  static DayMoment of(DaySummary summary, DateTime now) {
    final bool dayOver = now.hour >= endOfDayHour;
    if (summary.attendanceMarks > 0 && summary.hoursReported) return done;
    if (!summary.scheduleDownloaded) return noSchedule;
    if (summary.plannedHours <= 0) {
      return summary.hoursReported ? done : noClass;
    }
    if (summary.attendanceMarks == 0) {
      return dayOver ? missedAttendance : start;
    }
    if (dayOver) return wrapUp;
    if ((summary.stayHours ?? 0) >= summary.plannedHours) return wrapUp;
    return inClass;
  }
}

/** Formats hours like 1.5 → "1,5" and 2.0 → "2". */
String formatHours(double hours) {
  final String text = hours == hours.roundToDouble()
      ? hours.toStringAsFixed(0)
      : hours.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}
