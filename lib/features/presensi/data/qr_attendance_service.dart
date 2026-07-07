import '../../../core/network/api_client.dart';
import 'qr_attendance_models.dart';

class QrAttendanceService {
  QrAttendanceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<QrAttendanceSession> openSession({
    required int classId,
    required DateTime date,
  }) async {
    final response = await _apiClient.post(
      '/attendance/open',
      body: {'class_id': classId, 'date': _formatDate(date)},
    );

    return QrAttendanceSession.fromJson(response['data']);
  }

  Future<QrAttendanceToken> generateQr(int sessionId) async {
    final response = await _apiClient.post(
      '/attendance/generate-qr',
      body: {'session_id': sessionId},
    );

    return QrAttendanceToken.fromJson(response['data']);
  }

  Future<QrAttendanceToken> fetchActiveQr(int sessionId) async {
    final response = await _apiClient.get('/presensi-sessions/$sessionId/qr');

    return QrAttendanceToken.fromJson(response['data']);
  }

  Future<QrAttendanceSession> fetchSession(int sessionId) async {
    final response = await _apiClient.get('/attendance/session/$sessionId');

    return QrAttendanceSession.fromJson(response['data']);
  }

  Future<void> closeSession(int sessionId) async {
    await _apiClient.post('/attendance/close', body: {'session_id': sessionId});
  }

  Future<QrScanResult> scan({
    required int sessionId,
    required String token,
  }) async {
    final response = await _apiClient.post(
      '/attendance/scan',
      body: {'session_id': sessionId, 'token': token},
    );

    return QrScanResult.fromJson(response['data']);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
