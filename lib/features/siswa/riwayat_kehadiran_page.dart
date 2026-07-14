import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import 'data/student_attendance_models.dart';
import 'data/student_attendance_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  static const Color primaryBlue = Color(0xFF3E87D8);

  final StudentAttendanceService _service = StudentAttendanceService();
  final DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<StudentAttendanceRecord> _records = const [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final summary = await _service.fetchCurrentStudentAttendance(
        month: _currentMonth.month,
        year: _currentMonth.year,
      );
      if (!mounted) return;
      setState(() {
        _records = summary.records;
        _isLoading = false;
      });
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat riwayat kehadiran.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat riwayat kehadiran.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              monthLabel: _formatMonth(_currentMonth),
              onBack: () => Navigator.pop(context),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_errorMessage != null) {
      return _MessageState(message: _errorMessage!, onRetry: _loadHistory);
    }

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                'Belum ada riwayat kehadiran bulan ini.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: primaryBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _AttendanceTable(records: _records, formatDate: _formatDate),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onBack;

  const _PageHeader({required this.monthLabel, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Kehadiran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  final List<StudentAttendanceRecord> records;
  final String Function(DateTime date) formatDate;

  const _AttendanceTable({required this.records, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE3EA)),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 46,
                dataRowMinHeight: 50,
                dataRowMaxHeight: 60,
                horizontalMargin: 12,
                columnSpacing: 24,
                headingRowColor: const WidgetStatePropertyAll(
                  Color(0xFFF0F6FC),
                ),
                dividerThickness: 0.8,
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                headingTextStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF374151),
                ),
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Waktu')),
                  DataColumn(label: Text('Status')),
                ],
                rows: List.generate(records.length, (index) {
                  final record = records[index];
                  final checkInTime = record.checkInTime?.trim();

                  return DataRow(
                    color: WidgetStatePropertyAll(
                      index.isEven ? Colors.white : const Color(0xFFFAFBFC),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          '${index + 1}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 105),
                          child: Text(formatDate(record.date)),
                        ),
                      ),
                      DataCell(
                        Text(
                          checkInTime == null || checkInTime.isEmpty
                              ? '-'
                              : checkInTime,
                        ),
                      ),
                      DataCell(
                        Text(
                          record.statusLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
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
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
