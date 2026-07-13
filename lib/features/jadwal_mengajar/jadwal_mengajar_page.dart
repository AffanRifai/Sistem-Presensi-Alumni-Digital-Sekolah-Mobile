import 'dart:async';

import 'package:flutter/material.dart';
import 'data/schedule_model.dart';
import 'data/schedule_service.dart';

class JadwalMengajarPage extends StatefulWidget {
  const JadwalMengajarPage({super.key});

  @override
  State<JadwalMengajarPage> createState() => _JadwalMengajarPageState();
}

class _JadwalMengajarPageState extends State<JadwalMengajarPage> {
  final ScheduleService _service = ScheduleService();

  // State manual (proven stable)
  Map<String, List<ScheduleItem>>? _data;
  Object? _error;
  bool _loading = true;

  // Warna
  static const Color _blue = Color(0xFF2563EB);
  static const Color _blueSoft = Color(0xFFEAF1FE);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _amberSoft = Color(0xFFFEF3E0);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _divider = Color(0xFFE2E8F0);
  static const Color _bg = Color(0xFFF8FAFC);

  static const List<String> _weekOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  // Scroll & sticky header
  final ScrollController _scrollController = ScrollController();
  // GlobalKey pada SETIAP header hari di dalam ListView
  final Map<String, GlobalKey> _dayKeys = {};
  bool _didAutoScroll = false;
  // ValueNotifier: hanya rebuild bagian overlay, bukan seluruh list
  final ValueNotifier<String?> _stickyDay = ValueNotifier(null);

  static const double _stickyH = 58.0; // tinggi overlay sticky header

  // Timer auto-refresh
  Timer? _alignmentTimer;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scheduleAutoRefresh();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stickyDay.dispose();
    _alignmentTimer?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  // ── Load data ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchSchedules();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    _didAutoScroll = false;
    await _loadData();
  }

  // ── Auto-refresh jam 07:00, tiap 45 menit ─────────────────────────────
  Duration _nextSlot() {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, now.day, 7, 0, 0);
    const cycle = Duration(minutes: 45);
    if (now.isBefore(anchor)) return anchor.difference(now);
    final elapsed = now.difference(anchor).inSeconds;
    final cycleS = cycle.inSeconds;
    return anchor
        .add(Duration(seconds: ((elapsed ~/ cycleS) + 1) * cycleS))
        .difference(now);
  }

  void _scheduleAutoRefresh() {
    _alignmentTimer = Timer(_nextSlot(), () {
      _refresh();
      _periodicTimer = Timer.periodic(
        const Duration(minutes: 45),
        (_) => _refresh(),
      );
    });
  }

  // ── Sticky header: update ValueNotifier tanpa setState (no full rebuild) ─
  void _onScroll() {
    String? topDay;
    // Iterasi terbalik supaya dapat hari paling bawah yang sudah lewat garis sticky
    for (final entry in _dayKeys.entries.toList().reversed) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      // Posisi Y header relatif ke layar (bukan ke scroll)
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= _stickyH) {
        topDay = entry.key;
        break;
      }
    }
    if (_stickyDay.value != topDay) {
      _stickyDay.value = topDay;
    }
  }

  // ── Auto-scroll ke hari aktif ─────────────────────────────────────────
  void _scrollToDay(String dayKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final ctx = _dayKeys[dayKey]?.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      } catch (_) {}
    });
  }

  // ── Hitung kartu aktif ────────────────────────────────────────────────
  int? _toMin(String t) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mn = int.tryParse(m.group(2)!);
    return (h == null || mn == null) ? null : h * 60 + mn;
  }

  MapEntry<String, List<ScheduleItem>>? _findEntry(
    Map<String, List<ScheduleItem>> data,
    String key,
  ) {
    for (final e in data.entries) {
      if (e.key.toLowerCase() == key) return e;
    }
    return null;
  }

  _ActiveSchedule? _computeActive(Map<String, List<ScheduleItem>> data) {
    if (data.isEmpty) return null;
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final today = _weekOrder[now.weekday - 1];
    final entry = _findEntry(data, today);

    if (entry != null && entry.value.isNotEmpty) {
      for (var i = 0; i < entry.value.length; i++) {
        final s = _toMin(entry.value[i].startTime);
        final e = _toMin(entry.value[i].endTime);
        if (s != null && e != null && nowMins >= s && nowMins < e) {
          return _ActiveSchedule(dayKey: entry.key, index: i, isOngoing: true);
        }
      }
      for (var i = 0; i < entry.value.length; i++) {
        final s = _toMin(entry.value[i].startTime);
        if (s != null && s > nowMins) {
          return _ActiveSchedule(dayKey: entry.key, index: i, isOngoing: false);
        }
      }
      // Jika semua kelas hari ini sudah selesai, tetap posisikan hari aktif di hari ini tanpa menyorot kartu apa pun
      return _ActiveSchedule(dayKey: entry.key, index: -1, isOngoing: false);
    }
    for (var offset = 1; offset <= 6; offset++) {
      final key = _weekOrder[(now.weekday - 1 + offset) % 7];
      final found = _findEntry(data, key);
      if (found != null && found.value.isNotEmpty) {
        return _ActiveSchedule(dayKey: found.key, index: 0, isOngoing: false);
      }
    }
    return null;
  }

  MapEntry<String, int>? _afterActive(
    Map<String, List<ScheduleItem>> data,
    _ActiveSchedule a,
  ) {
    final flat = <MapEntry<String, int>>[];
    for (final key in data.keys) {
      for (var i = 0; i < data[key]!.length; i++) {
        flat.add(MapEntry(key, i));
      }
    }
    final pos = flat.indexWhere((e) => e.key == a.dayKey && e.value == a.index);
    if (pos == -1 || pos + 1 >= flat.length) return null;
    return flat[pos + 1];
  }

  static String _label(String key) {
    switch (key.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    }
  }

  // ── Build utama ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _blueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: _blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Jadwal Mengajar',
              style: TextStyle(
                color: _dark,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _dark),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _divider),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }

    // Error
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _amberSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: _amber,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat jadwal.',
                style: TextStyle(
                  color: _dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error.toString(),
                style: const TextStyle(color: _muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    final data = _data ?? {};
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: _blueSoft,
              child: Icon(Icons.event_busy_rounded, color: _blue, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada jadwal mengajar.',
              style: TextStyle(color: _muted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Data
    final active = _computeActive(data);
    final afterAct = active == null ? null : _afterActive(data, active);

    if (!_didAutoScroll && active != null) {
      _didAutoScroll = true;
      _scrollToDay(active.dayKey);
    }

    return Stack(
      children: [
        // ── Daftar jadwal ─────────────────────────────────────────────
        RefreshIndicator(
          onRefresh: _refresh,
          color: _blue,
          backgroundColor: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: _stickyH + 8, // beri ruang di bawah sticky header overlay
              bottom: 32,
            ),
            itemCount: data.keys.length,
            itemBuilder: (context, index) {
              final day = data.keys.elementAt(index);
              final schedules = data[day]!;
              final dayKey = _dayKeys.putIfAbsent(day, () => GlobalKey());

              return _DaySection(
                dayKey: dayKey,
                label: _label(day),
                schedules: schedules,
                active: active,
                afterActive: afterAct,
                dayId: day,
              );
            },
          ),
        ),

        // ── Sticky header overlay (hanya rebuild bagian ini) ──────────
        ValueListenableBuilder<String?>(
          valueListenable: _stickyDay,
          builder: (context, day, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: day == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : _StickyHeader(
                      key: ValueKey(day),
                      label: _label(day),
                      height: _stickyH,
                    ),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Data class
// ═══════════════════════════════════════════════════════════════════════
class _ActiveSchedule {
  const _ActiveSchedule({
    required this.dayKey,
    required this.index,
    required this.isOngoing,
  });
  final String dayKey;
  final int index;
  final bool isOngoing;
}

// ═══════════════════════════════════════════════════════════════════════
// Sticky header overlay
// ═══════════════════════════════════════════════════════════════════════
class _StickyHeader extends StatelessWidget {
  const _StickyHeader({super.key, required this.label, required this.height});
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Satu hari — header + kartu
// ═══════════════════════════════════════════════════════════════════════
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.dayKey,
    required this.label,
    required this.schedules,
    required this.active,
    required this.afterActive,
    required this.dayId,
  });

  final GlobalKey dayKey;
  final String label;
  final List<ScheduleItem> schedules;
  final _ActiveSchedule? active;
  final MapEntry<String, int>? afterActive;
  final String dayId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header hari (bukan sticky — overlay yang sticky)
        Padding(
          key: dayKey,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Kartu jadwal — tanpa IntrinsicHeight (no jank)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(schedules.length, (idx) {
              final isAct =
                  active != null &&
                  active!.dayKey == dayId &&
                  active!.index == idx;
              final isOngoing = isAct && active!.isOngoing;
              final isNext = isAct && !active!.isOngoing;
              final cutAbove =
                  afterActive != null &&
                  afterActive!.key == dayId &&
                  afterActive!.value == idx;
              return _ScheduleCard(
                schedule: schedules[idx],
                isFirst: idx == 0,
                isLast: idx == schedules.length - 1,
                isOngoing: isOngoing,
                isNext: isNext,
                cutAbove: cutAbove,
                cutBelow: isAct,
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Kartu jadwal — TANPA IntrinsicHeight (fix jank)
// Garis timeline digambar menggunakan Stack agar garis bersambung sempurna.
// ═══════════════════════════════════════════════════════════════════════
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule, required this.isFirst, required this.isLast,
    required this.isOngoing, required this.isNext,
    required this.cutAbove, required this.cutBelow,
  });

  final ScheduleItem schedule;
  final bool isFirst, isLast, isOngoing, isNext, cutAbove, cutBelow;

  static const Color _blue     = Color(0xFF2563EB);
  static const Color _blueSoft = Color(0xFFEAF1FE);
  static const Color _amber    = Color(0xFFF59E0B);
  static const Color _amberSoft = Color(0xFFFEF3E0);
  static const Color _dark     = Color(0xFF0F172A);
  static const Color _divider  = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final effectiveFirst = isFirst || cutAbove;
    final effectiveLast  = isLast  || cutBelow;

    final Color? accent = isOngoing ? _blue : (isNext ? _amber : null);
    final Color cardBg  = isOngoing ? _blueSoft : (isNext ? _amberSoft : Colors.white);

    // Timeline line position
    const double lineLeft = 14.0;
    const double lineWidth = 2.0;
    // Dot center Y
    const double dotY = 24.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Timeline: Garis atas ──
        if (!effectiveFirst)
          Positioned(
            top: 0,
            bottom: null,
            height: dotY,
            left: lineLeft,
            child: Container(width: lineWidth, color: _divider),
          ),
          
        // ── Timeline: Garis bawah ──
        if (!effectiveLast)
          Positioned(
            top: dotY,
            bottom: 0, // Garis memanjang sampai ke akhir Stack (termasuk bottom margin)
            left: lineLeft,
            child: Container(width: lineWidth, color: _divider),
          ),

        // ── Konten kartu ───────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 36),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent ?? _divider,
                width: accent != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waktu + badge
                Row(
                  children: [
                    _TimeChip(
                      start: schedule.startTime, end: schedule.endTime),
                    const Spacer(),
                    if (isOngoing)
                      _Badge(label: 'Berlangsung', color: _blue, icon: Icons.podcasts_rounded)
                    else if (isNext)
                      _Badge(label: 'Berikutnya', color: _amber, icon: Icons.upcoming_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                // Nama mapel
                Text(schedule.subjectName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _dark, height: 1.3)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: _divider),
                const SizedBox(height: 10),
                // Chip kelas & ruang
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _Chip(icon: Icons.groups_2_rounded,
                        label: 'Kelas ${schedule.className}'),
                    _Chip(icon: Icons.meeting_room_rounded,
                        label: schedule.room),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Timeline: Halo dot ──
        Positioned(
          top: dotY - 9,
          left: lineLeft + (lineWidth / 2) - 9,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: (accent ?? _blue).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // ── Timeline: Dot utama ──
        Positioned(
          top: dotY - 5,
          left: lineLeft + (lineWidth / 2) - 5,
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: accent ?? _blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Time chip ──────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.start, required this.end});
  final String start, end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFD7FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 13,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 5),
          Text(
            '$start – $end',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta chip ──────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE6BF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge status ───────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
