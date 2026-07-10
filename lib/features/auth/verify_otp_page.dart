import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/auth_service.dart';
import 'data/password_reset_service.dart';
import 'reset_password_page.dart';

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
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa terhubung ke server.');
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
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa mengirim ulang kode OTP.');
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
    const primaryBlue = Color(0xFF3E87D8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text('Verifikasi OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Masukkan 6 digit kode OTP yang dikirim ke ${widget.email}.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Kode OTP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final otp = value?.trim() ?? '';
                    if (otp.isEmpty) return 'Kode OTP wajib diisi.';
                    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                      return 'Kode OTP harus 6 digit angka.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _isLoading ? null : _verifyOtp(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Verifikasi'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: (_cooldown > 0 || _isResending || _isLoading)
                      ? null
                      : _resendOtp,
                  child: Text(
                    _cooldown > 0
                        ? 'Kirim ulang kode ($_cooldown)'
                        : _isResending
                        ? 'Mengirim ulang...'
                        : 'Kirim ulang kode',
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
