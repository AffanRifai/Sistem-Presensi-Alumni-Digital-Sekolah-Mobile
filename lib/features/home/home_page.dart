import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/fcm_service.dart';
import '../alumni/alumni_event_page.dart';
import '../alumni/alumni_profile_page.dart';
import '../alumni/job_vacancy_page.dart';
import '../auth/data/auth_service.dart';
import '../jadwal_mengajar/data/schedule_reminder_service.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../notification/data/notification_controller.dart';
import '../notification/notification_page.dart';
import '../presensi/pilih_kelas_page.dart';
import '../presensi/scan_qr_attendance_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';
import '../siswa/riwayat_kehadiran_page.dart';
import 'data/education_news_service.dart';
import 'data/parent_today_attendance_service.dart';
import '../orangtua/parent_home_page.dart';
import 'user_profile_page.dart';
import '../jadwal_mengajar/jadwal_mengajar_page.dart';

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

    // Aktifkan pengingat jadwal mengajar (khusus role teacher)
    _initScheduleReminder();
  }

  Future<void> _initScheduleReminder() async {
    final user = await _authService.readUser();
    if (user?.role == 'teacher') {
      await ScheduleReminderService.instance.init();
    }
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
    } catch (error, stackTrace) {
      ErrorMapper.getMessage(error, stackTrace: stackTrace);
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
                ClassRecapListPage(onBack: () => _selectTab(0)),
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
class _HomeDashboard extends StatefulWidget {
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
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _HomePageState.primaryBlue,
      displacement: 12,
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              userFuture: widget.userFuture,
              onProfileTap: widget.onProfileTap,
              onRefresh: widget.onRefresh,
            ),
            const SizedBox(height: 18),
            const _DashboardBannerCarousel(),
            const SizedBox(height: 24),
            FutureBuilder<AuthUser?>(
              future: widget.userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.data?.role == 'parent') {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _ParentQuickAccessCard(),
                      ),
                      const SizedBox(height: 24),
                      const _EducationInformationSection(),
                    ],
                  );
                }

                if (snapshot.data?.role == 'student') {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _StudentQuickAccessCard(),
                      ),
                      const SizedBox(height: 24),
                      const _EducationInformationSection(),
                    ],
                  );
                }

                return Column(
                  children: [
                    _MenuSection(userFuture: widget.userFuture),
                    const SizedBox(height: 28),
                    const _EducationInformationSection(),
                  ],
                );
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
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: FutureBuilder<AuthUser?>(
        future: userFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _HomePageState.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getInitials(user?.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Halo, ${user?.name ?? 'Pengguna'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Selamat datang, ',
                        children: [
                          TextSpan(
                            text: _formatRole(user?.role),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                          NotificationController.instance.refreshUnreadCount();
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF374151),
                        ),
                        tooltip: 'Notifikasi',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
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
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          );
        },
      ),
    );
  }

  String _getInitials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'PG';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _DashboardBannerData {
  final String imageAsset;

  const _DashboardBannerData({required this.imageAsset});
}

class _DashboardBannerCarousel extends StatefulWidget {
  const _DashboardBannerCarousel();

  @override
  State<_DashboardBannerCarousel> createState() =>
      _DashboardBannerCarouselState();
}

class _DashboardBannerCarouselState extends State<_DashboardBannerCarousel> {
  static const List<_DashboardBannerData> _banners = [
    _DashboardBannerData(
      imageAsset: 'assets/images/home/sistem_presensi_digital.png',
    ),
    _DashboardBannerData(
      imageAsset: 'assets/images/home/hari_pendidikan_nasional_2026.png',
    ),
    _DashboardBannerData(
      imageAsset: 'assets/images/home/hut_kemerdekaan_2026.png',
    ),
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.91);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextIndex = (_activeIndex + 1) % _banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handlePageChanged(int index) {
    setState(() => _activeIndex = index);
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 144,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final banner = _banners[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _DashboardBannerCard(banner: banner),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = index == _activeIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? _HomePageState.primaryBlue
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DashboardBannerCard extends StatelessWidget {
  final _DashboardBannerData banner;

  const _DashboardBannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        banner.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _EducationInformationSection extends StatefulWidget {
  const _EducationInformationSection();

  @override
  State<_EducationInformationSection> createState() =>
      _EducationInformationSectionState();
}

class _EducationInformationSectionState
    extends State<_EducationInformationSection> {
  final EducationNewsService _service = EducationNewsService();

  bool _isLoading = true;
  String? _errorMessage;
  List<EducationNews> _articles = const [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final articles = await _service.fetchLatest();
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Informasi pendidikan sedang tidak tersedia.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pendidikan',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kabar dan wawasan terbaru dari sumber pendidikan resmi.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_errorMessage != null)
            _EducationInformationError(
              message: _errorMessage!,
              onRetry: _loadNews,
            )
          else if (_articles.isEmpty)
            const Text(
              'Belum ada informasi pendidikan terbaru.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ..._articles.map(
              (article) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EducationInformationCard(article: article),
              ),
            ),
        ],
      ),
    );
  }
}

class _EducationInformationCard extends StatelessWidget {
  final EducationNews article;

  const _EducationInformationCard({required this.article});

  Future<void> _openArticle() async {
    final uri = Uri.parse(article.articleUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _openArticle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  article.imageUrl,
                  width: 108,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 108,
                    height: 78,
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${article.source} · ${article.publishedAt}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducationInformationError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EducationInformationError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
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
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat informasi kehadiran anak.',
          stackTrace: stackTrace,
        );
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
  final String iconAsset;
  final String label;

  const _MenuItemData({required this.iconAsset, required this.label});
}

class _StudentQuickAccessCard extends StatefulWidget {
  const _StudentQuickAccessCard();

  @override
  State<_StudentQuickAccessCard> createState() =>
      _StudentQuickAccessCardState();
}

class _StudentQuickAccessCardState extends State<_StudentQuickAccessCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kehadiran Saya',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceHistoryPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _HomePageState.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: _HomePageState.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Kehadiran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Lihat status presensi dan filter berdasarkan bulan.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParentQuickAccessCard extends StatelessWidget {
  const _ParentQuickAccessCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kehadiran Anak Saya',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentHomePage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _HomePageState.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: _HomePageState.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Kehadiran Anak',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Lihat status presensi anak dan filter berdasarkan bulan.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final Future<AuthUser?> userFuture;

  const _MenuSection({required this.userFuture});

  static const List<_MenuItemData> _items = [
    _MenuItemData(
      iconAsset: 'assets/icons/home/presensi_siswa.png',
      label: 'Presensi Siswa',
    ),
    _MenuItemData(
      iconAsset: 'assets/icons/home/jadwal.svg',
      label: 'Jadwal Mengajar',
    ),
    _MenuItemData(
      iconAsset: 'assets/icons/home/kelas.svg',
      label: 'Kelas Siswa',
    ),
    _MenuItemData(
      iconAsset: 'assets/icons/home/kehadiran_siswa.svg',
      label: 'Riwayat Kehadiran',
    ),
    _MenuItemData(
      iconAsset: 'assets/icons/home/presensi_qr.png',
      label: 'Presensi QR',
    ),
    _MenuItemData(
      iconAsset: 'assets/icons/home/kehadiran_siswa.svg',
      label: 'Kehadiran Siswa',
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Layanan Sekolah',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Layanan tidak ditemukan.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
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
      'Jadwal Mengajar' => const JadwalMengajarPage(),
      'Kelas Siswa' => const ClassRecapListPage(),
      'Kehadiran Siswa' => const AttendanceRecapSelectClassPage(),
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
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDCE3EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: _HomePageState.primaryBlue.withValues(alpha: 0.07),
        splashColor: _HomePageState.primaryBlue.withValues(alpha: 0.14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EducationMenuIcon(item: item),
              const SizedBox(height: 9),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducationMenuIcon extends StatelessWidget {
  final _MenuItemData item;

  const _EducationMenuIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.iconAsset.toLowerCase().endsWith('.svg')) {
      return Image.asset(
        item.iconAsset,
        width: 46,
        height: 42,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported_outlined,
          size: 42,
          color: Colors.grey,
        ),
      );
    }

    return SvgPicture.asset(
      item.iconAsset,
      width: 46,
      height: 42,
      fit: BoxFit.contain,
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

  switch (value.toLowerCase()) {
    case 'teacher':
      return 'Guru';
    case 'student':
      return 'Siswa';
    case 'parent':
      return 'Orang Tua';
    case 'alumni':
      return 'Alumni';
    case 'admin':
      return 'Admin';
    default:
      return value
          .split('_')
          .map((word) {
            if (word.isEmpty) return word;
            return '${word[0].toUpperCase()}${word.substring(1)}';
          })
          .join(' ');
  }
}
