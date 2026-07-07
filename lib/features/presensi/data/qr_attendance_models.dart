class QrAttendanceToken {
  final int sessionId;
  final String token;
  final int? classId;
  final String? date;

  const QrAttendanceToken({
    required this.sessionId,
    required this.token,
    this.classId,
    this.date,
  });

  factory QrAttendanceToken.fromJson(Map<String, dynamic> json) {
    return QrAttendanceToken(
      sessionId: int.tryParse(json['session_id']?.toString() ?? '') ?? 0,
      token: (json['qr_token'] ?? json['token'])?.toString() ?? '',
      classId: int.tryParse(json['class_id']?.toString() ?? ''),
      date: (json['date'] ?? json['tanggal'])?.toString(),
    );
  }
}

class QrAttendanceStudent {
  final int id;
  final String name;
  final String nis;
  final String? status;
  final String? statusLabel;
  final String? checkInTime;

  const QrAttendanceStudent({
    required this.id,
    required this.name,
    required this.nis,
    required this.status,
    required this.statusLabel,
    required this.checkInTime,
  });

  factory QrAttendanceStudent.fromJson(Map<String, dynamic> json) {
    return QrAttendanceStudent(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '-',
      nis: json['nis']?.toString() ?? '-',
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      checkInTime: json['check_in_time']?.toString(),
    );
  }
}

class QrAttendanceSession {
  final int id;
  final String status;
  final String className;
  final List<QrAttendanceStudent> students;

  const QrAttendanceSession({
    required this.id,
    required this.status,
    required this.className,
    required this.students,
  });

  factory QrAttendanceSession.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    final scheduleMap = schedule is Map<String, dynamic>
        ? schedule
        : <String, dynamic>{};
    final classData = scheduleMap['class'];
    final directClassData = json['class'];
    final classMap = classData is Map<String, dynamic>
        ? classData
        : directClassData is Map<String, dynamic>
        ? directClassData
        : <String, dynamic>{};
    final students = json['students'];

    return QrAttendanceSession(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '-',
      className: classMap['name']?.toString() ?? '-',
      students: students is List
          ? students
                .whereType<Map<String, dynamic>>()
                .map(QrAttendanceStudent.fromJson)
                .toList()
          : const [],
    );
  }
}

class QrScanResult {
  final String statusLabel;
  final String? checkInTime;

  const QrScanResult({required this.statusLabel, required this.checkInTime});

  factory QrScanResult.fromJson(Map<String, dynamic> json) {
    return QrScanResult(
      statusLabel: json['status_label']?.toString() ?? 'Hadir',
      checkInTime: json['check_in_time']?.toString(),
    );
  }
}
