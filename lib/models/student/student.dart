import 'package:front_end_flutter/models/student_age/student_age.dart';

class Student {
  final String id;
  final String schoolId;
  final String campus;
  final String code;
  final String attendance;
  final int number;
  final String name;
  final String grade;
  final String sex;
  final String age;
  final int? sample;
  final bool withdrawn;
  final Map<String, String> levels;

  bool get hasRequiredDemographics {
    return (sex == 'F' || sex == 'M') && StudentAge.isValid(age);
  }

  const Student({
    required this.id,
    this.schoolId = '',
    this.campus = '',
    this.code = '',
    this.attendance = 'sin_registro',
    required this.number,
    required this.name,
    required this.grade,
    this.sex = '',
    this.age = '',
    this.sample,
    this.withdrawn = false,
    this.levels = const {},
  });

  Student copyWith({
    String? attendance,
    String? sex,
    String? age,
    int? sample,
    bool? withdrawn,
    Map<String, String>? levels,
  }) {
    return Student(
      id: id,
      schoolId: schoolId,
      campus: campus,
      code: code,
      attendance: attendance ?? this.attendance,
      number: number,
      name: name,
      grade: grade,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      sample: sample ?? this.sample,
      withdrawn: withdrawn ?? this.withdrawn,
      levels: levels ?? this.levels,
    );
  }
}
