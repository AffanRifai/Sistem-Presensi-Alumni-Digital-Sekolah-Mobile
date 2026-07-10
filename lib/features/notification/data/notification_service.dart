import '../../../core/network/api_client.dart';
import 'app_notification_models.dart';

class NotificationListResult {
  final int unreadCount;
  final List<AppNotificationModel> notifications;

  const NotificationListResult({
    required this.unreadCount,
    required this.notifications,
  });
}

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<NotificationListResult> fetchNotifications({int limit = 50}) async {
    final response = await _apiClient.get(
      '/notifications',
      queryParameters: {'limit': limit.toString()},
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return const NotificationListResult(unreadCount: 0, notifications: []);
    }

    final rawNotifications = data['notifications'];
    final notifications = rawNotifications is List
        ? rawNotifications
              .whereType<Map<String, dynamic>>()
              .map(AppNotificationModel.fromJson)
              .where((notification) => notification.id.isNotEmpty)
              .toList()
        : <AppNotificationModel>[];

    return NotificationListResult(
      unreadCount: _readInt(data['unread_count']),
      notifications: notifications,
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return _readInt(data['unread_count']);
    }
    return 0;
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post('/notifications/mark-all-read');
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
