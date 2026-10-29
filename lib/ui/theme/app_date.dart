class AppDate {
  static String label(DateTime date) {
    const List<String> weekdays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /** Returns the Monday of the week in Colombia time as yyyy-MM-dd, the key the backend groups by. */
  static String mondayOfWeek(DateTime moment) {
    final DateTime colombia = moment.toUtc().subtract(const Duration(hours: 5));
    final DateTime monday = DateTime.utc(
      colombia.year,
      colombia.month,
      colombia.day,
    ).subtract(Duration(days: colombia.weekday - 1));
    return monday.toIso8601String().substring(0, 10);
  }
}
