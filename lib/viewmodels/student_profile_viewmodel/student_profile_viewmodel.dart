import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/services/group_service/group_service.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';
import 'package:front_end_flutter/services/student_api_adapter/student_api_adapter.dart';
import 'package:front_end_flutter/models/student/student.dart';

class StudentProfileViewModel extends SafeNotifier {
  StudentProfileViewModel({
    required this.student,
    required this.students,
    GroupService? groups,
  }) : _groups = groups ?? GroupService();
  Student student;
  final StudentsViewModel students;
  final GroupService _groups;
  bool loading = false;
  String? error;
  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> groups = [];
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final Map<String, dynamic> progress = await students.progress(student.id);
      if (progress['student'] is Map) {
        student = StudentApiAdapter().toDomain(
          Map<String, dynamic>.from(progress['student']),
          student.number,
        );
      }
      attendance = Map<String, dynamic>.from(
        progress['attendance'] as Map? ?? {},
      );
      final List<Map<String, dynamic>> available = await _groups.fetchGroups(
        schoolId: student.schoolId,
      );
      groups = available.where((Map<String, dynamic> group) {
        return (group['studentIds'] as List? ?? []).contains(student.id);
      }).toList();
    } catch (_) {
      error = 'No pudimos actualizar el perfil.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _groups.dispose();
    super.dispose();
  }
}
