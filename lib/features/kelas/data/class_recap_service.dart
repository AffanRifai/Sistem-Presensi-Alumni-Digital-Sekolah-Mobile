import '../../../core/network/api_client.dart';
import 'class_recap_models.dart';

class ClassRecapService {
  ClassRecapService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ClassRecapModel>> fetchClasses() async {
    final response = await _apiClient.get('/classes');
    final data = response['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ClassRecapModel.fromJson)
        .toList();
  }

  Future<List<StudentRecapModel>> fetchStudents(int classId) async {
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
        .map(StudentRecapModel.fromJson)
        .toList();
  }
}
