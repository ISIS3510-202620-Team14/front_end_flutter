// lib/data/local/levels_database.dart
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:front_end_flutter/domain/model/school_levels.dart';

/*
  LOCAL STORAGE (Sprint 4) — SQLite with Drift, same raw-SQL style as OfflineDatabase.
  The counts are structured and filtered by subject and grade, so each filter is one
  GROUP BY query, also offline. 
*/
class LevelsDatabase extends GeneratedDatabase {
  LevelsDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'enad_niveles_v1'));

  /** One instance for the whole app. */
  static final LevelsDatabase instance = LevelsDatabase();

  @override
  int get schemaVersion {
    return 1;
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables {
    return [];
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities {
    return [];
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await customStatement('''
          CREATE TABLE level_counts (
            uid TEXT NOT NULL,
            school_id TEXT NOT NULL,
            school_name TEXT NOT NULL,
            subject TEXT NOT NULL,
            grade INTEGER NOT NULL,
            level INTEGER NOT NULL,
            students INTEGER NOT NULL,
            saved_at INTEGER NOT NULL,
            PRIMARY KEY (uid, school_id, subject, grade, level)
          )''');
        await customStatement(
          'CREATE INDEX level_counts_filter ON level_counts(uid, subject, grade)',
        );
      },
    );
  }

  /** Replaces the counts of one institution in one transaction. */
  Future<void> saveSchool(
    String uid,
    String schoolId,
    String name,
    Int32List counts,
    DateTime savedAt,
  ) {
    return transaction(() async {
      await customStatement(
        'DELETE FROM level_counts WHERE uid = ? AND school_id = ?',
        [uid, schoolId],
      );
      for (int s = 0; s < SchoolLevels.subjects.length; s++) {
        for (int g = 0; g < SchoolLevels.grades.length; g++) {
          for (int level = 0; level < SchoolLevels.levels; level++) {
            final int students = counts[SchoolLevels.index(s, g, level)];
            if (students == 0) continue; // only cells with students
            await customStatement(
              'INSERT INTO level_counts VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [
                uid,
                schoolId,
                name,
                SchoolLevels.subjects[s],
                SchoolLevels.grades[g],
                level,
                students,
                savedAt.millisecondsSinceEpoch,
              ],
            );
          }
        }
      }
    });
  }

  /** Rows of one subject (grade 0 = all), the institution that needs most support first. */
  Future<List<LevelRow>> rows(String uid, String subject, int grade) async {
    final List<QueryRow> result = await customSelect(
      'SELECT school_id, school_name, level, SUM(students) AS students, '
      'MIN(saved_at) AS saved_at '
      'FROM level_counts '
      'WHERE uid = ? AND subject = ? AND (? = 0 OR grade = ?) '
      'GROUP BY school_id, school_name, level',
      variables: [
        Variable<String>(uid),
        Variable<String>(subject),
        Variable<int>(grade),
        Variable<int>(grade),
      ],
    ).get();
    final Map<String, LevelRow> bySchool = {};
    for (final QueryRow row in result) {
      final String id = row.read<String>('school_id');
      final LevelRow school = bySchool[id] ??= LevelRow(
        schoolId: id,
        name: row.read<String>('school_name'),
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('saved_at'),
          isUtc: true,
        ),
      );
      school.levels[row.read<int>('level')] = row.read<int>('students');
    }
    return bySchool.values.toList()..sort(LevelRow.bySupportNeeded);
  }

  /** After a full download, deletes the institutions that no longer exist. */
  Future<void> removeOlderThan(String uid, DateTime startedAt) {
    return customStatement(
      'DELETE FROM level_counts WHERE uid = ? AND saved_at < ?',
      [uid, startedAt.millisecondsSinceEpoch],
    );
  }
}
