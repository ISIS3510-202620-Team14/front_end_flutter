import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/models/student/student.dart';

class TeacherMetricsViewModel extends SafeNotifier {
  TeacherMetricsViewModel({required this.students});
  final StudentsViewModel students;
  bool loading = false;
  bool loaded = false;
  String? error;
  int recorded = 0;
  int present = 0;
  Future<void> load() async {
    if (loading || students.loading) {
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (students.error != null) {
        throw StateError('students');
      }
      int total = 0;
      int attended = 0;
      final List<Student> active = students.students.where((Student student) {
        return !student.withdrawn;
      }).toList();
      for (int index = 0; index < active.length; index += 5) {
        final Iterable<Student> batch = active.skip(index).take(5);
        final List<Map<String, dynamic>> results = await Future.wait(
          batch.map((Student student) {
            return students.progress(student.id);
          }),
        );
        for (final Map<String, dynamic> result in results) {
          final Map attendance = result['attendance'] as Map? ?? {};
          total += (attendance['recorded'] as num? ?? 0).toInt();
          attended += (attendance['present'] as num? ?? 0).toInt();
        }
      }
      recorded = total;
      present = attended;
      loaded = true;
    } catch (_) {
      error = 'No pudimos cargar la asistencia histórica.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
