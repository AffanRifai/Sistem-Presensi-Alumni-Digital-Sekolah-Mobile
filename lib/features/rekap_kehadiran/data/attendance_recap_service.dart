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
      '/attendances/report/daily',
      queryParameters: {
        'class_id': classId.toString(),
        'date': _formatDate(date),
      },
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return const [];
    }

    final students = data['students'];
    if (students is! List) {
      return const [];
    }

    return students
        .whereType<Map<String, dynamic>>()
        .map(DailyAttendanceRow.fromJson)
        .toList();
  }

  Future<List<MonthlyAttendanceRow>> fetchMonthly({
    required int classId,
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get(
      '/attendances/report/monthly',
      queryParameters: {
        'class_id': classId.toString(),
        'month': month.toString(),
        'year': year.toString(),
      },
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return const [];
    }

    final students = data['students'];
    if (students is! List) {
      return const [];
    }

    return students
        .whereType<Map<String, dynamic>>()
        .map(MonthlyAttendanceRow.fromJson)
        .toList();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
