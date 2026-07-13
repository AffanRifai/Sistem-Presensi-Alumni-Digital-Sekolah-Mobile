import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'schedule_model.dart';
import 'schedule_service.dart';

/// Service yang memeriksa jadwal mengajar secara berkala dan mengirim
/// notifikasi HP ketika jam masuk mengajar ≤ 15 menit lagi.
class ScheduleReminderService {
  ScheduleReminderService._();
  static final ScheduleReminderService instance = ScheduleReminderService._();

  // ─── Notifikasi ─────────────────────────────────────────────────────────
  static const String _channelId = 'schedule_reminder';
  static const String _channelName = 'Pengingat Jadwal Mengajar';
  static const int _notificationBase = 90000; // range id agar tidak bentrok

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ─── State internal ──────────────────────────────────────────────────────
  Timer? _timer;
  bool _isRunning = false;

  /// Kunci jadwal yang sudah diberi notifikasi pada sesi ini agar tidak
  /// mengirim ulang setiap menit. Format: "day|startTime|subjectName"
  final Set<String> _notified = {};

  // ─── Inisialisasi ────────────────────────────────────────────────────────

  /// Panggil sekali saat login berhasil (dari `FcmService.init()` atau
  /// `HomePage.initState()`).
  Future<void> init() async {
    if (_isRunning) return;

    await _setupChannel();
    _isRunning = true;

    // Cek langsung pertama kali, lalu setiap 60 detik
    await _checkAndNotify();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkAndNotify();
    });

    if (kDebugMode) print('[ScheduleReminderService] Mulai berjalan.');
  }

  /// Hentikan service (misalnya saat logout).
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _notified.clear();
    if (kDebugMode) print('[ScheduleReminderService] Dihentikan.');
  }

  // ─── Logika cek jadwal ───────────────────────────────────────────────────

  Future<void> _checkAndNotify() async {
    try {
      final now = DateTime.now();

      // Hanya jalankan pada hari kerja (Senin–Sabtu)
      if (now.weekday == DateTime.sunday) return;

      // Reset daftar yang sudah dinotifikasi pada awal hari baru
      final todayKey = '${now.year}-${now.month}-${now.day}';
      if (_lastCheckedDate != todayKey) {
        _notified.clear();
        _lastCheckedDate = todayKey;
      }

      final allSchedules = await ScheduleService().fetchSchedules();
      final todayDayName = _dayName(now.weekday);
      final todaySchedules = _findDay(allSchedules, todayDayName);

      if (todaySchedules == null || todaySchedules.isEmpty) return;

      final nowMins = now.hour * 60 + now.minute;

      for (final item in todaySchedules) {
        final startMins = _toMin(item.startTime);
        if (startMins == null) continue;

        final diff = startMins - nowMins;

        // Hanya notifikasi jika 1 ≤ sisa menit ≤ 15
        if (diff < 1 || diff > 15) continue;

        final key = '$todayKey|${item.startTime}|${item.subjectName}';
        if (_notified.contains(key)) continue;

        _notified.add(key);
        await _sendNotification(item, diff);
      }
    } catch (e) {
      if (kDebugMode) print('[ScheduleReminderService] Error: $e');
    }
  }

  String _lastCheckedDate = '';

  // ─── Helper ──────────────────────────────────────────────────────────────

  int? _toMin(String t) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mn = int.tryParse(m.group(2)!);
    return (h == null || mn == null) ? null : h * 60 + mn;
  }

  static String _dayName(int weekday) {
    const map = {
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'sunday',
    };
    return map[weekday] ?? 'monday';
  }

  List<ScheduleItem>? _findDay(
    Map<String, List<ScheduleItem>> all,
    String day,
  ) {
    for (final e in all.entries) {
      if (e.key.toLowerCase() == day) return e.value;
    }
    return null;
  }

  // ─── Notifikasi ──────────────────────────────────────────────────────────

  Future<void> _setupChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pengingat jadwal mengajar yang akan segera dimulai.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    if (kDebugMode) {
      print('[ScheduleReminderService] Notification channel siap.');
    }
  }

  Future<void> _sendNotification(ScheduleItem item, int minutesLeft) async {
    final id = (_notificationBase + item.id).hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Pengingat jadwal mengajar yang akan segera dimulai.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final title = '⏰ Mengajar $minutesLeft menit lagi!';
    final body =
        '${item.subjectName} • Kelas ${item.className} • Ruang ${item.room}\n'
        'Jam: ${item.startTime} – ${item.endTime}';

    await _localNotif.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );

    if (kDebugMode) {
      print('[ScheduleReminderService] Notifikasi terkirim → $title | $body');
    }
  }
}
