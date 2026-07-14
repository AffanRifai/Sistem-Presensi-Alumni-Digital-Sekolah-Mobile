import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import 'data/auth_service.dart';
import 'data/password_reset_service.dart';
import 'reset_password_page.dart';
import 'widgets/auth_page_components.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;

  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _service = PasswordResetService();

  Timer? _timer;
  bool _isLoading = false;
  bool _isResending = false;
  int _cooldown = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
        return;
      }

      if (mounted) setState(() => _cooldown--);
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final resetToken = await _service.verifyOtp(
        email: widget.email,
        otpCode: _otpController.text.trim(),
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResetPasswordPage(email: widget.email, resetToken: resetToken),
        ),
      );
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Kode OTP belum dapat diverifikasi.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Kode OTP belum dapat diverifikasi.',
          stackTrace: stackTrace,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_cooldown > 0 || _isResending || _isLoading) return;

    setState(() => _isResending = true);

    try {
      await _service.requestOtp(widget.email);
      if (!mounted) return;
      _otpController.clear();
      _startCooldown();
      _showMessage('Kode OTP baru sudah dikirim.');
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa mengirim ulang kode OTP.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa mengirim ulang kode OTP.',
          stackTrace: stackTrace,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthPageBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Verifikasi Kode',
                subtitle:
                    'Masukkan 6 digit kode yang kami kirim ke\n${widget.email}',
              ),
              const SizedBox(height: 38),
              AuthOtpInput(
                controller: _otpController,
                enabled: !_isLoading,
                onCompleted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 26),
              const Text(
                'Belum menerima kode?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AuthUi.muted),
              ),
              TextButton(
                onPressed: (_cooldown > 0 || _isResending || _isLoading)
                    ? null
                    : _resendOtp,
                child: Text(
                  _cooldown > 0
                      ? 'Kirim ulang dalam $_cooldown detik'
                      : _isResending
                      ? 'Sedang mengirim...'
                      : 'Kirim ulang kode',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Verifikasi',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
