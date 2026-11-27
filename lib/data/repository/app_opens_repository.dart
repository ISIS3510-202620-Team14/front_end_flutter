import 'package:front_end_flutter/data/remote/api_config.dart';
import 'package:front_end_flutter/domain/model/app_open.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/local/app_opens_store.dart';
import 'package:front_end_flutter/ui/theme/app_date.dart';

/** Saves each open on the phone first, then sends it to the backend; without network it stays pending. */
class AppOpensRepository {
  AppOpensRepository({
    required String userId,
    ApiClient? api,
    AppOpensStore? store,
  }) : _api = api ?? ApiClient(),
       _store = store ?? AppOpensStore(userId: userId);
  final ApiClient _api;
  final AppOpensStore _store;
  // El backend acepta hasta 200 aperturas por solicitud.
  static const int batchSize = 200;
  Future<void>? _running;

  /** Saves the open on the phone only; sending it is a separate step so the screen does not wait for the network. */
  Future<void> recordOpen([DateTime? now]) async {
    await _store.register(now ?? DateTime.now());
  }

  Future<void> registerOpen([DateTime? now]) async {
    await recordOpen(now);
    await synchronize();
  }

  Future<int> weeklyCount([DateTime? now]) {
    return _store.countInWeek(AppDate.mondayOfWeek(now ?? DateTime.now()));
  }

  /** Opens per complete week before the current one, oldest first, read from the phone. */
  Future<List<int>> completedWeeksOpens(int weeks, [DateTime? now]) async {
    final DateTime moment = now ?? DateTime.now();
    return [
      for (int back = weeks; back >= 1; back--)
        await _store.countInWeek(
          AppDate.mondayOfWeek(moment.subtract(Duration(days: 7 * back))),
        ),
    ];
  }

  /**
   * What the weekly card needs, from one read of the saved list: this week's opens, the opens
   * waiting to be sent and the opens of the complete weeks before this one (oldest first).
   * Asking each one separately read and decoded the whole list again every time.
   */
  Future<({int thisWeek, int pending, List<int> completedWeeks})> weekSummary(
    int weeks, [
    DateTime? now,
  ]) async {
    final DateTime moment = now ?? DateTime.now();
    final List<AppOpen> opens = await _store.read();
    final Map<String, int> perWeek = {};
    int pending = 0;
    for (final AppOpen open in opens) {
      perWeek[open.week] = (perWeek[open.week] ?? 0) + 1;
      if (!open.sent) pending++;
    }
    return (
      thisWeek: perWeek[AppDate.mondayOfWeek(moment)] ?? 0,
      pending: pending,
      completedWeeks: [
        for (int back = weeks; back >= 1; back--)
          perWeek[AppDate.mondayOfWeek(
                moment.subtract(Duration(days: 7 * back)),
              )] ??
              0,
      ],
    );
  }

  Future<int> pendingCount() async {
    return (await _store.pending()).length;
  }

  // Evita dos envíos al mismo tiempo: la segunda llamada espera a la primera.
  Future<void> synchronize() {
    final Future<void>? running = _running;
    if (running != null) {
      return running;
    }
    final Future<void> current = _send().whenComplete(() {
      _running = null;
    });
    _running = current;
    return current;
  }

  Future<void> _send() async {
    final List<AppOpen> pending = await _store.pending();
    for (int start = 0; start < pending.length; start += batchSize) {
      final List<AppOpen> batch = pending.skip(start).take(batchSize).toList();
      try {
        await _api.request(
          'POST',
          'appOpens',
          body: {
            'opens': [
              for (final AppOpen open in batch)
                {
                  'clientId': open.clientId,
                  'openedAt': open.openedAt.toUtc().toIso8601String(),
                  'week': open.week,
                  'platform': 'flutter',
                  'appVersion': ApiConfig.appVersion,
                },
            ],
          },
        );
      } on ApiException catch (error) {
        if (_canRetryLater(error)) {
          // Sin red o con la sesión caída: las aperturas siguen pendientes.
          return;
        }
        // Un rechazo definitivo (400, 409) no mejora al reintentar: se descarta.
      }
      await _store.markSent({for (final AppOpen open in batch) open.clientId});
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
