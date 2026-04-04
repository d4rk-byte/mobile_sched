// lib/models/notification_model.dart

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? metadata;
  final bool read;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.metadata,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      metadata: json['metadata'],
      read: json['read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'metadata': metadata,
        'read': read,
        'created_at': createdAt,
      };
}

class NotificationsResponse {
  final List<NotificationItem> notifications;
  final int unreadCount;

  NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['notifications'] as List?)
              ?.map((n) => NotificationItem.fromJson(n))
              .toList() ??
          [],
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'unread_count': unreadCount,
      };
}
