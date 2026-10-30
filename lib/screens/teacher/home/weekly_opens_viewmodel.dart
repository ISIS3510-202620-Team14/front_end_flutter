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
      await repository.registerOpen();
    } catch (_) {
      // Si falla guardar o enviar, la tarjeta muestra lo que haya en el teléfono.
    }
    await _refresh();
  }

  Future<void> retrySync() async {
    try {
      await repository.synchronize();
    } catch (_) {}
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      count = await repository.weeklyCount();
      pending = await repository.pendingCount();
      risk = EngagementRisk.fromWeeklyOpens(
        await repository.completedWeeksOpens(EngagementRisk.baselineWeeks + 1),
      );
      _logRisk();
    } catch (_) {
      // Sin lectura local no hay nada que mostrar: se conserva el último valor.
    }
    loading = false;
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
