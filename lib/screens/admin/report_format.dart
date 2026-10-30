// lib/screens/admin/report_format.dart
import 'package:front_end_flutter/data/repository/attendance_conflicts.dart';

const _months = [
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

/** Percentage in the same format as the Kotlin portal writes it: "33 %", "33,3 %" or "—". */
String adminPercentage(num? value) {
  if (value == null) return '—';
  if (value % 1 == 0) return '${value.toInt()} %';
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/** Hours in the same format as the Kotlin portal writes them: "40 h" or "40,5 h". */
String adminHours(num hours) {
  if (hours % 1 == 0) return '${hours.toInt()} h';
  return '${hours.toStringAsFixed(1).replaceAll('.', ',')} h';
}

/** Name of a subject key for the administrator; null stays null. */
String? subjectLabel(String? subject) {
  switch (subject) {
    case null:
      return null;
    case 'lectura':
      return 'Lectura';
    case 'matematicas':
      return 'Matemáticas';
    default:
      return '${subject[0].toUpperCase()}${subject.substring(1)}';
  }
}

/** "Semana del 5 de enero" from the Monday of the week (yyyy-MM-dd). */
String weekLabel(String monday) {
  try {
    final day = DateTime.parse(monday);
    return 'Semana del ${day.day} de ${_months[day.month - 1]}';
  } on FormatException {
    return monday;
  }
}

/** Monday of the current week in Colombia, as the backend calculates it. */
String currentMonday() {
  return AttendanceConflicts.weekOf(
    DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .toIso8601String()
        .substring(0, 10),
  );
}
