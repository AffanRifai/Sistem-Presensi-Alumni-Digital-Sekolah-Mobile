import 'package:flutter/material.dart';

import '../../core/network/fcm_service.dart';
import '../alumni/alumni_event_page.dart';
import '../alumni/alumni_profile_page.dart';
import '../alumni/job_vacancy_page.dart';
import '../auth/data/auth_service.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../notification/data/notification_controller.dart';
import '../notification/notification_page.dart';
import '../presensi/pilih_kelas_page.dart';
import '../presensi/scan_qr_attendance_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';
import '../siswa/data/student_attendance_models.dart';
import '../siswa/data/student_attendance_service.dart';
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
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.readUser();

    // Inisialisasi token FCM perangkat dan daftarkan ke Laravel backend
    FcmService().init();
    NotificationController.instance.refreshUnreadCount();
  }

  // Fungsi untuk melompat ke tab profil jika avatar diklik
  void _goToProfile(int profileIndex) {
    _selectTab(profileIndex);
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _refreshHome() async {
    AuthUser? refreshedUser;

    try {
      refreshedUser = await _authService.refreshCurrentUser();
    } catch (_) {
      refreshedUser = await _authService.readUser();
    }

    await NotificationController.instance.refreshUnreadCount();

    if (!mounted) return;
    setState(() {
      _refreshVersion++;
      _userFuture = Future<AuthUser?>.value(refreshedUser);
    });
  }

  void _handleBottomNavTap(
    BuildContext context,
    int index,
    bool isAlumni,
    bool isStudent,
  ) {
    if (isStudent && index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanQrAttendancePage()),
      );
      return;
    }

    if (isAlumni) {
      _selectTab(index);
      return;
    }

    if (index == 2) {
      _selectTab(2);
      return;
    }

    _selectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthUser?>(
      future: _userFuture,
      builder: (context, snapshot) {
        // Tampilkan layar loading saat mengecek data user
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

        // Cek apakah user adalah alumni
        final bool isAlumni = snapshot.data?.role == 'alumni';
        final bool isStudent = snapshot.data?.role == 'student';
        final bool isTeacher = snapshot.data?.role == 'teacher';
        final int profileIndex = (isAlumni || isStudent || isTeacher) ? 2 : 1;

        // Tentukan halaman berdasarkan role
        final List<Widget> pages = isAlumni
            ? [
                _AlumniHomeDashboard(
                  key: ValueKey('alumni-home-$_refreshVersion'),
                  userFuture: _userFuture,
                  onProfileTap: () => _goToProfile(profileIndex),
                  onRefresh: _refreshHome,
                ), // Index 0: Home (Header Biru + Lowongan Kerja)
                const AlumniEventPage(), // Index 1: Event Alumni
                const AlumniProfilePage(), // Index 2: Profil Alumni
              ]
            : isTeacher
            ? [
                _HomeDashboard(
                  key: ValueKey('teacher-home-$_refreshVersion'),
                  userFuture: _userFuture,
                  onProfileTap: () => _goToProfile(profileIndex),
                  onRefresh: _refreshHome,
                ),
                ClassRecapListPage(
                  onBack: () => _selectTab(0),
                ),
                UserProfilePage(
                  userFuture: _userFuture,
                  authService: _authService,
                ),
              ]
            : isStudent
            ? [
                _HomeDashboard(
                  key: ValueKey('student-home-$_refreshVersion'),
                  userFuture: _userFuture,
                  onProfileTap: () => _goToProfile(profileIndex),
                  onRefresh: _refreshHome,
                ),
                const SizedBox.shrink(),
                UserProfilePage(
                  userFuture: _userFuture,
                  authService: _authService,
                ),
              ]
            : [
                _HomeDashboard(
                  key: ValueKey('default-home-$_refreshVersion'),
                  userFuture: _userFuture,
                  onProfileTap: () => _goToProfile(profileIndex),
                  onRefresh: _refreshHome,
                ),
                UserProfilePage(
                  userFuture: _userFuture,
                  authService: _authService,
                ),
              ];

        // Proteksi jika index di luar batas saat perpindahan role
        int safeIndex = _selectedIndex;
        if (safeIndex >= pages.length) safeIndex = 0;

        return Scaffold(
          backgroundColor: white,
          body: _AnimatedTabStack(index: safeIndex, children: pages),
          bottomNavigationBar: _MainBottomNavigation(
            isAlumni: isAlumni,
            isStudent: isStudent,
            isTeacher: isTeacher,
            selectedIndex: safeIndex,
            onTap: (index) =>
                _handleBottomNavTap(context, index, isAlumni, isStudent),
          ),
        );
      },
    );
  }
}

class _AnimatedTabStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedTabStack({required this.index, required this.children});

  @override
  State<_AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<_AnimatedTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _currentIndex = 0;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.index != _currentIndex) {
      _direction = widget.index > _currentIndex ? 1 : -1;
      _currentIndex = widget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slideDistance = constraints.maxWidth * 0.22;

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Stack(
              children: List.generate(widget.children.length, (childIndex) {
                final isCurrent = childIndex == _currentIndex;
                final offsetX = isCurrent
                    ? _direction * slideDistance * (1 - _animation.value)
                    : 0.0;

                return Offstage(
                  offstage: !isCurrent,
                  child: IgnorePointer(
                    ignoring: !isCurrent,
                    child: TickerMode(
                      enabled: isCurrent,
                      child: Transform.translate(
                        offset: Offset(offsetX, 0),
                        child: widget.children[childIndex],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// WIDGET KHUSUS ALUMNI (HEADER BIRU + LOWONGAN KERJA)
// ============================================================================
class _AlumniHomeDashboard extends StatelessWidget {
  final Future<AuthUser?> userFuture;
  final VoidCallback onProfileTap;
  final Future<void> Function() onRefresh;

  const _AlumniHomeDashboard({
    super.key,
    required this.userFuture,
    required this.onProfileTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _HomePageState.primaryBlue,
      displacement: 12,
      onRefresh: onRefresh,
      child: Column(
        children: [
          // 1. Header Biru tetap dipertahankan
          _HeaderSection(
            userFuture: userFuture,
            onProfileTap: onProfileTap,
            onRefresh: onRefresh,
          ),

          // 2. Sisa layar di bawahnya langsung diisi oleh halaman Lowongan Kerja
          const Expanded(child: JobVacancyPage(enablePullRefresh: false)),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET KHUSUS SISWA / GURU (HEADER BIRU + MENU KOTAK)
// ============================================================================
class _HomeDashboard extends StatelessWidget {
  final Future<AuthUser?> userFuture;
  final VoidCallback onProfileTap;
  final Future<void> Function() onRefresh;

  const _HomeDashboard({
    super.key,
    required this.userFuture,
    required this.onProfileTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _HomePageState.primaryBlue,
      displacement: 12,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              userFuture: userFuture,
              onProfileTap: onProfileTap,
              onRefresh: onRefresh,
            ),
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

                if (snapshot.data?.role == 'student') {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _StudentQuickAccessCard(),
                      ),
                    ],
                  );
                }

                return _MenuSection(userFuture: userFuture);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET SHARED: HEADER BIRU & NAVIGASI BAWAH
// ============================================================================
class _HeaderSection extends StatelessWidget {
  final Future<AuthUser?> userFuture;
  final VoidCallback onProfileTap;
  final Future<void> Function() onRefresh;

  const _HeaderSection({
    required this.userFuture,
    required this.onProfileTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Icon Pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 140,
                color: Colors.white10,
              ),
            ),
          ),

          // Main Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- AVATAR YANG BISA DIKLIK ---
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<AuthUser?>(
                      future: userFuture,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Pengguna'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatRole(user?.role),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  AnimatedBuilder(
                    animation: NotificationController.instance,
                    builder: (context, _) {
                      final unreadCount =
                          NotificationController.instance.unreadCount;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage(),
                                ),
                              );
                              NotificationController.instance
                                  .refreshUnreadCount();
                            },
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'Notifikasi',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  unreadCount > 99
                                      ? '99+'
                                      : unreadCount.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Sistem Digital Sekolah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Informasi akademik dan layanan sekolah tersedia dalam satu dashboard.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
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

class _StudentQuickAccessCard extends StatefulWidget {
  const _StudentQuickAccessCard();

  @override
  State<_StudentQuickAccessCard> createState() =>
      _StudentQuickAccessCardState();
}

class _StudentQuickAccessCardState extends State<_StudentQuickAccessCard> {
  final StudentAttendanceService _service = StudentAttendanceService();

  bool _isLoading = true;
  String? _errorMessage;
  String _studentName = '-';
  List<StudentAttendanceRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _service.fetchCurrentStudentAttendance(
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
      if (!mounted) return;
      setState(() {
        _studentName = summary.profile?.name ?? '-';
        _records = summary.records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat riwayat kehadiran saat ini.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daftar kehadiran terbaru Anda bulan ini.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          )
        else if (_records.isEmpty)
          const Text(
            'Belum ada data kehadiran bulan ini.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          )
        else
          _StudentAttendanceTable(studentName: _studentName, records: _records),
      ],
    );
  }
}

class _StudentAttendanceTable extends StatelessWidget {
  final String studentName;
  final List<StudentAttendanceRecord> records;

  const _StudentAttendanceTable({
    required this.studentName,
    required this.records,
  });

  String _formatDate(DateTime date) {
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

  String _formatAttendanceTime(StudentAttendanceRecord record) {
    final time = record.checkInTime;
    if (time == null || time.trim().isEmpty) {
      return _formatDate(record.date);
    }

    return '${_formatDate(record.date)}\n$time';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height:
          records.length * 74 +
          42, // Perkiraan tinggi tabel berdasarkan jumlah baris
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 42,
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: 74,
                  horizontalMargin: 8,
                  columnSpacing: 14,
                  border: TableBorder.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1.2,
                  ),
                  headingTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  columns: const [
                    DataColumn(label: Text('No')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Waktu Presensi')),
                    DataColumn(label: Text('Status Presensi')),
                  ],
                  rows: List.generate(records.length, (index) {
                    final record = records[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 120,
                              maxWidth: 240,
                            ),
                            child: Text(
                              studentName,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 150,
                              maxWidth: 240,
                            ),
                            child: Text(
                              _formatAttendanceTime(record),
                              softWrap: true,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            record.statusLabel,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih fitur layanan yang ingin Anda gunakan.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 0),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
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
      return false;
    }
    if (role == 'teacher') {
      return label != 'Riwayat Kehadiran';
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
      'Lihat Kehadiran Siswa' => const AttendanceRecapSelectClassPage(),
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
      borderRadius: BorderRadius.circular(20),
      highlightColor: item.backgroundColor.withValues(alpha: 0.3),
      splashColor: item.backgroundColor.withValues(alpha: 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: item.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 32),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
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
  final bool isAlumni;
  final bool isStudent;
  final bool isTeacher;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _MainBottomNavigation({
    required this.isAlumni,
    required this.isStudent,
    required this.isTeacher,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isStudent) {
      return _StudentBottomNavigation(
        selectedIndex: selectedIndex,
        onTap: onTap,
      );
    }

    // Navigasi Bawah Khusus Alumni HANYA 3 MENU (Home, Event, Profil)
    final List<BottomNavigationBarItem> navItems = isAlumni
        ? const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.event_note_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.event_note),
              ),
              label: 'Event',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Profil',
            ),
          ]
        : isTeacher
        ? const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.class_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.class_),
              ),
              label: 'Ruang Kelas',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Profil',
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            backgroundColor: Colors.white,
            elevation: 0,
            iconSize: 30,
            selectedItemColor: const Color(0xFF1E88E5), // primaryBlue
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
        ),
      ),
    );
  }
}

class _StudentBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _StudentBottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  static const Color primaryBlue = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 104 + bottomPadding,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 78 + bottomPadding,
              padding: EdgeInsets.only(bottom: bottomPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StudentNavSideItem(
                      icon: selectedIndex == 0
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                      label: 'Home',
                      selected: selectedIndex == 0,
                      onTap: () => onTap(0),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: _StudentNavSideItem(
                      icon: selectedIndex == 2
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      label: 'Profil',
                      selected: selectedIndex == 2,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryBlue,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Scan',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentNavSideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StudentNavSideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _StudentBottomNavigation.primaryBlue
        : Colors.grey.shade500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
