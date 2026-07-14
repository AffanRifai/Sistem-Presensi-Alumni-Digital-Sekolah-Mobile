import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/errors/error_mapper.dart';
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
    } catch (error, stackTrace) {
      ErrorMapper.getMessage(error, stackTrace: stackTrace);
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
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      await _showResultDialog(
        title: 'Presensi Gagal',
        message: ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa mengirim hasil scan.',
          stackTrace: stackTrace,
        ),
        success: false,
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      await _showResultDialog(
        title: 'Presensi Gagal',
        message: ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa mengirim hasil scan.',
          stackTrace: stackTrace,
        ),
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
          title: success
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _AnimatedSuccessIcon(),
                    const SizedBox(height: 12),
                    Text(title, textAlign: TextAlign.center),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title)),
                  ],
                ),
          content: Text(message, textAlign: success ? TextAlign.center : null),
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
            errorBuilder: (context, error) {
              final message = ErrorMapper.getMessage(
                error,
                fallback:
                    'Kamera tidak dapat digunakan. Periksa izin kamera pada pengaturan aplikasi.',
              );
              return ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.no_photography_outlined,
                          size: 48,
                          color: Colors.black54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
            const Center(child: CircularProgressIndicator(color: primaryBlue)),
        ],
      ),
    );
  }
}

class _AnimatedSuccessIcon extends StatefulWidget {
  const _AnimatedSuccessIcon();

  @override
  State<_AnimatedSuccessIcon> createState() => _AnimatedSuccessIconState();
}

class _AnimatedSuccessIconState extends State<_AnimatedSuccessIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _turnAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _turnAnimation = Tween<double>(
      begin: -0.015,
      end: 0.015,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turnAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SvgPicture.asset(
          'assets/icons/success/Checked.svg',
          width: 88,
          height: 88,
        ),
      ),
    );
  }
}
