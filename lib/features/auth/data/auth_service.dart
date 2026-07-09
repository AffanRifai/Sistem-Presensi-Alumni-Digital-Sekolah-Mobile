import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final int? schoolId;
  final String? verificationStatus;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.schoolId,
    this.verificationStatus,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _readInt(json['id']),
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      phone: _readString(json, const [
        'phone',
        'no_hp',
        'nomor_hp',
        'no_telp',
        'telp',
        'whatsapp',
        'no_wa',
      ]),
      role: json['role']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'active',
      schoolId: _readNullableInt(json['school_id']),
      verificationStatus: json['verification_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'school_id': schoolId,
      'verification_status': verificationStatus,
    };
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class AuthResult {
  final AuthUser user;
  final String token;
  final String tokenType;

  const AuthResult({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
    );
  }
}

class AuthService {
  AuthService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _tokenTypeKey = 'auth_token_type';
  static const _userKey = 'auth_user';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  // Google Sign-In instance
  // serverClientId = WEB_CLIENT_ID dari .env Laravel
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '672967726472-chqbv8hfl85h6m8vvq764msaep7umnn6.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Login menggunakan Google — kirim ID Token ke Laravel
  Future<AuthResult> loginWithGoogle() async {
    // 1. Tampilkan dialog pilih akun Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Login Google dibatalkan.');
    }

    // 2. Ambil authentication credentials
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      await _googleSignIn.signOut();
      throw const AuthException(
        'Gagal mendapatkan token dari Google. Coba lagi.',
      );
    }

    // 3. Kirim ID Token ke Laravel backend
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/google'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response.body);
    final success = body['success'] == true;

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      await _googleSignIn.signOut();
      throw AuthException(_readErrorMessage(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Response login tidak valid.');
    }

    final result = AuthResult.fromJson(data);
    await _storage.write(key: _tokenKey, value: result.token);
    await _storage.write(key: _tokenTypeKey, value: result.tokenType);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(result.user.toJson()),
    );

    return result;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/login'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'device_name': 'flutter-app',
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response.body);
    final success = body['success'] == true;

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Response login tidak valid.');
    }

    final result = AuthResult.fromJson(data);
    await _saveAuthResult(result);

    return result;
  }

  Future<AuthResult> loginWithGoogleIdToken(String idToken) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/google'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(const Duration(seconds: 20));

    final body = _decodeResponse(response.body);
    final success = body['success'] == true;

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Response login Google tidak valid.');
    }

    final result = AuthResult.fromJson(data);
    if (result.token.isEmpty) {
      throw const AuthException('Token login Google tidak valid.');
    }

    await _saveAuthResult(result);

    return result;
  }

  Future<void> _saveAuthResult(AuthResult result) async {
    await _storage.write(key: _tokenKey, value: result.token);
    await _storage.write(key: _tokenTypeKey, value: result.tokenType);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(result.user.toJson()),
    );
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<AuthUser?> refreshCurrentUser() async {
    final token = await readToken();
    if (token == null || token.isEmpty) {
      return readUser();
    }

    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response.body);
    final success = body['success'] == true;

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(body));
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Response user tidak valid.');
    }

    final user = AuthUser.fromJson(data);
    await _saveUser(user);

    return user;
  }

  Future<AuthUser?> readUser() async {
    final rawUser = await _storage.read(key: _userKey);
    if (rawUser == null) return null;

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map<String, dynamic>) {
        return AuthUser.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> logout() async {
    final token = await readToken();
    if (token != null && token.isNotEmpty) {
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        await _client.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (fcmToken != null) 'fcm_token': fcmToken,
          }),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        // Silently ignore network errors during logout to ensure local storage gets cleared
      }
    }
    
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> _saveUser(AuthUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Map<String, dynamic> _decodeResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      throw const AuthException('Response server tidak bisa dibaca.');
    }

    throw const AuthException('Response server tidak valid.');
  }

  String _readErrorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }

    final message = body['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Login gagal. Periksa email dan password.';
  }
}
