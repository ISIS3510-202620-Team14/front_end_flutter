import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../analytics_service/analytics_service.dart';

/** Captures photos and reads each page locally. */
class StudentListScanner {
  /** Allows a camera or event logger to be replaced in tests. */
  StudentListScanner({ImagePicker? picker, this.logger})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  final Future<void> Function(String, Map<String, Object>)? logger;
  final Set<String> _photos = {};
  final Set<String> _reading = {};
  bool _closed = false;
  String _appVersion = 'unknown';
  static const _channel = MethodChannel('enad/scanner');
  final String _session = const Uuid().v4();

  /** Captures one photo without waiting for OCR. */
  Future<String?> capture() async {
    if (_closed) return null;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      throw UnsupportedError(
        'El escáner requiere la aplicación Android o iOS.',
      );
    }
    // # micro opt
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (photo == null) return null;
    _photos.add(photo.path);
    if (_closed) {
      await _delete(photo.path);
      return null;
    }
    return photo.path;
  }

  /** Reads a page and parses plain data on a worker isolate. */
  Future<List<ScannedRow>> read(String path, int page) async {
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
        };
        try {
          if (logger != null) {
            await logger!('scanner_page_processed', data);
          } else {
            await AnalyticsService.instance.log('scanner_page_processed', data);
          }
        } catch (_) {}
      }
    }
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
            (
              text: line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              bottom: line.boundingBox.bottom,
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
  static final _digits = RegExp(r'\d');
  static final _letters = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
  static final _numeric = RegExp(r'^\d+$');
  static final _trim = RegExp(r'^[|;,:]+|[|;,:]+$');
  static final _marks = RegExp(r'[\u0300-\u036f]');
  static const _grades = {'tercero': 3, 'tercer': 3, 'cuarto': 4, 'quinto': 5};
  static const _headers = {
    'nombre',
    'código',
    'codigo',
    'grado',
    'edad',
    'asistencia',
    'lista',
    'fecha',
    'colegio',
    'docente',
    'curso',
  };

  /** Rebuilds rows with the same geometry rule as Kotlin. */
  static List<ScannedRow> parseLines(
    List<({String text, double left, double top, double bottom})> source,
  ) {
    if (source.isEmpty) return [];
    var height = 0.0;
    for (final line in source) {
      height += line.bottom - line.top;
    }
    final tolerance = height / source.length * 0.6;
    final lines = List.of(source)
      ..sort((a, b) {
        return (a.top + a.bottom).compareTo(b.top + b.bottom);
      });
    final groups =
        <List<({String text, double left, double top, double bottom})>>[];
    var center = 0.0;
    for (final line in lines) {
      final current = (line.top + line.bottom) / 2;
      if (groups.isEmpty || (current - center).abs() > tolerance) {
        groups.add([line]);
        center = current;
      } else {
        groups.last.add(line);
      }
    }
    final rows = <String>[];
    for (final group in groups) {
      group.sort((a, b) {
        return a.left.compareTo(b.left);
      });
      rows.add(
        group
            .map((line) {
              return line.text;
            })
            .join(' '),
      );
    }
    return parseRows(rows);
  }

  /** Reads names, codes, grades and ages using Kotlin's row rules. */
  static List<ScannedRow> parseRows(Iterable<String> lines) {
    final rows = <ScannedRow>[];
    for (final line in lines) {
      final tokens = line
          .split(_spaces)
          .map((part) {
            return part.replaceAll(_trim, '');
          })
          .where((part) {
            return part.isNotEmpty;
          })
          .toList();
      if (tokens.length > 1 &&
          tokens.first.length <= 2 &&
          _numeric.hasMatch(tokens.first) &&
          _letters.hasMatch(tokens[1])) {
        tokens.removeAt(0);
      }
      final firstNumber = tokens.indexWhere((part) {
        return _digits.hasMatch(part);
      });
      if (firstNumber < 1) continue;
      int? grade;
      int? age;
      String code = '';
      final nameParts = <String>[];
      for (final part in tokens.take(firstNumber)) {
        final value = _grades[part.toLowerCase()];
        if (value != null) {
          grade = value;
        } else {
          nameParts.add(part);
        }
      }
      if (nameParts.any((part) {
        return _headers.contains(part.toLowerCase());
      })) {
        continue;
      }
      final name = nameParts.join(' ');
      if (name.length < 3) continue;
      for (final part in tokens.skip(firstNumber)) {
        final digits = _digits.allMatches(part).map((match) {
          return match.group(0)!;
        }).join();
        final value = int.tryParse(digits);
        if (code.isEmpty && part.length >= 3 && digits.isNotEmpty) {
          code = part;
        } else if (value != null && grade == null && value >= 3 && value <= 5) {
          grade = value;
        } else if (value != null && age == null && value >= 5 && value <= 99) {
          age = value;
        }
      }
      rows.add(ScannedRow(name, code: code, grade: grade, age: age));
    }
    return rows;
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
