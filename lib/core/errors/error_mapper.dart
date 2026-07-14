import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

abstract interface class AppError {
  String get message;
  int? get statusCode;
}

class ErrorMapper {
  ErrorMapper._();

  static const String unknownMessage =
      'Terjadi kendala. Silakan coba lagi beberapa saat.';

  static String getMessage(
    Object? error, {
    String fallback = unknownMessage,
    StackTrace? stackTrace,
  }) {
    _log(error, stackTrace);

    if (error == null) return fallback;

    if (error is TimeoutException) {
      return 'Koneksi membutuhkan waktu terlalu lama. Silakan coba lagi.';
    }

    if (error is http.ClientException) {
      return 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    }

    if (error is FormatException) {
      return 'Data yang diterima tidak dapat diproses. Silakan coba lagi.';
    }

    if (error is PlatformException) {
      return _mapPlatformException(error, fallback);
    }

    if (error is AppError) {
      return _mapMessage(
        error.message,
        statusCode: error.statusCode,
        fallback: fallback,
      );
    }

    return _mapMessage(error.toString(), fallback: fallback);
  }

  static String fromStatusCode(
    int statusCode, {
    String? serverMessage,
    String fallback = unknownMessage,
  }) {
    return _mapMessage(
      serverMessage ?? '',
      statusCode: statusCode,
      fallback: fallback,
    );
  }

  static String _mapPlatformException(
    PlatformException error,
    String fallback,
  ) {
    final text = '${error.code} ${error.message ?? ''}'.toLowerCase();

    if (_containsAny(text, const ['permission', 'denied', 'notauthorized'])) {
      if (_containsAny(text, const ['camera', 'barcode', 'scanner'])) {
        return 'Izin kamera diperlukan untuk menggunakan fitur ini.';
      }
      if (_containsAny(text, const ['storage', 'gallery', 'photo', 'file'])) {
        return 'Izin penyimpanan diperlukan untuk mengakses file.';
      }
      return 'Izin untuk fitur ini belum diberikan. Silakan periksa pengaturan aplikasi.';
    }

    if (_containsAny(text, const [
      'secure storage',
      'keystore',
      'keychain',
    ])) {
      return 'Data sesi tidak dapat diakses. Silakan masuk kembali.';
    }

    return _mapMessage(text, fallback: fallback);
  }

  static String _mapMessage(
    String rawMessage, {
    int? statusCode,
    required String fallback,
  }) {
    final cleaned = _clean(rawMessage);
    final lower = cleaned.toLowerCase();

    if (_isNetworkError(lower)) {
      return 'Tidak dapat terhubung ke internet. Periksa koneksi Anda.';
    }

    if (_containsAny(lower, const [
      'timeout',
      'timed out',
      'timeoutexception',
    ])) {
      return 'Koneksi membutuhkan waktu terlalu lama. Silakan coba lagi.';
    }

    if (_isPermissionError(lower)) {
      if (_containsAny(lower, const ['camera', 'barcode', 'scanner'])) {
        return 'Izin kamera diperlukan untuk menggunakan fitur ini.';
      }
      if (_containsAny(lower, const ['storage', 'gallery', 'photo', 'file'])) {
        return 'Izin penyimpanan diperlukan untuk mengakses file.';
      }
      return 'Anda belum memberikan izin untuk menggunakan fitur ini.';
    }

    if (_containsAny(lower, const [
      'validation failed',
      'the given data was invalid',
      'invalid data',
    ])) {
      return 'Data yang dimasukkan belum sesuai. Silakan periksa kembali.';
    }

    if (_containsAny(lower, const [
      'invalid credentials',
      'incorrect password',
      'wrong password',
    ])) {
      return 'Email atau password yang Anda masukkan tidak sesuai.';
    }

    if (_containsAny(lower, const ['invalid otp', 'otp is invalid'])) {
      return 'Kode OTP tidak valid. Silakan periksa kembali.';
    }

    if (_containsAny(lower, const [
      'too many attempts',
      'too many requests',
      'rate limit',
    ])) {
      return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat.';
    }

    if (statusCode != null) {
      if (statusCode == 401) {
        if (_isCredentialMessage(lower)) {
          return 'Email atau password yang Anda masukkan tidak sesuai.';
        }
        return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      }
      if (statusCode == 403) {
        return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
      }
      if (statusCode == 404) {
        return 'Data yang Anda cari tidak ditemukan.';
      }
      if (statusCode == 400 || statusCode == 422) {
        return _isSafeMessage(cleaned)
            ? cleaned
            : 'Data yang dimasukkan belum sesuai.';
      }
      if (statusCode >= 500) {
        return 'Server sedang mengalami kendala. Silakan coba lagi nanti.';
      }
    }

    if (_containsAny(lower, const [
      'unauthenticated',
      'unauthorized',
      'token expired',
      'token has expired',
      'session expired',
    ])) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }

    if (_containsAny(lower, const ['not found', 'route', '404'])) {
      return 'Data yang Anda cari tidak ditemukan.';
    }

    if (_containsAny(lower, const [
      'internal server error',
      'server error',
      'status code 500',
      'http 500',
      'sqlstate',
    ])) {
      return 'Server sedang mengalami kendala. Silakan coba lagi nanti.';
    }

    if (_isParsingError(lower)) {
      return 'Data yang diterima tidak dapat diproses. Silakan coba lagi.';
    }

    if (_containsAny(lower, const [
      'developer console is not set up correctly',
      'developer_error',
      'configuration_error',
    ])) {
      return 'Login Google belum dapat digunakan. Silakan hubungi administrator.';
    }

    if (_containsAny(lower, const ['reauth failed', 'account reauth'])) {
      return 'Sesi Google tidak dapat diverifikasi. Silakan coba login kembali.';
    }

    if (_isSafeMessage(cleaned)) return cleaned;
    return fallback;
  }

  static bool _isNetworkError(String text) {
    return _containsAny(text, const [
      'socketexception',
      'clientexception',
      'dioexception',
      'failed host lookup',
      'network is unreachable',
      'network request failed',
      'connection refused',
      'connection reset',
      'connection closed',
      'no address associated with hostname',
      'xmlhttprequest error',
      'software caused connection abort',
    ]);
  }

  static bool _isPermissionError(String text) {
    return _containsAny(text, const [
      'permission denied',
      'permissiondenied',
      'permission permanently denied',
      'notauthorized',
      'access denied',
      'camera permission',
      'storage permission',
    ]);
  }

  static bool _isParsingError(String text) {
    return _containsAny(text, const [
      'formatexception',
      'unexpected character',
      'response server tidak bisa dibaca',
      'response server tidak valid',
      'response login tidak valid',
      'response user tidak valid',
      'typeerror',
      'is not a subtype of',
      'null check operator used on a null value',
      'invalid json',
    ]);
  }

  static bool _isCredentialMessage(String text) {
    return _containsAny(text, const [
      'email atau password',
      'email dan password',
      'password salah',
      'kredensial',
      'credentials',
    ]);
  }

  static bool _isSafeMessage(String message) {
    if (message.isEmpty || message.length > 220) return false;
    final lower = message.toLowerCase();
    if (_containsAny(lower, const [
      ' is required',
      ' are required',
      ' must be',
      ' has failed',
      ' failed to',
      ' could not',
      ' cannot ',
      ' please ',
    ])) {
      return false;
    }
    return !_containsAny(lower, const [
      'exception',
      'stack trace',
      '#0 ',
      'package:',
      'dart:',
      '<html',
      '<!doctype',
      'sqlstate',
      'undefined index',
      'array_key_exists',
      'failed host lookup',
      'statuscode:',
      'bad state',
      'stateerror',
      'rangeerror',
      'nosuchmethod',
      'invalid argument',
      'assertion failed',
    ]);
  }

  static String _clean(String message) {
    return message
        .replaceFirst(RegExp(r'^(Exception|Error):\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsAny(String text, List<String> patterns) {
    return patterns.any(text.contains);
  }

  static void _log(Object? error, StackTrace? stackTrace) {
    if (!kDebugMode || error == null) return;
    debugPrint('[ErrorMapper] ${error.runtimeType}: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
