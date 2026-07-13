import 'package:flutter/material.dart';
import 'login_page.dart';
import 'data/auth_service.dart';
import 'widgets/auth_page_components.dart';

class PendingVerificationPage extends StatelessWidget {
  const PendingVerificationPage({super.key});

  void _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEAF2FE),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 36,
                        color: AuthUi.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pendaftaran Terkirim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: AuthUi.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Data akun alumni Anda sudah kami terima dan sedang diperiksa oleh admin. Silakan cek kembali secara berkala.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AuthUi.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 34),
                  AuthPrimaryButton(
                    label: 'Cek Status Ulang',
                    onPressed: () => _handleLogout(context),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => _handleLogout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthUi.text,
                        side: const BorderSide(color: AuthUi.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
