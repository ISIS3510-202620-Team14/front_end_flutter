import 'package:front_end_flutter/models/scanned_row/scanned_row.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class StudentListScanner {
  StudentListScanner({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<ScannedRow>?> scan() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (photo == null) {
      return null;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(photo.path),
      );

      final lines = [for (final block in result.blocks) ...block.lines]
        ..sort((a, b) {
          return a.boundingBox.top.compareTo(b.boundingBox.top);
        });

      return parseRows(
        lines.map((l) {
          return l.text;
        }),
      );
    } finally {
      await recognizer.close();
    }
  }

  static List<ScannedRow> parseRows(Iterable<String> lines) {
    final rows = <ScannedRow>[];
    for (final line in lines) {
      final match = RegExp(
        r'(?:c[oó]d(?:igo)?\s*[:#]?\s*([A-Za-z0-9-]+)|\b(\d{4,})\b)',
        caseSensitive: false,
      ).firstMatch(line);
      String code = '';
      String nameLine = line;
      if (match != null) {
        code = match.group(1) ?? match.group(2) ?? '';
        nameLine = line.replaceRange(match.start, match.end, ' ');
      }
      for (final name in parseNames([nameLine])) {
        rows.add(ScannedRow(name, code: code));
      }
    }
    return rows;
  }

  static const _headerWords = {
    'nombre',
    'nombres',
    'apellido',
    'apellidos',
    'lista',
    'listado',
    'grado',
    'curso',
    'estudiante',
    'estudiantes',
    'alumno',
    'alumnos',
    'asistencia',
    'fecha',
    'docente',
    'profesor',
    'profesora',
    'sede',
  };

  static List<String> parseNames(Iterable<String> lines) {
    final seen = <String>{};
    final names = <String>[];

    for (final raw in lines) {
      final cleaned = raw
          .replaceFirst(RegExp(r'^\s*\d+\s*[\.\)\-:]?\s*'), '')
          .replaceAll(RegExp(r"[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ' \-]"), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final words = cleaned.split(' ').where((w) {
        return w.length >= 2;
      }).toList();
      if (words.length < 2 || words.length > 6) {
        continue;
      }
      if (words.any((w) {
        return _headerWords.contains(w.toLowerCase());
      })) {
        continue;
      }

      final name = words.map(_capitalize).join(' ');
      if (seen.add(name.toLowerCase())) {
        names.add(name);
      }
    }
    return names;
  }

  static String _capitalize(String word) {
    return word
        .split('-')
        .map((p) {
          if (p.isEmpty) {
            return p;
          } else {
            return p[0].toUpperCase() + p.substring(1).toLowerCase();
          }
        })
        .join('-');
  }
}
