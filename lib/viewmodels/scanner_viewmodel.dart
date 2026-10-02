import 'package:flutter/foundation.dart';
import '../services/student_list_scanner.dart';

enum ScannerStatus { idle, scanning, review, empty, error }


class ScannedRow {
  ScannedRow(this.name);
  String name;
  String sex = ''; 
}

class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel({StudentListScanner? scanner})
      : _scanner = scanner ?? StudentListScanner();

  final StudentListScanner _scanner;

  ScannerStatus status = ScannerStatus.idle;
  List<ScannedRow> rows = [];
  String? error;

  Future<void> scan() async {
    status = ScannerStatus.scanning;
    error = null;
    notifyListeners();

    try {
      final names = await _scanner.scan();
      if (names == null) {
        status = rows.isEmpty ? ScannerStatus.idle : ScannerStatus.review;
      } else {
        
        final existing = rows.map((r) => r.name.toLowerCase()).toSet();
        rows = [
          ...rows,
          for (final n in names)
            if (!existing.contains(n.toLowerCase())) ScannedRow(n),
        ];
        status = rows.isEmpty ? ScannerStatus.empty : ScannerStatus.review;
      }
    } catch (e) {
      debugPrint('Scanner failed: $e');
      error = 'No pudimos leer la foto. Intenta con más luz y la hoja derecha.';
      status = ScannerStatus.error;
    }
    notifyListeners();
  }

  void rename(int index, String name) => rows[index].name = name.trim();

  void setSex(int index, String sex) {
    rows[index].sex = rows[index].sex == sex ? '' : sex;
    notifyListeners();
  }

  void remove(int index) {
    rows.removeAt(index);
    if (rows.isEmpty) status = ScannerStatus.empty;
    notifyListeners();
  }

  List<ScannedRow> get validRows =>
      rows.where((r) => r.name.split(' ').length >= 2).toList();
}
