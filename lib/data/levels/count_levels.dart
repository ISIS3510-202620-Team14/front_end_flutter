// lib/data/levels/count_levels.dart
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:front_end_flutter/domain/model/school_levels.dart';

/*
  MULTITHREADING (Sprint 4) — Isolate.run (slides: an isolate is a process with its own
  memory, event loop and main thread). Each institution's JSON is decoded and counted in a
  new isolate, so the UI keeps drawing. Top-level, so only the JSON text travels.
*/
Future<Int32List> countInIsolate(String studentsJson) {
  return Isolate.run(() => countLevels(studentsJson));
}

/** Runs inside the other isolate: 42 primitive counts in an Int32List, with indexed loops. */
Int32List countLevels(String studentsJson) {
  final Map<String, dynamic> body =
      jsonDecode(studentsJson) as Map<String, dynamic>;
  final List<dynamic> students = body['students'] as List<dynamic>;
  final Int32List counts = Int32List(SchoolLevels.size);
  for (int i = 0; i < students.length; i++) {
    final Map<String, dynamic> student = students[i] as Map<String, dynamic>;
    if (student['retired'] == true) continue;
    final int grade = SchoolLevels.grades.indexOf(
      (student['grade'] as num?)?.toInt() ?? 0,
    );
    if (grade < 0) continue;
    final Map<String, dynamic>? levels =
        student['levels'] as Map<String, dynamic>?;
    for (int s = 0; s < SchoolLevels.subjects.length; s++) {
      final Map<String, dynamic>? level =
          levels?[SchoolLevels.subjects[s]] as Map<String, dynamic>?;
      int order = (level?['orden'] as num?)?.toInt() ?? 0;
      if (order < 0 || order >= SchoolLevels.levels) order = 0;
      counts[SchoolLevels.index(s, grade, order)]++;
    }
  }
  return counts;
}
