import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HoursStore {
  HoursStore(this.userId);
  final String userId;
  static final Map<String, Future<void>> _operations = {};

  static String reportKey(String date, Object? schoolId) {
    return jsonEncode([date, schoolId]);
  }

  Future<Map<String, dynamic>> update(
    void Function(Map<String, dynamic>) change,
  ) {
    final Future<void> previous = _operations[userId] ?? Future<void>.value();
    final Future<Map<String, dynamic>> operation = previous.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      final String key = 'enad_hours_v1_$userId';
      final String? raw = preferences.getString(key);
      final Map<String, dynamic> reports;
      if (raw == null) {
        reports = {};
      } else {
        reports = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
      for (final entry in reports.entries.toList()) {
        final value = entry.value;
        if (value is Map && entry.key == value['date']) {
          final migratedKey = reportKey(
            value['date'] as String,
            value['schoolId'],
          );
          reports.putIfAbsent(migratedKey, () {
            return value;
          });
          reports[entry.key] = null;
        }
      }
      change(reports);
      if (!await preferences.setString(key, jsonEncode(reports))) {
        throw StateError('No pudimos guardar las horas en este dispositivo.');
      }
      return reports;
    });
    _operations[userId] = operation
        .then<void>((_) {})
        .catchError((Object _) {});
    return operation;
  }

  Future<Map<String, dynamic>> read() {
    return update((Map<String, dynamic> reports) {});
  }
}
