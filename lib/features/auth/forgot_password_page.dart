import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import 'data/auth_service.dart';
import 'data/password_reset_service.dart';
import 'verify_otp_page.dart';
import 'widgets/auth_page_components.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _service = PasswordResetService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await _service.requestOtp(email);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyOtpPage(email: email)),
      );
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Kode OTP belum dapat dikirim. Silakan coba lagi.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Kode OTP belum dapat dikirim. Silakan coba lagi.',
          stackTrace: stackTrace,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              const AuthHeader(
                title: 'Lupa Password?',
                subtitle:
                    'Masukkan email akun Anda. Kami akan mengirimkan kode OTP untuk mengatur ulang password.',
              ),
              const SizedBox(height: 38),
              const Text(
                'Email',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                decoration: AuthUi.inputDecoration(
                  hintText: 'nama@email.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 21),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  final valid = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(email);
                  if (email.isEmpty) return 'Email wajib diisi.';
                  if (!valid) return 'Format email tidak valid.';
                  return null;
                },
                onFieldSubmitted: (_) => _isLoading ? null : _requestOtp(),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Kirim Kode OTP',
                onPressed: _requestOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
