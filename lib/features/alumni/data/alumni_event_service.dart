import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';

class AlumniEvent {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String approvalStatus;
  final String? organizer;
  final String? bannerImage;
  final int? postedById;

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
    this.postedById,
  });

  factory AlumniEvent.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(String? key1, String? key2) {
      final value = json[key1] ?? json[key2];
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    // Helper to safely parse organizer
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

    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AlumniEvent(
      id: parseId(json['id']) ?? 0,
      title: json['title']?.toString() ?? 'Event Tanpa Judul',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '-',
      startDate: parseDate('event_date', 'eventDate') ?? parseDate('start_date', 'startDate') ?? DateTime.now(),
      endDate: parseDate('end_date', 'endDate'),
      status: json['is_active'] == false ? 'inactive' : (json['status']?.toString() ?? 'upcoming'),
      approvalStatus: json['approval_status']?.toString() ?? 'approved', // default approved
      organizer: parseOrganizer(),
      bannerImage: json['banner_image']?.toString(),
      postedById: parseId(json['posted_by']), // Menggunakan helper parseId
    );
  }
}

class AlumniEventService {
  AlumniEventService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AlumniEvent>> fetchEvents() async {
    final response = await _apiClient.get('/alumni-events');
    
    // 1. Ekstrak data mentah secara dinamis
    dynamic rawData = response['data'] ?? response;

    // 2. Cek apakah ini bentuk Pagination Laravel (Terdapat key 'data' di dalam data)
    if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
      rawData = rawData['data'];
    }

    // 3. Pastikan tipe datanya adalah List
    if (rawData is! List) {
      if (rawData is String) return []; 
      throw Exception('Data event alumni tidak valid.');
    }

    // 4. Konversi secara eksplisit ke List<AlumniEvent>
    return rawData
        .where((e) => e != null) // Hindari jika ada element yang null
        .map((e) => AlumniEvent.fromJson(Map<String, dynamic>.from(e as Map)))
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

  Future<AlumniEvent> updateEvent({
    required int id,
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
        '/alumni-events/$id',
        fields: fields,
        file: file,
      );
    } else {
      response = await _apiClient.post('/alumni-events/$id', body: fields);
    }
    
    return AlumniEvent.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEvent(int id) async {
    await _apiClient.delete('/alumni-events/$id');
  }
}