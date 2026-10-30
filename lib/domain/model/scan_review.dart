// lib/domain/model/scan_review.dart
import 'package:front_end_flutter/domain/model/scanned_row.dart';

/** Where the scanner was opened from; same keys as the Kotlin app. */
class ScanSource {
  static const attendance = 'attendance';
  static const manageStudents = 'manage_students';
}

/**
 * BQ 11: how much the teacher corrected what the scanner read before importing.
 * Only counts: a name or a code never leaves the phone.
 */
class ScanReviewSummary {
  const ScanReviewSummary({
    required this.read,
    required this.unchanged,
    required this.edited,
    required this.namesEdited,
    required this.codesEdited,
    required this.deleted,
  });
  final int read;
  final int unchanged;
  final int edited;
  final int namesEdited;
  final int codesEdited;
  final int deleted;

  /** Fields of the scan_review event; [source] is a [ScanSource]. */
  Map<String, Object> toAnalytics(String source) {
    return {
      'source': source,
      'rowsRead': read,
      'rowsUnchanged': unchanged,
      'rowsEdited': edited,
      'namesEdited': namesEdited,
      'codesEdited': codesEdited,
      'rowsDeleted': deleted,
    };
  }
}

/** Keeps what the scanner read next to what the teacher left, one entry per row id. */
class ScanReview {
  final Map<int, _Fields> _read = {};
  final Map<int, _Fields> _current = {};
  int _deleted = 0;

  /** A row the scanner just read. */
  void read(int id, ScannedRow row) {
    _read[id] = _Fields(row);
    _current[id] = _Fields(row);
  }

  /** The row as the teacher left it after an edit. */
  void update(int id, ScannedRow row) {
    if (_current.containsKey(id)) {
      _current[id] = _Fields(row);
    }
  }

  /** The teacher removed the row. */
  void discard(int id) {
    if (_current.remove(id) != null) {
      _deleted++;
    }
  }

  /** Counts for the import that is about to happen. */
  ScanReviewSummary get summary {
    var names = 0;
    var codes = 0;
    var edited = 0;
    _current.forEach((id, now) {
      final before = _read[id]!;
      final nameChanged = before.name != now.name;
      final codeChanged = before.code != now.code;
      if (nameChanged) names++;
      if (codeChanged) codes++;
      if (nameChanged || codeChanged) edited++;
    });
    return ScanReviewSummary(
      read: _current.length + _deleted,
      unchanged: _current.length - edited,
      edited: edited,
      namesEdited: names,
      codesEdited: codes,
      deleted: _deleted,
    );
  }
}

/** Name and code compared as they are imported: trimmed, and an empty code is "no code". */
class _Fields {
  _Fields(ScannedRow row) : name = _clean(row.name), code = _clean(row.code);
  final String? name;
  final String? code;

  static String? _clean(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
