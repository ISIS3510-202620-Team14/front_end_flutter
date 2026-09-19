import 'package:flutter/foundation.dart';
import '../models/group.dart';


class GruposViewModel extends ChangeNotifier {
  final String sectionTitle = 'Mis grupos';
  final String sectionSubtitle =
      'Un niño puede estar en un grupo de matemáticas y en otro de lectura.';
  final List<String> subjectLabels = const ['Matemáticas', 'Lectura'];

  //Will be changed to a backend call when we have the backend ready
  final List<Group> _mathGroups = const [
    Group(name: 'Grupo Abejitas', childrenCount: 2, teacherLabel: 'Yo'),
    Group(
        name: 'Grupo Colibríes',
        childrenCount: 2,
        teacherLabel: 'Prof. Nelson'),
    Group(
        name: 'Grupo Tortugas',
        childrenCount: 1,
        teacherLabel: 'Prof. Marina'),
  ];
  final List<Group> _readingGroups = const [];
  final int mathChildrenWithoutGroup = 3;

  int _selectedSubjectIndex = 0; 
  int get selectedSubjectIndex => _selectedSubjectIndex;
  bool get isMathSelected => _selectedSubjectIndex == 0;

  List<Group> get currentGroups =>
      isMathSelected ? _mathGroups : _readingGroups;

  int get pendingChildrenCount =>
      isMathSelected ? mathChildrenWithoutGroup : 0;

  void selectSubject(int index) {
    if (index == _selectedSubjectIndex) return;
    _selectedSubjectIndex = index;
    notifyListeners();
  }

  void createGroup() {}
}
