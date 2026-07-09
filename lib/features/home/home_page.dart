import 'package:flutter/material.dart';

import '../alumni/alumni_event_page.dart';
import '../alumni/alumni_profile_page.dart';
import '../alumni/job_vacancy_page.dart';
import '../auth/data/auth_service.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../notification/notification_page.dart';
import '../presensi/pilih_kelas_page.dart';
import '../presensi/scan_qr_attendance_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';
import '../siswa/riwayat_kehadiran_page.dart';
import 'classroom_page.dart';
import 'data/parent_today_attendance_service.dart';
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
          const SizedBox(height: 22),
          FutureBuilder<AuthUser?>(
            future: userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data?.role == 'parent') {
                return const _ParentTodayAttendanceSection();
              }

              return _MenuSection(userFuture: userFuture);
            },
          ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
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
}

class _ParentTodayAttendanceSection extends StatefulWidget {
  const _ParentTodayAttendanceSection();

  @override
  State<_ParentTodayAttendanceSection> createState() =>
      _ParentTodayAttendanceSectionState();
}

class _ParentTodayAttendanceSectionState
    extends State<_ParentTodayAttendanceSection> {
  final ParentTodayAttendanceService _service = ParentTodayAttendanceService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ParentChildAttendance> _children = const [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.fetchSummary();
      if (!mounted) return;
      setState(() {
        _children = summary.children;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat informasi kehadiran anak.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kehadiran Anak Hari Ini',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: _HomePageState.darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ringkasan presensi anak berdasarkan data hari ini.',
            style: TextStyle(fontSize: 13.5, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const _ParentInfoCardLoading()
          else if (_errorMessage != null)
            _ParentInfoCardError(message: _errorMessage!, onRetry: _loadSummary)
          else if (_children.isEmpty)
            const _ParentInfoCardEmpty()
          else
            ..._children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParentChildAttendanceCard(child: child),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParentChildAttendanceCard extends StatelessWidget {
  final ParentChildAttendance child;

  const _ParentChildAttendanceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(child.status);
    final dateText = _formatLongDate(child.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Anak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 18),
          _ParentInfoValue(label: 'Nama Anak', value: child.name),
          _ParentInfoValue(label: 'NIS', value: child.nis),
          _ParentInfoValue(label: 'NISN', value: child.nisn),
          _ParentInfoValue(label: 'Kelas', value: child.className),
          _ParentInfoValue(
            label: 'Kehadiran Hari Ini',
            value: child.statusLabel,
            valueColor: statusColor,
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Pada $dateText anak Anda "${child.name}" ${child.statusLabel.toUpperCase()} di sekolah.',
              style: TextStyle(
                color: statusColor,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'present' => const Color(0xFF16A34A),
      'late' => const Color(0xFFF59E0B),
      'permission' => const Color(0xFF7C3AED),
      'sick' => const Color(0xFF0F766E),
      'absent' => const Color(0xFFDC2626),
      _ => const Color(0xFF6B7280),
    };
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return 'tanggal ${date.day}, bulan ${months[date.month - 1]}, tahun ${date.year}';
  }
}

class _ParentInfoValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ParentInfoValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentInfoCardLoading extends StatelessWidget {
  const _ParentInfoCardLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ParentInfoCardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ParentInfoCardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _ParentInfoCardEmpty extends StatelessWidget {
  const _ParentInfoCardEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Belum ada data anak yang terhubung dengan akun ini.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
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
