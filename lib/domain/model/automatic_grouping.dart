import 'package:front_end_flutter/data/mapper/student_api_adapter.dart';
import 'package:front_end_flutter/domain/model/student.dart';

/**
 * Automatic method: the app puts in the group the students that still have no group of that
 * subject, with the same level and grade together, like armarGrupoAutomatico in Kotlin.
 */
class AutomaticGrouping {
  static final StudentApiAdapter _adapter = StudentApiAdapter();

  /** Position of the student's level in the subject (1 = lowest); 0 when not classified yet. */
  static int levelOrder(Student student, String subject) {
    final String title = subject == 'matematicas' ? 'Matemáticas' : 'Lectura';
    final String? label = student.levels[title];
    if (label == null) return 0;
    try {
      return _adapter.levelOrder(
        subject,
        _adapter.levelLabelToBackend(title, label),
      );
    } catch (_) {
      return 0;
    }
  }

  static int _grade(Student student) {
    return int.tryParse(student.grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  /**
   * Students of the school without a group of the subject, ordered by level, then grade, then name.
   * Students not classified yet go at the end, so a level never mixes with unknown ones.
   */
  static List<Student> pick({
    required List<Student> students,
    required String schoolId,
    required String subject,
    required Set<String> alreadyGrouped,
  }) {
    final List<Student> free = students.where((Student student) {
      return !student.withdrawn &&
          student.schoolId == schoolId &&
          !alreadyGrouped.contains(student.id);
    }).toList();
    int rank(Student student) {
      final int order = levelOrder(student, subject);
      return order == 0 ? 1 << 20 : order;
    }

    free.sort((Student a, Student b) {
      final int byLevel = rank(a).compareTo(rank(b));
      if (byLevel != 0) return byLevel;
      final int byGrade = _grade(a).compareTo(_grade(b));
      if (byGrade != 0) return byGrade;
      return a.name.compareTo(b.name);
    });
    return free;
  }
}
