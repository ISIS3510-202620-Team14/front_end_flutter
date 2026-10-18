import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Takes a photo of a class list with the camera and reads the names with
/// on-device OCR (ML Kit). Nothing leaves the phone.
class StudentListScanner {
  StudentListScanner({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns null if the teacher closes the camera without taking a photo.
  Future<List<String>?> scan() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (photo == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(photo.path));

      // ML Kit does not guarantee reading order: sort lines top to bottom.
      final lines = [
        for (final block in result.blocks) ...block.lines,
      ]..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      return parseNames(lines.map((l) => l.text));
    } finally {
      await recognizer.close();
    }
  }

  static const _headerWords = {
    'nombre', 'nombres', 'apellido', 'apellidos', 'lista', 'listado',
    'grado', 'curso', 'estudiante', 'estudiantes', 'alumno', 'alumnos',
    'asistencia', 'fecha', 'docente', 'profesor', 'profesora', 'sede',
  };

  /// Turns raw OCR lines into clean "Nombre Apellido" entries.
  /// Public and pure so it can be unit-tested without a camera.
  static List<String> parseNames(Iterable<String> lines) {
    final seen = <String>{};
    final names = <String>[];

    for (final raw in lines) {
      final cleaned = raw
          // Leading numbering: "1.", "02)", "3 -"
          .replaceFirst(RegExp(r'^\s*\d+\s*[\.\)\-:]?\s*'), '')
          // Keep letters (with accents), spaces, apostrophes and hyphens.
          .replaceAll(RegExp(r"[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ' \-]"), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final words = cleaned.split(' ').where((w) => w.length >= 2).toList();
      if (words.length < 2 || words.length > 6) continue;
      if (words.any((w) => _headerWords.contains(w.toLowerCase()))) continue;

      final name = words.map(_capitalize).join(' ');
      if (seen.add(name.toLowerCase())) names.add(name);
    }
    return names;
  }

  static String _capitalize(String word) => word
      .split('-')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join('-');
}
