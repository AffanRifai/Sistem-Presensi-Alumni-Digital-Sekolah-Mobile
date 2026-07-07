import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/network/api_exception.dart';
import 'data/qr_attendance_service.dart';

class ScanQrAttendancePage extends StatefulWidget {
  const ScanQrAttendancePage({super.key});

  @override
  State<ScanQrAttendancePage> createState() => _ScanQrAttendancePageState();
}

class _ScanQrAttendancePageState extends State<ScanQrAttendancePage> {
  final QrAttendanceService _qrAttendanceService = QrAttendanceService();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isSubmitting = false;
  DateTime? _lastScanAt;

  static const Color primaryBlue = Color(0xFF3E87D8);

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isSubmitting) return;

    final now = DateTime.now();
    if (_lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 3)) {
      return;
    }

    final rawValue = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        _showMessage('Format QR tidak valid.');
        return;
      }
      payload = decoded;
    } catch (_) {
      _showMessage('Format QR tidak valid.');
      return;
    }

    final sessionId = int.tryParse(payload['session_id']?.toString() ?? '');
    final token = payload['token']?.toString();
    if (sessionId == null || token == null || token.isEmpty) {
      _showMessage('Payload QR tidak lengkap.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _lastScanAt = now;
    });

    try {
      final result = await _qrAttendanceService.scan(
        sessionId: sessionId,
        token: token,
      );
      if (!mounted) return;
      await _showResultDialog(
        title: 'Presensi Berhasil',
        message:
            'Kehadiran tercatat ${result.statusLabel}${result.checkInTime == null ? '' : ' jam ${result.checkInTime}'}.',
        success: true,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showResultDialog(
        title: 'Presensi Gagal',
        message: error.message,
        success: false,
      );
    } catch (_) {
      if (!mounted) return;
      await _showResultDialog(
        title: 'Presensi Gagal',
        message: 'Tidak bisa mengirim hasil scan.',
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? const Color(0xFF2E9E5B) : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Oke'),
            ),
          ],
        );
      },
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Presensi QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _scannerController.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: primaryBlue, width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _isSubmitting
                    ? 'Mengirim presensi...'
                    : 'Arahkan kamera ke QR yang ditampilkan guru.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            ),
        ],
      ),
    );
  }
}
