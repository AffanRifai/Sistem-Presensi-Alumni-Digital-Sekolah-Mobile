import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '672967726472-chqbv8hfl85h6m8vvq764msaep7umnn6.apps.googleusercontent.com',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://192.168.1.23:8000/api/v1';
    }

    return 'http://192.168.1.23:8000/api/v1';
  }

  static String get storageUrl {
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base/storage';
  }
}
