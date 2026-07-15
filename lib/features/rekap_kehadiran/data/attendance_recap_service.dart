import '../../../core/network/api_client.dart';
import 'attendance_recap_models.dart';

class AttendanceRecapService {
  AttendanceRecapService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DailyAttendanceRow>> fetchDaily({
    required int classId,
    required DateTime date,
  }) async {
    final response = await _apiClient.get(
      '/attendance/daily',
      queryParameters: {
        'class_id': classId.toString(),
        'date': _formatDate(date),
      },
    );

    final students = _extractStudents(response['data']);

    return students
        .whereType<Map>()
        .map(
          (item) =>
              DailyAttendanceRow.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<MonthlyAttendanceRow>> fetchMonthly({
    required int classId,
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get(
      '/attendance/monthly',
      queryParameters: {
        'class_id': classId.toString(),
        'month': month.toString(),
        'year': year.toString(),
      },
    );

    final students = _extractStudents(response['data']);

    return students
        .whereType<Map>()
        .map(
          (item) =>
              MonthlyAttendanceRow.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  List<dynamic> _extractStudents(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];

    final map = Map<String, dynamic>.from(payload);
    if (map['students'] is List) return map['students'] as List;

    final nestedData = map['data'];
    if (nestedData is List) return nestedData;
    if (nestedData is Map && nestedData['students'] is List) {
      return nestedData['students'] as List;
    }

    return const [];
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
