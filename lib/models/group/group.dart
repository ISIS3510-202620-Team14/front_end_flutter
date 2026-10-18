class Group {
  final String id;
  final String name;
  final String subject;
  final String teacherId;
  final String schoolId;
  final List<String> studentIds;
  final String? createdAt;
  final String? updatedAt;

  final String? teacherName;

  const Group({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacherId,
    required this.schoolId,
    this.studentIds = const [],
    this.createdAt,
    this.updatedAt,
    this.teacherName,
  });

  int get childrenCount {
    return studentIds.length;
  }

  String get teacherLabel {
    return teacherName ?? teacherId;
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    String? fallbackTeacherName,
  }) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      teacherId: json['teacherId'] as String,
      schoolId: json['schoolId'] as String,
      studentIds: List<String>.from(json['studentIds'] ?? []),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      teacherName:
          (json['teacher'] as Map<String, dynamic>?)?['fullName'] as String? ??
          fallbackTeacherName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'teacherId': teacherId,
      'schoolId': schoolId,
      'studentIds': studentIds,
    };
  }
}
