// lib/data/local/report_snapshot_folder.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/** The last answer of one admin report, read from the phone, with the moment it was saved. */
class ReportSnapshot {
  const ReportSnapshot({required this.data, required this.savedAt});
  final Map<String, dynamic> data;
  final DateTime savedAt;
}

/*
  LOCAL STORAGE (Sprint 3 fix) — App-specific files.
  My admin reports (BQ 7, 8, 9, 11, 12) keep their last answer as a private JSON file:
  <app support>/respuestas/<uid>_<report>.json. Private, deleted on uninstall, and it
  survives closing the app. Same folder and write as ArchivoRespuestas in Kotlin.
*/
class ReportSnapshotFolder {
  static const String folder = 'respuestas';

  // Built once and reused for every file name.
  static final RegExp _unsafeCharacters = RegExp(r'[^A-Za-z0-9_-]');

  Future<File> _file(String uid, String report) async {
    final Directory support = await getApplicationSupportDirectory();
    final Directory dir = Directory('${support.path}/$folder');
    await dir.create(recursive: true);
    final String name = '${uid}_$report'.replaceAll(_unsafeCharacters, '_');
    return File('${dir.path}/$name.json');
  }

  /** Writes a .tmp file first and then renames it, so a crash never leaves half a JSON. */
  Future<void> save(
    String uid,
    String report,
    Map<String, dynamic> data,
  ) async {
    final File target = await _file(uid, report);
    final File temporary = File('${target.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      }),
      flush: true,
    );
    await temporary.rename(target.path);
    _log('guardado en ${target.path}');
  }

  /** Returns null if this account has no file for the report yet, or if the file is not valid JSON. */
  Future<ReportSnapshot?> read(String uid, String report) async {
    final File file = await _file(uid, report);
    if (!await file.exists()) return null;
    try {
      final Map<String, dynamic> json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final ReportSnapshot snapshot = ReportSnapshot(
        data: Map<String, dynamic>.from(json['data'] as Map),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
      _log('leído de ${file.path} (guardado ${snapshot.savedAt.toLocal()})');
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  /** Console proof for the demo (flutter run on the iPhone); silent in release builds. */
  static void _log(String message) {
    if (!kReleaseMode) debugPrint('[archivos] $message');
  }
}
