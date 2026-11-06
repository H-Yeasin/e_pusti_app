/// NOT-02 categories, plus measurement reminders (P1-4).
enum NotificationCategory { webinar, course, content, general, health }

class InboxItem {
  const InboxItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.route,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  /// In-app destination opened on tap, e.g. `/webinars/w1`.
  final String? route;

  bool get isRead => readAt != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'body': body,
    'created_at': createdAt.toUtc().toIso8601String(),
    'read_at': readAt?.toUtc().toIso8601String(),
    'route': route,
  };

  static InboxItem fromJson(Map<String, Object?> json) => InboxItem(
    id: json['id'] as String,
    category: NotificationCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => NotificationCategory.general,
    ),
    title: json['title'] as String,
    body: (json['body'] as String?) ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    readAt: json['read_at'] == null
        ? null
        : DateTime.parse(json['read_at'] as String).toLocal(),
    route: json['route'] as String?,
  );
}

/// The inbox exists because a swiped-away push is gone forever (NOT-01).
abstract interface class InboxRepository {
  Future<List<InboxItem>> list();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

/// Only in-app routes may be opened from a notification.
String? safeNotificationRoute(String? route) {
  if (route == null || !route.startsWith('/') || route.startsWith('//')) {
    return null;
  }
  return route;
}
