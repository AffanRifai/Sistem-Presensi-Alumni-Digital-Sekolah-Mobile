import '../../../core/network/api_client.dart';
import 'presensi_models.dart';

class PresensiService {
  PresensiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SchoolClassModel>> fetchClasses() async {
    final response = await _apiClient.get('/classes');
    final data = response['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(SchoolClassModel.fromJson)
        .toList();
  }

  Future<List<StudentModel>> fetchStudentsByClass(int classId) async {
    final response = await _apiClient.get('/classes/$classId/students');
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
        .map(StudentModel.fromJson)
        .toList();
  }

  Future<List<StudentAttendanceModel>> fetchClassAttendances({
    required int classId,
    required DateTime date,
  }) async {
    final response = await _apiClient.get(
      '/attendances',
      queryParameters: {
        'class_id': classId.toString(),
        'date': _formatDate(date),
      },
    );
    final data = response['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentAttendanceModel.fromJson)
        .toList();
  }

  Future<void> saveClassAttendance({
    required int classId,
    required DateTime date,
    required List<StudentAttendanceInput> attendances,
  }) async {
    await _apiClient.post(
      '/attendances/bulk',
      body: {
        'class_id': classId,
        'date': _formatDate(date),
        'attendances': attendances
            .map((attendance) => attendance.toJson())
            .toList(),
      },
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class StudentAttendanceInput {
  final int studentId;
  final String status;
  final String? note;

  const StudentAttendanceInput({
    required this.studentId,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'status': status,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
