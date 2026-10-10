import 'package:front_end_flutter/models/student/student.dart';

// Adapter: translates between the backend representation of students and the frontend domain model.
class StudentApiAdapter {
  static const _materias = {
    'matematicas': [
      'principiante',
      'un_digito',
      'dos_digitos',
      'resta',
      'division',
      'problema_escrito',
    ],
    'lectura': [
      'principiante',
      'letra',
      'palabra',
      'parrafo',
      'cuento',
      'comprension',
    ],
  };

  static const _etiquetas = {
    'principiante': 'Principiante',
    'un_digito': '1 dígito',
    'dos_digitos': '2 dígitos',
    'resta': 'Resta',
    'division': 'División',
    'problema_escrito': 'Problema escrito',
    'letra': 'Letra',
    'palabra': 'Palabra',
    'parrafo': 'Párrafo',
    'cuento': 'Cuento',
    'comprension': 'Comprensión',
  };

  String subjectToBackend(String title) {
    if (title == 'Matemáticas') {
      return 'matematicas';
    } else {
      return 'lectura';
    }
  }

  String levelLabelToBackend(String title, String label) {
    return _materias[subjectToBackend(title)]!.firstWhere((k) {
      return _etiquetas[k] == label;
    });
  }

  String levelBackendToLabel(String key) {
    return _etiquetas[key] ?? key;
  }

  Student toDomain(Map<String, dynamic> json, int number) {
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <String, String>{};
    for (final title in ['Lectura', 'Matemáticas']) {
      final entry = levelsJson[subjectToBackend(title)];
      if (entry != null) {
        levels[title] = levelBackendToLabel(
          (entry['clave'] ?? entry['level']) as String,
        );
      }
    }
    return Student(
      id: json['id'] as String,
      number: number,
      name: json['fullName'] as String,
      grade: 'Grado ${json['grade']}',
      sex: json['gender'] as String? ?? '',
      schoolId: json['schoolId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      attendance: json['attendance'] as String? ?? 'sin_registro',
      age: json['age']?.toString() ?? '',
      withdrawn: json['retired'] as bool? ?? false,
      levels: levels,
    );
  }
}
