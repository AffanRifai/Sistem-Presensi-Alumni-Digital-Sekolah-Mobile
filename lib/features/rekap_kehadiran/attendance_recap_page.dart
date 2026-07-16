import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import '../kelas/data/class_recap_models.dart';
import 'data/attendance_recap_models.dart';
import 'data/attendance_recap_service.dart';

enum RecapFilterMode { harian, bulanan }

class AttendanceRecapPage extends StatefulWidget {
  final ClassRecapModel classData;
  final String schoolName;

  const AttendanceRecapPage({
    super.key,
    required this.classData,
    this.schoolName = 'Sistem Presensi Sekolah',
  });

  @override
  State<AttendanceRecapPage> createState() => _AttendanceRecapPageState();
}

class _AttendanceRecapPageState extends State<AttendanceRecapPage> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color borderColor = Color(0xFFE3E8F2);

  final AttendanceRecapService _attendanceRecapService =
      AttendanceRecapService();
  final TextEditingController _monthlySearchController =
      TextEditingController();

  RecapFilterMode _mode = RecapFilterMode.harian;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _monthlySearchQuery = '';
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<DailyAttendanceRow> _dailyRows = const [];
  List<MonthlyAttendanceRow> _monthlyRows = const [];

  static const List<String> _statuses = [
    'Hadir',
    'Terlambat',
    'Izin',
    'Sakit',
    'Alpha',
  ];
  static const int _rowsPerPage = 15;

  @override
  void initState() {
    super.initState();
    _loadRecap();
  }

  @override
  void dispose() {
    _monthlySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_mode == RecapFilterMode.harian) {
        final rows = await _attendanceRecapService.fetchDaily(
          classId: widget.classData.id,
          date: _selectedDate,
        );
        if (!mounted) return;
        setState(() {
          _dailyRows = rows;
          _currentPage = 0;
          _isLoading = false;
        });
      } else {
        final rows = await _attendanceRecapService.fetchMonthly(
          classId: widget.classData.id,
          month: _selectedMonth.month,
          year: _selectedMonth.year,
        );
        if (!mounted) return;
        setState(() {
          _monthlyRows = rows;
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat rekap kehadiran.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat rekap kehadiran.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      default:
        return Colors.black87;
    }
  }

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

  String _formatMonth(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _loadRecap();
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int tempYear = _selectedMonth.year;
        int tempMonth = _selectedMonth.month;

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

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Pilih Bulan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setDialogState(() => tempYear--);
                          },
                        ),
                        Text(
                          tempYear.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setDialogState(() => tempYear++);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: months.length,
                      itemBuilder: (context, index) {
                        final isSelected = tempMonth == index + 1;

                        return InkWell(
                          onTap: () {
                            setDialogState(() => tempMonth = index + 1);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? primaryBlue
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              months[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, DateTime(tempYear, tempMonth));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pilih'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _currentPage = 0;
    });
    await _loadRecap();
  }

  void _setMode(RecapFilterMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _currentPage = 0;
    });
    _loadRecap();
  }

  List<Map<String, String>> get _harianRows {
    return _dailyRows
        .map((row) => {'name': row.name, 'nis': row.nis, 'status': row.status})
        .toList();
  }

  List<Map<String, dynamic>> get _bulananRows {
    final query = _monthlySearchQuery.trim().toLowerCase();
    final rows = _monthlyRows.map((row) => row.toTableRow()).toList();

    if (query.isEmpty) {
      return rows;
    }

    return rows.where((row) {
      final name = row['name']?.toString().toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  List<T> _paginate<T>(List<T> rows) {
    final start = _currentPage * _rowsPerPage;
    if (start >= rows.length) return const [];

    final requestedEnd = start + _rowsPerPage;
    final end = requestedEnd > rows.length ? rows.length : requestedEnd;
    return rows.sublist(start, end);
  }

  int _totalPages(int totalRows) {
    if (totalRows == 0) return 0;
    return (totalRows + _rowsPerPage - 1) ~/ _rowsPerPage;
  }

  void _changePage(int page, int totalPages) {
    if (page < 0 || page >= totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final harianRows = _harianRows;
    final bulananRows = _bulananRows;
    final activeRowCount = _mode == RecapFilterMode.harian
        ? harianRows.length
        : bulananRows.length;
    final totalPages = _totalPages(activeRowCount);
    final paginatedHarianRows = _paginate(harianRows);
    final paginatedBulananRows = _paginate(bulananRows);
    final startIndex = _currentPage * _rowsPerPage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Data Kehadiran Siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading ? null : _loadRecap,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Harian'),
                        selected: _mode == RecapFilterMode.harian,
                        showCheckmark: false,
                        onSelected: (_) {
                          _setMode(RecapFilterMode.harian);
                        },
                        selectedColor: primaryBlue,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _mode == RecapFilterMode.harian
                              ? primaryBlue
                              : borderColor,
                        ),
                        labelStyle: TextStyle(
                          color: _mode == RecapFilterMode.harian
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Bulanan'),
                        selected: _mode == RecapFilterMode.bulanan,
                        showCheckmark: false,
                        onSelected: (_) {
                          _setMode(RecapFilterMode.bulanan);
                        },
                        selectedColor: primaryBlue,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _mode == RecapFilterMode.bulanan
                              ? primaryBlue
                              : borderColor,
                        ),
                        labelStyle: TextStyle(
                          color: _mode == RecapFilterMode.bulanan
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isLoading
                        ? null
                        : (_mode == RecapFilterMode.harian
                              ? _pickDate
                              : _pickMonth),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _mode == RecapFilterMode.harian
                                ? _formatDate(_selectedDate)
                                : _formatMonth(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Color.fromARGB(255, 77, 79, 80),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_mode == RecapFilterMode.bulanan) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _monthlySearchController,
                      enabled: !_isLoading,
                      onChanged: (value) {
                        setState(() {
                          _monthlySearchQuery = value;
                          _currentPage = 0;
                        });
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari nama siswa',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: primaryBlue,
                        ),
                        suffixIcon: _monthlySearchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _monthlySearchController.clear();
                                  setState(() {
                                    _monthlySearchQuery = '';
                                    _currentPage = 0;
                                  });
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E2EC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD9E2EC),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryBlue),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _RecapContent(
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    mode: _mode,
                    harianRows: paginatedHarianRows,
                    bulananRows: paginatedBulananRows,
                    startIndex: startIndex,
                    statuses: _statuses,
                    statusColor: _statusColor,
                    onRetry: _loadRecap,
                  ),
                  if (!_isLoading &&
                      _errorMessage == null &&
                      activeRowCount > 0) ...[
                    const SizedBox(height: 16),
                    _PaginationBar(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      totalRows: activeRowCount,
                      rowsPerPage: _rowsPerPage,
                      onPageChanged: (page) {
                        _changePage(page, totalPages);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final RecapFilterMode mode;
  final List<Map<String, String>> harianRows;
  final List<Map<String, dynamic>> bulananRows;
  final int startIndex;
  final List<String> statuses;
  final Color Function(String) statusColor;
  final VoidCallback onRetry;

  const _RecapContent({
    required this.isLoading,
    required this.errorMessage,
    required this.mode,
    required this.harianRows,
    required this.bulananRows,
    required this.startIndex,
    required this.statuses,
    required this.statusColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final isEmpty = mode == RecapFilterMode.harian
        ? harianRows.isEmpty
        : bulananRows.isEmpty;
    if (isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada data rekap.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return mode == RecapFilterMode.harian
        ? _HarianTable(
            rows: harianRows,
            startIndex: startIndex,
            statusColor: statusColor,
          )
        : _BulananTable(
            rows: bulananRows,
            startIndex: startIndex,
            statuses: statuses,
            statusColor: statusColor,
          );
  }
}

class _HarianTable extends StatelessWidget {
  final List<Map<String, String>> rows;
  final int startIndex;
  final Color Function(String) statusColor;

  const _HarianTable({
    required this.rows,
    required this.startIndex,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AttendanceRecapPageState.borderColor),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final status = row['status'] ?? '-';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${startIndex + index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['name'] ?? '-',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIS: ${row['nis'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: status, color: statusColor(status)),
                  ],
                ),
              ),
              if (index != rows.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BulananTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final int startIndex;
  final List<String> statuses;
  final Color Function(String) statusColor;

  const _BulananTable({
    required this.rows,
    required this.startIndex,
    required this.statuses,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AttendanceRecapPageState.borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columnSpacing: 18,
          columns: [
            const DataColumn(label: Text('No')),
            const DataColumn(label: Text('Nama Siswa')),
            ...statuses.map(
              (status) => DataColumn(
                label: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor(status),
                  ),
                ),
              ),
            ),
          ],
          rows: List.generate(rows.length, (index) {
            final row = rows[index];
            return DataRow(
              cells: [
                DataCell(Text('${startIndex + index + 1}')),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row['name']?.toString() ?? '-',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'NIS: ${row['nis'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ...statuses.map(
                  (status) => DataCell(
                    Text(
                      '${row[status] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColor(status),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onPageChanged,
  });

  List<int?> _visiblePages() {
    if (totalPages <= 5) {
      return List<int>.generate(totalPages, (index) => index);
    }

    int start;
    int end;

    if (currentPage <= 2) {
      start = 1;
      end = 3;
    } else if (currentPage >= totalPages - 3) {
      start = totalPages - 4;
      end = totalPages - 2;
    } else {
      start = currentPage - 1;
      end = currentPage + 1;
    }

    return [
      0,
      if (start > 1) null,
      ...List<int>.generate(end - start + 1, (index) => start + index),
      if (end < totalPages - 1) null,
      totalPages - 1,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final firstRow = currentPage * rowsPerPage + 1;
    final requestedLastRow = firstRow + rowsPerPage - 1;
    final lastRow = requestedLastRow > totalRows ? totalRows : requestedLastRow;

    return Column(
      children: [
        Text(
          'Menampilkan $firstRow–$lastRow dari $totalRows siswa',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PaginationArrow(
                icon: Icons.chevron_left,
                enabled: currentPage > 0,
                onPressed: () => onPageChanged(currentPage - 1),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: _visiblePages().map((page) {
                    if (page == null) {
                      return const SizedBox(
                        width: 24,
                        height: 34,
                        child: Center(child: Text('…')),
                      );
                    }

                    final isSelected = page == currentPage;
                    return SizedBox(
                      width: 34,
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () => onPageChanged(page),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: isSelected
                              ? _AttendanceRecapPageState.primaryBlue
                              : Colors.white,
                          foregroundColor: isSelected
                              ? Colors.white
                              : Colors.black87,
                          side: BorderSide(
                            color: isSelected
                                ? _AttendanceRecapPageState.primaryBlue
                                : _AttendanceRecapPageState.borderColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('${page + 1}'),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 6),
              _PaginationArrow(
                icon: Icons.chevron_right,
                enabled: currentPage < totalPages - 1,
                onPressed: () => onPageChanged(currentPage + 1),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton.outlined(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          side: const BorderSide(color: _AttendanceRecapPageState.borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
