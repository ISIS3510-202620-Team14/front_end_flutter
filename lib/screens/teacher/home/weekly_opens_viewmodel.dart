import 'dart:async';

import 'package:front_end_flutter/data/repository/app_opens_repository.dart';
import 'package:front_end_flutter/data/telemetria/analytics_service.dart';
import 'package:front_end_flutter/domain/model/engagement_risk.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

/** Registers this session's open and exposes the weekly count against the goal of two. */
class WeeklyOpensViewModel extends SafeNotifier {
  WeeklyOpensViewModel({required this.repository});
  final AppOpensRepository repository;
  static const int goal = 2;
  int count = 0;
  int pending = 0;
  bool loading = false;
  // False until the first read of the phone ends, so the card does not show a made-up 0.
  bool loaded = false;
  bool _started = false;
  // Type 5 BQ: whether the opens are dropping, so Hoy shows the card to come back.
  EngagementRisk risk = EngagementRisk.none;
  bool _riskLogged = false;
  bool dismissedRisk = false;

  bool get reachedGoal {
    return count >= goal;
  }

  String get message {
    if (reachedGoal) {
      return 'Meta cumplida. Gracias por mantener al día a tus estudiantes.';
    }
    final int missing = goal - count;
    if (missing == 1) {
      return 'Vuelve a abrir la app una vez más esta semana para seguir el avance de tus estudiantes.';
    }
    return 'Abre la app $missing veces esta semana para seguir el avance de tus estudiantes.';
  }

  // Registra la apertura de esta sesión una sola vez y actualiza el conteo.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    loading = true;
    notifyListeners();
    try {
      await repository.recordOpen();
    } catch (_) {
      // Si falla guardar, la tarjeta muestra lo que haya en el teléfono.
    }
    await _refresh();
    // Fire and forget: the count is already on screen, the send (up to 20 s without
    // signal) goes on in the background and only updates the pending number when it ends.
    unawaited(_sendInBackground());
  }

  Future<void> _sendInBackground() async {
    try {
      await repository.synchronize();
    } catch (_) {
      // A failed send stays pending on the phone and is tried again later.
    }
    if (!disposed) await _refresh();
  }

  Future<void> retrySync() async {
    try {
      await repository.synchronize();
    } catch (_) {}
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      // One read of the saved list for the three numbers.
      final summary = await repository.weekSummary(
        EngagementRisk.baselineWeeks + 1,
      );
      count = summary.thisWeek;
      pending = summary.pending;
      risk = EngagementRisk.fromWeeklyOpens(summary.completedWeeks);
      _logRisk();
    } catch (_) {
      // Sin lectura local no hay nada que mostrar: se conserva el último valor.
    }
    loading = false;
    loaded = true;
    notifyListeners();
  }

  /** The re-engagement card is shown at most once per session in analytics. */
  void _logRisk() {
    if (!risk.atRisk || _riskLogged) return;
    _riskLogged = true;
    _track('reengagement_card_shown');
  }

  void _track(String name) {
    AnalyticsService.instance
        .log(name, {
          'lastWeekOpens': risk.lastWeek,
          'usualWeekOpens': risk.usualWeek,
        })
        .catchError((Object _) {});
  }

  /** The teacher used the card: hide it for this session and record it. */
  void acceptRisk() {
    _track('reengagement_card_used');
    dismissRisk();
  }

  void dismissRisk() {
    dismissedRisk = true;
    notifyListeners();
  }

  bool get showsRisk {
    return risk.atRisk && !dismissedRisk;
  }
}
