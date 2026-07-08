import 'package:flutter/material.dart';

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
  static const Color primaryBlue = Color(0xFF4A90D9);
  static const Color lightBlue = Color(0xFFBFE0F5);

  final AttendanceRecapService _attendanceRecapService =
      AttendanceRecapService();
  final TextEditingController _monthlySearchController =
      TextEditingController();

  RecapFilterMode _mode = RecapFilterMode.harian;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _monthlySearchQuery = '';
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
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat rekap kehadiran.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return Colors.green;
    }
    return Colors.black54;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      helpText: 'Pilih bulan',
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
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    await _loadRecap();
  }

  void _setMode(RecapFilterMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue, lightBlue],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Rekap Kehadiran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
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
                  _IdentityCard(
                    schoolName: widget.schoolName,
                    className: widget.classData.name,
                    teacherName: widget.classData.homeroomTeacherName,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterTab(
                            label: 'Harian',
                            selected: _mode == RecapFilterMode.harian,
                            onTap: () => _setMode(RecapFilterMode.harian),
                          ),
                        ),
                        Expanded(
                          child: _FilterTab(
                            label: 'Bulanan',
                            selected: _mode == RecapFilterMode.bulanan,
                            onTap: () => _setMode(RecapFilterMode.bulanan),
                          ),
                        ),
                      ],
                    ),
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
                        border: Border.all(color: const Color(0xFFD9E2EC)),
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
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: primaryBlue,
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
                        setState(() => _monthlySearchQuery = value);
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
                                  setState(() => _monthlySearchQuery = '');
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
                    harianRows: _harianRows,
                    bulananRows: _bulananRows,
                    statuses: _statuses,
                    statusColor: _statusColor,
                    onRetry: _loadRecap,
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

class _IdentityCard extends StatelessWidget {
  final String schoolName;
  final String className;
  final String teacherName;

  const _IdentityCard({
    required this.schoolName,
    required this.className,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identitas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Sekolah', value: schoolName),
          _InfoRow(label: 'Kelas', value: className),
          _InfoRow(label: 'Guru', value: teacherName),
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
  final List<String> statuses;
  final Color Function(String) statusColor;
  final VoidCallback onRetry;

  const _RecapContent({
    required this.isLoading,
    required this.errorMessage,
    required this.mode,
    required this.harianRows,
    required this.bulananRows,
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
        ? _HarianTable(rows: harianRows, statusColor: statusColor)
        : _BulananTable(
            rows: bulananRows,
            statuses: statuses,
            statusColor: statusColor,
          );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const Text(':  ', style: TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF3E87D8) : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _HarianTable extends StatelessWidget {
  final List<Map<String, String>> rows;
  final Color Function(String) statusColor;

  const _HarianTable({required this.rows, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIS: ${row['nis'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 11,
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _BulananTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final List<String> statuses;
  final Color Function(String) statusColor;

  const _BulananTable({
    required this.rows,
    required this.statuses,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
                DataCell(Text('${index + 1}')),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'NIS: ${row['nis'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 10,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
