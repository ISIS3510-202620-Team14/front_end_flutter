/** Type 2 BQ: how many days have passed since a student's last assessment in a subject, like UltimaEvaluacion in Kotlin. */
class LastAssessment {
  /** After this many days without an assessment the student is shown as overdue. */
  static const int limitDays = 30;

  /** Today's date in Colombia, the day the backend uses for assessments. */
  static DateTime todayInColombia([DateTime? now]) {
    final DateTime colombia = (now ?? DateTime.now()).toUtc().subtract(
      const Duration(hours: 5),
    );
    return DateTime.utc(colombia.year, colombia.month, colombia.day);
  }

  /** Days from the assessment date to [today]; null when there is no valid date. */
  static int? daysSince(String? isoDate, DateTime today) {
    if (isoDate == null || isoDate.trim().isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(isoDate.trim());
    if (parsed == null) return null;
    // A full timestamp is moved to Colombia time; a plain yyyy-MM-dd is already a day.
    final DateTime day = isoDate.trim().length > 10
        ? todayInColombia(parsed)
        : DateTime.utc(parsed.year, parsed.month, parsed.day);
    final int days = today.difference(day).inDays;
    return days < 0 ? 0 : days;
  }

  /** Never assessed or over the limit. */
  static bool isOverdue(int? days) {
    return days == null || days > limitDays;
  }

  /** How many of these dates are over the limit; students never assessed are not counted. */
  static int overdueCount(Iterable<String?> isoDates, DateTime today) {
    return isoDates.where((String? date) {
      final int? days = daysSince(date, today);
      return days != null && days > limitDays;
    }).length;
  }

  /** "Evaluado hoy", "Evaluado ayer" or "Última evaluación hace N días", as the Kotlin card says it. */
  static String label(int days) {
    if (days == 0) return 'Evaluado hoy';
    if (days == 1) return 'Evaluado ayer';
    return 'Última evaluación hace $days días';
  }
}
