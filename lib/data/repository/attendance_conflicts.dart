import 'dart:convert';

import '../../domain/model/attendance_conflict.dart';
import '../local/offline_database.dart';

/** Stores attendance outcomes for one account. */
class AttendanceConflicts {
  /** Uses the account's existing local database. */
  AttendanceConflicts(this.db, this.uid);
  final OfflineDatabase db;
  final String uid;
  static const _listKey = 'attendanceReplaced';

  /** Returns Monday for a school date. */
  static String weekOf(String date) {
    final day = DateTime.parse(date);
    return day
        .subtract(Duration(days: day.weekday - 1))
        .toIso8601String()
        .substring(0, 10);
  }

  /** Records a confirmed response in the caller's transaction. */
  Future<void> recordOutcome(
    Map<String, dynamic> op,
    Map<String, dynamic> result,
  ) async {
    if (op['action'] != 'attendance' ||
        !['confirmed', 'conflict'].contains(result['state'])) {
      return;
    }
    final id = op['id'] as String;
    if (await db.meta(uid, 'attendanceOutcome:$id') != null) return;
    final parts = (op['key'] as String).split('/');
    if (parts.length != 4 || parts[2] != 'attendance') return;
    final contextText = await db.meta(uid, 'attendanceContext:$id');
    final context = contextText == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(contextText) as Map);
    final studentRows = await db.rows(
      'SELECT data FROM records WHERE uid=? AND key=?',
      [uid, 'students/${parts[1]}'],
    );
    final student = studentRows.isEmpty || studentRows.first['data'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            jsonDecode(studentRows.first['data'] as String) as Map,
          );
    final body = Map<String, dynamic>.from(
      jsonDecode(op['body'] as String) as Map,
    );
    Map<String, dynamic>? server;
    for (final raw in result['records'] as List) {
      if (raw is Map && raw['key'] == op['key']) {
        server = raw['data'] == null
            ? null
            : Map<String, dynamic>.from(raw['data'] as Map);
        break;
      }
    }
    final sent = _status(body);
    final kept = _status(server);
    final conflict = result['state'] == 'conflict';
    final schoolId =
        (context['schoolId'] ?? student['schoolId'] ?? '') as String;
    if (conflict && sent != kept) {
      final entries = await _all();
      entries.removeWhere((item) {
        return item.studentId == parts[1] && item.date == parts[3];
      });
      entries.add(
        AttendanceConflict(
          operationId: id,
          studentId: parts[1],
          name:
              (context['name'] ?? student['fullName'] ?? 'Estudiante')
                  as String,
          schoolId: schoolId,
          date: parts[3],
          sent: sent,
          kept: kept,
        ),
      );
      await _write(
        entries.length > 50 ? entries.sublist(entries.length - 50) : entries,
      );
    }
    if (schoolId.isNotEmpty) {
      final eventId = 'attendance-sync-$id';
      final event = {
        'name': 'attendance_sync',
        'teacherId': uid,
        'platform': 'flutter',
        'schoolId': schoolId,
        'week': weekOf(parts[3]),
        'connectivity': context['connectivity'] ?? 'unknown',
        'sent': conflict ? 0 : 1,
        'conflicts': conflict ? 1 : 0,
      };
      await db.customStatement(
        'INSERT OR IGNORE INTO operations(uid,id,key,action,body,base,dependencies,state,created_at) VALUES(?,?,?,?,?,?,?,?,?)',
        [
          uid,
          eventId,
          'events/$eventId',
          'create',
          jsonEncode(event),
          null,
          '[]',
          'pending',
          DateTime.now().toUtc().toIso8601String(),
        ],
      );
    }
    await db.setMeta(uid, 'attendanceOutcome:$id', result['state'] as String);
  }

  /** Reads unreviewed marks for the selected week. */
  Future<List<AttendanceConflict>> pending(
    String date, {
    String? schoolId,
  }) async {
    final week = weekOf(date);
    final entries = await _all();
    // # micro opt
    return entries
        .where((item) {
          return !item.reviewed &&
              weekOf(item.date) == week &&
              (schoolId == null || item.schoolId == schoolId);
        })
        .toList(growable: false);
  }

  /** Acknowledges one conflict without changing attendance. */
  Future<void> review(String operationId) async {
    await db.transaction(() async {
      final entries = await _all();
      await db.setMeta(
        uid,
        _listKey,
        jsonEncode(
          entries.map((item) {
            final data = item.toJson();
            if (item.operationId == operationId) data['reviewed'] = true;
            return data;
          }).toList(),
        ),
      );
    });
  }

  /** Reads stored entries. */
  Future<List<AttendanceConflict>> _all() async {
    final raw = await db.meta(uid, _listKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((value) {
      return AttendanceConflict.fromJson(
        Map<String, dynamic>.from(value as Map),
      );
    }).toList();
  }

  /** Saves the bounded review list. */
  Future<void> _write(List<AttendanceConflict> values) async {
    await db.setMeta(
      uid,
      _listKey,
      jsonEncode(
        values.map((item) {
          return item.toJson();
        }).toList(),
      ),
    );
  }

  /** Normalizes server and client attendance values. */
  static String _status(Map<String, dynamic>? data) {
    if (data == null || data['status'] == 'sin_registro') return 'sin_registro';
    if (data['status'] == 'vino' ||
        data['status'] == 'present' ||
        data['present'] == true) {
      return 'vino';
    }
    if (data['status'] == 'no_vino' ||
        data['status'] == 'absent' ||
        data['present'] == false) {
      return 'no_vino';
    }
    return 'sin_registro';
  }
}
