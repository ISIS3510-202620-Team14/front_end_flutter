// lib/data/telemetria/scan_review_log.dart
import 'package:front_end_flutter/data/telemetria/analytics_service.dart';
import 'package:front_end_flutter/domain/model/scan_review.dart';

/** Sends the scan_review event when a scanned list is imported. */
class ScanReviewLog {
  /** Allows the event logger to be replaced in tests. */
  ScanReviewLog({this.logger});
  final Future<void> Function(String, Map<String, Object>)? logger;

  /** Records one import; [source] is a [ScanSource]. A list with no rows sends nothing. */
  Future<void> record(ScanReviewSummary summary, String source) async {
    if (summary.read == 0) return;
    final data = summary.toAnalytics(source);
    if (logger != null) {
      await logger!('scan_review', data);
    } else {
      await AnalyticsService.instance.log('scan_review', data);
    }
  }
}
