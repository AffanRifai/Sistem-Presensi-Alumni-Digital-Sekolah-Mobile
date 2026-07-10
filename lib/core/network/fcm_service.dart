import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/notification/data/notification_controller.dart';
import '../navigation/app_navigator.dart';
import 'api_client.dart';

class FcmService {
  FcmService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static bool _isInitialized = false;
  static const String _channelId = 'attendance_notifications';
  static const String _channelName = 'Presensi Sekolah';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiClient _apiClient;

  /// Inisialisasi Firebase Messaging
  Future<void> init() async {
    if (kIsWeb) return; // Web push ditangani terpisah
    if (_isInitialized) return;

    try {
      // 1. Minta izin notifikasi (iOS/Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _initLocalNotifications();

      if (kDebugMode) {
        print('[FcmService] Izin notifikasi: ${settings.authorizationStatus}');
      }

      // 2. Daftarkan token FCM ke server
      await registerDeviceToken();
      await NotificationController.instance.refreshUnreadCount();
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        registerDeviceToken(tokenOverride: token);
      });

      // 3. Tangani notifikasi saat aplikasi di foreground (aktif dibuka)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notifikasi';
        final body = message.notification?.body ?? '';

        NotificationController.instance.handleIncomingPush();
        _showLocalNotification(title, body, message);
        _showForegroundMessage(title, body);

        if (kDebugMode) {
          print('[FcmService] Menerima notifikasi foreground!');
          print('Judul: $title');
          print('Isi: $body');
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        NotificationController.instance.load(silent: true);
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Gagal inisialisasi FCM: $e');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: settings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi presensi siswa dan informasi sekolah.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Ambil token perangkat dan daftarkan ke Laravel backend
  Future<void> registerDeviceToken({String? tokenOverride}) async {
    try {
      final token =
          tokenOverride ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      if (kDebugMode) {
        print('[FcmService] Token FCM Perangkat: $token');
      }

      final deviceType = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      await _apiClient.post(
        '/device-token',
        body: {'token': token, 'device_type': deviceType},
      );

      if (kDebugMode) {
        print(
          '[FcmService] Token FCM berhasil disinkronkan ke server backend.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Gagal menyinkronkan token FCM ke server: $e');
      }
    }
  }

  void _showForegroundMessage(String title, String body) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;

    final message = body.isEmpty ? title : '$title\n$body';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    RemoteMessage message,
  ) async {
    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi presensi siswa dan informasi sekolah.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }
}
