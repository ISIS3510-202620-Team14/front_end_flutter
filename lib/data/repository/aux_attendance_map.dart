import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/ui/theme/app_date.dart';

/** Helpers of AttendanceMapRepository.
 *
 *   1. Dates
 *   2. Storage keys
 *   3. Responses → one row per school
 */

// =================== 1. DATES ===================

List<String> thisWeekDays() {
  final DateTime monday = DateTime.parse(AppDate.mondayOfWeek(DateTime.now()));
  final List<String> days = [];
  for (int i = 0; i < 5; i++) {
    days.add(_isoDate(monday.add(Duration(days: i))));
  }
  return days;
}
List<String> askedDays(List<String> thisWeek) {
  final String today = _colombiaToday();
  final List<String> asked = [];

  for (final String day in thisWeek) {
    final DateTime lastWeekDay = DateTime.parse(day)
        .subtract(const Duration(days: 7));
    asked.add(_isoDate(lastWeekDay));
  }

  for (final String day in thisWeek) {
    if (day.compareTo(today) <= 0) {
      asked.add(day);
    }
  }
  return asked;
}

String _colombiaToday() {
  return _isoDate(DateTime.now().toUtc().subtract(const Duration(hours: 5)));
}

String _isoDate(DateTime date) {
  return date.toIso8601String().substring(0, 10);
}

// =================== 2. STORAGE KEYS ===================


const String attendanceRamKey = 'attendance_map';

String attendancePhoneKey() {
  return 'attendance_map_${FirebaseAuth.instance.currentUser?.uid}';
}

// =================== 3. RESPONSES → ONE ROW PER SCHOOL ===================

List<Map<String, dynamic>> groupBySchool(
  List schools,
  int daysPerSchool,
  List<Map<String, dynamic>> responses,
) {
  final List<Map<String, dynamic>> rows = [];
  int next = 0;

  for (final school in schools) {
    final List<List> lists = [];
    for (int i = 0; i < daysPerSchool; i++) {
      lists.add(responses[next]['students'] as List);
      next++;
    }
    final List<List> lastWeek = lists.sublist(0, 5);
    final List<List> thisWeek = lists.sublist(5);
    while (thisWeek.length < 5) {
      thisWeek.add(const []);
    }

    rows.add({
      'name': school['name'],
      'lastWeek': lastWeek,
      'thisWeek': thisWeek,
    });
  }
  return rows;
}
