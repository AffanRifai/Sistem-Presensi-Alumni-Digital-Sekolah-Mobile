import '../../../core/network/api_client.dart';
import 'package:intl/intl.dart';

class JobVacancy {
  final int id;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String description;
  final String? requirements;
  final String? link;
  final String location;
  final int? salaryMin;
  final int? salaryMax;
  final String jobType;
  final String category;
  final DateTime? deadline;
  final bool isActive;

  const JobVacancy({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo,
    required this.description,
    this.requirements,
    this.link,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    required this.jobType,
    required this.category,
    this.deadline,
    required this.isActive,
  });

  factory JobVacancy.fromJson(Map<String, dynamic> json) {
    return JobVacancy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Lowongan Tanpa Judul',
      companyName: json['company_name']?.toString() ?? 'Perusahaan Tidak Diketahui',
      companyLogo: json['company_logo']?.toString(),
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString(),
      link: json['link']?.toString(),
      location: json['location']?.toString() ?? '-',
      salaryMin: (json['salary_min'] as num?)?.toInt(),
      salaryMax: (json['salary_max'] as num?)?.toInt(),
      jobType: json['job_type']?.toString() ?? 'Lainnya',
      category: json['category']?.toString() ?? 'Lainnya',
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  String get formattedSalary {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    if (salaryMin != null && salaryMax != null) {
      return '${formatCurrency.format(salaryMin)} - ${formatCurrency.format(salaryMax)}';
    } else if (salaryMin != null) {
      return '${formatCurrency.format(salaryMin)} - ...';
    } else if (salaryMax != null) {
      return '... - ${formatCurrency.format(salaryMax)}';
    }
    return 'Tidak disebutkan';
  }
}

class JobVacancyService {
  JobVacancyService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<JobVacancy>> fetchVacancies() async {
    final response = await _apiClient.get('/alumni/jobs');
    
    // Karena Laravel menggunakan paginate(), datanya ada di dalam ['data']['data']
    dynamic rawData = response['data'];
    List dataList = [];
    
    if (rawData is Map && rawData.containsKey('data')) {
      dataList = rawData['data'] as List;
    } else if (rawData is List) {
      dataList = rawData;
    } else {
      throw Exception('Data lowongan kerja tidak valid.');
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map(JobVacancy.fromJson)
        .toList();
  }
}
