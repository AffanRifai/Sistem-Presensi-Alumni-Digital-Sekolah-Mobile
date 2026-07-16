import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import '../home/data/parent_today_attendance_service.dart';

class _ParentPalette {
  static const Color navy = Color(0xFF123B63);
  static const Color primary = Color(0xFF1F6FB2);
  static const Color background = Color(0xFFF3F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF18212B);
  static const Color muted = Color(0xFF667085);
  static const Color border = Color(0xFFDCE2E8);
}

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  final ParentTodayAttendanceService _attendanceService =
      ParentTodayAttendanceService();

  ParentDashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _attendanceService.fetchSummary();
      if (!mounted) return;

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat kehadiran anak hari ini.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat kehadiran anak hari ini.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
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

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ParentPalette.background,
      body: Column(
        children: [
          _PageHeader(dateLabel: _formatDate(DateTime.now())),
          Expanded(
            child: RefreshIndicator(
              color: _ParentPalette.primary,
              onRefresh: _loadTodayAttendance,
              child: _PageContent(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                children: _summary?.children ?? const [],
                onRetry: _loadTodayAttendance,
                formatDate: _formatDate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String dateLabel;

  const _PageHeader({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 18, 18),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: _ParentPalette.ink,
                  ),
                  tooltip: 'Kembali',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kehadiran Anak',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _ParentPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _ParentPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<ParentChildAttendance> children;
  final Future<void> Function() onRetry;
  final String Function(DateTime date) formatDate;

  const _PageContent({
    required this.isLoading,
    required this.errorMessage,
    required this.children,
    required this.onRetry,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _ParentInfoCardLoading();
    }

    if (errorMessage != null) {
      return _ParentInfoCardError(message: errorMessage!, onRetry: onRetry);
    }

    if (children.isEmpty) {
      return const _ParentInfoCardEmpty();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
      children: [
        _AttendanceSectionHeader(totalChildren: children.length),
        const SizedBox(height: 16),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _ParentChildAttendanceCard(
              child: child,
              formattedDate: formatDate(child.date),
            ),
          ),
        ),
        const _AttendanceInformationPanel(),
      ],
    );
  }
}

class _AttendanceSectionHeader extends StatelessWidget {
  final int totalChildren;

  const _AttendanceSectionHeader({required this.totalChildren});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Kehadiran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ParentPalette.ink,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Status presensi anak untuk hari ini.',
                style: TextStyle(fontSize: 13, color: _ParentPalette.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParentChildAttendanceCard extends StatelessWidget {
  final ParentChildAttendance child;
  final String formattedDate;

  const _ParentChildAttendanceCard({
    required this.child,
    required this.formattedDate,
  });

  Color get _statusColor {
    return switch (child.status) {
      'present' => const Color(0xFF16803A),
      'late' => const Color(0xFFC77800),
      'permission' => const Color(0xFF2563EB),
      'sick' => const Color(0xFF7C3AED),
      'absent' => const Color(0xFFB42318),
      _ => const Color(0xFF6B7280),
    };
  }

  IconData get _statusIcon {
    return switch (child.status) {
      'present' => Icons.check_circle_rounded,
      'late' => Icons.warning_amber_rounded,
      'permission' => Icons.assignment_turned_in_outlined,
      'sick' => Icons.medical_services_outlined,
      'absent' => Icons.cancel_rounded,
      _ => Icons.schedule_rounded,
    };
  }

  bool get _hasCheckInTime {
    final value = child.checkInTime?.trim();
    return value != null && value.isNotEmpty;
  }

  String get _checkInTime {
    final value = child.checkInTime?.trim();
    if (value == null || value.isEmpty) return 'Belum tercatat';

    final parts = value.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(_statusIcon, color: Colors.white, size: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS KEHADIRAN HARI INI',
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF2F6FA),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      child.statusLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_hasCheckInTime) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Jam masuk $_checkInTime',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _ParentPalette.surface,
            border: Border.all(color: _ParentPalette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Text(
                  'Informasi Anak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ParentPalette.ink,
                  ),
                ),
              ),
              const Divider(height: 1, color: _ParentPalette.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _IdentityItem(label: 'Nama Anak', value: child.name),
                    const Divider(height: 24, color: _ParentPalette.border),
                    _IdentityItem(label: 'NIS', value: child.nis),
                    const Divider(height: 24, color: _ParentPalette.border),
                    _IdentityItem(label: 'NISN', value: child.nisn),
                    const Divider(height: 24, color: _ParentPalette.border),
                    _IdentityItem(label: 'Kelas', value: child.className),
                    const Divider(height: 24, color: _ParentPalette.border),
                    _IdentityItem(label: 'Tanggal', value: formattedDate),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityItem extends StatelessWidget {
  final String label;
  final String value;

  const _IdentityItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ParentPalette.muted,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ParentPalette.ink,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _AttendanceInformationPanel extends StatelessWidget {
  const _AttendanceInformationPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ParentPalette.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, size: 24, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Kehadiran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Data pada halaman ini menampilkan status presensi anak untuk hari ini.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFFE8F1F8),
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

class _ParentInfoCardLoading extends StatelessWidget {
  const _ParentInfoCardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: _ParentPalette.surface,
            border: Border.all(color: _ParentPalette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _ParentPalette.primary),
          ),
        ),
      ],
    );
  }
}

class _ParentInfoCardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ParentInfoCardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ParentPalette.surface,
            border: Border.all(color: _ParentPalette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: _ParentPalette.navy,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _ParentPalette.muted,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ParentPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParentInfoCardEmpty extends StatelessWidget {
  const _ParentInfoCardEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ParentPalette.surface,
            border: Border.all(color: _ParentPalette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              Icon(Icons.family_restroom, size: 40, color: _ParentPalette.navy),
              SizedBox(height: 12),
              Text(
                'Belum ada data anak yang terhubung dengan akun ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _ParentPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
