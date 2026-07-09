import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '833253908047-25s0bldnepokl7jhco1safds2o499g66.apps.googleusercontent.com',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://192.168.1.13:8000/api/v1';
    }

    return 'http://192.168.1.13:8000/api/v1';
  }

  static String get storageUrl {
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base/storage';
  }
}
