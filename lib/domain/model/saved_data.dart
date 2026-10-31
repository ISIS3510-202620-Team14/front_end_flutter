// lib/domain/model/saved_data.dart
// # local storage strategy: when the saved list was downloaded, matching Kotlins DatosGuardados.

/** Says when the data on the phone was saved, same wording as DatosGuardados in Kotlin. */
class SavedData {
  static const List<String> _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  // UTC-5 all year.
  static const Duration _colombia = Duration(hours: -5);

  static String when(DateTime savedAt, [DateTime? now]) {
    final DateTime saved = savedAt.toUtc().add(_colombia);
    final DateTime today = (now ?? DateTime.now()).toUtc().add(_colombia);
    final int days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(saved.year, saved.month, saved.day)).inDays;
    final String day;
    if (days == 0) {
      day = 'hoy';
    } else if (days == 1) {
      day = 'ayer';
    } else {
      day = 'el ${saved.day} de ${_months[saved.month - 1]}';
    }
    final int hour = saved.hour % 12 == 0 ? 12 : saved.hour % 12;
    final String minutes = saved.minute.toString().padLeft(2, '0');
    final String period = saved.hour < 12 ? 'a. m.' : 'p. m.';
    return '$day ${hour == 1 ? 'a la' : 'a las'} $hour:$minutes $period';
  }
}
