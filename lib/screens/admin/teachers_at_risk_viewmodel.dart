import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/local/saved_reports_store.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/domain/model/teacher_at_risk.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';

/**
 * Teachers at risk (BQ 14) with cache then network: the copy saved on the phone shows first,
 * the network answer replaces it, and without internet the saved copy stays with a notice
 * until the connection comes back.
 */
class TeachersAtRiskViewModel extends SafeNotifier {
  TeachersAtRiskViewModel({
    required this.reports,
    required this.store,
    Stream<List<ConnectivityResult>>? connectivity,
  }) {
    _connection = (connectivity ?? Connectivity().onConnectivityChanged).listen(
      _onConnectivity,
    );
  }

  static const String reportKey = 'teachers_at_risk';
  final ReportsRepository reports;
  final SavedReportsStore store;
  late final StreamSubscription<List<ConnectivityResult>> _connection;

  List<TeacherAtRisk> teachers = [];
  String? lastWeek;
  // True when what is on screen is the saved copy and not a fresh answer.
  bool fromSavedCopy = false;
  DateTime? savedAt;
  bool loading = false;
  String? error;
  bool _hasData = false;
  bool _waitingNetwork = false;

  bool get hasData {
    return _hasData;
  }

  /** Shows the saved copy right away and then asks the network. */
  Future<void> start() async {
    final SavedReport? saved = await store.read(reportKey);
    if (saved != null && !_hasData) {
      _show(saved.data);
      fromSavedCopy = true;
      savedAt = saved.savedAt;
      notifyListeners();
    }
    await refresh();
  }

  /** Asks the network; force skips the memory cache (refresh button). */
  Future<void> refresh({bool force = false}) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final Map<String, dynamic> result = await reports.teachersAtRisk(
        force: force,
      );
      _show(result);
      fromSavedCopy = false;
      savedAt = DateTime.now();
      _waitingNetwork = false;
      // Fire and forget: the list is already on screen, so the copy is written in the background.
      _saveCopy(result);
    } catch (failure) {
      // With a list on screen it becomes the saved copy and the notice says so;
      // without one, the error explains why there is nothing.
      _waitingNetwork = true;
      if (_hasData) {
        fromSavedCopy = true;
      } else {
        error = reportErrorMessage(failure);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // One write after another, so two quick refreshes never write at the same time.
  Future<void> _writes = Future<void>.value();

  void _saveCopy(Map<String, dynamic> data) {
    _writes = _writes.then((_) async {
      try {
        await store.save(reportKey, data);
      } catch (error) {
        // A copy that could not be saved only means there is none next time; the screen is fine.
        debugPrint('Teachers at risk copy was not saved: $error');
      }
    });
  }

  void _show(Map<String, dynamic> data) {
    lastWeek = data['lastWeek'] as String?;
    teachers = [
      for (final dynamic row in data['teachers'] as List)
        TeacherAtRisk.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
    _hasData = true;
  }

  /** When the internet comes back after a failed load, it reloads by itself. */
  void _onConnectivity(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) return;
    if (_waitingNetwork) refresh(force: true);
  }

  @override
  void dispose() {
    _connection.cancel();
    super.dispose();
  }
}
