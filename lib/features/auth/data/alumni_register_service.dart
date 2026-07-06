import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AlumniRegisterService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> fetchSchools() async {
    try {
      final response = await _apiClient.get('/schools/public');
      final data = response['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      throw ApiException('Gagal memuat daftar sekolah: ${e.toString()}');
    }
  }

  Future<void> registerAlumni({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int schoolId,
    required String nisn,
    required int graduationYear,
    required String className,
    required String major,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'school_id': schoolId,
      'nisn': nisn,
      'graduation_year': graduationYear,
      'class_name': className,
      'major': major,
    };

    await _apiClient.post('/alumni/register', body: body);
  }
}
