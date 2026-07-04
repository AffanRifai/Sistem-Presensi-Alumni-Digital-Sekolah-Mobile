class DailyAttendanceRow {
  final int studentId;
  final String name;
  final String nis;
  final String status;

  const DailyAttendanceRow({
    required this.studentId,
    required this.name,
    required this.nis,
    required this.status,
  });

  factory DailyAttendanceRow.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceRow(
      studentId: json['student_id'] as int,
      name: json['name']?.toString() ?? '-',
      nis: json['nis']?.toString() ?? '-',
      status: _statusLabel(json['status']?.toString()),
    );
  }
}

class MonthlyAttendanceRow {
  final int studentId;
  final String name;
  final String nis;
  final int hadir;
  final int terlambat;
  final int izin;
  final int sakit;
  final int alpha;

  const MonthlyAttendanceRow({
    required this.studentId,
    required this.name,
    required this.nis,
    required this.hadir,
    required this.terlambat,
    required this.izin,
    required this.sakit,
    required this.alpha,
  });

  factory MonthlyAttendanceRow.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final counts = summary is Map<String, dynamic>
        ? summary
        : <String, dynamic>{};

    return MonthlyAttendanceRow(
      studentId: json['student_id'] as int,
      name: json['name']?.toString() ?? '-',
      nis: json['nis']?.toString() ?? '-',
      hadir: counts['present'] as int? ?? 0,
      terlambat: counts['late'] as int? ?? 0,
      izin: counts['permission'] as int? ?? 0,
      sakit: counts['sick'] as int? ?? 0,
      alpha: counts['absent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toTableRow() {
    return {
      'name': name,
      'nis': nis,
      'Hadir': hadir,
      'Terlambat': terlambat,
      'Izin': izin,
      'Sakit': sakit,
      'Alpha': alpha,
    };
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'present':
      return 'Hadir';
    case 'late':
      return 'Terlambat';
    case 'permission':
      return 'Izin';
    case 'sick':
      return 'Sakit';
    case 'absent':
      return 'Alpha';
    case 'not_recorded':
      return '-';
    default:
      return status ?? '-';
  }
}
