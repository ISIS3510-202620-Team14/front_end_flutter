/** One grouping session created on the phone, kept until the backend confirms it. */
class GroupingSession {
  const GroupingSession({
    required this.clientId,
    required this.schoolId,
    required this.subject,
    required this.groupName,
    required this.studentsCounted,
    required this.teachersCounted,
    required this.studentsAssigned,
    required this.createdAt,
    required this.connectivity,
    this.attempts = 0,
    this.failed = false,
  });
  final String clientId;
  final String schoolId;
  final String subject;
  final String groupName;
  final int studentsCounted;
  final int teachersCounted;
  final int studentsAssigned;
  final DateTime createdAt;
  // online u offline en el momento de crear el grupo.
  final String connectivity;
  final int attempts;
  // El servidor la rechazó de forma definitiva: no se vuelve a intentar.
  final bool failed;

  factory GroupingSession.fromJson(Map<String, dynamic> json) {
    return GroupingSession(
      clientId: json['clientId'] as String,
      schoolId: json['schoolId'] as String,
      subject: json['subject'] as String,
      groupName: json['groupName'] as String,
      studentsCounted: json['studentsCounted'] as int,
      teachersCounted: json['teachersCounted'] as int,
      studentsAssigned: json['studentsAssigned'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      connectivity: json['connectivity'] as String,
      attempts: json['attempts'] as int? ?? 0,
      failed: json['failed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'schoolId': schoolId,
      'subject': subject,
      'groupName': groupName,
      'studentsCounted': studentsCounted,
      'teachersCounted': teachersCounted,
      'studentsAssigned': studentsAssigned,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'connectivity': connectivity,
      'attempts': attempts,
      'failed': failed,
    };
  }

  GroupingSession copyWith({int? attempts, bool? failed}) {
    return GroupingSession(
      clientId: clientId,
      schoolId: schoolId,
      subject: subject,
      groupName: groupName,
      studentsCounted: studentsCounted,
      teachersCounted: teachersCounted,
      studentsAssigned: studentsAssigned,
      createdAt: createdAt,
      connectivity: connectivity,
      attempts: attempts ?? this.attempts,
      failed: failed ?? this.failed,
    );
  }
}
