import '../sync/offline_runtime.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// # local storage: account-scoped drafts and bases; Kotlin reference: Santiago Quiroz, ControlSincronizacion.
/** Persists account-scoped attendance drafts. */
class AttendanceDraftStore {
  /** Selects the account storage key. */
  AttendanceDraftStore({required this.userId});
  final String userId;
  Future<String?> _readRaw(SharedPreferences prefs) async {
    final runtime = OfflineRuntime.current;
    if (runtime?.uid == userId) {
      return runtime!.db.meta(userId, 'attendanceDrafts');
    }
    return prefs.getString(_key);
  }

  Future<void> _writes = Future<void>.value();

  String get _key {
    return 'enad_attendance_v1_$userId';
  }

  Future<Map<String, Map<String, bool>>> load() async {
    await _writes;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = await _readRaw(preferences);
    if (stored == null) {
      return {};
    }
    final Map<String, dynamic> decoded =
        jsonDecode(stored) as Map<String, dynamic>;
    final Map<String, dynamic> dates = decoded['version'] == 2
        ? Map<String, dynamic>.from(decoded['drafts'] as Map)
        : decoded;
    final Map<String, Map<String, bool>> result = {};
    for (final MapEntry<String, dynamic> date in dates.entries) {
      result[date.key] = Map<String, bool>.from(date.value as Map);
    }
    return result;
  }

  Future<Map<String, Map<String, String>>> loadMetadata(String field) async {
    await _writes;
    final prefs = await SharedPreferences.getInstance();
    final raw = await _readRaw(prefs);
    if (raw == null) {
      return {};
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != 2) {
      return {};
    }
    final values = data[field] as Map? ?? {};
    return values.map((date, entries) {
      return MapEntry(date as String, Map<String, String>.from(entries as Map));
    });
  }

  Future<void> saveNotice(String notice) async {
    final runtime = OfflineRuntime.current;
    if (runtime?.uid == userId) {
      await runtime!.db.setMeta(userId, 'attendanceNotice', notice);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('${_key}_notice', notice)) {
      throw StateError('No se pudo guardar el aviso de sincronización.');
    }
  }

  Future<String?> takeNotice() async {
    final runtime = OfflineRuntime.current;
    if (runtime?.uid == userId) {
      final notice = await runtime!.db.meta(userId, 'attendanceNotice');
      await runtime.db.setMeta(userId, 'attendanceNotice', '');
      return notice == '' ? null : notice;
    }
    final prefs = await SharedPreferences.getInstance();
    final notice = prefs.getString('${_key}_notice');
    if (notice != null) {
      await prefs.remove('${_key}_notice');
    }
    return notice;
  }

  /** Stores marks and their original network context together. */
  Future<void> save(
    Map<String, Map<String, bool>> drafts, {
    Map<String, Map<String, String>> bases = const {},
    Map<String, Map<String, String>> failures = const {},
    Map<String, Map<String, String>> connectivity = const {},
  }) {
    final String snapshot = jsonEncode({
      'version': 2,
      'drafts': drafts,
      'bases': bases,
      'failures': failures,
      'connectivity': connectivity,
    });
    final Future<void> operation = _writes.then((_) async {
      final runtime = OfflineRuntime.current;
      if (runtime?.uid == userId) {
        await runtime!.db.setMeta(userId, 'attendanceDrafts', snapshot);
        return;
      }
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
