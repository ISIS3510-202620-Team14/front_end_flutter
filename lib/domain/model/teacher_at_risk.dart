import 'package:front_end_flutter/domain/model/engagement_risk.dart';

/** Type 5 BQ for the admin: one teacher whose weekly opens dropped, with the same rule as Hoy. */
class TeacherAtRisk {
  const TeacherAtRisk({
    required this.uid,
    required this.name,
    required this.lastWeek,
    required this.usualWeek,
  });

  final String uid;
  final String? name;
  final int lastWeek;
  final double usualWeek;

  factory TeacherAtRisk.fromJson(Map<String, dynamic> json) {
    return TeacherAtRisk(
      uid: json['uid'] as String,
      name: json['name'] as String?,
      lastWeek: (json['lastWeek'] as num).toInt(),
      usualWeek: (json['usualWeek'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'lastWeek': lastWeek,
      'usualWeek': usualWeek,
    };
  }

  /**
   * [weeks] are the answers of appOpens/teachers, oldest first. A teacher missing from a week
   * opened the app 0 times that week. It runs in an isolate (compute), so it only takes and
   * returns plain lists and maps. The biggest drops come first.
   */
  static List<Map<String, dynamic>> findAtRisk(List<Map<String, dynamic>> weeks) {
    final Map<String, List<int>> opens = {};
    final Map<String, String?> names = {};
    for (int i = 0; i < weeks.length; i++) {
      for (final dynamic row in weeks[i]['teachers'] as List) {
        final String uid = row['uid'] as String;
        opens.putIfAbsent(uid, () => List<int>.filled(weeks.length, 0))[i] =
            (row['opens'] as num).toInt();
        names[uid] ??= row['fullName'] as String?;
      }
    }
    final List<TeacherAtRisk> atRisk = [];
    opens.forEach((String uid, List<int> perWeek) {
      final EngagementRisk risk = EngagementRisk.fromWeeklyOpens(perWeek);
      if (!risk.atRisk) return;
      atRisk.add(
        TeacherAtRisk(
          uid: uid,
          name: names[uid],
          lastWeek: risk.lastWeek,
          usualWeek: risk.usualWeek,
        ),
      );
    });
    atRisk.sort((TeacherAtRisk a, TeacherAtRisk b) {
      return (b.usualWeek - b.lastWeek).compareTo(a.usualWeek - a.lastWeek);
    });
    return [for (final TeacherAtRisk teacher in atRisk) teacher.toJson()];
  }
}
