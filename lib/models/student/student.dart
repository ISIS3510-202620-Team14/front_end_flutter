class Student {
  final String id;
  final String schoolId;
  final String code;
  final String attendance;
  final int number;
  final String name;
  final String grade;
  final String sex;
  final String age;
  final bool withdrawn;
  final Map<String, String> levels;

  const Student({
    required this.id,
    this.schoolId = '',
    this.code = '',
    this.attendance = 'sin_registro',
    required this.number,
    required this.name,
    required this.grade,
    this.sex = 'F',
    this.age = '',
    this.withdrawn = false,
    this.levels = const {},
  });

  Student copyWith({
    String? sex,
    String? age,
    bool? withdrawn,
    Map<String, String>? levels,
  }) {
    return Student(
      id: id,
      schoolId: schoolId,
      code: code,
      attendance: attendance,
      number: number,
      name: name,
      grade: grade,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      withdrawn: withdrawn ?? this.withdrawn,
      levels: levels ?? this.levels,
    );
  }
}
