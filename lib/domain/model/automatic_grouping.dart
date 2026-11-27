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

  // Compiled once: building it inside the sort compared it again on every comparison.
  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  static int _grade(Student student) {
    return int.tryParse(student.grade.replaceAll(_nonDigits, '')) ?? 0;
  }

  /** Students not classified yet go after every level. */
  static int _rank(Student student, String subject) {
    final int order = levelOrder(student, subject);
    return order == 0 ? 1 << 20 : order;
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
    // The level and the grade are worked out once per student, not on every comparison.
    final List<({Student student, int rank, int grade})> keyed = [
      for (final Student student in free)
        (student: student, rank: _rank(student, subject), grade: _grade(student)),
    ];
    keyed.sort((a, b) {
      final int byLevel = a.rank.compareTo(b.rank);
      if (byLevel != 0) return byLevel;
      final int byGrade = a.grade.compareTo(b.grade);
      if (byGrade != 0) return byGrade;
      return a.student.name.compareTo(b.student.name);
    });
    return [for (final item in keyed) item.student];
  }
}
