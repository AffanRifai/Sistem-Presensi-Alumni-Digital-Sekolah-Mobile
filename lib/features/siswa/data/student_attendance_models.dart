class StudentAttendanceProfile {
  final String name;
  final String grade;
  final String nis;
  final String nisn;
  final String gender;
  final String birthDate;

  const StudentAttendanceProfile({
    required this.name,
    required this.grade,
    required this.nis,
    required this.nisn,
    required this.gender,
    required this.birthDate,
  });

  factory StudentAttendanceProfile.fromAttendanceJson(
    Map<String, dynamic> json,
  ) {
    final student = json['student'];
    final classData = json['class'];
    final studentMap = student is Map<String, dynamic>
        ? student
        : <String, dynamic>{};
    final classMap = classData is Map<String, dynamic>
        ? classData
        : <String, dynamic>{};
    final gender = studentMap['gender']?.toString();

    return StudentAttendanceProfile(
      name: studentMap['name']?.toString() ?? '-',
      grade: classMap['name']?.toString() ?? '-',
      nis: studentMap['nis']?.toString() ?? '-',
      nisn: studentMap['nisn']?.toString() ?? '-',
      gender: gender == 'male'
          ? 'Laki-laki'
          : gender == 'female'
          ? 'Perempuan'
          : '-',
      birthDate: studentMap['birth_date']?.toString() ?? '-',
    );
  }
}

class StudentAttendanceRecord {
  final DateTime date;
  final String status;
  final String statusLabel;
  final String? checkInTime;
  final String? note;

  const StudentAttendanceRecord({
    required this.date,
    required this.status,
    required this.statusLabel,
    required this.checkInTime,
    required this.note,
  });

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'not_recorded',
      statusLabel: json['status_label']?.toString() ?? '-',
      checkInTime: json['check_in_time']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class StudentAttendanceSummary {
  final StudentAttendanceProfile? profile;
  final List<StudentAttendanceRecord> records;

  const StudentAttendanceSummary({
    required this.profile,
    required this.records,
  });
}
