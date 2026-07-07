import 'package:flutter/material.dart';
import '../auth/data/auth_service.dart';
import '../auth/login_page.dart';
import '../kelas/kelas_guru_page.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../presensi/pilih_kelas_page.dart';
import '../presensi/scan_qr_attendance_page.dart';
import '../siswa/riwayat_kehadiran_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';
import '../alumni/alumni_profile_page.dart';
import '../alumni/alumni_event_page.dart';
import '../alumni/job_vacancy_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _HeaderSection(),
              SizedBox(height: 24),
              _MenuSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// header
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeText = _formatTime(now);
    final dateText = _formatDate(now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90D9), Color(0xFFBFE0F5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30, color: Color(0xFF4A90D9)),
              ),
              const SizedBox(width: 12),
              FutureBuilder<AuthUser?>(
                future: AuthService().readUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final name = user?.name ?? 'User';
                  final role = _formatRole(user?.role);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Jam besar
          Center(
            child: Text(
              timeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              dateText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$day, $month ${dt.day}, ${dt.year}';
  }

  String _formatRole(String? role) {
    if (role == null || role.isEmpty) return 'Role';

    return role
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah kamu yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E87D8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await AuthService().logout();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });
}

class _MenuSection extends StatelessWidget {
  const _MenuSection();

  static const List<_MenuItemData> _items = [
    _MenuItemData(
      icon: Icons.event_available_outlined,
      label: 'Presensi Siswa',
      bgColor: Color(0xFFD9F2E4),
      iconColor: Color(0xFF2E9E5B),
    ),
    _MenuItemData(
      icon: Icons.class_outlined,
      label: 'Kelas yang Diampu',
      bgColor: Color(0xFFD9F2E4),
      iconColor: Color(0xFF2E9E5B),
    ),
    _MenuItemData(
      icon: Icons.assignment_outlined,
      label: 'Rekap Kelas',
      bgColor: Color(0xFFD9F2E4),
      iconColor: Color(0xFF2E9E5B),
    ),
    _MenuItemData(
      icon: Icons.history_outlined,
      label: 'Riwayat Kehadiran',
      bgColor: Color(0xFFD9F2E4),
      iconColor: Color(0xFF2E9E5B),
    ),
    _MenuItemData(
      icon: Icons.qr_code_scanner_outlined,
      label: 'Presensi QR',
      bgColor: Color(0xFFE3EEFF),
      iconColor: Color(0xFF4A90D9),
    ),
    _MenuItemData(
      icon: Icons.analytics_outlined,
      label: 'Rekap Kehadiran',
      bgColor: Color(0xFFD9F2E4),
      iconColor: Color(0xFF2E9E5B),
    ),
    _MenuItemData(
      icon: Icons.person_outline,
      label: 'Profil Alumni',
      bgColor: Color(0xFFE3EEFF),
      iconColor: Color(0xFF4A90D9),
    ),
    _MenuItemData(
      icon: Icons.event_note_outlined,
      label: 'Event Alumni',
      bgColor: Color(0xFFFCEBD3),
      iconColor: Color(0xFFE0983C),
    ),
    _MenuItemData(
      icon: Icons.work_outline,
      label: 'Lowongan Kerja',
      bgColor: Color(0xFFE8F5E9),
      iconColor: Color(0xFF4CAF50),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: AuthService().readUser(),
      builder: (context, snapshot) {
        final role = snapshot.data?.role;
        final items = _items
            .where((item) => _isMenuVisibleForRole(item.label, role))
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gunakan menu ini untuk mengelola data presensi dan akademik.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MenuTile(
                    item: item,
                    onTap: () => _handleMenuTap(context, item),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  bool _isMenuVisibleForRole(String label, String? role) {
    if (role == 'student') {
      return label == 'Riwayat Kehadiran' || label == 'Presensi QR';
    }

    if (role == 'teacher') {
      return label != 'Riwayat Kehadiran' &&
          label != 'Presensi QR' &&
          label != 'Profil Alumni' &&
          label != 'Event Alumni' &&
          label != 'Lowongan Kerja';
    }

    if (role == 'alumni') {
      return label == 'Profil Alumni' || label == 'Event Alumni' || label == 'Lowongan Kerja';
    }

    return true;
  }

  void _handleMenuTap(BuildContext context, _MenuItemData item) {
    final Widget page = switch (item.label) {
      'Kelas yang Diampu' => const TeacherClassesPage(),
      'Rekap Kelas' => const ClassRecapListPage(),
      'Riwayat Kehadiran' => const AttendanceHistoryPage(),
      'Presensi QR' => const ScanQrAttendancePage(),
      'Rekap Kehadiran' => const AttendanceRecapSelectClassPage(),
      'Profil Alumni' => const AlumniProfilePage(),
      'Event Alumni' => const AlumniEventPage(),
      'Lowongan Kerja' => const JobVacancyPage(),
      _ => const SelectClassDatePage(),
    };

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData item;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
