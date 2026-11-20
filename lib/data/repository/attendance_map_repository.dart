import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/domain/model/attendance_map.dart';
import 'package:front_end_flutter/ui/theme/app_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceMapRepository {
  AttendanceMapRepository(this._api, {this.onLog});
  final ApiClient _api;
  final void Function(String message)? onLog;

  void _log(String message) {
    if (kDebugMode) debugPrint('[mapa] $message');
    onLog?.call(message);
  }

  String get _key {
    return 'attendance_map_${FirebaseAuth.instance.currentUser?.uid}';
  }

  static const String _cacheKey = 'attendance_map';

  /* CACHING: Cache then network

  1. Emits the cached map right away (RAM, or the copy saved on the phone).
  2. Asks the network for the new map and emits it when it arrives.
  If the network fails, the cached map stays, marked as offline.
  */
  Stream<({AttendanceMap map, String source})> load() async* {
    final AttendanceMap? cached = await _cached();
    if (cached != null) {
      _log('Cache then network: mostrando la caché mientras llega la red');
      yield (map: cached, source: 'cache');
    } else {
      _log('Cache then network: no hay caché, esperando la red');
    }
    try {
      final AttendanceMap fresh = await _download();
      ReportsRepository.cache.put(_cacheKey, fresh, expires: false);
      _log('Red respondió: la caché se actualizó');
      yield (map: fresh, source: 'red');
    } catch (error) {
      final String reason = '$error';
      _log(
        'Falló la red: ${reason.length > 80 ? reason.substring(0, 80) : reason}',
      );
      if (cached == null) {
        _log('Sin caché ni copia guardada: no hay mapa que mostrar');
        rethrow;
      }
      yield (map: cached, source: 'disco');
    }
  }

  Future<AttendanceMap?> _cached() async {
    final AttendanceMap? inMemory = ReportsRepository.cache.get<AttendanceMap>(
      _cacheKey,
    );
    if (inMemory != null) {
      _log('Caché en memoria (RAM): ACIERTO');
      return inMemory;
    }
    final preferences = await SharedPreferences.getInstance();
    final String? saved = preferences.getString(_key);
    if (saved == null) return null;
    _log('Copia guardada en el celular: ACIERTO (${saved.length} bytes)');
    return AttendanceMap.fromJson(jsonDecode(saved));
  }

  Future<AttendanceMap> _download() async {
    final DateTime monday = DateTime.parse(
      AppDate.mondayOfWeek(DateTime.now()),
    );
    final List<String> days = [for (int i = 0; i < 5; i++) _date(monday, i)];
    final List<String> lastWeek = [
      for (int i = -7; i < -2; i++) _date(monday, i),
    ];
    final String today = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 5))
        .toIso8601String()
        .substring(0, 10);
    final List<String> asked = [
      ...lastWeek,
      ...days.where((day) => day.compareTo(today) <= 0),
    ];
    final List schools = (await _api.request('GET', 'schools'))['schools'];
    _log('GET schools → ${schools.length} instituciones');
    final Stopwatch watch = Stopwatch()..start();
    _log(
      'Future.wait: ${schools.length * asked.length} peticiones en paralelo',
    );

    /* CONCURRENCY 
    
    `Future.wait` to fetch data for multiple (API requests) 
    schools and days AND 3 more concurrently. 
    a bunch of GETS 
    [
      {name: "I.E.R. La Esperanza", thisWeek: [lista lun, lista mar, ...], lastWeek: [...]},
      {name: "Demostración Samuel", thisWeek: [...], lastWeek: [...]},
      {name: "rogelio", ...},
    ] 
    */

    final List<Map<String, dynamic>> rows = await Future.wait([
      for (final school in schools)
        () async {
          final List lists = await Future.wait([
            for (final day in asked) _students(school['id'], day),
          ]);
          return {
            'name': school['name'],
            'lastWeek': lists.sublist(0, 5),
            'thisWeek': [
              ...lists.sublist(5),
              for (int i = lists.length - 5; i < 5; i++) const [],
            ],
          };
        }(),
    ]);
    _log('Future.wait terminó en ${watch.elapsedMilliseconds} ms');
    watch.reset();
    _log('compute(): calculando en otro isolate');

    /* MULTI-THREADING

    `compute` to build the AttendanceMap in OTHER isolate.
   
    */

    final AttendanceMap map = await compute(buildAttendanceMap, {
      'days': days,
      'schools': rows,
    });

    _log('compute() terminó en ${watch.elapsedMilliseconds} ms');

    final preferences = await SharedPreferences.getInstance();
    final String json = jsonEncode(map.toJson());
    await preferences.setString(_key, json);
    _log('SharedPreferences: mapa guardado (${json.length} bytes)');
    return map;
  }

  Future<List> _students(String schoolId, String day) async {
    final result = await _api.request(
      'GET',
      'students',
      query: {'schoolId': schoolId, 'date': day},
    );
    return result['students'] as List;
  }

  static String _date(DateTime monday, int plusDays) {
    return monday
        .add(Duration(days: plusDays))
        .toIso8601String()
        .substring(0, 10);
  }
}
