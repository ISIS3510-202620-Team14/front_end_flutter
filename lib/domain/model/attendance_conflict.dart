/** A rejected attendance mark kept for review. */
class AttendanceConflict {
  /** Creates a saved conflict. */
  const AttendanceConflict({
    required this.operationId,
    required this.studentId,
    required this.name,
    required this.schoolId,
    required this.date,
    required this.sent,
    required this.kept,
    this.reviewed = false,
  });
  final String operationId;
  final String studentId;
  final String name;
  final String schoolId;
  final String date;
  final String sent;
  final String kept;
  final bool reviewed;

  /** Reads a saved conflict. */
  factory AttendanceConflict.fromJson(Map<String, dynamic> value) {
    return AttendanceConflict(
      operationId: value['operationId'] as String,
      studentId: value['studentId'] as String,
      name: value['name'] as String,
      schoolId: value['schoolId'] as String,
      date: value['date'] as String,
      sent: value['sent'] as String,
      kept: value['kept'] as String,
      reviewed: value['reviewed'] == true,
    );
  }

  /** Returns storage values. */
  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'studentId': studentId,
      'name': name,
      'schoolId': schoolId,
      'date': date,
      'sent': sent,
      'kept': kept,
      'reviewed': reviewed,
    };
  }

  /** Returns a readable attendance value. */
  static String label(String value) {
    if (value == 'vino' || value == 'present') return 'Asistió';
    if (value == 'no_vino' || value == 'absent') return 'No asistió';
    return 'Sin registrar';
  }
}
