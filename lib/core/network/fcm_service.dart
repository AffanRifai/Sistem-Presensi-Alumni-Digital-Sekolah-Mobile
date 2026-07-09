import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class FcmService {
  FcmService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Inisialisasi Firebase Messaging
  Future<void> init() async {
    if (kIsWeb) return; // Web push ditangani terpisah

    try {
      // 1. Minta izin notifikasi (iOS/Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        print('[FcmService] Izin notifikasi: ${settings.authorizationStatus}');
      }

      // 2. Daftarkan token FCM ke server
      await registerDeviceToken();

      // 3. Tangani notifikasi saat aplikasi di foreground (aktif dibuka)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[FcmService] Menerima notifikasi foreground!');
          print('Judul: ${message.notification?.title}');
          print('Isi: ${message.notification?.body}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Gagal inisialisasi FCM: $e');
      }
    }
  }

  /// Ambil token perangkat dan daftarkan ke Laravel backend
  Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      if (kDebugMode) {
        print('[FcmService] Token FCM Perangkat: $token');
      }

      final deviceType = Platform.isIOS ? 'ios' : 'android';

      await _apiClient.post(
        '/device-token',
        body: {
          'token': token,
          'device_type': deviceType,
        },
      );

      if (kDebugMode) {
        print('[FcmService] Token FCM berhasil disinkronkan ke server backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Gagal menyinkronkan token FCM ke server: $e');
      }
    }
  }
}
