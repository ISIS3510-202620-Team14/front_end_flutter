class Student {
  final String id;
  final int number;
  final String name;
  final String grade;
  final String sex;
  final String age;
  final bool withdrawn;
  final Map<String, String> levels;

  const Student({
    required this.id,
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
