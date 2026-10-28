import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:front_end_flutter/data/local/grouping_sessions_store.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/remote/api_config.dart';
import 'package:front_end_flutter/domain/model/grouping_session.dart';
import 'package:uuid/uuid.dart';

/** Saves each grouping session on the phone first and sends it to the backend; without network it stays pending. */
class GroupingSessionService {
  GroupingSessionService({
    required String userId,
    ApiClient? api,
    GroupingSessionsStore? store,
    Future<String> Function()? connectivity,
  }) : _api = api ?? ApiClient(),
       _store = store ?? GroupingSessionsStore(userId: userId),
       _connectivity = connectivity ?? _readConnectivity;
  final ApiClient _api;
  final GroupingSessionsStore _store;
  final Future<String> Function() _connectivity;
  Future<void>? _running;

  static Future<String> _readConnectivity() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    return result.contains(ConnectivityResult.none) ? 'offline' : 'online';
  }

  /** Registers the session with the connectivity of this moment and tries to send it. */
  Future<void> register({
    required String schoolId,
    required String subject,
    required String groupName,
    required int studentsCounted,
    required int teachersCounted,
    required int studentsAssigned,
    DateTime? now,
  }) async {
    String connectivity;
    try {
      connectivity = await _connectivity();
    } catch (_) {
      connectivity = 'offline';
    }
    await _store.add(
      GroupingSession(
        clientId: const Uuid().v4(),
        schoolId: schoolId,
        subject: subject,
        groupName: groupName.trim(),
        studentsCounted: studentsCounted,
        teachersCounted: teachersCounted,
        studentsAssigned: studentsAssigned,
        createdAt: now ?? DateTime.now(),
        connectivity: connectivity,
      ),
    );
    await synchronize();
  }

  Future<int> pendingCount() async {
    return (await _store.pending()).length;
  }

  // Evita dos envíos al mismo tiempo: la segunda llamada espera a la primera.
  Future<void> synchronize([DateTime? now]) {
    final Future<void>? running = _running;
    if (running != null) {
      return running;
    }
    final Future<void> current = _send(now).whenComplete(() {
      _running = null;
    });
    _running = current;
    return current;
  }

  Future<void> _send(DateTime? now) async {
    for (final GroupingSession session in await _store.pending()) {
      final GroupingSession attempt = session.copyWith(
        attempts: session.attempts + 1,
      );
      await _store.update(attempt);
      try {
        await _api.request(
          'POST',
          'groupings',
          body: {
            'clientId': attempt.clientId,
            'platform': 'flutter',
            'appVersion': ApiConfig.appVersion,
            'connectivity': attempt.connectivity,
            'createdAt': attempt.createdAt.toUtc().toIso8601String(),
            // El servidor mide la demora con la hora del teléfono al enviar.
            'sentAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
            'attempt': attempt.attempts,
            'schoolId': attempt.schoolId,
            'subject': attempt.subject,
            'groupName': attempt.groupName,
            'studentsCounted': attempt.studentsCounted,
            'teachersCounted': attempt.teachersCounted,
            'studentsAssigned': attempt.studentsAssigned,
          },
        );
        await _store.remove(attempt.clientId);
      } on ApiException catch (error) {
        if (_canRetryLater(error)) {
          // Sin red o con la sesión caída: sigue pendiente y no se insiste ahora.
          return;
        }
        // Un rechazo definitivo (400, 409) no mejora al reintentar.
        await _store.update(attempt.copyWith(failed: true));
      }
    }
  }

  bool _canRetryLater(ApiException error) {
    return error.statusCode == 0 ||
        error.statusCode == 401 ||
        error.statusCode == 403 ||
        error.statusCode == 408 ||
        error.statusCode == 429 ||
        error.statusCode >= 500;
  }
}
