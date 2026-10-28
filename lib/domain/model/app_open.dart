/** One time the teacher opened the app, kept until the server confirms it. */
class AppOpen {
  const AppOpen({
    required this.clientId,
    required this.openedAt,
    required this.week,
    this.sent = false,
  });
  final String clientId;
  final DateTime openedAt;
  final String week;
  final bool sent;

  factory AppOpen.fromJson(Map<String, dynamic> json) {
    return AppOpen(
      clientId: json['clientId'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      week: json['week'] as String,
      sent: json['sent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'openedAt': openedAt.toUtc().toIso8601String(),
      'week': week,
      'sent': sent,
    };
  }

  AppOpen markSent() {
    return AppOpen(
      clientId: clientId,
      openedAt: openedAt,
      week: week,
      sent: true,
    );
  }
}
