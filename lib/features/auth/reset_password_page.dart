import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import 'data/auth_service.dart';
import 'data/password_reset_service.dart';
import 'login_page.dart';
import 'widgets/auth_page_components.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _service = PasswordResetService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _service.resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(
            initialMessage:
                'Password berhasil diperbarui. Silakan login kembali.',
          ),
        ),
        (route) => false,
      );
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Password belum dapat diperbarui. Silakan coba lagi.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Password belum dapat diperbarui. Silakan coba lagi.',
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
                title: 'Password Baru',
                subtitle:
                    'Buat password baru yang berbeda dari password sebelumnya.',
              ),
              const SizedBox(height: 38),
              const Text(
                'Password',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimal 8 karakter',
                  filled: true,
                  fillColor: AuthUi.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AuthUi.primary),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Password wajib diisi.';
                  if (password.length < 8) {
                    return 'Password minimal 8 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Konfirmasi Password',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmationController,
                enabled: !_isLoading,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Ulangi password baru',
                  filled: true,
                  fillColor: AuthUi.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AuthUi.primary),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final confirmation = value ?? '';
                  if (confirmation.isEmpty) {
                    return 'Konfirmasi password wajib diisi.';
                  }
                  if (confirmation != _passwordController.text) {
                    return 'Konfirmasi password tidak sama.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _isLoading ? null : _resetPassword(),
              ),
              const SizedBox(height: 26),
              AuthPrimaryButton(
                label: 'Buat Password Baru',
                onPressed: _resetPassword,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
