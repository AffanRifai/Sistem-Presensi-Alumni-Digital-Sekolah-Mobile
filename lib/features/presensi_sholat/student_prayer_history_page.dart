import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../auth/data/auth_service.dart';
import 'data/prayer_attendance_service.dart';
import 'data/prayer_models.dart';
import 'student_prayer_history_detail_page.dart';
import 'widgets/prayer_history_widgets.dart';

class StudentPrayerHistoryPage extends StatefulWidget {
  const StudentPrayerHistoryPage({super.key});

  @override
  State<StudentPrayerHistoryPage> createState() =>
      _StudentPrayerHistoryPageState();
}

class _StudentPrayerHistoryPageState extends State<StudentPrayerHistoryPage> {
  final AuthService _authService = AuthService();
  final PrayerAttendanceService _service = PrayerAttendanceService();

  PrayerHistoryPeriod _selectedPeriod = PrayerHistoryPeriod.daily;
  DateTime _selectedDate = prayerDateOnly(DateTime.now());
  PrayerType? _selectedPrayerType;
  PrayerAttendanceStatus? _selectedStatus;
  bool _isLoading = true;
  String? _errorMessage;
  List<PrayerAttendanceHistoryItem> _allItems = const [];
  List<PrayerAttendanceHistoryItem> _filteredItems = const [];
  int _visibleItemCount = 15;

  bool get _hasActiveFilter =>
      _selectedPrayerType != null || _selectedStatus != null;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.readUser();
      if (user == null || user.role != 'student') {
        throw StateError('Sesi siswa tidak tersedia.');
      }

      final items = await _service.fetchStudentHistory(studentId: user.id);

      if (!mounted) return;
      _allItems = items;
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Riwayat presensi sholat tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final periodStart = switch (_selectedPeriod) {
      PrayerHistoryPeriod.daily => prayerDateOnly(_selectedDate),
      PrayerHistoryPeriod.weekly => prayerWeekStart(_selectedDate),
      PrayerHistoryPeriod.monthly => DateTime(
        _selectedDate.year,
        _selectedDate.month,
      ),
    };
    final periodEnd = switch (_selectedPeriod) {
      PrayerHistoryPeriod.daily => periodStart,
      PrayerHistoryPeriod.weekly => periodStart.add(const Duration(days: 6)),
      PrayerHistoryPeriod.monthly => DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
      ),
    };

    _filteredItems = _allItems.where((item) {
      final date = prayerDateOnly(item.attendanceDate);
      if (date.isBefore(periodStart) || date.isAfter(periodEnd)) return false;
      if (_selectedPrayerType != null &&
          item.prayerType != _selectedPrayerType) {
        return false;
      }
      if (_selectedStatus != null && item.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();
    _visibleItemCount = 15;
  }

  void _updatePeriod(PrayerHistoryPeriod period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
      _applyFilters();
    });
  }

  void _movePeriod(int direction) {
    final next = switch (_selectedPeriod) {
      PrayerHistoryPeriod.daily => _selectedDate.add(Duration(days: direction)),
      PrayerHistoryPeriod.weekly => _selectedDate.add(
        Duration(days: 7 * direction),
      ),
      PrayerHistoryPeriod.monthly => DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
      ),
    };
    if (_isFuturePeriod(next)) return;
    setState(() {
      _selectedDate = next;
      _applyFilters();
    });
  }

  bool _isFuturePeriod(DateTime candidate) {
    final today = prayerDateOnly(DateTime.now());
    return switch (_selectedPeriod) {
      PrayerHistoryPeriod.daily => prayerDateOnly(candidate).isAfter(today),
      PrayerHistoryPeriod.weekly => prayerWeekStart(candidate).isAfter(today),
      PrayerHistoryPeriod.monthly => DateTime(
        candidate.year,
        candidate.month,
      ).isAfter(DateTime(today.year, today.month)),
    };
  }

  Future<void> _pickPeriod() async {
    if (_selectedPeriod == PrayerHistoryPeriod.monthly) {
      final selected = await _showMonthPicker();
      if (selected == null) return;
      setState(() {
        _selectedDate = selected;
        _applyFilters();
      });
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = prayerDateOnly(picked);
      _applyFilters();
    });
  }

  Future<DateTime?> _showMonthPicker() async {
    var month = _selectedDate.month;
    var year = _selectedDate.year;
    final current = DateTime.now();

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final years = List.generate(
            current.year - 2019,
            (index) => 2020 + index,
          );
          return AlertDialog(
            title: const Text('Pilih bulan'),
            content: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: month,
                    decoration: const InputDecoration(labelText: 'Bulan'),
                    items: List.generate(12, (index) {
                      final value = index + 1;
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          formatPrayerMonth(
                            DateTime(2020, value),
                          ).split(' ').first,
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => month = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    items: years
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => year = value);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed:
                    DateTime(
                      year,
                      month,
                    ).isAfter(DateTime(current.year, current.month))
                    ? null
                    : () => Navigator.pop(dialogContext, DateTime(year, month)),
                child: const Text('Pilih'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showPrayerHistoryFilterSheet(
      context,
      prayerType: _selectedPrayerType,
      status: _selectedStatus,
    );
    if (result == null) return;
    setState(() {
      _selectedPrayerType = result.prayerType;
      _selectedStatus = result.status;
      _applyFilters();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedPrayerType = null;
      _selectedStatus = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Riwayat Presensi Sholat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _hasActiveFilter,
              child: const Icon(Icons.tune_rounded),
            ),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              PrayerHistoryPeriodSelector(
                value: _selectedPeriod,
                onChanged: _updatePeriod,
              ),
              const SizedBox(height: 12),
              PrayerHistoryDateSelector(
                period: _selectedPeriod,
                selectedDate: _selectedDate,
                onPrevious: () => _movePeriod(-1),
                onNext: _isFuturePeriod(_nextPeriod)
                    ? null
                    : () => _movePeriod(1),
                onPick: _pickPeriod,
              ),
              if (_hasActiveFilter) ...[
                const SizedBox(height: 10),
                _ActiveFilters(
                  prayerType: _selectedPrayerType,
                  status: _selectedStatus,
                  onReset: _resetFilters,
                ),
              ],
              const SizedBox(height: 16),
              if (_isLoading)
                const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                PrayerHistoryErrorState(
                  message: _errorMessage!,
                  onRetry: _loadHistory,
                )
              else ...[
                PrayerHistorySummary(items: _filteredItems),
                const SizedBox(height: 14),
                _buildPeriodContent(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DateTime get _nextPeriod => switch (_selectedPeriod) {
    PrayerHistoryPeriod.daily => _selectedDate.add(const Duration(days: 1)),
    PrayerHistoryPeriod.weekly => _selectedDate.add(const Duration(days: 7)),
    PrayerHistoryPeriod.monthly => DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
    ),
  };

  Widget _buildPeriodContent() {
    if (_selectedPeriod == PrayerHistoryPeriod.daily) {
      return _buildDailyList();
    }
    final groups = _groupByDate(_filteredItems);
    if (groups.isEmpty) {
      return PrayerHistoryEmptyState(
        message: _hasActiveFilter
            ? 'Tidak ada riwayat yang sesuai filter.'
            : 'Belum ada riwayat pada periode ini.',
        onReset: _hasActiveFilter ? _resetFilters : null,
      );
    }

    final visibleGroups = groups.take(_visibleItemCount).toList();
    return Column(
      children: [
        ...visibleGroups.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _selectedPeriod == PrayerHistoryPeriod.weekly
                ? _StudentWeeklyCard(
                    date: entry.key,
                    items: entry.value,
                    onTap: _openDetail,
                  )
                : _StudentMonthlyCard(
                    date: entry.key,
                    items: entry.value,
                    onTap: _openDetail,
                  ),
          ),
        ),
        if (_visibleItemCount < groups.length)
          TextButton(
            onPressed: () => setState(() => _visibleItemCount += 15),
            child: const Text('Muat Lebih Banyak'),
          ),
      ],
    );
  }

  Widget _buildDailyList() {
    final byPrayer = {for (final item in _filteredItems) item.prayerType: item};
    final visiblePrayerTypes = _selectedPrayerType == null
        ? PrayerType.values
        : [_selectedPrayerType!];

    if (_selectedStatus != null && byPrayer.isEmpty) {
      return PrayerHistoryEmptyState(
        message: 'Tidak ada riwayat yang sesuai filter.',
        onReset: _resetFilters,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E6ED)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(visiblePrayerTypes.length, (index) {
          final type = visiblePrayerTypes[index];
          final item = byPrayer[type];
          return Column(
            children: [
              ListTile(
                onTap: item == null ? null : () => _openDetail(item),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(
                  Icons.mosque_outlined,
                  color: prayerHistoryPrimary,
                ),
                title: Text(
                  type.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  item == null
                      ? 'Belum ada data'
                      : 'Dikirim ${formatPrayerTime(item.submittedAt)}',
                ),
                trailing: item == null
                    ? const Text('-', style: TextStyle(color: Colors.black38))
                    : PrayerHistoryStatusBadge(
                        status: item.status,
                        compact: true,
                      ),
              ),
              if (index != visiblePrayerTypes.length - 1)
                const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }

  List<MapEntry<DateTime, List<PrayerAttendanceHistoryItem>>> _groupByDate(
    List<PrayerAttendanceHistoryItem> items,
  ) {
    final map = <DateTime, List<PrayerAttendanceHistoryItem>>{};
    for (final item in items) {
      map.putIfAbsent(prayerDateOnly(item.attendanceDate), () => []).add(item);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  void _openDetail(PrayerAttendanceHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPrayerHistoryDetailPage(item: item),
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  final PrayerType? prayerType;
  final PrayerAttendanceStatus? status;
  final VoidCallback onReset;

  const _ActiveFilters({
    required this.prayerType,
    required this.status,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (prayerType != null) Chip(label: Text(prayerType!.label)),
              if (status != null) Chip(label: Text(status!.label)),
            ],
          ),
        ),
        TextButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _StudentWeeklyCard extends StatelessWidget {
  final DateTime date;
  final List<PrayerAttendanceHistoryItem> items;
  final ValueChanged<PrayerAttendanceHistoryItem> onTap;

  const _StudentWeeklyCard({
    required this.date,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final byPrayer = {for (final item in items) item.prayerType: item};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatPrayerDate(date),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 11),
          ...PrayerType.values.map((type) {
            final item = byPrayer[type];
            return InkWell(
              onTap: item == null ? null : () => onTap(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        type.label,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    Expanded(
                      child: item == null
                          ? const Text(
                              '-',
                              style: TextStyle(color: Colors.black38),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: PrayerHistoryStatusBadge(
                                status: item.status,
                                compact: true,
                              ),
                            ),
                    ),
                    if (item != null)
                      const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StudentMonthlyCard extends StatelessWidget {
  final DateTime date;
  final List<PrayerAttendanceHistoryItem> items;
  final ValueChanged<PrayerAttendanceHistoryItem> onTap;

  const _StudentMonthlyCard({
    required this.date,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int count(PrayerAttendanceStatus status) =>
        items.where((item) => item.status == status).length;

    return InkWell(
      onTap: items.isEmpty ? null : () => onTap(items.first),
      borderRadius: BorderRadius.circular(15),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1E6ED)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPrayerDate(date),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${items.length} sholat • ${count(PrayerAttendanceStatus.approved)} disetujui • ${count(PrayerAttendanceStatus.pending)} menunggu',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
