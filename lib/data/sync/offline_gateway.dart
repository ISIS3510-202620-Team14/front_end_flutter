import '../mapper/student_api_adapter.dart';

import 'package:uuid/uuid.dart';

import '../remote/api_client.dart';
import 'offline_runtime.dart';
import 'offline_projection.dart';

class OfflineGateway {
  OfflineGateway(this.runtime);
  final OfflineRuntime runtime;
  static bool supports(String path) {
    return [
      'students',
      'groups',
      'workedHours',
      'activities',
      'plans',
      'profile',
      'registerSchools',
      'analytics',
      'events',
    ].contains(path.split('/').first);
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path,
    Map<String, dynamic> body,
    Map<String, String> query,
  ) async {
    if (!runtime.ownsSession) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    final parts = path.split('/');
    if (method == 'GET') return _read(path, query);
    if (path == 'analytics/grouping-events' || path == 'events') {
      final key =
          '${path == 'events' ? 'events' : 'groupingEvents'}/${const Uuid().v4()}';
      await runtime.enqueue(key, 'create', body);
      return {'syncState': 'pending'};
    }
    if (path == 'students/import') {
      final created = <Map<String, dynamic>>[];
      final skipped = <String>[];
      for (final item in body['students'] as List) {
        final rows = (await _read('students', {}))['students'] as List;
        if (rows.any((row) {
          return row['schoolId'] == body['schoolId'] &&
              row['code'] == item['code'];
        })) {
          skipped.add(item['code'] as String);
          continue;
        }
        final student = await request('POST', 'students', {
          ...Map<String, dynamic>.from(item as Map),
          'schoolId': body['schoolId'],
        }, {});
        created.add({'id': student['id'], 'code': student['code']});
      }
      return {'created': created, 'skipped': skipped, 'syncState': 'pending'};
    }
    String key = path;
    String action = method == 'POST'
        ? 'create'
        : method == 'DELETE'
        ? 'delete'
        : 'update';
    final values = Map<String, dynamic>.from(body);
    final useExpected = values.containsKey('_baseVersion');
    final expected = values.remove('_baseVersion') as String?;
    final references = <String>[];
    if (parts.first == 'workedHours') {
      key = 'hours/${body['schoolId']}/${parts[1]}';
      action = 'save';
      values['date'] = parts[1];
    } else if (path == 'profile') {
      action = 'update';
    } else if (path == 'plans' || path == 'students' || path == 'groups') {
      final id =
          body['clientId'] as String? ??
          body['activityId'] as String? ??
          const Uuid().v4();
      key = '$path/$id';
      if (path == 'students' &&
          body['provisional'] == true &&
          body['code'] == null) {
        values['code'] = 'PROV-${id.substring(0, 12)}';
      }
      if (path == 'groups') values['teacherId'] ??= runtime.uid;
    } else if (parts.first == 'students' &&
        parts.length == 3 &&
        parts[2] == 'attendance') {
      key = 'students/${parts[1]}/attendance/${body['date']}';
      action = 'attendance';
      references.add('students/${parts[1]}');
    } else if (parts.first == 'students' &&
        parts.length == 3 &&
        parts[2] == 'evaluations') {
      key = 'students/${parts[1]}';
      action = 'evaluate';
      values['date'] ??= DateTime.now().toUtc().toIso8601String();
    } else if (parts.first == 'groups' &&
        parts.length >= 3 &&
        parts[2] == 'students') {
      key = 'groups/${parts[1]}';
      action = method == 'POST' ? 'addStudent' : 'removeStudent';
      values['studentId'] ??= parts.last;
      references.add('students/${values['studentId']}');
      if (action == 'addStudent') {
        final records = await runtime.data();
        final group = records[key];
        final elsewhere = OfflineProjection.collection(records, 'groups').any((
          other,
        ) {
          return other['id'] != parts[1] &&
              other['subject'] == group?['subject'] &&
              (other['studentIds'] as List? ?? []).contains(
                values['studentId'],
              );
        });
        if (elsewhere) {
          throw const ApiException(
            409,
            'El estudiante ya está en otro grupo de esta materia. Retíralo antes de moverlo.',
          );
        }
      }
    }
    await runtime.enqueue(
      key,
      action,
      values,
      references: references,
      useExpectedVersion: useExpected,
      expectedVersion: expected,
    );
    if (action == 'attendance') {
      return {
        'id': parts[1],
        'date': body['date'],
        'status': body['status'],
        'syncState': 'pending',
      };
    }
    if (action == 'evaluate') return {'syncState': 'pending'};
    if (parts.first == 'workedHours') {
      return {'stored': false, 'report': values, 'syncState': 'pending'};
    }
    final data = await runtime.data();
    return {
      ...Map<String, dynamic>.from(data[key] as Map? ?? {}),
      'id': key.split('/').last,
      'syncState': 'pending',
    };
  }

  Map<String, dynamic> _progress(
    String subject,
    List<Map<String, dynamic>> history,
  ) {
    final adapter = StudentApiAdapter();
    final rows = history.where((row) {
      return row['subject'] == subject;
    }).toList();
    rows.sort((a, b) {
      return (a['date'] as String).compareTo(b['date'] as String);
    });
    Map<String, dynamic>? describe(Map<String, dynamic>? row) {
      if (row == null) return null;
      return {
        ...row,
        'clave': row['level'],
        'etiqueta': adapter.levelBackendToLabel(row['level'] as String),
        'orden': adapter.levelOrder(subject, row['level'] as String),
      };
    }

    final baseline = rows.where((row) {
      return row['type'] == 'inicial';
    }).lastOrNull;
    final current = rows.lastOrNull;
    return {
      'baseline': describe(baseline),
      'midline': describe(
        rows.where((row) {
          return row['type'] == 'media';
        }).lastOrNull,
      ),
      'endline': describe(
        rows.where((row) {
          return row['type'] == 'final';
        }).lastOrNull,
      ),
      'current': describe(current),
      'levelsGained': baseline == null || current == null
          ? null
          : adapter.levelOrder(subject, current['level'] as String) -
                adapter.levelOrder(subject, baseline['level'] as String),
      'totalLevels': 6,
      'history': [for (final row in rows) describe(row)],
    };
  }

  Future<Map<String, dynamic>> _read(
    String path,
    Map<String, String> query,
  ) async {
    if (!runtime.ready) {
      throw const ApiException(
        0,
        'Descarga los datos con conexión antes de continuar.',
      );
    }
    final data = await runtime.data();
    final versions = await runtime.db.records(runtime.uid);
    final parts = path.split('/');
    List<Map<String, dynamic>> list(String prefix) {
      return OfflineProjection.collection(data, prefix);
    }

    if (path == 'analytics/grouping-events') {
      return {
        'events': list('groupingEvents').where((item) {
          return query['subject'] == null ||
              item['subject'] == query['subject'];
        }).toList(),
      };
    }
    if (path == 'profile') {
      return Map<String, dynamic>.from(data['profile'] as Map);
    }
    if (path == 'registerSchools') return {'schools': list('schools')};
    if (path == 'activities') return {'activities': list('activityLibrary')};
    if (path == 'plans') {
      // Without a date it returns every plan, used for the library vs own usage card.
      return {
        'activities': list('plans').where((item) {
          return query['date'] == null || item['date'] == query['date'];
        }).toList(),
      };
    }
    if (path == 'students') {
      final students = list('students');
      for (final student in students) {
        final attendance =
            data['students/${student['id']}/attendance/${query['date']}'];
        student['syncState'] =
            attendance?['syncState'] ??
            (attendance == null ? null : 'confirmed');
        student['attendance'] =
            attendance == null || attendance['status'] == 'sin_registro'
            ? 'sin_registro'
            : attendance['present'] == true
            ? 'vino'
            : 'no_vino';
      }
      students.sort((a, b) {
        return (a['fullName'] as String).compareTo(b['fullName'] as String);
      });
      return {'students': students};
    }
    if (parts.first == 'students' && parts.length >= 2) {
      final key = 'students/${parts[1]}';
      final student = Map<String, dynamic>.from(data[key] as Map? ?? {});
      if (student.isEmpty || student['active'] == false) {
        throw const ApiException(404, 'Estudiante no disponible.');
      }
      student['id'] = parts[1];
      if (parts.length == 3 && parts[2] == 'progress') {
        final attendance = list('$key/attendance').where((item) {
          return item['status'] != 'sin_registro';
        }).toList();
        final present = attendance.where((item) {
          return item['present'] == true;
        }).length;
        return {
          'student': student,
          'subjects': {
            for (final subject in ['lectura', 'matematicas'])
              subject: _progress(subject, list('$key/evaluations')),
          },
          'attendance': {
            'recorded': attendance.length,
            'present': present,
            'percentage': attendance.isEmpty
                ? null
                : (present * 100 / attendance.length).round(),
          },
        };
      }
      return student;
    }
    if (path == 'groups') {
      return {
        'groups': list('groups').where((item) {
          return query.entries.every((filter) {
            return item[filter.key] == filter.value;
          });
        }).toList(),
      };
    }
    if (parts.first == 'groups' && parts.length == 2) {
      final group = Map<String, dynamic>.from(data[path] as Map? ?? {});
      if (group.isEmpty || group['active'] == false) {
        throw const ApiException(404, 'Grupo no disponible.');
      }
      return {
        ...group,
        'id': parts[1],
        'teacher': {
          'id': group['teacherId'],
          'fullName': group['teacherId'] == runtime.uid
              ? data['profile']['fullName']
              : null,
        },
        'students': list('students').where((item) {
          return (group['studentIds'] as List? ?? []).contains(item['id']);
        }).toList(),
      };
    }
    if (parts.first == 'workedHours') {
      final reports = <Map<String, dynamic>>[];
      for (final entry in data.entries) {
        if (!entry.key.startsWith('hours/')) continue;
        final value = Map<String, dynamic>.from(entry.value as Map);
        value['syncState'] ??= 'sent';
        value['_version'] = versions[entry.key]?['version'];
        reports.add(value);
      }
      if (parts.length == 2) {
        return {
          'report': reports.where((r) {
            return r['date'] == parts[1] && r['schoolId'] == query['schoolId'];
          }).firstOrNull,
        };
      }
      return {
        'reports': reports.where((r) {
          return (query['from'] == null ||
                  (r['date'] as String).compareTo(query['from']!) >= 0) &&
              (query['to'] == null ||
                  (r['date'] as String).compareTo(query['to']!) <= 0);
        }).toList(),
      };
    }
    throw const ApiException(400, 'Consulta no disponible sin conexión.');
  }
}
