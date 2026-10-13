import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_flutter/models/group/group.dart';

Map<String, dynamic> _json({Map<String, dynamic>? teacher}) => {
      'id': 'g1',
      'name': 'Mariposas',
      'subject': 'matematicas',
      'teacherId': 'uid-1',
      'schoolId': 'escuela-1',
      'studentIds': ['a', 'b'],
      'teacher': ?teacher,
    };

void main() {
  test('el listado sin teacher usa el nombre de respaldo', () {
    final group = Group.fromJson(_json(), fallbackTeacherName: 'Ana Ríos');

    expect(group.teacherLabel, 'Ana Ríos');
    expect(group.childrenCount, 2);
  });

  test('el nombre que trae el backend gana sobre el de respaldo', () {
    final group = Group.fromJson(
      _json(teacher: {'id': 'uid-1', 'fullName': 'Ana Ríos Gómez'}),
      fallbackTeacherName: 'Ana',
    );

    expect(group.teacherLabel, 'Ana Ríos Gómez');
  });

  test('sin nombre ni respaldo se muestra el id', () {
    expect(Group.fromJson(_json()).teacherLabel, 'uid-1');
  });
}
