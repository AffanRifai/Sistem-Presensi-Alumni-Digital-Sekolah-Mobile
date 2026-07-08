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
<<<<<<< HEAD
      return 'https://ashley-inner-joyce-lending.trycloudflare.com/api/v1';
    }

    return 'https://ashley-inner-joyce-lending.trycloudflare.com/api/v1';
=======
      return 'http://192.168.1.19:8000/api/v1';
    }

    return 'http://192.168.1.19:8000/api/v1';
>>>>>>> 3b2ba15eee168514bfee341eed42b5b619ab91ab
  }

  static String get storageUrl {
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base/storage';
  }
}
