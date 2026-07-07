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
  final QrAttendanceService _qrAttendanceService = QrAttendanceService();

  QrAttendanceToken? _token;
  QrAttendanceSession? _session;
  Timer? _sessionPollingTimer;
  bool _isClosing = false;
  String? _errorMessage;

  static const Color primaryBlue = Color(0xFF3E87D8);

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
            'Apakah kamu yakin ingin menutup sesi presensi hari ini? Murid yang belum presensi tidak akan bisa presensi lagi setelah sesi ditutup.',
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
              child: const Text('Ya, Tutup Sesi'),
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

    return jsonEncode({
      'session_id': token.sessionId,
      'token': token.token,
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final students = _session?.students ?? const <QrAttendanceStudent>[];
    final presentStudents = students.where((student) => student.status != null);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Presensi QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isClosing ? null : _closeSession,
            child: _isClosing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tutup'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSession,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.className,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (_qrData.isEmpty)
                    const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sudah Presensi (${presentStudents.length}/${students.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (presentStudents.isEmpty)
              const _EmptyAttendanceCard()
            else
              ...presentStudents.map((student) => _PresentStudentTile(student)),
          ],
        ),
      ),
    );
  }
}

class _EmptyAttendanceCard extends StatelessWidget {
  const _EmptyAttendanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Belum ada siswa yang scan QR.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E9E5B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
