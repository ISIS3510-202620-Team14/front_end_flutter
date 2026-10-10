import 'package:front_end_flutter/models/group/group.dart';
import 'package:front_end_flutter/models/user_profile/user_profile.dart';
import 'package:front_end_flutter/services/group_service/group_service.dart';
import 'package:front_end_flutter/services/grouping_analytics_service/grouping_analytics_service.dart';
import 'package:front_end_flutter/services/safe_notifier/safe_notifier.dart';
import 'package:front_end_flutter/viewmodels/students_viewmodel/students_viewmodel.dart';

class GruposViewModel extends SafeNotifier {
  GruposViewModel({
    required this.profile,
    required this.students,
    GroupService? groupService,
    GroupingAnalyticsService? analyticsService,
  }) : _groupService = groupService ?? GroupService(),
       analyticsService = analyticsService ?? GroupingAnalyticsService();
  final UserProfile profile;
  final StudentsViewModel students;
  final GroupService _groupService;
  final GroupingAnalyticsService analyticsService;
  final String sectionTitle = 'Mis grupos';
  final String sectionSubtitle =
      'Un niño puede estar en un grupo de matemáticas y en otro de lectura.';
  final List<String> subjectLabels = const ['Matemáticas', 'Lectura'];
  static const List<String> subjectKeys = ['matematicas', 'lectura'];
  List<Group> _groups = [];
  bool _loading = false;
  String? _error;
  String? selectedSchoolId;
  int _selectedSubjectIndex = 0;
  int get selectedSubjectIndex {
    return _selectedSubjectIndex;
  }

  bool get isMathSelected {
    return _selectedSubjectIndex == 0;
  }

  bool get loading {
    return _loading;
  }

  String? get error {
    return _error;
  }

  String get currentSubjectKey {
    return subjectKeys[_selectedSubjectIndex];
  }

  List<Group> get currentGroups {
    return _groups.where((group) {
      return group.subject == currentSubjectKey &&
          (selectedSchoolId == null || group.schoolId == selectedSchoolId);
    }).toList();
  }

  int get totalStudentsInSubject {
    return students.students.where((student) {
      return !student.withdrawn &&
          (selectedSchoolId == null || student.schoolId == selectedSchoolId);
    }).length;
  }

  int get pendingChildrenCount {
    final assigned = <String>{};
    for (final group in currentGroups) {
      assigned.addAll(group.studentIds);
    }
    return students.students.where((student) {
      return !student.withdrawn &&
          !assigned.contains(student.id) &&
          student.schoolId == selectedSchoolId;
    }).length;
  }

  Future<GroupingRecommendation> recommend({
    required String subject,
    required int classSize,
  }) async {
    return analyticsService.recommend(subject: subject, classSize: classSize);
  }

  void selectSubject(int index) {
    _selectedSubjectIndex = index;
    notifyListeners();
  }

  Future<void> selectSchool(String id) async {
    selectedSchoolId = id;
    await loadGroups();
  }

  Future<void> loadGroups({String? schoolId, String? teacherId}) async {
    selectedSchoolId ??= profile.schoolIds.first;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _groupService.fetchGroups(
        schoolId: schoolId ?? selectedSchoolId,
        teacherId: teacherId ?? profile.uid,
      );
      _groups = data.map(Group.fromJson).toList();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroupOnBackend({
    required String name,
    required String subject,
    required GroupingMethod method,
    String? schoolId,
    String? teacherId,
  }) async {
    final school = schoolId ?? selectedSchoolId;
    if (school == null || !profile.schoolIds.contains(school)) {
      _error = 'Selecciona una institución autorizada.';
      notifyListeners();
      return false;
    }
    _error = null;
    try {
      final size = totalStudentsInSubject;
      final data = await _groupService.createGroup(
        name: name,
        subject: subject,
        schoolId: school,
        teacherId: profile.uid,
      );
      _groups.add(Group.fromJson(data));
      // A telemetry failure must not pretend that the already saved group failed.
      try {
        await analyticsService.trackGroupingEvent(
          GroupingEvent(
            subject: subject,
            classSize: size,
            method: method,
            teacherId: profile.uid,
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {
        _error = 'Grupo guardado; no pudimos registrar la recomendación de agrupación.';
      }
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _groupService.deleteGroup(id);
      await loadGroups();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> renameGroup(String id, String name) async {
    if (name.trim().isEmpty) {
      throw const ApiException(400, 'Escribe el nombre del grupo.');
    }
    await _groupService.renameGroup(id, name.trim());
    await loadGroups();
  }

  Future<Map<String, dynamic>> detail(String id) async {
    return _groupService.fetchGroupDetail(id);
  }

  Future<void> addStudent(String id, String studentId) async {
    await _groupService.addStudentToGroup(id, studentId);
    await loadGroups();
  }

  Future<void> removeStudent(String id, String studentId) async {
    await _groupService.removeStudentFromGroup(id, studentId);
    await loadGroups();
  }

  @override
  void dispose() {
    _groupService.dispose();
    analyticsService.dispose();
    super.dispose();
  }
}
