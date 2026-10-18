import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AttendanceDraftStore {
  AttendanceDraftStore({required this.userId});
  final String userId;
  Future<void> _writes = Future<void>.value();

  String get _key {
    return 'enad_attendance_v1_$userId';
  }

  Future<Map<String, Map<String, bool>>> load() async {
    await _writes;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(_key);
    if (stored == null) {
      return {};
    }
    final Map<String, dynamic> dates =
        jsonDecode(stored) as Map<String, dynamic>;
    final Map<String, Map<String, bool>> result = {};
    for (final MapEntry<String, dynamic> date in dates.entries) {
      result[date.key] = Map<String, bool>.from(date.value as Map);
    }
    return result;
  }

  Future<void> save(Map<String, Map<String, bool>> drafts) {
    final String snapshot = jsonEncode(drafts);
    final Future<void> operation = _writes.then((_) async {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final bool saved = await preferences.setString(_key, snapshot);
      if (!saved) {
        throw StateError('No se pudo guardar el borrador en este dispositivo.');
      }
    });
    _writes = operation.catchError((Object error) {});
    return operation;
  }
}
