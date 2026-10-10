part of 'grouping_analytics_service.dart';

class GroupingEvent {
  const GroupingEvent({
    required this.subject,
    required this.classSize,
    required this.method,
    required this.teacherId,
    required this.timestamp,
  });
  final String subject;
  final int classSize;
  final GroupingMethod method;
  final String teacherId;
  final DateTime timestamp;
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'classSize': classSize,
      'method': method.name,
      'teacherId': teacherId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GroupingEvent.fromJson(Map<String, dynamic> json) {
    GroupingMethod method = GroupingMethod.manual;
    if (json['method'] == 'automatic') {
      method = GroupingMethod.automatic;
    }
    return GroupingEvent(
      subject: json['subject'] as String,
      classSize: json['classSize'] as int,
      method: method,
      teacherId: json['teacherId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
