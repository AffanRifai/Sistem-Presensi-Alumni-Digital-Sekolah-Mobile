import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_exception.dart';
import 'app_notification_models.dart';
import 'notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();

  final NotificationService _service = NotificationService();

  bool isLoading = false;
  String? errorMessage;
  int unreadCount = 0;
  List<AppNotificationModel> notifications = const [];

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _service.fetchNotifications();
      notifications = result.notifications;
      unreadCount = result.unreadCount;
      errorMessage = null;
    } on ApiException catch (error, stackTrace) {
      errorMessage = ErrorMapper.getMessage(
        error,
        fallback: 'Tidak bisa memuat notifikasi.',
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      errorMessage = ErrorMapper.getMessage(
        error,
        fallback: 'Tidak bisa memuat notifikasi.',
        stackTrace: stackTrace,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount = await _service.fetchUnreadCount();
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorMapper.getMessage(error, stackTrace: stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      unreadCount = 0;
      notifications = notifications
          .map(
            (notification) => AppNotificationModel(
              id: notification.id,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              payload: notification.payload,
              readAt: notification.readAt ?? DateTime.now(),
              createdAt: notification.createdAt,
            ),
          )
          .toList();
      notifyListeners();
    } catch (error, stackTrace) {
      ErrorMapper.getMessage(error, stackTrace: stackTrace);
    }
  }

  void handleIncomingPush() {
    unreadCount += 1;
    notifyListeners();
    load(silent: true);
  }
}
