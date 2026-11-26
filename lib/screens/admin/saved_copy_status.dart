import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/local/saved_reports_store.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Store of the signed in account; it falls back when Firebase is not available (tests). */
SavedReportsStore savedReportsStoreOfSession() {
  String userId = 'sin-sesion';
  try {
    userId = FirebaseAuth.instance.currentUser?.uid ?? userId;
  } catch (_) {
    // No Firebase: the copy is kept under a neutral key.
  }
  return SavedReportsStore(userId: userId);
}

/** Tells the admin where the data of a report comes from, so a saved copy is never taken as current. */
class SavedCopyStatus extends StatelessWidget {
  const SavedCopyStatus({
    super.key,
    required this.loading,
    required this.showingSavedCopy,
    this.savedAt,
  });
  final bool loading;
  final bool showingSavedCopy;
  final DateTime? savedAt;

  String _when(DateTime moment) {
    final DateTime local = moment.toLocal();
    final String hour =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${local.day}/${local.month} a las $hour';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ReportPill(
        text: 'Actualizando…',
        background: AppTheme.pendingBackground,
        color: AppTheme.pendingText,
      );
    }
    if (showingSavedCopy) {
      return ReportPill(
        text: savedAt == null
            ? 'No se pudo actualizar · datos guardados'
            : 'No se pudo actualizar · datos guardados el ${_when(savedAt!)}',
        background: AppTheme.amberBackground,
        color: AppTheme.amberText,
      );
    }
    return const ReportPill(
      text: 'Conectado',
      background: AppTheme.assessedBackground,
      color: AppTheme.assessedText,
    );
  }
}

/** Calls [onReconnect] when the internet comes back, only after a load failed. */
class ReconnectWatcher {
  ReconnectWatcher({required this.onReconnect, Stream<List<ConnectivityResult>>? changes}) {
    _subscription = (changes ?? Connectivity().onConnectivityChanged).listen((
      List<ConnectivityResult> result,
    ) {
      if (!waiting || result.contains(ConnectivityResult.none)) return;
      waiting = false;
      onReconnect();
    });
  }

  final VoidCallback onReconnect;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  // Set to true when a load fails; the next connection reloads once.
  bool waiting = false;

  void dispose() {
    _subscription.cancel();
  }
}
