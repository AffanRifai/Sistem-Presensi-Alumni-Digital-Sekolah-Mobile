import '../../../core/network/api_client.dart';
import 'schedule_model.dart';

class ScheduleService {
  ScheduleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, List<ScheduleItem>>> fetchSchedules() async {
    final response = await _apiClient.get('/teacher/schedules');
    final data = response['data']?['schedules'];

    if (data is Map<String, dynamic>) {
      final Map<String, List<ScheduleItem>> schedules = {};
      data.forEach((key, value) {
        if (value is List) {
          schedules[key] = value
              .whereType<Map<String, dynamic>>()
              .map(ScheduleItem.fromJson)
              .toList();
        }
      });
      return schedules;
    }

    return {};
  }
}
