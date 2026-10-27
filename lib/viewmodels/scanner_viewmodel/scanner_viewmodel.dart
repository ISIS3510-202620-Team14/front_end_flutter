import 'dart:async';
import 'dart:collection';

import 'package:uuid/uuid.dart';

import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/models/scanned_row/scanner_page.dart';
export 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
export 'package:front_end_flutter/models/scanned_row/scanner_page.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/services/student_list_scanner/student_list_scanner.dart';

enum ScannerStatus { idle, scanning, review, empty, error }

/** Coordinates two page readers and keeps results in capture order. */
class ScannerViewModel extends SafeNotifier {
  /** Creates a scanner with replaceable page operations. */
  ScannerViewModel({
    this.allowProvisional = false,
    StudentListScanner? scanner,
    Future<String?> Function()? capture,
    Future<List<ScannedRow>> Function(String, int)? read,
    Future<void> Function()? close,
  }) {
    final service = scanner ?? StudentListScanner();
    _capture = capture ?? service.capture;
    _read = read ?? service.read;
    _close = close ?? service.close;
  }
  late final Future<String?> Function() _capture;
  late final Future<List<ScannedRow>> Function(String, int) _read;
  late final Future<void> Function() _close;
  final _queue = Queue<ScannerPage>();
  final Map<int, List<ScannedRow>> _finished = {};
  final List<ScannerPage> _pages = [];
  final List<ScannedRow> _rows = [];
  final List<int> _rowIds = [];
  final bool allowProvisional;
  final Map<int, String> _provisionalCodes = {};
  int _nextRowId = 0;
  int _delivered = 0;
  int _active = 0;
  bool capturing = false;
  String? error;

  /** Returns immutable row snapshots. */
  List<ScannedRow> get rows {
    return List.unmodifiable(_rows);
  }

  /** Returns immutable page snapshots. */
  List<ScannerPage> get pages {
    return List.unmodifiable(_pages);
  }

  /** Reports unfinished page work. */
  bool get processing {
    return _active > 0 || _queue.isNotEmpty;
  }

  /** Keeps field identities stable while rows are edited. */
  int rowId(int index) {
    return _rowIds[index];
  }

  /** Describes the visible scanner state. */
  ScannerStatus get status {
    if (processing) return ScannerStatus.scanning;
    if (_rows.isNotEmpty) return ScannerStatus.review;
    if (error != null) return ScannerStatus.error;
    return _pages.isEmpty ? ScannerStatus.idle : ScannerStatus.empty;
  }

  /** Queues a photo and releases the camera before processing completes. */
  Future<void> scan() async {
    if (disposed || capturing) return;
    if (_pages.length >= 20) {
      error = 'Revisa e importa estas páginas antes de escanear más.';
      notifyListeners();
      return;
    }
    capturing = true;
    error = null;
    notifyListeners();
    try {
      final path = await _capture();
      if (disposed || path == null) return;
      final page = ScannerPage(_pages.length + 1, path);
      _pages.add(page);
      _queue.add(page);
      _pump();
    } catch (failure) {
      error = failure is UnsupportedError
          ? failure.message
          : 'No pudimos abrir la cámara. Revisa el permiso e intenta de nuevo.';
    } finally {
      capturing = false;
      notifyListeners();
    }
  }

  /** Starts no more than two page jobs at once. */
  void _pump() {
    // # micro opt
    while (!disposed && _active < 2 && _queue.isNotEmpty) {
      final page = _queue.removeFirst();
      _active++;
      _pages[page.number - 1] = page.updated(ScannerPageState.reading);
      unawaited(_process(page));
    }
  }

  /** Delivers successful pages even when a different page fails. */
  Future<void> _process(ScannerPage page) async {
    var result = <ScannedRow>[];
    var failed = false;
    try {
      result = await _read(page.path, page.number);
    } catch (_) {
      failed = true;
    }
    if (disposed) return;
    _active--;
    _pages[page.number - 1] = page.updated(
      failed ? ScannerPageState.failed : ScannerPageState.ready,
      result.length,
    );
    if (failed) {
      error =
          'No se pudo leer la página ${page.number}. Puedes tomarla de nuevo.';
    }
    _finished[page.number] = result;
    // # micro opt
    final seen = _rows.map(StudentListScanner.rowKey).toSet();
    while (_finished.containsKey(_delivered + 1)) {
      final ready = _finished.remove(++_delivered)!;
      for (final row in ready) {
        if (seen.add(StudentListScanner.rowKey(row))) {
          _rows.add(row);
          _rowIds.add(_nextRowId++);
        }
      }
    }
    _pump();
    notifyListeners();
  }

  /** Changes a reviewed code. */
  void setCode(int index, String code) {
    _rows[index] = _rows[index].copyWith(code: code.trim());
    notifyListeners();
  }

  /** Changes a reviewed name. */
  void rename(int index, String name) {
    _rows[index] = _rows[index].copyWith(name: name.trim());
    notifyListeners();
  }

  /** Changes the optional sex. */
  void setSex(int index, String sex) {
    _rows[index] = _rows[index].copyWith(
      sex: _rows[index].sex == sex ? '' : sex,
    );
    notifyListeners();
  }

  /** Changes the grade or leaves the screen's selected course. */
  void setGrade(int index, String value) {
    final row = _rows[index];
    _rows[index] = ScannedRow(
      row.name,
      code: row.code,
      sex: row.sex,
      grade: int.tryParse(value),
      age: row.age,
    );
    notifyListeners();
  }

  /** Changes the optional age. */
  void setAge(int index, String value) {
    final row = _rows[index];
    _rows[index] = ScannedRow(
      row.name,
      code: row.code,
      sex: row.sex,
      grade: row.grade,
      age: int.tryParse(value),
    );
    notifyListeners();
  }

  /** Removes one reviewed student. */
  void remove(int index) {
    _provisionalCodes.remove(_rowIds[index]);
    _rows.removeAt(index);
    _rowIds.removeAt(index);
    notifyListeners();
  }

  /** Returns only rows ready for import. */
  List<ScannedRow> get validRows {
    final result = <ScannedRow>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.name.trim().isEmpty) continue;
      if (row.code.trim().isNotEmpty) {
        result.add(row);
      } else if (allowProvisional) {
        final code = _provisionalCodes.putIfAbsent(_rowIds[i], () {
          return 'PROV-${const Uuid().v4().substring(0, 12)}';
        });
        result.add(row.copyWith(code: code, provisional: true));
      }
    }
    return result;
  }

  /** Validates the existing import contract. */
  String? get validationError {
    if (_rows.length > 200) return 'Importa máximo 200 estudiantes por lista.';
    final codes = <String>{};
    for (final row in _rows) {
      if (row.name.trim().isEmpty ||
          (!allowProvisional && row.code.trim().isEmpty)) {
        return allowProvisional
            ? 'Completa el nombre de cada estudiante.'
            : 'Completa el nombre y el código de cada estudiante.';
      }
      if (row.code.trim().isNotEmpty && !codes.add(row.code.trim())) {
        return 'Hay códigos repetidos. Corrige o elimina las filas duplicadas.';
      }
      if (row.grade != null && (row.grade! < 3 || row.grade! > 5)) {
        return 'El grado debe estar entre 3 y 5.';
      }
      if (row.age != null && (row.age! < 5 || row.age! > 18)) {
        return 'La edad debe estar entre 5 y 18 años.';
      }
    }
    return null;
  }

  /** Discards queued pages and releases scanner resources. */
  @override
  void dispose() {
    _queue.clear();
    _finished.clear();
    super.dispose();
    unawaited(_close());
  }
}
