import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/services/api_client/api_client.dart';
import 'package:front_end_flutter/services/hours_store/hours_store.dart';

class HoursRepository {
  HoursRepository({ApiClient? api, String? userId}) {
    final User? user = userId == null
        ? FirebaseAuth.instance.currentUser
        : null;
    _userId = userId ?? user?.uid ?? '';
    _api =
        api ??
        ApiClient(
          tokenProvider: () async {
            if (user == null ||
                FirebaseAuth.instance.currentUser?.uid != user.uid) {
              throw const ApiException(401, 'Inicia sesión para continuar.');
            }
            String? token;
            try {
              token = await user.getIdToken();
            } on FirebaseAuthException catch (error) {
              if (error.code == 'network-request-failed') {
                throw const ApiException(
                  0,
                  'Sin conexión. Las horas siguen guardadas en este dispositivo.',
                );
              }
              throw const ApiException(
                401,
                'Inicia sesión de nuevo para enviar las horas pendientes.',
              );
            }
            if (token == null) {
              throw const ApiException(401, 'Inicia sesión de nuevo.');
            }
            return token;
          },
        );
    _store = HoursStore(_userId);
  }
  late final String _userId;
  late final ApiClient _api;
  late final HoursStore _store;
  static final Map<String, Future<void>> _syncs = {};
  bool usingCache = false;

  String _key(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  void _requireSession() {
    if (_userId.isEmpty) {
      throw const ApiException(401, 'Inicia sesión para continuar.');
    }
  }

  bool _transient(ApiException error) {
    return error.statusCode == 0 ||
        error.statusCode == 408 ||
        error.statusCode == 429 ||
        error.statusCode >= 500;
  }

  Future<Map<String, dynamic>?> load(String date) async {
    final DateTime day = DateTime.parse(date);
    final reports = await loadPeriod(day, day);
    return reports.isEmpty ? null : reports.first;
  }

  Future<List<Map<String, dynamic>>> loadPeriod(
    DateTime start,
    DateTime end,
  ) async {
    _requireSession();
    final String from = _key(start);
    final String to = _key(end);
    usingCache = false;
    Map<String, dynamic> local;
    try {
      final response = await _api.request(
        'GET',
        'workedHours',
        query: {'from': from, 'to': to},
      );
      final Map<String, dynamic> remote = {};
      for (final item in response['reports'] as List) {
        final report = Map<String, dynamic>.from(item as Map);
        remote[report['date'] as String] = {...report, 'syncState': 'sent'};
      }
      local = await _store.update((reports) {
        for (
          DateTime day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))
        ) {
          final String date = _key(day);
          final existing = reports[date];
          if (existing is Map && existing['syncState'] != 'sent') continue;
          final incoming = remote[date];
          if (existing is Map && incoming == null) continue;
          if (existing is Map &&
              incoming is Map &&
              DateTime.parse(existing['savedAt'] as String)
                  .isAfter(DateTime.parse(incoming['savedAt'] as String))) {
            continue;
          }
          reports[date] = remote[date];
        }
      });
    } on ApiException catch (error) {
      if (!_transient(error)) rethrow;
      local = await _store.read();
      usingCache = true;
      for (
        DateTime day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        if (!local.containsKey(_key(day))) rethrow;
      }
    }
    final List<Map<String, dynamic>> result = [];
    for (final entry in local.entries) {
      if (entry.key.compareTo(from) >= 0 &&
          entry.key.compareTo(to) <= 0 &&
          entry.value is Map) {
        result.add(Map<String, dynamic>.from(entry.value as Map));
      }
    }
    result.sort((a, b) {
      return (a['date'] as String).compareTo(b['date'] as String);
    });
    return result;
  }

  Future<List<Map<String, dynamic>>> localReports() async {
    _requireSession();
    final values = await _store.read();
    return values.values.whereType<Map>().map((value) {
      return Map<String, dynamic>.from(value);
    }).toList();
  }

  Future<bool> save(String date, Map<String, dynamic> body) async {
    _requireSession();
    await _store.update((reports) {
      reports[date] = {...body, 'date': date, 'syncState': 'pending'};
    });
    await synchronize();
    final local = await _store.read();
    final report = local[date] as Map;
    if (report['syncState'] == 'conflict' || report['syncState'] == 'failed') {
      throw ApiException(409, report['syncError'] as String);
    }
    return report['syncState'] == 'sent';
  }

  Future<void> synchronize() {
    _requireSession();
    final Future<void> previous = _syncs[_userId] ?? Future<void>.value();
    final Future<void> operation = previous.catchError((Object _) {}).then((_) {
      return _sendPending();
    });
    _syncs[_userId] = operation;
    return operation.whenComplete(() {
      if (identical(_syncs[_userId], operation)) _syncs.remove(_userId);
    });
  }

  Future<void> _sendPending() async {
    final reports = await localReports();
    for (final report in reports) {
      if (report['syncState'] != 'pending') continue;
      final String date = report['date'] as String;
      final body = Map<String, dynamic>.from(report)
        ..remove('syncState')
        ..remove('date');
      Map<String, dynamic> updated;
      try {
        final response = await _api.request(
          'PUT',
          'workedHours/$date',
          body: body,
        );
        if (response['stored'] == true) {
          updated = {
            ...Map<String, dynamic>.from(response['report'] as Map),
            'syncState': 'sent',
          };
        } else {
          updated = {
            ...report,
            'syncState': 'conflict',
            'remote': response['report'],
            'syncError': 'Hay un reporte más reciente en el servidor. Revisa ambas versiones antes de guardar de nuevo.',
          };
        }
      } on ApiException catch (error) {
        if (_transient(error) || error.statusCode == 401) return;
        updated = {
          ...report,
          'syncState': 'failed',
          'syncError': error.message,
        };
      } on FirebaseAuthException {
        return;
      }
      await _store.update((current) {
        final existing = current[date];
        if (existing is Map && existing['savedAt'] == report['savedAt']) {
          current[date] = updated;
        }
      });
    }
  }

  Future<void> useServer(String date) async {
    await synchronize();
    final response = await _api.request('GET', 'workedHours/$date');
    await _store.update((reports) {
      final remote = response['report'];
      reports[date] = remote == null
          ? null
          : {...Map<String, dynamic>.from(remote as Map), 'syncState': 'sent'};
    });
  }

  static String statusLabel(Map<String, dynamic> report) {
    switch (report['syncState']) {
      case 'pending':
        return 'Pendiente de envío';
      case 'conflict':
        return 'Revisar conflicto';
      case 'failed':
        return 'No enviado';
      default:
        return 'Enviado';
    }
  }

  void dispose() {
    _api.dispose();
  }
}
