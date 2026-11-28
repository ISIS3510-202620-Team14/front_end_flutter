import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/aux_attendance_map.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/domain/model/attendance_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*   YES TEACHER I WROTE COMMENTS, JSJSJ */

class AttendanceMapRepository {
  AttendanceMapRepository(this._api, {this.onLog});

  final ApiClient _api;

  final void Function(String message)? onLog;

  // =================== 1. CACHING + EVENTUAL CONNECTIVITY ===================

  Stream<({AttendanceMap map, String source})> load() async* {
    // 1. Look for the saved map: first in RAM, then on the phone.
    // 2. If there is a saved map, show it right awa
    // 3. Try to download the fresh map from the network (red).
    // 4. If the network fails, show the saved map (disco).


    // 1
    AttendanceMap? saved = ReportsRepository.cache.get<AttendanceMap>(
      attendanceRamKey,
    );
    if (saved != null) {
      onLog?.call('Caché en memoria (RAM): ACIERTO');
    } else {
      final preferences = await SharedPreferences.getInstance();
      final String? json = preferences.getString(attendancePhoneKey());
      if (json != null) {
        onLog?.call(
          'Copia guardada en el celular: ACIERTO (${json.length} bytes)',
        );
        saved = AttendanceMap.fromJson(jsonDecode(json));
      }
    }
    // 2
    if (saved != null) {
      yield (map: saved, source: 'cache');
    }
    try {
      // 3. 
      final List<String> thisWeek = thisWeekDays();
      final schools = await _downloadAllSchools(thisWeek);
      final AttendanceMap fresh = await _calculateInAnotherIsolate(
        thisWeek,
        schools,
      );
      await _save(fresh);
      yield (map: fresh, source: 'red');
    } catch (error) {
      // 4. 
      onLog?.call('Falló la red: $error');
      if (saved == null) {
        rethrow;
      }
      yield (map: saved, source: 'disco');
    }
  }

  // =================== 2. CONCURRENCY ===================

  Future<List<Map<String, dynamic>>> _downloadAllSchools(
    List<String> thisWeek,
  ) async {
    // 1. Get the days to ask for and the list of schools.
    // 2. Start one request per school and per day, all at the same time.
    // 3. Wait until all of them finish (Future.wait).
    // 4. Group the responses into one row per school.

    // 1
    final List<String> asked = askedDays(thisWeek);
    final List schools = (await _api.request('GET', 'schools'))['schools'];
    onLog?.call('GET schools → ${schools.length} instituciones');
    // 2
    onLog?.call(
      'Future.wait: ${schools.length * asked.length} peticiones en paralelo',
    );
    final Stopwatch watch = Stopwatch()..start();
    final List<Future<Map<String, dynamic>>> requests = [];
    for (final school in schools) {
      for (final String day in asked) {
        requests.add(
          _api.request(
            'GET',
            'students',
            query: {'schoolId': school['id'], 'date': day},
          ),
        );
      }
    }
    // 3
    final List<Map<String, dynamic>> responses = await Future.wait(requests);
    onLog?.call('Future.wait terminó en ${watch.elapsedMilliseconds} ms');
    // 4
    return groupBySchool(schools, asked.length, responses);
  }

  // =================== 3. MULTI-THREADING ===================

  Future<AttendanceMap> _calculateInAnotherIsolate(
    List<String> thisWeek,
    List<Map<String, dynamic>> schools,
  ) async {
    // 1. Calculate the percentages in another isolate,
    //    so the screen does not freeze (compute).

    // 1
    onLog?.call('compute(): calculando en otro isolate');
    final Stopwatch watch = Stopwatch()..start();
    final AttendanceMap map = await compute(buildAttendanceMap, {
      'days': thisWeek,
      'schools': schools,
    });
    onLog?.call('compute() terminó en ${watch.elapsedMilliseconds} ms');
  
    return map;
  }

  // =================== 4. LOCAL STORAGE ===================

  Future<void> _save(AttendanceMap map) async {
    // 1. Save in RAM: fastest, but lost when the app is closed.
    // 2. Save on the phone as JSON (SharedPreferences): survives closing the app.

    // 1
    ReportsRepository.cache.put(attendanceRamKey, map, expires: false);
    // 2
    final preferences = await SharedPreferences.getInstance();
    final String json = jsonEncode(map.toJson());
    await preferences.setString(attendancePhoneKey(), json);
    onLog?.call('SharedPreferences: mapa guardado (${json.length} bytes)');
  }
}
