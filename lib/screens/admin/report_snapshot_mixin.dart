// lib/screens/admin/report_snapshot_mixin.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/repository/report_loader.dart';
import 'package:front_end_flutter/domain/model/saved_data.dart';
import 'package:front_end_flutter/screens/admin/report_message.dart';
import 'package:front_end_flutter/ui/components/offline_notice.dart';

/*
  EVENTUAL CONNECTIVITY (Sprint 3 fix) — shared by my reports BQ 7, 8, 9, 11 and 12.
  Shows the saved copy with its date and, when the internet comes back, tells the user
  and reloads the report (anti-pattern #7).
*/
mixin ReportSnapshotMixin<T extends StatefulWidget> on State<T> {
  final ReportLoader _reportLoader = ReportLoader();
  late final StreamSubscription<List<ConnectivityResult>> _network;
  bool _waitingForNetwork = false;
  ReportSource? _source;
  DateTime? _savedAt;

  /** Each report reloads itself from the network (force: true). */
  void reloadReport();

  @override
  void initState() {
    super.initState();
    _network = Connectivity().onConnectivityChanged.listen(_onNetwork);
  }

  @override
  void dispose() {
    _network.cancel();
    super.dispose();
  }

  void _onNetwork(List<ConnectivityResult> result) {
    if (!_waitingForNetwork || result.contains(ConnectivityResult.none)) return;
    _waitingForNetwork = false;
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Volvió la conexión. Actualizando el reporte…'),
      ),
    );
    reloadReport();
  }

  /** Network or saved copy; each report keeps its own setState. */
  Future<Map<String, dynamic>> loadReport(
    String report,
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    try {
      final ReportResult result = await _reportLoader.load(report, fetch);
      _source = result.source;
      _savedAt = result.savedAt;
      _waitingForNetwork = result.source == ReportSource.saved;
      return result.data;
    } catch (error) {
      _source = null;
      _waitingForNetwork = true;
      rethrow;
    }
  }

  /** Specific message when there is no copy which resolves the non-informative anti-pattern. */
  String reportError(Object error) {
    if (error is ReportUnavailable) return error.message;
    return reportErrorMessage(error);
  }

  /** Notice shown only while the saved copy is on screen. */
  Widget snapshotNotice() {
    final DateTime? savedAt = _savedAt;
    if (_source != ReportSource.saved || savedAt == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OfflineNotice(
        messages: [
          'Sin conexión. Datos guardados ${SavedData.when(savedAt)}.',
          'Se actualizará solo cuando vuelva internet.',
        ],
        onRefresh: reloadReport,
      ),
    );
  }
}
