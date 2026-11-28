// lib/screens/admin/levels/level_map_viewmodel.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_end_flutter/data/repository/levels_repository.dart';
import 'package:front_end_flutter/domain/model/school_levels.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LevelsStatus { loading, updating, online, offline, empty }

/*
  EVENTUAL CONNECTIVITY (Sprint 4) — strategy 1 (cache, falling back to network) and
  strategy 6 (generic fallback). SQLite shows first; the network is used only for expired
  cache files (30 min) or a pull to refresh. Checks the connection first, then 
  marks institutions that did not update (#4) and offers "Actualizar" when the internet
  comes back, so the admin decides when to spend data.
*/
class LevelMapViewModel extends SafeNotifier {
  LevelMapViewModel({
    LevelsRepository? repository,
    Stream<List<ConnectivityResult>>? connectivity,
  }) {
    _repository = repository ?? LevelsRepository(onLog: addLog);
    _network = (connectivity ?? Connectivity().onConnectivityChanged).listen(
      _onNetwork,
    );
  }

  late final LevelsRepository _repository;
  late final StreamSubscription<List<ConnectivityResult>> _network;

  /** Every step of the load; the view shows it in developer mode. */
  final List<String> logs = [];

  void addLog(String message) {
    final DateTime now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    logs.add(
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}  $message',
    );
  }

  String subject = 'lectura';
  int grade = 0; // 0 = all grades
  List<LevelRow> rows = const [];
  LevelsStatus status = LevelsStatus.loading;
  int done = 0;
  int total = 0;
  int failed = 0;
  bool connectionBack = false;
  DateTime? lastAttempt;

  String get _uid {
    return FirebaseAuth.instance.currentUser?.uid ?? 'sin-sesion';
  }

  String get _subjectKey {
    return 'niveles_materia_$_uid';
  }

  String get _gradeKey {
    return 'niveles_grado_$_uid';
  }

  Future<void> start() async {
    // LOCAL STORAGE (Sprint 4): SharedPreferences keeps the admin's last filter.
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    subject = preferences.getString(_subjectKey) ?? 'lectura';
    grade = preferences.getInt(_gradeKey) ?? 0;
    addLog('SharedPreferences: filtro guardado = $subject, grado $grade');
    await _show();
    if (await _online()) {
      await refresh();
    } else {
      addLog('Sin conexión: se muestra lo guardado en SQLite');
      status = rows.isEmpty ? LevelsStatus.empty : LevelsStatus.offline;
      notifyListeners();
    }
  }

  Future<void> choose({String? subject, int? grade}) async {
    this.subject = subject ?? this.subject;
    this.grade = grade ?? this.grade;
    await _show();
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_subjectKey, this.subject);
    await preferences.setInt(_gradeKey, this.grade);
  }

  /** force = true skips the cache files (pull to refresh). */
  Future<void> refresh({bool force = false}) async {
    if (status == LevelsStatus.updating) return;
    if (!await _online()) {
      addLog('Actualizar sin conexión: no se lanza ninguna petición');
      status = rows.isEmpty ? LevelsStatus.empty : LevelsStatus.offline;
      notifyListeners();
      return;
    }
    addLog(force ? 'Actualizar (pull): se salta la caché' : 'Actualizar');
    status = LevelsStatus.updating;
    connectionBack = false;
    done = 0;
    failed = 0;
    notifyListeners();
    try {
      final LevelsDownload result = await _repository.download(
        _uid,
        force: force,
        onProgress: (int done, int total) {
          this.done = done;
          this.total = total;
          _show(); // each institution appears as soon as it is ready
        },
      );
      failed = result.failed;
      lastAttempt = result.startedAt;
      await _show();
      if (rows.isEmpty) {
        status = LevelsStatus.empty;
      } else if (result.total > 0 && result.failed == result.total) {
        status = LevelsStatus.offline;
      } else {
        status = LevelsStatus.online;
      }
    } catch (_) {
      status = rows.isEmpty ? LevelsStatus.empty : LevelsStatus.offline;
    }
    notifyListeners();
  }

  Future<void> _show() async {
    rows = await _repository.rows(_uid, subject, grade);
    notifyListeners();
  }

  void _onNetwork(List<ConnectivityResult> network) {
    final bool online = !network.contains(ConnectivityResult.none);
    if (online &&
        (status == LevelsStatus.offline || status == LevelsStatus.empty)) {
      addLog('Conectividad: volvió la conexión');
      connectionBack = true;
      notifyListeners();
    }
  }

  Future<bool> _online() async {
    try {
      final List<ConnectivityResult> network = await Connectivity()
          .checkConnectivity();
      return !network.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /** An institution whose data is older than the last attempt did not update. */
  bool isStale(LevelRow row) {
    final DateTime? attempt = lastAttempt;
    return attempt != null && row.savedAt.isBefore(attempt);
  }

  int get assessed {
    int sum = 0;
    for (int i = 0; i < rows.length; i++) {
      sum += rows[i].assessed;
    }
    return sum;
  }

  int get beginners {
    int sum = 0;
    for (int i = 0; i < rows.length; i++) {
      sum += rows[i].beginners;
    }
    return sum;
  }

  /** Rows are sorted by support needed, so the first one answers the BQ. */
  LevelRow? get needsMostSupport {
    if (rows.isEmpty || rows.first.beginnerShare == null) return null;
    return rows.first;
  }

  /** Oldest saved institution: the date shown in the offline banner. */
  DateTime? get savedAt {
    DateTime? oldest;
    for (final LevelRow row in rows) {
      if (oldest == null || row.savedAt.isBefore(oldest)) oldest = row.savedAt;
    }
    return oldest;
  }

  @override
  void dispose() {
    // MICRO-OPT / lifecycle: no listener or HTTP client stays alive after the screen.
    _network.cancel();
    _repository.dispose();
    super.dispose();
  }
}
