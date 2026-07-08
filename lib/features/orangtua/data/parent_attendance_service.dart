import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_service.dart';
import '../../siswa/data/student_attendance_models.dart';

class ParentAttendanceService {
  ParentAttendanceService({ApiClient? apiClient, AuthService? authService})
    : _apiClient = apiClient ?? ApiClient(),
      _authService = authService ?? AuthService();

  final ApiClient _apiClient;
  final AuthService _authService;

  Future<StudentAttendanceSummary> fetchAttendance({
    required int month,
    required int year,
  }) async {
    final user = await _authService.readUser();
    if (user?.role != 'parent') {
      throw const ApiException(
        'Fitur ini hanya tersedia untuk akun orangtua.',
      );
    }

    final response = await _apiClient.get(
      '/attendances',
      queryParameters: {
        'month': month.toString(),
        'year': year.toString()
      },
    );
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      final profile = data['profile'];
      final records = data['records'];

      return StudentAttendanceSummary(
        profile: profile is Map<String, dynamic>
            ? StudentAttendanceProfile.fromProfileJson(profile)
            : null,
        records: records is List
            ? records
                  .whereType<Map<String, dynamic>>()
                  .map(StudentAttendanceRecord.fromJson)
                  .toList()
            : const [],
      );
    }

    if (data is! List || data.isEmpty) {
      return const StudentAttendanceSummary(profile: null, records: []);
    }

    final rows = data.whereType<Map<String, dynamic>>().toList();
    final records = rows.map(StudentAttendanceRecord.fromJson).toList();

    return StudentAttendanceSummary(
      profile: StudentAttendanceProfile.fromAttendanceJson(rows.first),
      records: records,
    );
  }
}
