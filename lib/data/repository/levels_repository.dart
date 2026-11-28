// lib/data/repository/levels_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/data/cache/levels_file_cache.dart';
import 'package:front_end_flutter/data/levels/count_levels.dart';
import 'package:front_end_flutter/data/local/levels_database.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/remote/api_config.dart';
import 'package:front_end_flutter/domain/model/school_levels.dart';
import 'package:http/http.dart' as http;

/** Numbers of one download, for the logs and the wiki. */
class LevelsDownload {
  const LevelsDownload({
    required this.total,
    required this.failed,
    required this.requests,
    required this.fromCache,
    required this.dbMicros,
    required this.millis,
    required this.startedAt,
  });
  final int total;
  final int failed;
  final int requests;
  final int fromCache;
  final int dbMicros;
  final int millis;
  final DateTime startedAt;
}

/** BQ: view model -> repository -> (cache file | network) -> Isolate.run -> SQLite. */
class LevelsRepository {
  LevelsRepository({http.Client? client, LevelsDatabase? database, this.onLog})
    : _client = client ?? http.Client(),
      _db = database ?? LevelsDatabase.instance;
  final http.Client _client;
  final LevelsDatabase _db;
  /** Every step is also shown on the phone (logs sheet of the view, developer mode). */
  final void Function(String message)? onLog;

  /** What the screen shows: always read from SQLite, so it also works offline. */
  Future<List<LevelRow>> rows(String uid, String subject, int grade) async {
    final Stopwatch watch = Stopwatch()..start();
    final List<LevelRow> rows = await _db.rows(uid, subject, grade);
    _log(
      'SQLite: ${rows.length} instituciones ($subject, grado ${grade == 0 ? 'todos' : grade}) en ${watch.elapsedMilliseconds} ms',
    );
    return rows;
  }

  /*
    One institution after another, in a chain of Futures (then / catchError), so a weak rural
    connection is not saturated: cache or network -> Isolate.run -> SQLite -> progress.
    If one institution fails, it keeps its saved data and the next one goes on.
  */
  Future<LevelsDownload> download(
    String uid, {
    required bool force,
    required void Function(int done, int total) onProgress,
  }) async {
    final Stopwatch watch = Stopwatch()..start();
    // Whole milliseconds, the same precision SQLite keeps (used to find old rows).
    final DateTime startedAt = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch,
      isUtc: true,
    );
    int requests = 0;
    int fromCache = 0;
    int done = 0;
    int failed = 0;
    int dbMicros = 0;

    // CACHING: cache, falling back to network.
    Future<String> cachedOrNetwork(
      String cacheKey,
      String label,
      String path,
      Map<String, String>? query,
    ) async {
      if (!force) {
        final String? cached = await LevelsFileCache.fresh(cacheKey);
        if (cached != null) {
          fromCache++;
          _log('Caché: $label (archivo válido, no se pide a la red)');
          return cached;
        }
      }
      final Uri uri = Uri.parse('${ApiConfig.baseUrl}/$path')
          .replace(queryParameters: query);
      requests++;
      _log('Red: GET $path ($label)');
      final String body = await _get(uri);
      await LevelsFileCache.put(cacheKey, uri.toString(), body);
      return body;
    }

    final Map<String, dynamic> schoolsBody = jsonDecode(
      await cachedOrNetwork(
        '${uid}_instituciones',
        'instituciones',
        'schools',
        null,
      ),
    ) as Map<String, dynamic>;
    final List<Map<String, dynamic>> schools = [
      for (final Object? school in schoolsBody['schools'] as List)
        Map<String, dynamic>.from(school as Map),
    ];
    onProgress(0, schools.length);

    Future<void> oneSchool(Map<String, dynamic> school) {
      return cachedOrNetwork(
            '${uid}_estudiantes_${school['id']}',
            '${school['name']}',
            'students',
            {'schoolId': '${school['id']}'},
          )
          .then((String body) {
            final Stopwatch isolate = Stopwatch()..start();
            return countInIsolate(body).then((Int32List counts) {
              _log(
                'Isolate.run: ${school['name']} contada en ${isolate.elapsedMilliseconds} ms',
              );
              return counts;
            });
          })
          .then((Int32List counts) {
            final Stopwatch db = Stopwatch()..start();
            return _db
                .saveSchool(
                  uid,
                  '${school['id']}',
                  '${school['name'] ?? 'Sin nombre'}',
                  counts,
                  startedAt,
                )
                .then((_) {
                  dbMicros += db.elapsedMicroseconds;
                  _log(
                    'SQLite: ${school['name']} guardada en ${db.elapsedMilliseconds} ms',
                  );
                });
          })
          .then((_) {
            done++;
            onProgress(done + failed, schools.length);
          })
          .catchError((Object error) {
            failed++;
            _log('${school['name']}: no se actualizó ($error)');
            onProgress(done + failed, schools.length);
          });
    }

    Future<void> chain = Future<void>.value();
    for (final Map<String, dynamic> school in schools) {
      chain = chain.then((_) => oneSchool(school));
    }
    await chain;
    if (failed == 0) await _db.removeOlderThan(uid, startedAt);

    final LevelsDownload result = LevelsDownload(
      total: schools.length,
      failed: failed,
      requests: requests,
      fromCache: fromCache,
      dbMicros: dbMicros,
      millis: watch.elapsedMilliseconds,
      startedAt: startedAt,
    );
    _log(
      'TOTAL: ${result.total} instituciones en ${result.millis} ms · '
      'peticiones=${result.requests} · desde caché=${result.fromCache} · '
      'SQLite=${(result.dbMicros / 1000).toStringAsFixed(1)} ms · fallidas=${result.failed}',
    );
    return result;
  }

  Future<String> _get(Uri uri) async {
    final String token = await AuthApi.getIdToken();
    final http.Response response = await _client
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'El servidor respondió ${response.statusCode}.',
      );
    }
    return response.body;
  }

  void dispose() {
    _client.close();
  }

  void _log(String message) {
    if (!kReleaseMode) debugPrint('[niveles] $message');
    onLog?.call(message);
  }
}
