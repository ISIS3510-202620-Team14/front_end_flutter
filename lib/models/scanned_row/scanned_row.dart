class ScannedRow {
  ScannedRow(this.name, {this.code = '', this.sex = ''});
  String name;
  String code;
  String sex;
  Map<String, dynamic> toJson(int grade) {
    final data = <String, dynamic>{
      'fullName': name.trim(),
      'code': code.trim(),
      'grade': grade,
    };
    if (sex.isNotEmpty) {
      data['gender'] = sex;
    }
    return data;
  }
}
