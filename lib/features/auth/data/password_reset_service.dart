import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import 'auth_service.dart';

class PasswordResetService {
  PasswordResetService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> requestOtp(String email) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));

    _handleResponse(response);
  }

  Future<String> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/verify-otp'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email, 'otp_code': otpCode}),
        )
        .timeout(const Duration(seconds: 15));

    final body = _handleResponse(response);
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final token = data['reset_token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    }

    throw const AuthException('Token reset password tidak valid.');
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/reset-password'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'reset_token': resetToken,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));

    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = _decodeResponse(response.body);
    final success = body['success'] == true;

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_readErrorMessage(body));
    }

    return body;
  }

  Map<String, dynamic> _decodeResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
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
    if (message is String && message.isNotEmpty) return message;

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
