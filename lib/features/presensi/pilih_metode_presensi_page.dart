import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'data/qr_attendance_service.dart';
import 'presensi_page.dart';
import 'qr_attendance_page.dart';

class AttendanceMethodPage extends StatefulWidget {
  final int classId;
  final String className;
  final DateTime date;

  const AttendanceMethodPage({
    super.key,
    required this.classId,
    required this.className,
    required this.date,
  });

  @override
  State<AttendanceMethodPage> createState() => _AttendanceMethodPageState();
}

class _AttendanceMethodPageState extends State<AttendanceMethodPage> {
  final QrAttendanceService _qrAttendanceService = QrAttendanceService();
  bool _isOpeningQr = false;

  Future<void> _openQrSession() async {
    setState(() => _isOpeningQr = true);

    try {
      final session = await _qrAttendanceService.openSession(
        classId: widget.classId,
        date: widget.date,
      );
      final token = await _qrAttendanceService.generateQr(session.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QrAttendancePage(
            sessionId: session.id,
            className: widget.className,
            initialToken: token,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa membuka sesi QR.');
    } finally {
      if (mounted) setState(() => _isOpeningQr = false);
    }
  }

  void _openManualPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentKehadiranPage(
          classId: widget.classId,
          className: widget.className,
          date: widget.date,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pilih Metode Presensi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(widget.date),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _MethodCard(
              icon: Icons.edit_note_outlined,
              title: 'Manual',
              description: 'Input status kehadiran siswa satu per satu.',
              onTap: _isOpeningQr ? null : _openManualPage,
            ),
            const SizedBox(height: 14),
            _MethodCard(
              icon: Icons.qr_code_2_outlined,
              title: 'QR Code',
              description: 'Tampilkan QR dinamis yang berubah otomatis.',
              isLoading: _isOpeningQr,
              onTap: _isOpeningQr ? null : _openQrSession,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isLoading = false,
  });

  static const Color primaryBlue = Color(0xFF3E87D8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right, color: primaryBlue),
          ],
        ),
      ),
    );
  }
}
