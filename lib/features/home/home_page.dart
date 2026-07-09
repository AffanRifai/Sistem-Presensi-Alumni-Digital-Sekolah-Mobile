import 'package:flutter/material.dart';

import '../alumni/alumni_event_page.dart';
import '../alumni/alumni_profile_page.dart';
import '../alumni/job_vacancy_page.dart';
import '../auth/data/auth_service.dart';
import '../kelas/kelas_guru_page.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../presensi/pilih_kelas_page.dart';
import '../presensi/scan_qr_attendance_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';
import '../siswa/riwayat_kehadiran_page.dart';
import 'classroom_page.dart';
import 'user_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color white = Color(0xFFFFFFFF);

  final AuthService _authService = AuthService();
  late Future<AuthUser?> _userFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.readUser();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboard(userFuture: _userFuture),
      const ClassroomPage(),
      UserProfilePage(userFuture: _userFuture, authService: _authService),
    ];

    return Scaffold(
      backgroundColor: white,
      body: pages[_selectedIndex],
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final Future<AuthUser?> userFuture;

  const _HomeDashboard({required this.userFuture});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(userFuture: userFuture),
          const SizedBox(height: 20),
          const SizedBox(height: 18),
          const SizedBox(height: 26),
          _MenuSection(userFuture: userFuture),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Future<AuthUser?> userFuture;

  const _HeaderSection({required this.userFuture});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 30),
      color: _HomePageState.primaryBlue,
      child: Stack(
        children: [
          const Positioned(
            right: 4,
            bottom: 0,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 94,
              color: Colors.white24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 31,
                      color: _HomePageState.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<AuthUser?>(
                      future: userFuture,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'User'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatRole(user?.role),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showNotificationInfo(context),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Notifikasi',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Selamat Datang di Sistem Presensi Digital Sekolah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Informasi akademik yang tersedia dalam satu dashboard.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationInfo(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Belum ada notifikasi baru.')));
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
  });
}

class _MenuSection extends StatelessWidget {
  final Future<AuthUser?> userFuture;

  const _MenuSection({required this.userFuture});

  static const List<_MenuItemData> _items = [
    _MenuItemData(
      icon: Icons.event_available_outlined,
      label: 'Presensi Siswa',
      backgroundColor: Color(0xFFFFDDE8),
      iconColor: Color(0xFFE84393),
    ),
    _MenuItemData(
      icon: Icons.assignment_outlined,
      label: 'Lihat Kelas Anda',
      backgroundColor: Color(0xFFFFE9CD),
      iconColor: Color(0xFFF39C12),
    ),
    _MenuItemData(
      icon: Icons.history_outlined,
      label: 'Riwayat Kehadiran',
      backgroundColor: Color(0xFFFFD6D9),
      iconColor: Color(0xFFE53935),
    ),
    _MenuItemData(
      icon: Icons.qr_code_scanner_outlined,
      label: 'Presensi QR',
      backgroundColor: Color(0xFFD4FFF2),
      iconColor: Color(0xFF20C997),
    ),
    _MenuItemData(
      icon: Icons.analytics_outlined,
      label: 'Lihat Kehadiran Siswa',
      backgroundColor: Color(0xFFDDEBFF),
      iconColor: Color(0xFF2F80ED),
    ),
    _MenuItemData(
      icon: Icons.person_outline,
      label: 'Profil Alumni',
      backgroundColor: Color(0xFFDDF8D5),
      iconColor: Color(0xFF45C653),
    ),
    _MenuItemData(
      icon: Icons.event_note_outlined,
      label: 'Event Alumni',
      backgroundColor: Color(0xFFE7D6FF),
      iconColor: Color(0xFF8E44EC),
    ),
    _MenuItemData(
      icon: Icons.work_outline,
      label: 'Lowongan Kerja',
      backgroundColor: Color(0xFFFFDCD2),
      iconColor: Color(0xFFFF7043),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: userFuture,
      builder: (context, snapshot) {
        final role = snapshot.data?.role;
        final items = _items
            .where((item) => _isMenuVisibleForRole(item.label, role))
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _HomePageState.darkBlue,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih fitur yang ingin digunakan.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 26,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _MenuTile(
                    item: item,
                    onTap: () => _handleMenuTap(context, item),
                  );
                },
              ),
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
          label != 'Profil Alumni' &&
          label != 'Event Alumni' &&
          label != 'Lowongan Kerja';
    }

    if (role == 'alumni') {
      return label == 'Profil Alumni' ||
          label == 'Event Alumni' ||
          label == 'Lowongan Kerja';
    }

    return true;
  }

  void _handleMenuTap(BuildContext context, _MenuItemData item) {
    final roleFuture = userFuture;

    if (item.label == 'Presensi QR') {
      roleFuture.then((user) {
        if (!context.mounted) return;
        final page = user?.role == 'student'
            ? const ScanQrAttendancePage()
            : const SelectClassDatePage(mode: PresensiEntryMode.qr);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      });
      return;
    }

    final Widget page = switch (item.label) {
      'Kelas Diampu' => const TeacherClassesPage(),
      'Lihat Kelas Anda' => const ClassRecapListPage(),
      'Riwayat Kehadiran' => const AttendanceHistoryPage(),
      'Lihat Kehadiran Siswa' => const AttendanceRecapSelectClassPage(),
      'Profil Alumni' => const AlumniProfilePage(),
      'Event Alumni' => const AlumniEventPage(),
      'Lowongan Kerja' => const JobVacancyPage(),
      _ => const SelectClassDatePage(mode: PresensiEntryMode.manual),
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
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: item.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 40),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _MainBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        selectedItemColor: _HomePageState.primaryBlue,
        unselectedItemColor: Colors.black45,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_rounded),
            label: 'Ruang Kelas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

String _formatRole(String? value) {
  if (value == null || value.isEmpty) return '-';

  return value
      .split('_')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
