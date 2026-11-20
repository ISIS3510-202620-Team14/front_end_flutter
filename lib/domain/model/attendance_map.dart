class SchoolAttendance {
  const SchoolAttendance({
    required this.name,
    required this.days,
    required this.week,
    required this.lastWeek,
  });
  final String name;
  final List<double?> days;
  final double? week;
  final double? lastWeek;

  double? get change {
    if (week == null || lastWeek == null) return null;
    return week! - lastWeek!;
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'days': days, 'week': week, 'lastWeek': lastWeek};
  }

  factory SchoolAttendance.fromJson(Map<String, dynamic> json) {
    return SchoolAttendance(
      name: json['name'] as String,
      days: [for (final day in json['days'] as List) (day as num?)?.toDouble()],
      week: (json['week'] as num?)?.toDouble(),
      lastWeek: (json['lastWeek'] as num?)?.toDouble(),
    );
  }
}

class AttendanceMap {
  const AttendanceMap({
    required this.days,
    required this.schools,
    required this.week,
    required this.savedAt,
  });
  final List<String> days;
  final List<SchoolAttendance> schools;
  final double? week;
  final DateTime savedAt;

  SchoolAttendance? get biggestDrop {
    SchoolAttendance? worst;
    for (final SchoolAttendance school in schools) {
      final double? change = school.change;
      if (change != null && change < 0 && change < (worst?.change ?? 0)) {
        worst = school;
      }
    }
    return worst;
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'schools': [for (final school in schools) school.toJson()],
      'week': week,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory AttendanceMap.fromJson(Map<String, dynamic> json) {
    return AttendanceMap(
      days: List<String>.from(json['days'] as List),
      schools: [
        for (final school in json['schools'] as List)
          SchoolAttendance.fromJson(Map<String, dynamic>.from(school as Map)),
      ],
      week: (json['week'] as num?)?.toDouble(),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}
AttendanceMap buildAttendanceMap(Map<String, dynamic> input) {
  final List<SchoolAttendance> schools = [];
  int allPresent = 0;
  int allMarked = 0;
  for (final Map school in input['schools'] as List) {
    final List<double?> days = [];
    int present = 0;
    int marked = 0;
    for (final List students in school['thisWeek'] as List) {
      final (int p, int m) = _count(students);
      days.add(_percentage(p, m));
      present += p;
      marked += m;
    }
    int lastPresent = 0;
    int lastMarked = 0;
    for (final List students in school['lastWeek'] as List) {
      final (int p, int m) = _count(students);
      lastPresent += p;
      lastMarked += m;
    }
    allPresent += present;
    allMarked += marked;
    schools.add(
      SchoolAttendance(
        name: school['name'] as String,
        days: days,
        week: _percentage(present, marked),
        lastWeek: _percentage(lastPresent, lastMarked),
      ),
    );
  }
  schools.sort((a, b) => (a.week ?? 101).compareTo(b.week ?? 101));
  return AttendanceMap(
    days: List<String>.from(input['days'] as List),
    schools: schools,
    week: _percentage(allPresent, allMarked),
    savedAt: DateTime.now(),
  );
}

(int, int) _count(List students) {
  int present = 0;
  int marked = 0;
  for (final student in students) {
    if (student['attendance'] == 'vino') present++;
    if (student['attendance'] != 'sin_registro') marked++;
  }
  return (present, marked);
}

double? _percentage(int part, int total) {
  if (total == 0) return null;
  return (part * 1000 / total).round() / 10;
}
