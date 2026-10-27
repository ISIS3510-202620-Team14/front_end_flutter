import 'package:front_end_flutter/domain/model/user_profile.dart';
import 'package:front_end_flutter/domain/model/subject_progress.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';

class HomeViewModel extends SafeNotifier {
  HomeViewModel({required this.profile, StudentsViewModel? students})
    : studentsViewModel = students ?? StudentsViewModel() {
    studentsViewModel.addListener(notifyListeners);
  }
  final UserProfile profile;
  final StudentsViewModel studentsViewModel;
  String get teacherName {
    return profile.name;
  }

  final String sectionTitle = 'Hoy';
  static const List<String> subjectTitles = ['Lectura', 'Matemáticas'];
  List<SubjectProgress> get subjects {
    return [for (final title in subjectTitles) _progressOf(title)];
  }

  Future<void> changeUser() async {
    await AuthApi.logout();
  }

  SubjectProgress _progressOf(String title) {
    final evaluated = studentsViewModel.evaluatedCount(title);
    final total = studentsViewModel.activeCount;
    int percent = 0;
    if (total > 0) {
      percent = (evaluated / total * 100).round();
    }
    return SubjectProgress(
      title: title,
      percent: percent,
      evaluated: evaluated,
      total: total,
    );
  }

  @override
  void dispose() {
    studentsViewModel.removeListener(notifyListeners);
    studentsViewModel.dispose();
    super.dispose();
  }
}
