class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.type,
    this.targetRole,
    required this.priority,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool read;
  final String type;
  final String? targetRole;
  final int priority;
  final DateTime? readAt;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        read: json['read'] ?? false,
        type: json['type'] ?? 'SYSTEM',
        targetRole: json['targetRole'],
        priority: json['priority'] ?? 0,
        readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
