import '../auth/auth_api.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../remote/api_client.dart';
import '../local/offline_database.dart';
import 'offline_projection.dart';
import 'background_sync.dart';
import '../repository/attendance_conflicts.dart';

/** Coordinates local changes and server receipts. */
class OfflineRuntime extends ChangeNotifier with WidgetsBindingObserver {
  /** Creates a foreground or background coordinator. */
  OfflineRuntime(
    this.uid,
    this.db,
    this.api, {
    this.sessionValid,
    this.background = false,
  });
  final bool background;
  final bool Function()? sessionValid;
  final String uid;
  final OfflineDatabase db;
  final ApiClient api;
  static OfflineRuntime? current;
  static final OfflineDatabase _database = OfflineDatabase();
  final String _owner = const Uuid().v4();
  bool active = true;
  bool running = false;
  bool downloading = false;
  bool paused = false;
  bool ready = false;
  String? message;
  String? downloadedAt;
  int pending = 0;
  int attention = 0;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _network;
  Future<void>? _download;
  int _nextDownload = 0;
  final Random _random = Random();
  /** Checks the current account. */
  bool get ownsSession {
    return (sessionValid?.call() ??
            (FirebaseAuth.instance.currentUser?.uid == uid)) &&
        identical(current, this);
  }

  /** Checks whether the account has downloaded data. */
  static Future<bool> hasDownload(String uid) async {
    return await _database.meta(uid, 'downloadedAt') != null;
  }

  /** Opens the local session and starts foreground sync. */
  static Future<OfflineRuntime> open(String uid) async {
    if (current?.uid == uid) {
      if (!current!.ready) await current!.download();
      return current!;
    }
    current?.stop();
    final runtime = OfflineRuntime(
      uid,
      _database,
      ApiClient(
        localFirst: false,
        tokenProvider: () async {
          if (FirebaseAuth.instance.currentUser?.uid != uid ||
              await _database.meta('', 'activeUid') != uid) {
            throw const ApiException(401, 'La sesión cambió.');
          }
          final token = await AuthApi.getIdToken();
          if (FirebaseAuth.instance.currentUser?.uid != uid ||
              await _database.meta('', 'activeUid') != uid) {
            throw const ApiException(401, 'La sesión cambió.');
          }
          return token;
        },
      ),
    );
    current = runtime;
    try {
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        throw const ApiException(401, 'La sesión cambió.');
      }
      await runtime.db.setMeta('', 'activeUid', uid);
      await runtime._migrate();
      runtime.downloadedAt = await runtime.db.meta(uid, 'downloadedAt');
      runtime.ready = runtime.downloadedAt != null;
      if (!runtime.ready) await runtime.download();
      WidgetsBinding.instance.addObserver(runtime);
      runtime._network = Connectivity().onConnectivityChanged.listen((
        connections,
      ) {
        if (!connections.contains(ConnectivityResult.none)) {
          runtime.connectionReturned();
        }
      });
      runtime._timer = Timer.periodic(const Duration(seconds: 2), (_) {
        runtime.kick();
      });
      await runtime.refreshCounts();
      await runtime.scheduleBackground();
      runtime.kick();
      return runtime;
    } catch (_) {
      runtime.stop();
      if (identical(current, runtime)) current = null;
      rethrow;
    }
  }

  /** Stops foreground listeners. */
  void stop() {
    active = false;
    _timer?.cancel();
    _network?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /** Revokes background access before signing out. */
  static Future<void> clearActiveSession() async {
    final uid = current?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    await _database.setMeta('', 'activeUid', '');
    current?.stop();
    current = null;
    if (uid != null) await BackgroundSync.cancel(uid);
  }

  /** Keeps local saves valid when scheduling is unavailable. */
  Future<void> scheduleBackground() async {
    if (background || pending == 0) return;
    try {
      await BackgroundSync.schedule(uid);
    } catch (_) {
      message = 'Guardado en este celular. Abre la app para sincronizar.';
      notifyListeners();
    }
  }

  @override
  /** Pauses work when the app leaves the foreground. */
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) {
      connectionReturned();
    }
  }

  /** Retries pending work after a network change. */
  void connectionReturned() {
    if (!active || !ownsSession) return;
    _nextDownload = 0;
    unawaited(
      db
          .customStatement(
            "UPDATE operations SET next_attempt=0 WHERE uid=? AND state='pending'",
            [uid],
          )
          .then((_) {
            kick();
          })
          .catchError((Object _) {
            message = 'No pudimos leer los pendientes guardados.';
            notifyListeners();
          }),
    );
  }

  /** Preserves reports and drafts from preferences. */
  Future<void> _migrate() async {
    if (await db.meta(uid, 'migration') != null) return;
    final prefs = await SharedPreferences.getInstance();
    final hours = prefs.getString('enad_hours_v1_$uid');
    final drafts = prefs.getString('enad_attendance_v1_$uid');
    await db.transaction(() async {
      if (drafts != null) await db.setMeta(uid, 'attendanceDrafts', drafts);
      final notice = prefs.getString('enad_attendance_v1_${uid}_notice');
      if (notice != null) await db.setMeta(uid, 'attendanceNotice', notice);
      if (hours != null) {
        for (final item in (jsonDecode(hours) as Map).values) {
          if (item is! Map || item['schoolId'] == null) continue;
          final body = Map<String, dynamic>.from(item);
          final key = 'hours/${body['schoolId']}/${body['date']}';
          if (body['syncState'] == 'pending') {
            await _insert(key, 'save', body, [], null);
          } else {
            await db.putRecord(uid, {
              'key': key,
              'data': body,
              'version': null,
            });
            if (['conflict', 'failed'].contains(body['syncState'])) {
              final opId = await _insert(key, 'save', body, [], null);
              await db.customStatement(
                'UPDATE operations SET state=?,error=? WHERE uid=? AND id=?',
                [
                  body['syncState'],
                  body['syncError'] ?? 'Revisa este registro.',
                  uid,
                  opId,
                ],
              );
            }
          }
        }
      }
      await db.setMeta(uid, 'migration', '1');
    });
  }

  /** Adds one durable operation. */
  Future<String> _insert(
    String key,
    String action,
    Map<String, dynamic> body,
    List<String> dependencies,
    String? base,
  ) async {
    final id = const Uuid().v4();
    await db.customStatement(
      'INSERT INTO operations(uid,id,key,action,body,base,dependencies,state,created_at) VALUES(?,?,?,?,?,?,?,?,?)',
      [
        uid,
        id,
        key,
        action,
        jsonEncode(body),
        base,
        jsonEncode(dependencies),
        'pending',
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
    return id;
  }

  /** Saves a local change before sending it. */
  Future<String> enqueue(
    String key,
    String action,
    Map<String, dynamic> body, {
    List<String> references = const [],
    bool useExpectedVersion = false,
    String? expectedVersion,
  }) async {
    if (!ownsSession) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
    if (paused) {
      throw const ApiException(
        403,
        'Actualiza tu sesión antes de guardar nuevos cambios.',
      );
    }
    late String id;
    final values = Map<String, dynamic>.from(body);
    final attendanceContext = values.remove('_attendanceContext');
    await db.transaction(() async {
      final records = await db.records(uid);
      final history = await db.history(uid);
      final dependencies = <String>[];
      for (final op in history) {
        if (['pending', 'sending', 'blocked'].contains(op['state']) &&
            (op['key'] == key || references.contains(op['key']))) {
          dependencies.add(op['id'] as String);
        }
      }
      id = await _insert(
        key,
        action,
        values,
        dependencies,
        useExpectedVersion
            ? expectedVersion
            : records[key]?['version'] as String?,
      );
      if (action == 'attendance' && attendanceContext is Map) {
        await db.setMeta(
          uid,
          'attendanceContext:$id',
          jsonEncode(attendanceContext),
        );
      }
    });
    await refreshCounts();
    await scheduleBackground();
    kick();
    return id;
  }

  /** Reads downloaded data with pending changes. */
  Future<Map<String, dynamic>> data() async {
    return db.transaction(() async {
      return OfflineProjection.materialize(
        await db.records(uid),
        await db.history(uid),
      );
    });
  }

  /** Updates visible sync counts. */
  Future<void> refreshCounts() async {
    final history = await db.history(uid);
    pending = history.where((op) {
      return ['pending', 'sending', 'blocked'].contains(op['state']);
    }).length;
    attention = history.where((op) {
      return ['conflict', 'failed'].contains(op['state']);
    }).length;
    notifyListeners();
  }

  /** Shares one active download. */
  Future<void> download() {
    return _download ??= _downloadAll().whenComplete(() {
      _download = null;
    });
  }

  /** Replaces the cache only after a complete download. */
  Future<void> _downloadAll() async {
    if (!ownsSession) return;
    downloading = true;
    notifyListeners();
    final records = <String, Map<String, dynamic>>{};
    Future<void> page(
      String entity, [
      Map<String, String> filters = const {},
    ]) async {
      String? cursor;
      do {
        if (!ownsSession || !active) {
          throw const ApiException(0, 'Descarga pausada.');
        }
        final response = await api.request(
          'GET',
          'sync/v1/download',
          query: {'entity': entity, ...filters, 'cursor': ?cursor},
        );
        for (final item in response['records'] as List) {
          final record = Map<String, dynamic>.from(item as Map);
          records[record['key'] as String] = record;
        }
        cursor = response['nextCursor'] as String?;
      } while (cursor != null);
    }

    try {
      await page('profile');
      await page('schools');
      final schools = records.values.where((r) {
        return (r['key'] as String).startsWith('schools/');
      }).toList();
      for (final school in schools) {
        if (school['data'] == null || school['data']['active'] == false) {
          continue;
        }
        final id = (school['key'] as String).split('/').last;
        await page('students', {'schoolId': id});
        await page('groups', {'schoolId': id});
      }
      final students = records.values.where((r) {
        return (r['key'] as String).startsWith('students/') &&
            r['data']?['active'] != false;
      }).toList();
      for (final student in students) {
        final id = (student['key'] as String).split('/').last;
        await page('attendance', {'parentId': id});
        await page('evaluations', {'parentId': id});
      }
      await page('activities');
      await page('hours');
      await page('plans');
      await page('groupingEvents');
      if (!ownsSession) return;
      final at = DateTime.now().toUtc().toIso8601String();
      await db.transaction(() async {
        await db.customStatement('DELETE FROM records WHERE uid=?', [uid]);
        for (final item in records.values) {
          await db.putRecord(uid, item);
        }
        await db.setMeta(uid, 'downloadedAt', at);
      });
      downloadedAt = at;
      ready = true;
      message = null;
    } catch (error) {
      message = ready
          ? 'Sin actualizar. Tus datos descargados siguen disponibles.'
          : 'Conéctate para descargar los datos antes de trabajar sin conexión.';
      if (!ready) rethrow;
      if (error is ApiException && [401, 403].contains(error.statusCode)) {
        paused = true;
      }
    } finally {
      _nextDownload = DateTime.now().millisecondsSinceEpoch + 300000;
      downloading = false;
      notifyListeners();
    }
  }

  /** Starts one foreground sync cycle. */
  void kick() {
    if (active && ownsSession && !running && !paused && !downloading) {
      unawaited(synchronize());
    }
  }

  /** Retries pending and blocked operations. */
  Future<void> retry() async {
    paused = false;
    await db.customStatement(
      "UPDATE operations SET next_attempt=0,state='pending' WHERE uid=? AND state IN ('pending','blocked')",
      [uid],
    );
    await synchronize();
  }

  /** Sends independent records with a shared database lease. */
  Future<void> synchronize() async {
    if (running || !active || !ownsSession || paused || downloading) return;
    running = true;
    bool acquired = false;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.transaction(() async {
        await db.customStatement(
          'DELETE FROM leases WHERE uid=? AND expires<?',
          [uid, now],
        );
        await db.customStatement(
          'INSERT OR IGNORE INTO leases(uid,owner,expires) VALUES(?,?,?)',
          [uid, _owner, now + 120000],
        );
        final leases = await db.rows('SELECT owner FROM leases WHERE uid=?', [
          uid,
        ]);
        acquired = leases.first['owner'] == _owner;
        if (acquired) {
          await db.customStatement(
            "UPDATE operations SET state='pending' WHERE uid=? AND state='sending'",
            [uid],
          );
        }
      });
      if (!acquired) return;
      while (active && ownsSession && !paused) {
        await db.customStatement(
          'UPDATE leases SET expires=? WHERE uid=? AND owner=?',
          [DateTime.now().millisecondsSinceEpoch + 120000, uid, _owner],
        );
        final history = await db.history(uid);
        final byId = {for (final op in history) op['id']: op};
        final selected = <Map<String, dynamic>>[];
        final keys = <String>{};
        for (final op in history) {
          if (op['state'] != 'pending') continue;
          final dependencies = List<String>.from(
            jsonDecode(op['dependencies'] as String) as List,
          );
          if (dependencies.any((id) {
            return ['failed', 'conflict'].contains(byId[id]?['state']);
          })) {
            await db.customStatement(
              "UPDATE operations SET state='conflict',error=? WHERE uid=? AND id=?",
              [
                'No enviado: un cambio anterior fue rechazado. Se conserva el servidor.',
                uid,
                op['id'],
              ],
            );
            continue;
          }
          if (dependencies.any((id) {
            return byId[id]?['state'] != 'confirmed';
          })) {
            continue;
          }
          if ((op['next_attempt'] as int) >
                  DateTime.now().millisecondsSinceEpoch ||
              keys.contains(op['key'])) {
            continue;
          }
          selected.add(op);
          keys.add(op['key'] as String);
          if (selected.length == 4) break;
        }
        if (selected.isEmpty) break;
        await Future.wait(selected.map(_send));
        await refreshCounts();
      }
      await refreshCounts();
      final last = DateTime.tryParse(downloadedAt ?? '');
      if (!background &&
          pending == 0 &&
          active &&
          ownsSession &&
          !paused &&
          DateTime.now().millisecondsSinceEpoch >= _nextDownload &&
          (last == null || DateTime.now().difference(last).inMinutes >= 5)) {
        await download();
      }
    } catch (error) {
      message = 'No pudimos sincronizar. Tus pendientes siguen guardados en este celular.';
      notifyListeners();
    } finally {
      running = false;
      if (acquired) {
        try {
          await db.customStatement(
            'DELETE FROM leases WHERE uid=? AND owner=?',
            [uid, _owner],
          );
        } catch (_) {
          message = 'No pudimos acceder al almacenamiento. Intenta de nuevo.';
        }
      }
    }
  }

  /** Stores a verified server receipt atomically. */
  Future<void> _send(Map<String, dynamic> op) async {
    if (!ownsSession || !active || paused) return;
    if ((background || sessionValid == null) &&
        await db.meta('', 'activeUid') != uid) {
      paused = true;
      return;
    }
    await db.customStatement(
      "UPDATE operations SET state='sending' WHERE uid=? AND id=?",
      [uid, op['id']],
    );
    notifyListeners();
    try {
      final result = await api.request(
        'POST',
        'sync/v1/operations',
        body: {
          'operationId': op['id'],
          'key': op['key'],
          'action': op['action'],
          'body': jsonDecode(op['body'] as String),
          'baseVersion': op['base'],
        },
      );
      if (result['operationId'] != op['id'] ||
          !['confirmed', 'conflict'].contains(result['state']) ||
          result['records'] is! List) {
        throw const ApiException(502, 'No pudimos confirmar el envío.');
      }
      await db.transaction(() async {
        await AttendanceConflicts(db, uid).recordOutcome(op, result);
        for (final raw in result['records'] as List) {
          final record = Map<String, dynamic>.from(raw as Map);
          await db.putRecord(uid, record);
          if (record['key'] == op['key'] && result['state'] == 'confirmed') {
            final history = await db.history(uid);
            for (final later in history) {
              if (later['key'] == op['key'] &&
                  later['state'] == 'pending' &&
                  (jsonDecode(later['dependencies'] as String) as List)
                      .contains(op['id'])) {
                await db.customStatement(
                  'UPDATE operations SET base=? WHERE uid=? AND id=?',
                  [record['version'], uid, later['id']],
                );
              }
            }
          }
        }
        await db.customStatement(
          'UPDATE operations SET state=?,error=? WHERE uid=? AND id=?',
          [
            result['state'],
            result['state'] == 'conflict'
                ? 'No enviado: el registro cambió. Se conserva el servidor.'
                : null,
            uid,
            op['id'],
          ],
        );
      });
    } catch (error) {
      final code = error is ApiException ? error.statusCode : 0;
      final transient = code == 0 || code == 408 || code == 429 || code >= 500;
      final attempts = (op['attempts'] as int) + 1;
      var seconds =
          min(300, 2 * pow(2, min(attempts - 1, 8)).toInt()) +
          _random.nextInt(3);
      if (error is ApiException && error.retryAfter != null) {
        seconds = max(seconds, error.retryAfter!);
      }
      final state = [401, 403].contains(code)
          ? 'blocked'
          : transient
          ? 'pending'
          : code == 409
          ? 'conflict'
          : 'failed';
      if (state == 'blocked') paused = true;
      await db.customStatement(
        'UPDATE operations SET state=?,attempts=?,next_attempt=?,error=? WHERE uid=? AND id=?',
        [
          state,
          attempts,
          DateTime.now().millisecondsSinceEpoch + seconds * 1000,
          error.toString(),
          uid,
          op['id'],
        ],
      );
    }
  }
}
