import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
export 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/services/student_list_scanner/student_list_scanner.dart';

enum ScannerStatus { idle, scanning, review, empty, error }

class ScannerViewModel extends SafeNotifier {
  ScannerViewModel({StudentListScanner? scanner})
    : _scanner = scanner ?? StudentListScanner();

  final StudentListScanner _scanner;

  ScannerStatus status = ScannerStatus.idle;
  List<ScannedRow> rows = [];
  String? error;

  Future<void> scan() async {
    if (status == ScannerStatus.scanning) {
      return;
    }
    status = ScannerStatus.scanning;
    error = null;
    notifyListeners();

    try {
      final names = await _scanner.scan();
      if (names == null) {
        final ScannerStatus selectedValue1;
        if (rows.isEmpty) {
          selectedValue1 = ScannerStatus.idle;
        } else {
          selectedValue1 = ScannerStatus.review;
        }
        status = selectedValue1;
      } else {
        for (final ScannedRow row in names) {
          rows.add(row);
        }
        final ScannerStatus selectedValue2;
        if (rows.isEmpty) {
          selectedValue2 = ScannerStatus.empty;
        } else {
          selectedValue2 = ScannerStatus.review;
        }
        status = selectedValue2;
      }
    } catch (e) {
      debugPrint('Scanner failed: $e');
      error = 'No pudimos leer la foto. Intenta con más luz y la hoja derecha.';
      status = ScannerStatus.error;
    }
    notifyListeners();
  }

  void setCode(int index, String code) {
    rows[index].code = code.trim();
    notifyListeners();
  }

  void rename(int index, String name) {
    rows[index].name = name.trim();
    notifyListeners();
  }

  void setSex(int index, String sex) {
    final String selectedValue3;
    if (rows[index].sex == sex) {
      selectedValue3 = '';
    } else {
      selectedValue3 = sex;
    }
    rows[index].sex = selectedValue3;
    notifyListeners();
  }

  void remove(int index) {
    rows.removeAt(index);
    if (rows.isEmpty) {
      status = ScannerStatus.empty;
    }
    notifyListeners();
  }

  List<ScannedRow> get validRows {
    return rows.where((r) {
      return r.name.trim().isNotEmpty && r.code.trim().isNotEmpty;
    }).toList();
  }

  String? get validationError {
    if (rows.length > 200) {
      return 'Importa máximo 200 estudiantes por lista.';
    }
    final codes = <String>{};
    for (final row in rows) {
      if (row.name.trim().isEmpty || row.code.trim().isEmpty) {
        return 'Completa el nombre y el código de cada estudiante.';
      }
      if (!codes.add(row.code.trim())) {
        return 'Hay códigos repetidos. Corrige o elimina las filas duplicadas.';
      }
    }
    return null;
  }
}
