// lib/screens/teacher/home/home_viewmodel.dart
import 'package:front_end_flutter/domain/model/user_profile.dart';
import 'package:front_end_flutter/domain/model/subject_progress.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:front_end_flutter/data/auth/auth_api.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';

class HomeViewModel extends SafeNotifier {
  HomeViewModel({required this.profile, StudentsViewModel? students})
    : studentsViewModel = students ?? StudentsViewModel() {
    studentsViewModel.addListener(_onStudentsChanged);
  }
  final UserProfile profile;
  final StudentsViewModel studentsViewModel;
  String get teacherName {
    return profile.name;
  }

  final String sectionTitle = 'Hoy';
  static const List<String> subjectTitles = ['Lectura', 'Matemáticas'];

  // # micro opt
  // The cards are rebuilt on every frame that changes, but the numbers only change
  // when the students change.
  List<SubjectProgress>? _subjects;

  List<SubjectProgress> get subjects {
    return _subjects ??= [
      for (final title in subjectTitles) _progressOf(title),
    ];
  }

  void _onStudentsChanged() {
    _subjects = null;
    notifyListeners();
  }

  Future<void> changeUser() async {
    await AuthApi.logout();
  }

  SubjectProgress _progressOf(String title) {
    final evaluated = studentsViewModel.evaluatedCount(title);
    final total = studentsViewModel.activeCount;
    int percent = 0;
    if (total > 0) {
      // Whole division like Kotlin: 199 of 200 is 99%, never 100% while one is missing.
      percent = evaluated * 100 ~/ total;
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
    studentsViewModel.removeListener(_onStudentsChanged);
    studentsViewModel.dispose();
    super.dispose();
  }
}
