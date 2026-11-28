// lib/data/repository/report_loader.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/data/local/report_snapshot_folder.dart';
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';
import 'package:front_end_flutter/data/repository/scan_reports_repository.dart';

/** File names of the five admin reports. */
class MyReports {
  static const String classification = 'bq7_clasificacion';
  static const String scanQuality = 'bq8_escaneo';
  static const String scanReview = 'bq9_revision';
  static const String activities = 'bq11_actividades';
  static const String assessments = 'bq12_evaluaciones';
}

/** Where the report on screen came from. */
enum ReportSource { network, saved }

class ReportResult {
  const ReportResult(this.data, this.source, {this.savedAt});
  final Map<String, dynamic> data;
  final ReportSource source;
  final DateTime? savedAt;
}

/** Thrown when there is no internet (or the request failed) and the phone has no copy. */
class ReportUnavailable implements Exception {
  const ReportUnavailable({required this.offline});
  final bool offline;

  String get message {
    if (offline) {
      return 'Sin conexión. Este reporte todavía no está guardado en este celular: '
          'ábrelo una vez con internet para poder verlo después sin conexión.';
    }
    return 'No pudimos actualizar el reporte y no hay una copia guardada. Intenta de nuevo.';
  }

  @override
  String toString() {
    return message;
  }
}

/*
  EVENTUAL CONNECTIVITY (Sprint 3 fix) — strategy 3: network falling back to cache.
  Checks the connection first , saves each answer on the phone, shows the
  saved copy offline or when the request fails, and a specific message if there is none.
*/
class ReportLoader {
  ReportLoader({ReportSnapshotFolder? files})
    : _files = files ?? ReportSnapshotFolder();
  final ReportSnapshotFolder _files;

  String get _uid {
    return FirebaseAuth.instance.currentUser?.uid ?? 'sin-sesion';
  }

  Future<ReportResult> load(
    String report,
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    final String uid = _uid;
    if (!await _online()) {
      return _fromFile(uid, report, offline: true);
    }
    final Map<String, dynamic> data;
    try {
      data = await fetch();
    } catch (error) {
      // A rejection (no permission, expired session) is not a connectivity problem.
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        rethrow;
      }
      return _fromFile(uid, report, offline: false);
    }
    // MULTITHREADING (Sprint 3 fix): then is a non-blocking option,
    // so the report is shown right away and the file is written when the main thread is free.
    final Stopwatch watch = Stopwatch()..start();
    _files
        .save(uid, report, data)
        .then((_) {
          _log('$report guardado en ${watch.elapsedMilliseconds} ms');
        })
        .catchError((Object error) {
          _log('$report no se pudo guardar: $error');
        });
    return ReportResult(data, ReportSource.network);
  }

  Future<ReportResult> _fromFile(
    String uid,
    String report, {
    required bool offline,
  }) async {
    final ReportSnapshot? saved = await _files.read(uid, report);
    if (saved == null) throw ReportUnavailable(offline: offline);
    return ReportResult(saved.data, ReportSource.saved, savedAt: saved.savedAt);
  }

  static Future<bool> _online() async {
    try {
      final List<ConnectivityResult> network = await Connectivity()
          .checkConnectivity();
      return !network.contains(ConnectivityResult.none);
    } catch (_) {
      // If the plugin fails we still try the network; the request decides.
      return true;
    }
  }

  /*
    MULTITHREADING (Sprint 3 fix) — a chain of Futures with then / catchError.
    When the admin portal opens, the five reports are downloaded one after another and saved.
    Nobody waits for the chain, and catchError lets the next report go on if one fails.
    Returns how many reports came from the network.
  */
  static Future<int> prefetchMine() {
    final ApiClient api = ApiClient(localFirst: false);
    final ReportsRepository reports = ReportsRepository(api);
    final ScanReportsRepository scans = ScanReportsRepository(api);
    final ReportLoader loader = ReportLoader();
    final Stopwatch watch = Stopwatch()..start();
    int saved = 0;

    Future<void> next(
      String report,
      Future<Map<String, dynamic>> Function() fetch,
    ) {
      return loader
          .load(report, fetch)
          .then((ReportResult result) {
            if (result.source == ReportSource.network) saved++;
            _log('precarga $report: ${result.source.name}');
          })
          .catchError((Object error) {
            _log('precarga $report: falló ($error)');
          });
    }

    return next(
          '${MyReports.classification}_todas',
          () => reports.classification(),
        )
        .then((_) => next(MyReports.scanQuality, () => scans.scanQuality()))
        .then((_) => next(MyReports.scanReview, () => scans.scanReview()))
        .then((_) => next(MyReports.activities, () => reports.topActivities()))
        .then(
          (_) =>
              next(MyReports.assessments, () => reports.assessmentsByGrade()),
        )
        .then((_) {
          api.dispose();
          _log(
            'precarga: $saved de 5 reportes en ${watch.elapsedMilliseconds} ms',
          );
          return saved;
        });
  }

  static void _log(String message) {
    if (!kReleaseMode) debugPrint('[reportes] $message');
  }
}
