import 'package:flutter/material.dart';

import 'data/app_notification_models.dart';
import 'data/notification_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController _controller = NotificationController.instance;

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) => _controller.markAllAsRead());
  }

  Future<void> _refresh() async {
    await _controller.load();
    await _controller.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali'),
                style: TextButton.styleFrom(
                  foregroundColor: NotificationPage.textDark,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Notifikasi',
                style: TextStyle(
                  color: NotificationPage.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Presensi dan informasi terbaru dari sekolah.',
                style: TextStyle(
                  color: NotificationPage.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: NotificationPage.primaryBlue,
                      ),
                    );
                  }

                  if (_controller.errorMessage != null) {
                    return _ErrorNotification(
                      message: _controller.errorMessage!,
                      onRetry: _refresh,
                    );
                  }

                  final notifications = _controller.notifications;
                  if (notifications.isEmpty) {
                    return const _EmptyNotification();
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: NotificationPage.primaryBlue,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NotificationCard(
                          notification: notifications[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isAttendance = notification.type == 'student_attendance_recorded';
    final color = isAttendance
        ? NotificationPage.primaryBlue
        : const Color(0xFF20A67A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isUnread ? const Color(0xFFF8FBFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isUnread
              ? NotificationPage.primaryBlue.withValues(alpha: 0.28)
              : NotificationPage.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAttendance
                  ? Icons.fact_check_outlined
                  : Icons.campaign_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          color: NotificationPage.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (notification.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5, left: 8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.body,
                  style: const TextStyle(
                    color: NotificationPage.textMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _relativeTime(notification.createdAt),
                  style: const TextStyle(
                    color: NotificationPage.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Terbaru';

    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ErrorNotification extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorNotification({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NotificationPage.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotification extends StatelessWidget {
  const _EmptyNotification();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada notifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: NotificationPage.textMuted, fontSize: 14),
        ),
      ),
    );
  }
}
