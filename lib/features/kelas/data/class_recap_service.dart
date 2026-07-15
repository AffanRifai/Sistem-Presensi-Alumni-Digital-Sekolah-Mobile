import '../../../core/network/api_client.dart';
import 'class_recap_models.dart';

class ClassRecapService {
  ClassRecapService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ClassRecapModel>> fetchClasses() async {
    final response = await _apiClient.get('/classes');
    final data = _extractList(response['data'], key: 'classes');

    return data
        .whereType<Map>()
        .map(
          (item) => ClassRecapModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<StudentRecapModel>> fetchStudents(int classId) async {
    final response = await _apiClient.get('/classes/$classId/students');
    final students = _extractList(response['data'], key: 'students');

    return students
        .whereType<Map>()
        .map(
          (item) => StudentRecapModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  List<dynamic> _extractList(dynamic payload, {required String key}) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];

    final map = Map<String, dynamic>.from(payload);
    final direct = map[key];
    if (direct is List) return direct;

    final nestedData = map['data'];
    if (nestedData is List) return nestedData;
    if (nestedData is Map && nestedData[key] is List) {
      return nestedData[key] as List;
    }

    return const [];
  }
}
