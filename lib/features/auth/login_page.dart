import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/features/home/home_page.dart';
import '../../core/config/api_config.dart';
import 'alumni_register_page.dart';
import 'forgot_password_page.dart';
import 'pending_verification_page.dart';
import 'welcome_page.dart';
import 'widgets/google_login_button.dart';

import 'data/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? initialMessage;

  const LoginPage({super.key, this.initialMessage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();

    final message = widget.initialMessage;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(message);
      });
    }
  }

  @override
  void dispose() {
    _googleAuthSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(email: email, password: password);

      if (!mounted) return;

      await _handleAuthResult(result);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa terhubung ke server Laravel.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleInitialized) return;

    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? ApiConfig.googleWebClientId : null,
        serverClientId: ApiConfig.googleWebClientId,
      );
      _googleAuthSubscription ??= GoogleSignIn.instance.authenticationEvents
          .listen(_handleGoogleAuthEvent, onError: _handleGoogleAuthError);
      _isGoogleInitialized = true;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      _isGoogleInitialized = false;
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _initializeGoogleSignIn();

      if (!_isGoogleInitialized) {
        throw const AuthException('Konfigurasi Google Sign-In belum valid.');
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthException(
          'Gunakan tombol Google resmi yang tampil untuk login di Chrome.',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      await _loginToLaravelWithGoogle(account);
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      _showMessage(error.description ?? 'Login Google gagal.');
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Google login error: $error');
      _showMessage(_formatGoogleError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleAuthEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _loginToLaravelWithGoogle(event.user);
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Google login event error: $error');
      _showMessage(_formatGoogleError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleAuthError(Object error) {
    if (!mounted) return;
    debugPrint('Google auth stream error: $error');
    _resetGoogleSessionAfterReauthFailure(error);
    _showMessage(_formatGoogleError(error));
  }

  Future<void> _resetGoogleSessionAfterReauthFailure(Object error) async {
    final message = error.toString().toLowerCase();
    if (!message.contains('account reauth failed')) return;

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore. The next tap on the Google button will create a fresh session.
    }
  }

  String _formatGoogleError(Object error) {
    final rawMessage = error.toString().toLowerCase();
    if (rawMessage.contains('account reauth failed')) {
      return 'Sesi Google gagal divalidasi. Coba klik Login Google lagi, atau pastikan origin Flutter sudah ditambahkan di Google Cloud OAuth.';
    }

    if (error is GoogleSignInException) {
      final description = error.description;
      if (description != null && description.trim().isNotEmpty) {
        return description;
      }
      return 'Login Google gagal: ${error.code.name}.';
    }

    final message = error.toString();
    if (message.trim().isNotEmpty && message != 'Exception') {
      return message;
    }

    return 'Login Google gagal. Periksa konfigurasi Google OAuth.';
  }

  Future<void> _loginToLaravelWithGoogle(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('ID Token Google tidak ditemukan.');
    }

    final result = await _authService.loginWithGoogleIdToken(idToken);
    if (!mounted) return;
    await _handleAuthResult(result);
  }

  Future<void> _handleAuthResult(AuthResult result) async {
    if (result.user.role == 'alumni' &&
        result.user.verificationStatus == 'pending') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const PendingVerificationPage(),
        ),
        (route) => false,
      );
    } else if (result.user.role == 'alumni' &&
        result.user.verificationStatus == 'rejected') {
      _showMessage('Maaf, pendaftaran akun alumni Anda ditolak.');
      await _authService.logout();
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  void _goBackToWelcome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }

  void _goToAlumniRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlumniRegisterPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFFFFFFF);
    const Color fieldColor = Color(0xFFFFFFFF);
    const Color buttonColor = Color(0xFF3E87D8);
    const Color iconColor = Color(0xFF7A8B96);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 120),
                        const Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Kartu putih berisi input username & password
                        Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              // Username field
                              Container(
                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      157,
                                      160,
                                      164,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: TextStyle(color: iconColor),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: iconColor,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Password field
                              Container(
                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      157,
                                      160,
                                      164,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  enabled: !_isLoading,
                                  onSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: TextStyle(color: iconColor),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: iconColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: iconColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Tombol Login
                        Center(
                          child: SizedBox(
                            width: 220,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.black.withValues(alpha: 0.12),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.black.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Center(
                          child: GoogleLoginButton(
                            isLoading: _isLoading || !_isGoogleInitialized,
                            onPressed: _handleGoogleLogin,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(
                              color: buttonColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : _goToAlumniRegister,
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: buttonColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 8,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _goBackToWelcome,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                label: const Text('Kembali'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3E87D8),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
