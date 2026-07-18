import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../auth/data/auth_service.dart';
import '../kelas/data/class_recap_models.dart';
import '../kelas/data/class_recap_service.dart';
import 'data/prayer_attendance_service.dart';
import 'data/prayer_models.dart';
import 'teacher_prayer_history_detail_page.dart';
import 'widgets/prayer_history_widgets.dart';

class TeacherPrayerHistoryPage extends StatefulWidget {
  const TeacherPrayerHistoryPage({super.key});

  @override
  State<TeacherPrayerHistoryPage> createState() =>
      _TeacherPrayerHistoryPageState();
}

class _TeacherPrayerHistoryPageState extends State<TeacherPrayerHistoryPage> {
  final AuthService _authService = AuthService();
  final ClassRecapService _classService = ClassRecapService();
  final PrayerAttendanceService _prayerService = PrayerAttendanceService();
  final TextEditingController _searchController = TextEditingController();

  PrayerHistoryPeriod _selectedPeriod = PrayerHistoryPeriod.daily;
  DateTime _selectedDate = prayerDateOnly(DateTime.now());
  String _searchQuery = '';
  int? _selectedClassId;
  PrayerType? _selectedPrayerType;
  PrayerAttendanceStatus? _selectedStatus;
  bool _isLoading = true;
  String? _errorMessage;
  int _visibleItemCount = 15;
  List<ClassRecapModel> _teacherClasses = const [];
  List<PrayerAttendanceHistoryItem> _allItems = const [];
  List<PrayerAttendanceHistoryItem> _filteredItems = const [];
  Timer? _searchDebounce;

  bool get _hasActiveFilter =>
      _selectedClassId != null ||
      _selectedPrayerType != null ||
      _selectedStatus != null ||
      _searchQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.readUser();
      if (user == null || user.role != 'teacher') {
        throw StateError('Sesi guru tidak tersedia.');
      }

      final classes = await _classService.fetchClasses();
      final studentLists = await Future.wait(
        classes.map((classData) => _classService.fetchStudents(classData.id)),
      );
      final membershipById = <int, _AllowedStudent>{};
      final membershipByName = <String, _AllowedStudent>{};

      for (var index = 0; index < classes.length; index++) {
        final classData = classes[index];
        for (final student in studentLists[index]) {
          final membership = _AllowedStudent(
            student: student,
            classData: classData,
          );
          membershipById[student.id] = membership;
          membershipByName[_normalizeName(student.fullName)] = membership;
        }
      }
      final rawItems = await _prayerService.fetchTeacherHistory(
        allowedStudentIds: membershipById.keys,
        allowedStudentNames: membershipByName.keys,
      );
      final enrichedItems = <PrayerAttendanceHistoryItem>[];
      for (final item in rawItems) {
        final membership =
            membershipById[item.studentId] ??
            membershipByName[_normalizeName(item.studentName)];
        if (membership == null) continue;
        enrichedItems.add(
          item.copyWith(
            studentId: membership.student.id,
            studentName: membership.student.fullName,
            studentNumber: membership.student.nis,
            classId: membership.classData.id,
            className: membership.classData.name,
          ),
        );
      }

      if (!mounted) return;
      _teacherClasses = classes;
      _allItems = enrichedItems;
      _applyFilters();
      setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          stackTrace: stackTrace,
          fallback:
              'Riwayat siswa dari kelas yang Anda ampu tidak dapat dimuat.',
        );
        _isLoading = false;
      });
    }
  }

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
    final query = _searchQuery.trim().toLowerCase();

    _filteredItems = _allItems.where((item) {
      final date = prayerDateOnly(item.attendanceDate);
      if (date.isBefore(periodStart) || date.isAfter(periodEnd)) return false;
      if (_selectedClassId != null && item.classId != _selectedClassId) {
        return false;
      }
      if (_selectedPrayerType != null &&
          item.prayerType != _selectedPrayerType) {
        return false;
      }
      if (_selectedStatus != null && item.status != _selectedStatus) {
        return false;
      }
      if (query.isNotEmpty) {
        final name = item.studentName.toLowerCase();
        final nis = item.studentNumber?.toLowerCase() ?? '';
        if (!name.contains(query) && !nis.contains(query)) return false;
      }
      return true;
    }).toList();
    _visibleItemCount = 15;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
        _applyFilters();
      });
    });
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
      final picked = await _showMonthPicker();
      if (picked == null) return;
      setState(() {
        _selectedDate = picked;
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
          final isFuture = DateTime(
            year,
            month,
          ).isAfter(DateTime(current.year, current.month));
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
                    items: List.generate(
                      current.year - 2019,
                      (index) => DropdownMenuItem(
                        value: 2020 + index,
                        child: Text('${2020 + index}'),
                      ),
                    ),
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
                onPressed: isFuture
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
    _searchController.clear();
    setState(() {
      _selectedClassId = null;
      _selectedPrayerType = null;
      _selectedStatus = null;
      _searchQuery = '';
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
          'Riwayat Sholat Siswa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _openFilters,
            icon: Badge(
              isLabelVisible:
                  _selectedPrayerType != null || _selectedStatus != null,
              child: const Icon(Icons.tune_rounded),
            ),
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
              const SizedBox(height: 12),
              _buildClassFilter(),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIS siswa',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
                  ),
                ),
              ),
              if (_hasActiveFilter) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset semua filter'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_isLoading)
                const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                PrayerHistoryErrorState(
                  message: _errorMessage!,
                  onRetry: _loadHistory,
                )
              else if (_teacherClasses.isEmpty)
                const PrayerHistoryEmptyState(
                  message: 'Anda belum memiliki kelas yang diampu.',
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

  Widget _buildClassFilter() {
    return DropdownButtonFormField<int?>(
      initialValue: _selectedClassId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Kelas yang diampu',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua kelas')),
        ..._teacherClasses.map(
          (classData) => DropdownMenuItem<int?>(
            value: classData.id,
            child: Text(classData.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildPeriodContent() {
    if (_filteredItems.isEmpty) {
      return PrayerHistoryEmptyState(
        message: _hasActiveFilter
            ? 'Tidak ada riwayat yang sesuai filter.'
            : 'Belum ada riwayat pada periode ini.',
        onReset: _hasActiveFilter ? _resetFilters : null,
      );
    }
    return switch (_selectedPeriod) {
      PrayerHistoryPeriod.daily => _buildDailyList(),
      PrayerHistoryPeriod.weekly => _buildWeeklyTable(),
      PrayerHistoryPeriod.monthly => _buildMonthlyTable(),
    };
  }

  Widget _buildDailyList() {
    final visibleItems = _filteredItems.take(_visibleItemCount).toList();
    final grouped = <PrayerType, List<PrayerAttendanceHistoryItem>>{};
    for (final item in visibleItems) {
      grouped.putIfAbsent(item.prayerType, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...PrayerType.values.where(grouped.containsKey).map((type) {
          final items = grouped[type]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE1E6ED)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return Column(
                        children: [
                          ListTile(
                            onTap: () => _openDetail([item]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            title: Text(
                              item.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'NIS ${item.studentNumber ?? '-'} • ${item.className ?? '-'}\nInput ${formatPrayerTime(item.submittedAt)}${item.verifierName == null ? '' : ' • ${item.verifierName}'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PrayerHistoryStatusBadge(
                              status: item.status,
                              compact: true,
                            ),
                          ),
                          if (index != items.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
        if (_visibleItemCount < _filteredItems.length)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visibleItemCount += 15),
              child: const Text('Muat Lebih Banyak'),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyTable() {
    final rows = _buildStudentAggregates().take(_visibleItemCount).toList();
    return _TeacherHistoryTableContainer(
      footer: _buildLoadMoreFooter(_buildStudentAggregates().length),
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Sbh')),
          DataColumn(label: Text('Dzh')),
          DataColumn(label: Text('Ash')),
          DataColumn(label: Text('Mgh')),
          DataColumn(label: Text('Isy')),
          DataColumn(label: Text('Total')),
        ],
        rows: rows.map((row) {
          int approved(PrayerType type) => row.items
              .where(
                (item) =>
                    item.prayerType == type &&
                    item.status == PrayerAttendanceStatus.approved,
              )
              .length;
          final total = row.items
              .where((item) => item.status == PrayerAttendanceStatus.approved)
              .length;
          return DataRow(
            onSelectChanged: (_) => _openDetail(row.items),
            cells: [
              DataCell(
                SizedBox(
                  width: 145,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${row.nis} • ${row.className}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...PrayerType.values.map(
                (type) => DataCell(Text('${approved(type)}')),
              ),
              DataCell(Text('$total')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyTable() {
    final allRows = _buildStudentAggregates();
    final rows = allRows.take(_visibleItemCount).toList();
    return _TeacherHistoryTableContainer(
      footer: _buildLoadMoreFooter(allRows.length),
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 18,
        columns: const [
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Setuju')),
          DataColumn(label: Text('Menunggu')),
          DataColumn(label: Text('Tolak')),
          DataColumn(label: Text('Terlambat')),
          DataColumn(label: Text('Persen')),
        ],
        rows: rows.map((row) {
          int count(PrayerAttendanceStatus status) =>
              row.items.where((item) => item.status == status).length;
          final approved = count(PrayerAttendanceStatus.approved);
          final percent = row.items.isEmpty
              ? 0
              : (approved * 100 / row.items.length).round();
          return DataRow(
            onSelectChanged: (_) => _openDetail(row.items),
            cells: [
              DataCell(
                SizedBox(
                  width: 145,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${row.nis} • ${row.className}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text('$approved')),
              DataCell(Text('${count(PrayerAttendanceStatus.pending)}')),
              DataCell(Text('${count(PrayerAttendanceStatus.rejected)}')),
              DataCell(Text('${count(PrayerAttendanceStatus.late)}')),
              DataCell(Text('$percent%')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget? _buildLoadMoreFooter(int total) {
    if (_visibleItemCount >= total) return null;
    return TextButton(
      onPressed: () => setState(() => _visibleItemCount += 15),
      child: const Text('Muat Lebih Banyak'),
    );
  }

  List<_StudentAggregate> _buildStudentAggregates() {
    final map = <int, List<PrayerAttendanceHistoryItem>>{};
    for (final item in _filteredItems) {
      map.putIfAbsent(item.studentId, () => []).add(item);
    }
    final rows =
        map.values.map((items) {
          final first = items.first;
          return _StudentAggregate(
            studentId: first.studentId,
            name: first.studentName,
            nis: first.studentNumber ?? '-',
            className: first.className ?? '-',
            items: items,
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return rows;
  }

  void _openDetail(List<PrayerAttendanceHistoryItem> items) {
    if (items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherPrayerHistoryDetailPage(
          title: items.first.studentName,
          items: items,
        ),
      ),
    );
  }
}

class _TeacherHistoryTableContainer extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const _TeacherHistoryTableContainer({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
          if (footer != null) ...[const Divider(height: 1), footer!],
        ],
      ),
    );
  }
}

class _AllowedStudent {
  final StudentRecapModel student;
  final ClassRecapModel classData;

  const _AllowedStudent({required this.student, required this.classData});
}

class _StudentAggregate {
  final int studentId;
  final String name;
  final String nis;
  final String className;
  final List<PrayerAttendanceHistoryItem> items;

  const _StudentAggregate({
    required this.studentId,
    required this.name,
    required this.nis,
    required this.className,
    required this.items,
  });
}
