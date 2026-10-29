import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/**
 * Keeps on the phone the context of the teacher's days: the first and last time they were seen
 * at each school, and the group they confirmed. Only times are stored, never the position.
 */
class DayContextStore {
  DayContextStore({required this.userId});
  final String userId;
  Future<void> _writes = Future<void>.value();

  // Se guardan dos semanas para que la sugerencia de horas sirva en días anteriores.
  static const int keptDays = 14;

  String get _key {
    return 'enad_day_context_v1_$userId';
  }

  Future<Map<String, dynamic>> _readNow() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(_key);
    if (stored == null) {
      return {
        'presence': <String, dynamic>{},
        'confirmed': <String, dynamic>{},
      };
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      jsonDecode(stored) as Map,
    );
    data['presence'] = Map<String, dynamic>.from(
      data['presence'] as Map? ?? {},
    );
    data['confirmed'] = Map<String, dynamic>.from(
      data['confirmed'] as Map? ?? {},
    );
    return data;
  }

  Future<void> _writeNow(Map<String, dynamic> data, String today) async {
    final DateTime limit = DateTime.parse(today)
        .subtract(const Duration(days: keptDays));
    bool recent(String key) {
      final DateTime? day = DateTime.tryParse(key.split('|').first);
      return day == null || !day.isBefore(limit);
    }

    for (final String section in ['presence', 'confirmed']) {
      (data[section] as Map<String, dynamic>).removeWhere((key, _) {
        return !recent(key);
      });
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(data));
  }

  // Ejecuta los cambios uno detrás de otro para no pisar escrituras.
  Future<T> _serialized<T>(Future<T> Function() change) {
    final Future<T> operation = _writes.then((_) {
      return change();
    });
    _writes = operation.then<void>((_) {}).catchError((Object _) {});
    return operation;
  }

  /** Records that the teacher was at that school now, keeping the first time of the day. */
  Future<void> savePresence(String date, String schoolId, DateTime now) {
    return _serialized<void>(() async {
      final Map<String, dynamic> data = await _readNow();
      final Map<String, dynamic> presence =
          data['presence'] as Map<String, dynamic>;
      final String key = '$date|$schoolId';
      final List<dynamic>? previous = presence[key] as List<dynamic>?;
      final int millis = now.millisecondsSinceEpoch;
      presence[key] = [previous?.first ?? millis, millis];
      await _writeNow(data, date);
    });
  }

  /** Longest stay of that day at one school, in hours; null when the teacher was not seen there. */
  Future<double?> stayHours(String date, {String? schoolId}) async {
    await _writes;
    final Map<String, dynamic> data = await _readNow();
    double? longest;
    (data['presence'] as Map<String, dynamic>).forEach((key, value) {
      final List<String> parts = key.split('|');
      if (parts.first != date) return;
      if (schoolId != null && parts.last != schoolId) return;
      final List<dynamic> times = value as List<dynamic>;
      final double hours =
          ((times.last as int) - (times.first as int)) / 3600000.0;
      if (longest == null || hours > longest!) longest = hours;
    });
    return longest;
  }

  Future<void> confirm(String date, String groupId, String origin) {
    return _serialized<void>(() async {
      final Map<String, dynamic> data = await _readNow();
      (data['confirmed'] as Map<String, dynamic>)[date] = {
        'groupId': groupId,
        'origin': origin,
        'confirmedAt': DateTime.now().toUtc().toIso8601String(),
      };
      await _writeNow(data, date);
    });
  }

  /** Group confirmed that day, if any. */
  Future<String?> confirmedGroup(String date) async {
    await _writes;
    final Map<String, dynamic> data = await _readNow();
    final Map? confirmed =
        (data['confirmed'] as Map<String, dynamic>)[date] as Map?;
    return confirmed?['groupId'] as String?;
  }
}
