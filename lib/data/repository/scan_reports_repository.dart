// lib/data/repository/scan_reports_repository.dart
import 'package:front_end_flutter/data/remote/api_client.dart';
import 'package:front_end_flutter/data/repository/reports_repository.dart';

/** Reads the two scanner reports; they share the memory cache of the other admin reports. */
class ScanReportsRepository {
  ScanReportsRepository(this._api);
  final ApiClient _api;

  /** BQ 10: rows read and failures by light, steadiness, torch and auto capture. */
  Future<Map<String, dynamic>> scanQuality({bool force = false}) {
    return ReportsRepository.cache.getOrLoad<Map<String, dynamic>>(
      'escaneo',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'analytics/scan-quality',
          query: {'weeks': '8'},
        );
        if (result['pages'] is! num ||
            result['teachers'] is! num ||
            result['ready'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
    );
  }

  /** BQ 11: what teachers corrected in the rows the scanner read. */
  Future<Map<String, dynamic>> scanReview({bool force = false}) {
    return ReportsRepository.cache.getOrLoad<Map<String, dynamic>>(
      'revision-escaneo',
      () async {
        final Map<String, dynamic> result = await _api.request(
          'GET',
          'analytics/scan-review',
          query: {'weeks': '8'},
        );
        if (result['teachers'] is! num ||
            result['imports'] is! num ||
            result['rowsRead'] is! num ||
            result['bySource'] is! List) {
          throw const ApiException(502, 'El reporte recibido está incompleto.');
        }
        return result;
      },
      force: force,
    );
  }
}
