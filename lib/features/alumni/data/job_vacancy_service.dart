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
    final salaryMin =
        _parseSalaryValue(json['salary_min']) ??
        _parseSalaryValue(json['min_salary']) ??
        _parseSalaryValue(json['salary']);
    final salaryMax =
        _parseSalaryValue(json['salary_max']) ??
        _parseSalaryValue(json['max_salary']);

    return JobVacancy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Lowongan Tanpa Judul',
      companyName:
          json['company_name']?.toString() ?? 'Perusahaan Tidak Diketahui',
      companyLogo: json['company_logo']?.toString(),
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString(),
      link: json['link']?.toString(),
      location: json['location']?.toString() ?? '-',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      jobType: json['job_type']?.toString() ?? 'Lainnya',
      category: json['category']?.toString() ?? 'Lainnya',
      deadline: _parseDeadline(json),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1',
    );
  }

  static int? _parseSalaryValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final numeric = int.tryParse(trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
      return numeric;
    }
    return null;
  }

  static DateTime? _parseDeadline(Map<String, dynamic> json) {
    for (final key in ['deadline', 'deadline_at', 'expired_at', 'end_date']) {
      final value = json[key];
      if (value == null || value.toString().trim().isEmpty) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String get formattedSalary {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    if (salaryMin != null && salaryMax != null) {
      return '${formatCurrency.format(salaryMin)} - ${formatCurrency.format(salaryMax)}';
    } else if (salaryMin != null) {
      return formatCurrency.format(salaryMin);
    } else if (salaryMax != null) {
      return formatCurrency.format(salaryMax);
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
