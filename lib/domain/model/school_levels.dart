// lib/domain/model/school_levels.dart
import 'dart:typed_data';

/*
  BQ(Type 4): % of assessed students still at Beginner, per institution, in Reading and Math.
  One institution fits in 42 counts: 2 subjects x 3 grades x 7 levels (0 = not assessed yet).
*/
class SchoolLevels {
  static const List<String> subjects = ['lectura', 'matematicas'];
  static const List<int> grades = [3, 4, 5];
  static const int levels = 7;
  static const int size = 2 * 3 * levels;

  /** Position of one cell inside the Int32List. */
  static int index(int subject, int grade, int level) {
    return (subject * grades.length + grade) * levels + level;
  }
}

/** One institution on screen, for the chosen subject and grade. */
class LevelRow {
  LevelRow({
    required this.schoolId,
    required this.name,
    required this.savedAt,
    Int32List? levels,
  }) : levels = levels ?? Int32List(SchoolLevels.levels);

  final String schoolId;
  final String name;
  final DateTime savedAt;
  /** levels[0] = not assessed, levels[1..6] = students in each ENAd level. */
  final Int32List levels;

  int get pending {
    return levels[0];
  }

  int get assessed {
    int total = 0;
    for (int level = 1; level < SchoolLevels.levels; level++) {
      total += levels[level];
    }
    return total;
  }

  int get beginners {
    return levels[1];
  }

  /** Percentage of assessed students still in Principiante; null if nobody was assessed. */
  double? get beginnerShare {
    final int total = assessed;
    if (total == 0) return null;
    return beginners * 100 / total;
  }

  /** The institution that needs more support goes first. */
  static int bySupportNeeded(LevelRow a, LevelRow b) {
    final int byShare = (b.beginnerShare ?? -1).compareTo(
      a.beginnerShare ?? -1,
    );
    if (byShare != 0) return byShare;
    return a.name.compareTo(b.name);
  }
}
