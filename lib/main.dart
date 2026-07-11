import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/navigation/app_navigator.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/pending_verification_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/home/home_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  if (kDebugMode) {
    print('Menerima notifikasi background: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase secara aman (tidak crash jika berkas google-services.json belum dimasukkan)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) {
      print('[Firebase] Inisialisasi diabaikan atau gagal: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'sistem presensi sekolah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3E87D8)),
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    Widget nextPage = const WelcomePage();

    try {
      final token = await _authService.readToken();
      if (token != null && token.isNotEmpty) {
        AuthUser? user;
        try {
          user = await _authService.refreshCurrentUser();
        } catch (_) {
          user = await _authService.readUser();
        }

        if (user != null) {
          if (user.role == 'alumni' && user.verificationStatus == 'pending') {
            nextPage = const PendingVerificationPage();
          } else if (user.role == 'alumni' &&
              user.verificationStatus == 'rejected') {
            await _authService.logout();
            nextPage = const WelcomePage();
          } else {
            nextPage = const HomePage();
          }
        }
      }
    } catch (_) {
      nextPage = const WelcomePage();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
