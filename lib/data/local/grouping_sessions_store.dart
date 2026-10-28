import 'dart:convert';

import 'package:front_end_flutter/domain/model/grouping_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/** Keeps on the phone the grouping sessions that the backend has not confirmed yet, one list per teacher. */
class GroupingSessionsStore {
  GroupingSessionsStore({required this.userId});
  final String userId;
  Future<void> _writes = Future<void>.value();

  // Las rechazadas se conservan para diagnóstico, pero la lista no crece sin límite.
  static const int maxKept = 100;

  String get _key {
    return 'enad_grouping_sessions_v1_$userId';
  }

  Future<List<GroupingSession>> read() async {
    await _writes;
    return _readNow();
  }

  Future<List<GroupingSession>> _readNow() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? stored = preferences.getString(_key);
    if (stored == null) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
    return [
      for (final dynamic item in decoded)
        GroupingSession.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> _writeNow(List<GroupingSession> sessions) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<GroupingSession> kept = sessions.length > maxKept
        ? sessions.sublist(sessions.length - maxKept)
        : sessions;
    final bool saved = await preferences.setString(
      _key,
      jsonEncode([for (final GroupingSession session in kept) session.toJson()]),
    );
    if (!saved) {
      throw StateError('No pudimos guardar la sesión en este dispositivo.');
    }
  }

  // Ejecuta los cambios uno detrás de otro para no pisar escrituras.
  Future<void> _serialized(Future<void> Function() change) {
    final Future<void> operation = _writes.then((_) {
      return change();
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> add(GroupingSession session) {
    return _serialized(() async {
      final List<GroupingSession> sessions = await _readNow();
      await _writeNow([...sessions, session]);
    });
  }

  /** Replaces the stored session with the same id. */
  Future<void> update(GroupingSession session) {
    return _serialized(() async {
      final List<GroupingSession> sessions = await _readNow();
      await _writeNow([
        for (final GroupingSession item in sessions)
          item.clientId == session.clientId ? session : item,
      ]);
    });
  }

  Future<void> remove(String clientId) {
    return _serialized(() async {
      final List<GroupingSession> sessions = await _readNow();
      await _writeNow([
        for (final GroupingSession item in sessions)
          if (item.clientId != clientId) item,
      ]);
    });
  }

  Future<List<GroupingSession>> pending() async {
    final List<GroupingSession> sessions = await read();
    return sessions.where((GroupingSession session) {
      return !session.failed;
    }).toList();
  }
}
