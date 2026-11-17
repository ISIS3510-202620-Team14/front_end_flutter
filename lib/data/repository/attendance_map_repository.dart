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
    onLog?.call(message);
  }

  String get _key {
    return 'attendance_map_${FirebaseAuth.instance.currentUser?.uid}';
  }

  Future<({AttendanceMap map, String source})> load({
    bool force = false,
  }) async {
    bool downloaded = false;
    _log(force ? 'Recarga forzada: se salta la caché' : 'Buscando en caché');
    try {
      final AttendanceMap map = await ReportsRepository.cache
          .getOrLoad<AttendanceMap>('attendance_map', () {
            downloaded = true;
            _log('Caché en memoria: no está → descargando');
            return _download();
          }, force: force);
      if (!downloaded) _log('Caché en memoria: ACIERTO, sin descargar');
      return (map: map, source: downloaded ? 'red' : 'memoria');
    } catch (error) {
      final String reason = '$error';
      _log(
        'Falló la red: ${reason.length > 80 ? reason.substring(0, 80) : reason}',
      );
      final preferences = await SharedPreferences.getInstance();
      final String? saved = preferences.getString(_key);
      if (saved == null) {
        _log('SharedPreferences: no hay mapa guardado');
        rethrow;
      }
      _log('SharedPreferences: mapa leído (${saved.length} bytes)');
      return (map: AttendanceMap.fromJson(jsonDecode(saved)), source: 'disco');
    }
  }

  Future<AttendanceMap> _download() async {
    final DateTime monday = DateTime.parse(
      AppDate.mondayOfWeek(DateTime.now()),
    );
    final List<String> days = [for (int i = 0; i < 5; i++) _date(monday, i)];
    final List<String> lastWeek = [
      for (int i = -7; i < -2; i++) _date(monday, i),
    ];
    final List schools = (await _api.request('GET', 'schools'))['schools'];
    _log('GET schools → ${schools.length} instituciones');
    final Stopwatch watch = Stopwatch()..start();
    _log('Future.wait: ${schools.length * 10} peticiones en paralelo');

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
          return {
            'name': school['name'],
            'thisWeek': await Future.wait([
              for (final day in days) _students(school['id'], day),
            ]),
            'lastWeek': await Future.wait([
              for (final day in lastWeek) _students(school['id'], day),
            ]),
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
