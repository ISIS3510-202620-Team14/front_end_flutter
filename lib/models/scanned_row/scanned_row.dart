/** A reviewed student from a scanned page. */
class ScannedRow {
  /** Creates a scanned student. */
  const ScannedRow(
    this.name, {
    this.code = '',
    this.sex = '',
    this.grade,
    this.age,
    this.provisional = false,
  });
  final String name;
  final String code;
  final String sex;
  final int? grade;
  final int? age;
  final bool provisional;

  /** Returns an edited row. */
  ScannedRow copyWith({
    String? name,
    String? code,
    String? sex,
    int? grade,
    int? age,
    bool? provisional,
  }) {
    return ScannedRow(
      name ?? this.name,
      code: code ?? this.code,
      sex: sex ?? this.sex,
      grade: grade ?? this.grade,
      age: age ?? this.age,
      provisional: provisional ?? this.provisional,
    );
  }

  /** Builds the import payload. */
  Map<String, dynamic> toJson(int selectedGrade) {
    return {
      'fullName': name.trim(),
      'code': code.trim(),
      'grade': grade ?? selectedGrade,
      if (sex.isNotEmpty) 'gender': sex,
      if (age != null) 'age': age,
      if (provisional) 'provisional': true,
    };
  }
}
