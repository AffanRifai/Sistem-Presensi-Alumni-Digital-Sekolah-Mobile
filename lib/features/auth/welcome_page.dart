import 'package:flutter/material.dart';

import 'alumni_register_page.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color primaryBlue = Color(0xFF3E87D8);
  static const Color accentBlue = Color(0xFF74B9FF);
  static const Color white = Color(0xFFFFFFFF);
  static const String welcomeImage =
      'assets/images/home/splash/splashwelcome.png';

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _goToAlumniRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlumniRegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = constraints.maxHeight * 0.58;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: heroHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          welcomeImage,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.52, 0.78, 1],
                              colors: [
                                Colors.transparent,
                                Color(0x33FFFFFF),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Text(
                            '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF12395B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pantau presensi siswa, rekap kehadiran, dan akses alumni dalam satu aplikasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF4B6C85),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _PrimaryActionButton(
                            label: 'Masuk',
                            icon: Icons.login_rounded,
                            onPressed: () => _goToLogin(context),
                          ),
                          const SizedBox(height: 12),
                          _SecondaryActionButton(
                            label: 'Daftar sebagai Alumni',
                            icon: Icons.person_add_alt_1_rounded,
                            onPressed: () => _goToAlumniRegister(context),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: accentBlue,
                                size: 17,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Cepat, aman, dan mudah digunakan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B6C85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: WelcomePage.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: WelcomePage.primaryBlue,
          backgroundColor: Colors.white,
          side: const BorderSide(color: WelcomePage.primaryBlue, width: 1.4),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
