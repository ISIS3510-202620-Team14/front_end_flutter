import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class GruposViewModel extends ChangeNotifier {
  final String sectionTitle = 'Mis grupos';
  final String sectionSubtitle =
      'Un niño puede estar en un grupo de matemáticas y en otro de lectura.';
  final List<String> subjectLabels = const ['Matemáticas', 'Lectura'];
  static const List<String> _subjectKeys = ['matematicas', 'lectura'];

  final GroupService _groupService;

  GruposViewModel({GroupService? groupService})
      : _groupService = groupService ?? GroupService();

  List<Group> _groups = [];
  bool _loading = false;
  String? _error;

  int _selectedSubjectIndex = 0;
  int get selectedSubjectIndex => _selectedSubjectIndex;
  bool get isMathSelected => _selectedSubjectIndex == 0;
  bool get loading => _loading;
  String? get error => _error;

  String get currentSubjectKey => _subjectKeys[_selectedSubjectIndex];

  List<Group> get currentGroups =>
      _groups.where((g) => g.subject == currentSubjectKey).toList();

  int get pendingChildrenCount => 0;

  void selectSubject(int index) {
    if (index == _selectedSubjectIndex) return;
    _selectedSubjectIndex = index;
    notifyListeners();
  }

  Future<void> loadGroups({String? schoolId, String? teacherId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _groupService.fetchGroups(
        schoolId: schoolId,
        teacherId: teacherId,
      );
      _groups = data.map((json) => Group.fromJson(json)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'No se pudieron cargar los grupos. Revisa tu conexión.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroupOnBackend({
    required String name,
    required String subject,
    String? schoolId,
    String? teacherId,
  }) async {
    try {
      final data = await _groupService.createGroup(
        name: name,
        subject: subject,
        schoolId: schoolId ?? 'default-school',
        teacherId: teacherId,
      );
      final group = Group.fromJson(data);
      _groups.add(group);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'No se pudo crear el grupo. Revisa tu conexión.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      await _groupService.deleteGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'No se pudo eliminar el grupo.';
      notifyListeners();
      return false;
    }
  }

  void createGroup() {}
}
