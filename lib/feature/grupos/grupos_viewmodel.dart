import 'package:front_end_flutter/data/sync/offline_runtime.dart';
import 'package:front_end_flutter/ui/utils/user_message.dart';
import 'package:flutter/foundation.dart';
import 'package:front_end_flutter/domain/model/group.dart';
import 'package:front_end_flutter/domain/model/user_profile.dart';
import 'package:front_end_flutter/data/repository/group_service.dart';
import 'package:front_end_flutter/data/telemetria/grouping/grouping_analytics_service.dart';
import 'package:front_end_flutter/data/telemetria/grouping/grouping_session_service.dart';
import 'package:front_end_flutter/ui/state/safe_notifier.dart';
import 'package:front_end_flutter/screens/teacher/students/students_viewmodel.dart';
import 'package:front_end_flutter/domain/model/automatic_grouping.dart';
import 'package:front_end_flutter/domain/model/student.dart';

class GruposViewModel extends SafeNotifier {
  GruposViewModel({
    required this.profile,
    required this.students,
    GroupService? groupService,
    GroupingAnalyticsService? analyticsService,
    GroupingSessionService? sessionService,
  }) : _groupService = groupService ?? GroupService(),
       analyticsService = analyticsService ?? GroupingAnalyticsService(),
       _sessionService =
           sessionService ?? GroupingSessionService(userId: profile.uid) {
    OfflineRuntime.current?.addListener(_syncChanged);
  }
  void _syncChanged() {
    if (!disposed && !_loading && profile.schoolIds.isNotEmpty) loadGroups();
  }

  final UserProfile profile;
  final StudentsViewModel students;
  final GroupService _groupService;
  final GroupingAnalyticsService analyticsService;
  final GroupingSessionService _sessionService;
  final String sectionTitle = 'Mis grupos';
  final String sectionSubtitle =
      'Un estudiante puede estar en un grupo de matemáticas y en otro de lectura.';
  final List<String> subjectLabels = const ['Matemáticas', 'Lectura'];
  static const List<String> subjectKeys = ['matematicas', 'lectura'];
  List<Group> _groups = [];
  // Aviso para mostrar al cerrar el diálogo, por ejemplo cuántos estudiantes metió el método automático.
  String? notice;
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

  List<Group> get allGroups {
    return List<Group>.unmodifiable(_groups);
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
    _retryPendingSessions();
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _groupService.fetchGroups(
        schoolId: schoolId ?? selectedSchoolId,
        teacherId: teacherId ?? profile.uid,
      );
      _groups = data.map(_parseGroup).toList();
    } catch (error) {
      _error = UserMessage.from(error);
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
    notice = null;
    try {
      final size = totalStudentsInSubject;
      final data = await _groupService.createGroup(
        name: name,
        subject: subject,
        schoolId: school,
        teacherId: profile.uid,
      );
      _groups.add(_parseGroup(data));
      int assigned = 0;
      if (method == GroupingMethod.automatic) {
        assigned = await _fillAutomatically(
          data['id'] as String,
          school,
          subject,
        );
        notice = assigned == 0
            ? 'Grupo creado. Todos los estudiantes ya tienen grupo en esta materia.'
            : 'Grupo creado con $assigned estudiante(s) sin grupo, ordenados por nivel.';
        await loadGroups();
      }
      await _registerSession(school, subject, name, size, assigned);

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
      } catch (error) {
        debugPrint('Grouping event was not recorded: $error');
        _error = 'Grupo guardado; no pudimos registrar la recomendación de agrupación.';
      }
      notifyListeners();
      return true;
    } catch (error) {
      _error = UserMessage.from(error);
      notifyListeners();
      return false;
    }
  }

  /** Counts the teachers of this school with a group of the subject, including the current one. */
  int _teachersCounted(String schoolId, String subject) {
    final Set<String> teachers = {profile.uid};
    for (final Group group in _groups) {
      if (group.schoolId == schoolId && group.subject == subject) {
        teachers.add(group.teacherId);
      }
    }
    return teachers.length;
  }

  // La sesión de agrupación se guarda en el teléfono y se envía cuando hay red.
  // Si falla, el grupo ya creado no se pierde ni se muestra como error.
  Future<void> _registerSession(
    String schoolId,
    String subject,
    String name,
    int studentsCounted,
    int studentsAssigned,
  ) async {
    if (studentsCounted < 1) {
      return;
    }
    try {
      await _sessionService.register(
        schoolId: schoolId,
        subject: subject,
        groupName: name,
        studentsCounted: studentsCounted,
        teachersCounted: _teachersCounted(schoolId, subject),
        studentsAssigned: studentsAssigned,
      );
    } catch (error) {
      debugPrint('Grouping session was not registered: $error');
    }
  }

  /**
   * Automatic method: adds the students without a group of this subject, ordered by level and grade.
   * Groups of every teacher of the school count, because a student can only be in one group per subject.
   * Returns how many were added; one that fails (for example another phone took it first) is skipped.
   */
  Future<int> _fillAutomatically(
    String groupId,
    String schoolId,
    String subject,
  ) async {
    final Set<String> grouped = {};
    try {
      final List<Map<String, dynamic>> schoolGroups = await _groupService
          .fetchGroups(schoolId: schoolId, subject: subject);
      for (final Map<String, dynamic> group in schoolGroups) {
        grouped.addAll(List<String>.from(group['studentIds'] as List? ?? []));
      }
    } catch (_) {
      // Sin la lista completa se usan los grupos ya cargados; el backend rechaza los repetidos.
      for (final Group group in _groups) {
        if (group.schoolId == schoolId && group.subject == subject) {
          grouped.addAll(group.studentIds);
        }
      }
    }
    final List<Student> chosen = AutomaticGrouping.pick(
      students: students.students,
      schoolId: schoolId,
      subject: subject,
      alreadyGrouped: grouped,
    );
    int added = 0;
    for (final Student student in chosen) {
      try {
        await _groupService.addStudentToGroup(groupId, student.id);
        added++;
      } catch (error) {
        debugPrint('Student ${student.id} was not added automatically: $error');
      }
    }
    return added;
  }

  Future<void> _retryPendingSessions() async {
    try {
      await _sessionService.synchronize();
    } catch (error) {
      debugPrint('Pending grouping sessions were not sent: $error');
    }
  }

  Group _parseGroup(Map<String, dynamic> json) {
    final isMine = json['teacherId'] == profile.uid;
    String? teacherName;
    if (isMine) {
      teacherName = profile.name;
    }
    return Group.fromJson(json, fallbackTeacherName: teacherName);
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _groupService.deleteGroup(id);
      await loadGroups();
      return true;
    } catch (error) {
      _error = UserMessage.from(error);
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
    OfflineRuntime.current?.removeListener(_syncChanged);
    _groupService.dispose();
    analyticsService.dispose();
    super.dispose();
  }
}
