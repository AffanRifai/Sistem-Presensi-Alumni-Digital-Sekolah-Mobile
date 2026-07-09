import '../../../core/network/api_client.dart';

class ParentDashboardSummary {
  final List<ParentChildAttendance> children;

  const ParentDashboardSummary({required this.children});

  factory ParentDashboardSummary.fromJson(Map<String, dynamic> json) {
    final children = json['children'];

    return ParentDashboardSummary(
      children: children is List
          ? children
                .whereType<Map<String, dynamic>>()
                .map(ParentChildAttendance.fromJson)
                .toList()
          : const [],
    );
  }
}

class ParentChildAttendance {
  final String name;
  final String nis;
  final String nisn;
  final String className;
  final DateTime date;
  final String status;
  final String statusLabel;

  const ParentChildAttendance({
    required this.name,
    required this.nis,
    required this.nisn,
    required this.className,
    required this.date,
    required this.status,
    required this.statusLabel,
  });

  factory ParentChildAttendance.fromJson(Map<String, dynamic> json) {
    final classData = json['class'];
    final classMap = classData is Map<String, dynamic>
        ? classData
        : <String, dynamic>{};
    final attendance = json['today_attendance'];
    final attendanceMap = attendance is Map<String, dynamic>
        ? attendance
        : <String, dynamic>{};
    final grade = classMap['grade']?.toString();
    final major = classMap['major']?.toString();
    final className = classMap['name']?.toString();
    final classLabel = className?.isNotEmpty == true
        ? className!
        : [
            grade,
            major,
          ].where((value) => value != null && value.isNotEmpty).join(' ');

    return ParentChildAttendance(
      name: json['name']?.toString() ?? '-',
      nis: json['nis']?.toString() ?? '-',
      nisn: json['nisn']?.toString() ?? '-',
      className: classLabel.isEmpty ? '-' : classLabel,
      date:
          DateTime.tryParse(attendanceMap['date']?.toString() ?? '') ??
          DateTime.now(),
      status: attendanceMap['status']?.toString() ?? 'not_recorded',
      statusLabel:
          attendanceMap['status_label']?.toString() ?? 'Belum Tercatat',
    );
  }
}

class ParentTodayAttendanceService {
  ParentTodayAttendanceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ParentDashboardSummary> fetchSummary() async {
    final response = await _apiClient.get('/dashboard');
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return ParentDashboardSummary.fromJson(data);
    }

    return const ParentDashboardSummary(children: []);
  }
}
