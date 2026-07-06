import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.schoolId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      schoolId: json['school_id'] as int?,
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
    };
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
      token: json['token'] as String,
      tokenType: json['token_type'] as String,
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
    await _storage.write(key: _tokenKey, value: result.token);
    await _storage.write(key: _tokenTypeKey, value: result.tokenType);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(result.user.toJson()),
    );

    return result;
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

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
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _userKey);
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
