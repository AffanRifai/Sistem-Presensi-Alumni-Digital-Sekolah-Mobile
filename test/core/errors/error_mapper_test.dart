import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sistem_presensi_digital_sekolah/core/errors/error_mapper.dart';
import 'package:sistem_presensi_digital_sekolah/core/network/api_exception.dart';

void main() {
  group('ErrorMapper', () {
    test('memetakan error koneksi internet', () {
      final message = ErrorMapper.getMessage(
        http.ClientException('Failed host lookup'),
      );

      expect(message, contains('Periksa koneksi'));
    });

    test('memetakan timeout', () {
      final message = ErrorMapper.getMessage(TimeoutException('timeout'));

      expect(message, contains('terlalu lama'));
    });

    test('memetakan status HTTP utama', () {
      expect(
        ErrorMapper.getMessage(
          const ApiException('Validation failed', statusCode: 400),
        ),
        contains('belum sesuai'),
      );
      expect(
        ErrorMapper.getMessage(
          const ApiException('Unauthenticated.', statusCode: 401),
        ),
        contains('Sesi Anda telah berakhir'),
      );
      expect(
        ErrorMapper.getMessage(
          const ApiException('Not Found', statusCode: 404),
        ),
        contains('tidak ditemukan'),
      );
      expect(
        ErrorMapper.getMessage(
          const ApiException('Forbidden', statusCode: 403),
        ),
        contains('tidak memiliki izin'),
      );
      expect(
        ErrorMapper.getMessage(
          const ApiException('Internal Server Error', statusCode: 500),
        ),
        contains('Server sedang mengalami kendala'),
      );
    });

    test('mempertahankan pesan validasi yang sudah ramah', () {
      final message = ErrorMapper.getMessage(
        const ApiException('Password minimal 8 karakter.', statusCode: 422),
      );

      expect(message, 'Password minimal 8 karakter.');
    });

    test('memetakan permission kamera', () {
      final message = ErrorMapper.getMessage(
        PlatformException(
          code: 'camera_permission_denied',
          message: 'Permission denied',
        ),
      );

      expect(message, contains('Izin kamera diperlukan'));
    });

    test('memetakan error parsing dan fallback', () {
      expect(
        ErrorMapper.getMessage(const FormatException('Unexpected character')),
        contains('tidak dapat diproses'),
      );
      expect(
        ErrorMapper.getMessage(StateError('bad state')),
        ErrorMapper.unknownMessage,
      );
    });
  });
}
