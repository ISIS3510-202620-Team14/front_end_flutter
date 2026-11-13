// lib/data/ocr/student_list_scanner.dart
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:front_end_flutter/domain/model/capture_conditions.dart';
import 'package:front_end_flutter/domain/model/scanned_row.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../telemetria/analytics_service.dart';

/** Reads each captured page locally; the photo itself comes from CameraCaptureView. */
class StudentListScanner {
  /** Allows an event logger to be replaced in tests. */
  StudentListScanner({this.logger});
  final Future<void> Function(String, Map<String, Object>)? logger;
  final Set<String> _photos = {};
  final Set<String> _reading = {};
  bool _closed = false;
  String _appVersion = 'unknown';
  static const _channel = MethodChannel('enad/scanner');
  final String _session = const Uuid().v4();

  /** Marks a photo as owned by this scan, to delete it when closing. */
  void own(String path) {
    _photos.add(path);
    if (_closed) unawaited(_delete(path));
  }

  /** Reads a page and parses plain data on a worker isolate. */
  Future<List<ScannedRow>> read(
    String path,
    int page,
    CaptureConditions conditions,
  ) async {
    if (_closed) return [];
    _reading.add(path);
    final watch = Stopwatch()..start();
    var ocrMs = 0;
    var parseMs = 0;
    var rows = <ScannedRow>[];
    var status = 'error';
    try {
      final lines = await _recognize(path, page);
      ocrMs = watch.elapsedMilliseconds;
      if (_closed) return [];
      // # multithreading: worker parsing mirrors Santiago Quiroz's OCR pipeline.
      // # micro opt
      rows = await compute(
        parseLines,
        lines,
        debugLabel: 'scanner-parser-$page',
      );
      parseMs = watch.elapsedMilliseconds - ocrMs;
      status = rows.isEmpty ? 'empty' : 'ready';
      return _closed ? [] : rows;
    } finally {
      _reading.remove(path);
      if (_closed) {
        await _delete(path);
      } else {
        final data = <String, Object>{
          'appVersion': _appVersion,
          'page': page,
          'status': status,
          'ocrMs': ocrMs,
          'parseMs': parseMs,
          'totalMs': watch.elapsedMilliseconds,
          'rows': rows.length,
          ...conditions.toAnalytics(),
        };
        await _log('scanner_page_processed', data);
        // Same events and fields that EventosEscaneo.kt: is the one that reads the report
        // "Escaneo" of the admin (BQ 10). A failed OCR counts as a page with no rows, and
        // ocrMs is the total time of the page (OCR plus parser), as in Kotlin.
        await _log('scan_page', {
          'rows': rows.length,
          'ocrFailed': status == 'error',
          'ocrMs': watch.elapsedMilliseconds,
          ...conditions.toAnalytics(),
        });
      }
    }
  }

  /** Sends an analytics event; a failed log never breaks the scan. */
  Future<void> _log(String name, Map<String, Object> data) async {
    try {
      if (logger != null) {
        await logger!(name, data);
      } else {
        await AnalyticsService.instance.log(name, data);
      }
    } catch (_) {}
  }

  /** Keeps Android image decoding off the native UI thread. */
  Future<List<({String text, double left, double top, double bottom})>>
  _recognize(String path, int page) async {
    if (Platform.isAndroid) {
      final response = await _channel.invokeMapMethod<String, dynamic>('read', {
        'session': _session,
        'path': path,
        'page': page,
      });
      _appVersion = response?['appVersion'] as String? ?? 'unknown';
      final raw = response?['lines'] as List?;
      return [
        for (final item in raw ?? [])
          (
            text: item['text'] as String,
            left: (item['left'] as num).toDouble(),
            top: (item['top'] as num).toDouble(),
            bottom: (item['bottom'] as num).toDouble(),
          ),
      ];
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            for (final word in line.elements)
              (
                text: word.text,
                left: word.boundingBox.left,
                top: word.boundingBox.top,
                bottom: word.boundingBox.bottom,
              ),
      ];
    } finally {
      await recognizer.close();
    }
  }

  /** Stops accepting work and removes unused photos. */
  Future<void> close() async {
    _closed = true;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('close', {'session': _session});
      } catch (_) {}
    }
    for (final path in _photos.toList()) {
      if (!_reading.contains(path)) await _delete(path);
    }
  }

  /** Removes only a photo owned by this scanner. */
  Future<void> _delete(String path) async {
    if (!_photos.remove(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // # micro opt
  static final _spaces = RegExp(r'\s+');
  static final _code = RegExp(
    r'^(?=[A-Z0-9-]*[0-9])[A-Z0-9][A-Z0-9-]{1,19}$',
    caseSensitive: false,
  );
  static final _person = RegExp(
    r"^[A-Za-zÁÉÍÓÚÑÜáéíóúñü]+(?:[-’'][A-Za-zÁÉÍÓÚÑÜáéíóúñü]+)*$",
  );
  static final _marks = RegExp(r'[\u0300-\u036f]');

  /** Reads cells below the printed header, using the column positions on this page. */
  static List<ScannedRow> parseLines(
    List<({String text, double left, double top, double bottom})> source,
  ) {
    final words =
        source
            .where(
              (w) =>
                  w.left.isFinite &&
                  w.top.isFinite &&
                  w.bottom.isFinite &&
                  w.bottom > w.top &&
                  w.text.trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) => (a.top + a.bottom).compareTo(b.top + b.bottom));
    if (words.isEmpty) return [];
    final heights = words.map((w) => w.bottom - w.top).toList()..sort();
    final tolerance = heights[heights.length ~/ 2] * .65;
    // Column titles provide a baseline even when the photograph is tilted.
    final gradeTitles = words.where((w) => _column(w.text) == 'grade');
    final nameTitles = words.where((w) => _column(w.text) == 'name');
    var slope = 0.0;
    baseline:
    for (final grade in gradeTitles) {
      for (final name in nameTitles) {
        final dx = grade.left - name.left;
        if (dx.abs() < tolerance * 4) continue;
        final candidate =
            (grade.top + grade.bottom - name.top - name.bottom) / (2 * dx);
        if (candidate.abs() <= .18) {
          slope = candidate;
          break baseline;
        }
      }
    }
    double level(({String text, double left, double top, double bottom}) word) {
      return (word.top + word.bottom) / 2 - slope * word.left;
    }

    words.sort((a, b) => level(a).compareTo(level(b)));
    final lines =
        <List<({String text, double left, double top, double bottom})>>[];
    var center = double.negativeInfinity;
    for (final word in words) {
      final y = level(word);
      if (y - center > tolerance) {
        lines.add([]);
        center = y;
      }
      lines.last.add(word);
    }
    var columns = <({String key, double left})>[];
    final result = <ScannedRow>[];
    for (final line in lines) {
      line.sort((a, b) => a.left.compareTo(b.left));
      final titles = <String, double>{};
      for (final word in line) {
        final key = _column(word.text);
        if (key != null) titles.putIfAbsent(key, () => word.left);
      }
      // A damaged code heading can split into "C" and digits. Accept it only
      // between the name and grade headings, above two aligned student codes.
      if (titles.containsKey('name') &&
          titles.containsKey('grade') &&
          !titles.containsKey('code')) {
        for (final w in line) {
          if (!w.text.toLowerCase().startsWith('c') ||
              w.left <= titles['name']! ||
              w.left >= titles['grade']!)
            continue;
          final aligned = words.where(
            (item) =>
                item.top > w.bottom &&
                (item.left - w.left).abs() < tolerance * 2 &&
                _code.hasMatch(item.text) &&
                item.text.length >= 4,
          );
          if (aligned.take(2).length == 2) {
            titles['code'] = w.left;
            break;
          }
        }
      }
      if (titles.containsKey('name') &&
          titles.containsKey('grade') &&
          titles.containsKey('code')) {
        columns = [for (final t in titles.entries) (key: t.key, left: t.value)]
          ..sort((a, b) => a.left.compareTo(b.left));
        continue;
      }
      if (columns.isEmpty) continue;
      if (line
          .map((w) => w.text.toLowerCase())
          .join(' ')
          .contains('fin de lista')) {
        columns.clear();
        continue;
      }
      final cells = <String, List<String>>{};
      final margin = heights[heights.length ~/ 2] * .8;
      for (final word in line) {
        final index = columns.lastIndexWhere(
          (column) => word.left >= column.left - margin,
        );
        if (index < 0 && (word.left - columns.first.left).abs() > margin * 4)
          continue;
        final column = columns[index < 0 ? 0 : index];
        if (column.key == 'sex' && word.left > column.left + margin * 3)
          continue;
        cells.putIfAbsent(column.key, () => []).add(word.text.trim());
      }
      final code = cells['code']?.join() ?? '';
      final names = (cells['name']?.join(' ') ?? '').split(_spaces);
      final grade = int.tryParse(cells['grade']?.join() ?? '');
      final ageText = cells['age']?.join() ?? '';
      final age = int.tryParse(ageText);
      final sex = cells['sex']?.join().toUpperCase() ?? '';
      if ((code.isNotEmpty && !_code.hasMatch(code)) ||
          names.length < 2 ||
          !names.every(_person.hasMatch) ||
          grade == null ||
          grade < 3 ||
          grade > 5 ||
          (ageText.isNotEmpty && (age == null || age < 5 || age > 18)) ||
          !{'', 'F', 'M'}.contains(sex)) {
        continue;
      }
      result.add(
        ScannedRow(
          names.join(' '),
          code: code,
          grade: grade,
          age: age,
          sex: sex,
        ),
      );
    }
    return result;
  }

  /** Maps printed column headings to editable fields. */
  static String? _column(String text) {
    final label = text.trim().toLowerCase().replaceAll('ó', 'o');
    return switch (label) {
      'nombre' ||
      'nombres' ||
      'nombre y apellidos' ||
      'apellido' ||
      'apellidos' ||
      'estudiante' => 'name',
      'codigo' => 'code',
      'grado' || 'graöo' || 'gra0o' => 'grade',
      'edad' || 'ed•d' => 'age',
      'sexo' => 'sex',
      'asistencia' => 'attendance',
      _ => null,
    };
  }

  /** Uses the code, or a normalized name when no code exists. */
  static String rowKey(ScannedRow row) {
    if (row.code.trim().isNotEmpty) return 'code:${row.code.trim()}';
    var name = row.name.trim().toLowerCase().replaceAll(_marks, '');
    const accented = 'áàâäãåéèêëíìîïóòôöõúùûüñç';
    const plain = 'aaaaaaeeeeiiiiooooouuuunc';
    for (var i = 0; i < accented.length; i++) {
      name = name.replaceAll(accented[i], plain[i]);
    }
    return 'name:${name.replaceAll(_spaces, ' ')}';
  }
}
