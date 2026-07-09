import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import 'data/qr_attendance_models.dart';
import 'data/qr_attendance_service.dart';

class QrAttendancePage extends StatefulWidget {
  final int sessionId;
  final String className;
  final QrAttendanceToken initialToken;

  const QrAttendancePage({
    super.key,
    required this.sessionId,
    required this.className,
    required this.initialToken,
  });

  @override
  State<QrAttendancePage> createState() => _QrAttendancePageState();
}

class _QrAttendancePageState extends State<QrAttendancePage> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFEAF5FF);
  static const Color softGreen = Color(0xFFE8F8EF);

  final QrAttendanceService _qrAttendanceService = QrAttendanceService();

  QrAttendanceToken? _token;
  QrAttendanceSession? _session;
  Timer? _sessionPollingTimer;
  bool _isClosing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _loadQrTokenOnce();
    _loadSession();
    _sessionPollingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadSession(showError: false),
    );
  }

  @override
  void dispose() {
    _sessionPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQrTokenOnce() async {
    try {
      final token = await _qrAttendanceService.fetchActiveQr(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _token = token;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Tidak bisa memuat QR presensi.');
    }
  }

  Future<void> _refreshSession() async {
    await _loadSession(showError: true);
  }

  Future<void> _loadSession({bool showError = true}) async {
    try {
      final session = await _qrAttendanceService.fetchSession(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        if (_errorMessage == 'Tidak bisa memuat detail sesi.') {
          _errorMessage = null;
        }
      });
    } catch (_) {
      if (!mounted || !showError) return;
      setState(() => _errorMessage = 'Tidak bisa memuat detail sesi.');
    }
  }

  Future<void> _closeSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tutup Sesi QR?'),
          content: const Text(
            'Apakah kamu yakin ingin menutup sesi presensi hari ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Tutup'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() => _isClosing = true);

    try {
      await _qrAttendanceService.closeSession(widget.sessionId);
      if (!mounted) return;
      _showMessage('Sesi presensi berhasil ditutup.');
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa menutup sesi.');
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  String get _qrData {
    final token = _token;
    if (token == null) return '';

    return jsonEncode({'session_id': token.sessionId, 'token': token.token});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final students = _session?.students ?? const <QrAttendanceStudent>[];
    final presentStudents = students
        .where((student) => student.status != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshSession,
          color: primaryBlue,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _QrHeader(onClose: _isClosing ? null : _closeSession),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.groups_rounded,
                            label: 'Total Siswa',
                            value: students.length.toString(),
                            backgroundColor: softBlue,
                            iconColor: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Sudah Scan',
                            value: presentStudents.length.toString(),
                            backgroundColor: softGreen,
                            iconColor: const Color(0xFF22A862),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _QrCard(qrData: _qrData, errorMessage: _errorMessage),
                    const SizedBox(height: 22),
                    _AttendanceList(
                      presentStudents: presentStudents,
                      totalStudents: students.length,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _QrHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _QrAttendancePageState.darkBlue,
            ),
          ),
          const Expanded(
            child: Text(
              'Presensi QR',
              style: TextStyle(
                color: _QrAttendancePageState.darkBlue,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('Tutup'),
            style: TextButton.styleFrom(
              foregroundColor: _QrAttendancePageState.primaryBlue,
              backgroundColor: _QrAttendancePageState.softBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8ECFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _QrAttendancePageState.darkBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String qrData;
  final String? errorMessage;

  const _QrCard({required this.qrData, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD8ECFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR untuk presensi',
            style: TextStyle(
              color: _QrAttendancePageState.darkBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Minta siswa membuka menu Presensi QR lalu scan kode ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _QrAttendancePageState.softBlue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: qrData.isEmpty
                ? const SizedBox(
                    height: 230,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _QrAttendancePageState.primaryBlue,
                      ),
                    ),
                  )
                : QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 230,
                    backgroundColor: Colors.white,
                  ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  final List<QrAttendanceStudent> presentStudents;
  final int totalStudents;

  const _AttendanceList({
    required this.presentStudents,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sudah Presensi (${presentStudents.length}/$totalStudents)',
          style: const TextStyle(
            color: _QrAttendancePageState.darkBlue,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (presentStudents.isEmpty)
          const _EmptyAttendanceCard()
        else
          ...presentStudents.map((student) => _PresentStudentTile(student)),
      ],
    );
  }
}

class _EmptyAttendanceCard extends StatelessWidget {
  const _EmptyAttendanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _QrAttendancePageState.softBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8ECFF)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: _QrAttendancePageState.primaryBlue,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada siswa yang scan QR.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _PresentStudentTile extends StatelessWidget {
  final QrAttendanceStudent student;

  const _PresentStudentTile(this.student);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8ECFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _QrAttendancePageState.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _QrAttendancePageState.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'NIS: ${student.nis}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            student.checkInTime ?? '-',
            style: const TextStyle(
              color: _QrAttendancePageState.darkBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
