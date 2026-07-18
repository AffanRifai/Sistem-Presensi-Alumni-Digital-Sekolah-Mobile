import '../../../core/network/api_client.dart';
import 'prayer_models.dart';

class PrayerAttendanceService {
  PrayerAttendanceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<TodayPrayerSummary> fetchTodaySummary() async {
    final response = await _apiClient.get('/prayer-attendances/today');
    return TodayPrayerSummary.fromJson(_asMap(response['data']));
  }

  Future<void> submitAttendance({required PrayerType type}) async {
    await _apiClient.post(
      '/prayer-attendances',
      body: {'prayer_type': type.apiValue},
    );
  }

  Future<List<PrayerVerificationItem>> fetchPendingVerifications() async {
    final response = await _apiClient.get('/prayer-attendances/pending');
    return _asList(
      response['data'],
    ).map(PrayerVerificationItem.fromJson).toList(growable: false);
  }

  Future<void> verifyAttendance({
    required int attendanceId,
    required bool approved,
    String? note,
    int? verifiedBy,
    String? verifierName,
  }) async {
    await _apiClient.post(
      '/prayer-attendances/$attendanceId/verify',
      body: {
        'approved': approved,
        if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      },
    );
  }

  Future<void> verifyAllAttendances({
    required Iterable<int> attendanceIds,
    String? note,
    int? verifiedBy,
    String? verifierName,
  }) async {
    await _apiClient.post(
      '/prayer-attendances/verify-all',
      body: {
        'attendance_ids': attendanceIds.toSet().toList(),
        if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      },
    );
  }

  Future<List<PrayerAttendanceHistoryItem>> fetchStudentHistory({
    required int studentId,
  }) async {
    return _fetchHistory();
  }

  Future<List<PrayerAttendanceHistoryItem>> fetchTeacherHistory({
    required Iterable<int> allowedStudentIds,
    Iterable<String> allowedStudentNames = const [],
  }) async {
    return _fetchHistory();
  }

  Future<PrayerAttendanceHistoryItem?> fetchHistoryDetail({
    required int historyId,
  }) async {
    final response = await _apiClient.get('/prayer-attendances/$historyId');
    final data = response['data'];
    if (data is! Map) return null;
    return PrayerAttendanceHistoryItem.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<PrayerAttendanceHistoryItem>> _fetchHistory() async {
    final response = await _apiClient.get('/prayer-attendances/history');
    return _asList(
      response['data'],
    ).map(PrayerAttendanceHistoryItem.fromJson).toList(growable: false);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Data presensi sholat tidak valid.');
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) {
      throw const FormatException('Daftar presensi sholat tidak valid.');
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
