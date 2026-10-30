// lib/data/repository/reports_repository.dart
import 'package:front_end_flutter/data/cache/memory_cache.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';

/** Reads the admin reports and keeps them in memory, like ReportesRepository in the Kotlin app. */
class ReportsRepository {
  ReportsRepository(this._api);
  final ApiClient _api;
  // The cache for storing admin reports.
  static final MemoryCache cache = MemoryCache(name: 'reportes');

  /** Empties the cache; it runs on login and logout so one account never sees another's reports. */
  static void clearCache() {
    cache.clear();
  }

  /** Attendance marks replaced by another device in a week (Monday as yyyy-MM-dd). */
  Future<Map<String, dynamic>> attendanceConflicts(
    String week, {
    bool force = false,
  }) {
    return cache.getOrLoad<Map<String, dynamic>>(
      'conflictos:$week',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'attendanceConflicts/report',
          query: {'week': week},
        );
        _requireCompleteConflicts(result);
        return result;
      },
      force: force,
      // The current week is still changing: expires. A closed week no longer does.
      expires: (Map<String, dynamic> result) {
        return result['provisional'] != false;
      },
    );
  }

  /** Teachers who opened the app in a week (Monday as yyyy-MM-dd). */
  Future<Map<String, dynamic>> weeklyOpens(String week, {bool force = false}) {
    return cache.getOrLoad<Map<String, dynamic>>(
      'aperturas:$week',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'appOpens/report',
          query: {'week': week},
        );
        if (result['teachers'] is! num || result['teachersOverOnce'] is! num) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
      expires: (Map<String, dynamic> result) {
        return result['provisional'] != false;
      },
    );
  }

  /** Grouping sessions that did not reach the server within 24 h, per week. */
  Future<Map<String, dynamic>> groupingSync({bool force = false}) {
    return cache.getOrLoad<Map<String, dynamic>>(
      'sincronizacion',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'groupings/report',
        );
        if (result['weeks'] is! List || result['rows'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
      // A current week causes that the numbers might still change.
      expires: (Map<String, dynamic> result) {
        return (result['weeks'] as List).any((week) {
          return week is Map && week['provisional'] != false;
        });
      },
    );
  }

  /** Minutes per 25 students by school and teacher; subject is null for all. */
  Future<Map<String, dynamic>> classification({
    String? subject,
    bool force = false,
  }) {
    return cache.getOrLoad<Map<String, dynamic>>(
      'clasificacion:${subject ?? 'todas'}',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'classificationSessions/report',
          query: {'subject': ?subject},
        );
        if (result['schools'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
    );
  }

  /** Activities most used by teachers across all schools (BQ #11). */
  Future<Map<String, dynamic>> topActivities({bool force = false}) {
    return cache.getOrLoad<Map<String, dynamic>>('actividades', () async {
      final Map<String, dynamic> result = await _api.request(
        'GET',
        'analytics/top-activities',
      );
      if (result['total'] is! num || result['activities'] is! List) {
        throw const ApiException(502, 'El reporte recibido está incompleto.');
      }
      return result;
    }, force: force);
  }

  /** Planned and worked hours per week, newest week first (last 8 weeks). */
  Future<Map<String, dynamic>> hours({bool force = false}) {
    return cache.getOrLoad<Map<String, dynamic>>('horas', () async {
      final Map<String, dynamic> result = await _api.request(
        'GET',
        'workedHours/report',
        query: {'weeks': '8'},
      );
      if (result['summary'] is! List) {
        throw const ApiException(502, 'El reporte recibido está incompleto.');
      }
      final List<Object?> summary = [...result['summary'] as List];
      summary.sort((a, b) {
        return '${b is Map ? b['week'] : ''}'.compareTo(
          '${a is Map ? a['week'] : ''}',
        );
      });
      return {...result, 'summary': summary};
    }, force: force);
  }

  /** Assessments per subject, overall and by grade (BQ #12). */
  Future<Map<String, dynamic>> assessmentsByGrade({bool force = false}) {
    return cache.getOrLoad<Map<String, dynamic>>('evaluaciones', () async {
      final Map<String, dynamic> result = await _api.request(
        'GET',
        'analytics/assessments-by-grade',
      );
      if (result['total'] is! num ||
          result['overall'] is! Map ||
          result['grades'] is! List) {
        throw const ApiException(502, 'El reporte recibido está incompleto.');
      }
      return result;
    }, force: force);
  }

  /** Every active school for an administrator; [search] filters by name or municipality. */
  Future<Map<String, dynamic>> schools(String search, {bool force = false}) {
    final String text = search.trim();
    return cache.getOrLoad<Map<String, dynamic>>(
      'instituciones:$text',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'schools',
          query: {if (text.isNotEmpty) 'q': text},
        );
        if (result['schools'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
    );
  }

  /** Teachers registered in one school. */
  Future<Map<String, dynamic>> teachersOfSchool(
    String schoolId, {
    bool force = false,
  }) {
    return cache.getOrLoad<Map<String, dynamic>>(
      'docentes:$schoolId',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'teachers/school/${Uri.encodeComponent(schoolId)}',
        );
        if (result['teachers'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
    );
  }

  /** Throws before caching, so an incomplete answer is never stored. */
  void _requireCompleteConflicts(Map<String, dynamic> result) {
    if (result['total'] is! num ||
        result['conflicts'] is! num ||
        result['bySchool'] is! List ||
        result['byConnectivity'] is! List ||
        result['byPlatform'] is! List) {
      throw const ApiException(502, 'El reporte recibido está incompleto.');
    }
    for (final String key in ['bySchool', 'byConnectivity', 'byPlatform']) {
      for (final Object? row in result[key] as List) {
        if (row is! Map || row['total'] is! num || row['conflicts'] is! num) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
      }
    }
  }
}
