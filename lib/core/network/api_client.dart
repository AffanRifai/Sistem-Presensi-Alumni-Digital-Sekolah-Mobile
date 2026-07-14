import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_service.dart';
import '../config/api_config.dart';
import '../errors/error_mapper.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? AuthService();

  final http.Client _client;
  final AuthService _authService;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client
        .get(_buildUri(path, queryParameters), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client
        .post(
          _buildUri(path),
          headers: await _headers(),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client
        .put(
          _buildUri(path),
          headers: await _headers(),
          body: jsonEncode(body ?? {}),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    http.MultipartFile? file,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    final currentHeaders = await _headers();
    // MultipartRequest automatically sets the content-type boundary
    currentHeaders.remove('Content-Type');
    request.headers.addAll(currentHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (file != null) {
      request.files.add(file);
    }

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client
        .delete(_buildUri(path, queryParameters), headers: await _headers())
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.readToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = _decode(response.body);
    final success =
        decoded['success'] == true || decoded['status'] == 'success';

    if (!success || response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _readErrorMessage(decoded),
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decode(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (error, stackTrace) {
      ErrorMapper.getMessage(error, stackTrace: stackTrace);
      throw const ApiException('Response server tidak bisa dibaca.');
    }

    throw const ApiException('Response server tidak valid.');
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

    return 'Terjadi kesalahan saat menghubungi server.';
  }
}
