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

  NotificationItem copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? metadata,
    bool? read,
    String? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final metadataValue = json['metadata'] ?? json['meta'];

    return NotificationItem(
      id: _asInt(json['id']) ?? 0,
      title: _asString(json['title']),
      message: _asString(json['message'] ?? json['body'] ?? json['content']),
      type: _asString(json['type'], fallback: 'system'),
      metadata: metadataValue is Map
          ? Map<String, dynamic>.from(metadataValue)
          : null,
      read: _readFlagFromJson(json),
      createdAt: _asString(
        json['created_at'] ??
            json['createdAt'] ??
            json['created'] ??
            json['timestamp'],
      ),
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
    final notifications = _extractNotificationEntries(json)
        .whereType<Map>()
        .map((item) =>
            NotificationItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return NotificationsResponse(
      notifications: notifications,
      unreadCount: _resolveUnreadCount(json, notifications),
    );
  }

  Map<String, dynamic> toJson() => {
        'notifications': notifications.map((n) => n.toJson()).toList(),
        'unread_count': unreadCount,
      };
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim());
  }

  return null;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'read' ||
        normalized == 'viewed';
  }

  return false;
}

bool _readFlagFromJson(Map<String, dynamic> json) {
  const directReadKeys = [
    'read',
    'is_read',
    'isRead',
    'viewed',
    'is_viewed',
    'isViewed',
    'seen',
  ];

  for (final key in directReadKeys) {
    if (json.containsKey(key) && json[key] != null) {
      return _asBool(json[key]);
    }
  }

  const readTimestampKeys = ['read_at', 'readAt', 'viewed_at', 'viewedAt'];
  for (final key in readTimestampKeys) {
    final timestamp = _asString(json[key]);
    if (timestamp.isNotEmpty) {
      return true;
    }
  }

  return false;
}

List<dynamic> _extractNotificationEntries(Map<String, dynamic> json) {
  const keys = ['notifications', 'data', 'items', 'results'];

  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }

  return const <dynamic>[];
}

int _resolveUnreadCount(
  Map<String, dynamic> json,
  List<NotificationItem> notifications,
) {
  final direct = _asInt(json['unread_count'] ?? json['unreadCount']);
  if (direct != null) {
    return direct;
  }

  final nested = json['meta'];
  if (nested is Map<String, dynamic>) {
    final nestedCount = _asInt(nested['unread_count'] ?? nested['unreadCount']);
    if (nestedCount != null) {
      return nestedCount;
    }
  }

  return notifications.where((item) => !item.read).length;
}
