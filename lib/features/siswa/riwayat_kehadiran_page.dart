import 'package:flutter/material.dart';

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
  static const Color pageBg = Color(0xFFEAF5FB);

  final StudentAttendanceService _studentAttendanceService =
      StudentAttendanceService();

  StudentAttendanceSummary? _summary;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
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
      final summary = await _studentAttendanceService
          .fetchCurrentStudentAttendance(
            month: _selectedMonth.month,
            year: _selectedMonth.year,
          );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat riwayat kehadiran.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF2E9E5B);
      case 'late':
        return const Color(0xFFE0983C);
      case 'permission':
        return const Color(0xFF3E87D8);
      case 'sick':
        return const Color(0xFF9B6FD9);
      case 'absent':
        return const Color(0xFFC94A4A);
      default:
        return Colors.black54;
    }
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      helpText: 'Pilih bulan riwayat',
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
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Riwayat Kehadiran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: primaryBlue),
                    onPressed: _isLoading ? null : _loadHistory,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _HistoryContent(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                summary: _summary,
                statusColor: _statusColor,
                formatDate: _formatDate,
                selectedMonthLabel: _formatMonth(_selectedMonth),
                onPickMonth: _isLoading ? null : _pickMonth,
                onRetry: _loadHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final StudentAttendanceSummary? summary;
  final Color Function(String status) statusColor;
  final String Function(DateTime date) formatDate;
  final String selectedMonthLabel;
  final VoidCallback? onPickMonth;
  final VoidCallback onRetry;

  const _HistoryContent({
    required this.isLoading,
    required this.errorMessage,
    required this.summary,
    required this.statusColor,
    required this.formatDate,
    required this.selectedMonthLabel,
    required this.onPickMonth,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (errorMessage != null) {
      return _MessageState(message: errorMessage!, onRetry: onRetry);
    }

    final data = summary;
    if (data == null || data.profile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada riwayat presensi untuk akun siswa ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(profile: data.profile!),
          const SizedBox(height: 16),
          _MonthFilterCard(
            selectedMonthLabel: selectedMonthLabel,
            onTap: onPickMonth,
          ),
          const SizedBox(height: 16),
          _LogCard(
            records: data.records,
            statusColor: statusColor,
            formatDate: formatDate,
          ),
        ],
      ),
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
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentAttendanceProfile profile;

  const _ProfileCard({required this.profile});

  static const Color primaryBlue = Color(0xFF3E87D8);

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFDDEEF8),
                child: Icon(Icons.person, color: primaryBlue, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.grade,
                      style: const TextStyle(
                        fontSize: 13,
                        color: primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoField(label: 'NIS', value: profile.nis),
              ),
              Expanded(
                child: _InfoField(label: 'NISN', value: profile.nisn),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoField(label: 'Gender', value: profile.gender),
              ),
              Expanded(
                child: _InfoField(
                  label: 'Tanggal Lahir',
                  value: profile.birthDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthFilterCard extends StatelessWidget {
  final String selectedMonthLabel;
  final VoidCallback? onTap;

  const _MonthFilterCard({
    required this.selectedMonthLabel,
    required this.onTap,
  });

  static const Color primaryBlue = Color(0xFF3E87D8);

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Bulan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedMonthLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final List<StudentAttendanceRecord> records;
  final Color Function(String status) statusColor;
  final String Function(DateTime date) formatDate;

  const _LogCard({
    required this.records,
    required this.statusColor,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Log Riwayat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Presensi Siswa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    'NO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'HARI/TANGGAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada riwayat presensi.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...List.generate(records.length, (index) {
              final record = records[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatDate(record.date),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          record.statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor(record.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
