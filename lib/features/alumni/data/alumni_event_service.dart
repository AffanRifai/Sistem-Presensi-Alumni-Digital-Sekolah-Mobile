import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';

class AlumniEvent {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // Ini untuk active/inactive
  final String approvalStatus; // pending, approved, rejected
  final String? organizer;
  final String? bannerImage;

  const AlumniEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.approvalStatus,
    this.organizer,
    this.bannerImage,
  });

  factory AlumniEvent.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates (handles both snake_case and camelCase)
    DateTime? parseDate(String? key1, String? key2) {
      final value = json[key1!] ?? json[key2!];
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String? parseOrganizer() {
      final org = json['organizer'] ?? json['posted_by'] ?? json['author'] ?? json['user'];
      if (org == null) return null;
      if (org is Map) {
        return org['name']?.toString() ?? 'Admin';
      }
      if (org is num) {
        return 'Admin';
      }
      return org.toString();
    }

    return AlumniEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Event Tanpa Judul',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '-',
      startDate: parseDate('event_date', 'eventDate') ?? parseDate('start_date', 'startDate') ?? DateTime.now(),
      endDate: parseDate('end_date', 'endDate'),
      status: json['is_active'] == false ? 'inactive' : (json['status']?.toString() ?? 'upcoming'),
      approvalStatus: json['approval_status']?.toString() ?? 'approved', // default approved jika null (event lama)
      organizer: parseOrganizer(),
      bannerImage: json['banner_image']?.toString(),
    );
  }
}

class AlumniEventService {
  AlumniEventService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AlumniEvent>> fetchEvents() async {
    final response = await _apiClient.get('/alumni-events');
    final data = response['data'];
    if (data is! List) {
      throw Exception('Data event alumni tidak valid.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AlumniEvent.fromJson)
        .toList();
  }

  Future<AlumniEvent> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    String? bannerImagePath,
  }) async {
    final fields = {
      'title': title,
      'description': description,
      'location': location,
      'event_date': eventDate.toIso8601String(),
    };

    dynamic response;
    if (bannerImagePath != null && bannerImagePath.isNotEmpty) {
      final file = await http.MultipartFile.fromPath('banner_image', bannerImagePath);
      response = await _apiClient.postMultipart(
        '/alumni-events',
        fields: fields,
        file: file,
      );
    } else {
      response = await _apiClient.post('/alumni-events', body: fields);
    }
    
    return AlumniEvent.fromJson(response['data'] as Map<String, dynamic>);
  }
}