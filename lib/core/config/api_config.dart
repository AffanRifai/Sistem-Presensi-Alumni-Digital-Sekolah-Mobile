import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'https://medicine-respectively-sen-recommends.trycloudflare.com/api/v1';
    }

    return 'https://medicine-respectively-sen-recommends.trycloudflare.com/api/v1';
  } 

  static String get storageUrl {
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base/storage';
  }
}
