class Student {
  final int number;
  final String name;
  final String grade;
  final String sex;
  final String age;
  final bool withdrawn;
  final Map<String, String> levels;
 
  const Student({
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