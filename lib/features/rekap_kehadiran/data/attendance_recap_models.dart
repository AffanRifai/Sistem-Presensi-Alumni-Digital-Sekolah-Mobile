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
      studentId: _asInt(json['student_id'] ?? json['id']),
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
      studentId: _asInt(json['student_id'] ?? json['id']),
      name: json['name']?.toString() ?? '-',
      nis: json['nis']?.toString() ?? '-',
      hadir: _asInt(counts['present']),
      terlambat: _asInt(counts['late']),
      izin: _asInt(counts['permission']),
      sakit: _asInt(counts['sick']),
      alpha: _asInt(counts['absent']),
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
