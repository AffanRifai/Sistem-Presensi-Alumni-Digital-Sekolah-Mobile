class SchoolClassModel {
  final int id;
  final String name;
  final String? grade;
  final String? major;

  const SchoolClassModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.major,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      id: json['id'] as int,
      name: json['name'] as String,
      grade: json['grade']?.toString(),
      major: json['major']?.toString(),
    );
  }

  String get displayName {
    final parts = [
      name,
      if (grade != null && grade!.isNotEmpty) grade,
      if (major != null && major!.isNotEmpty) major,
    ];

    return parts.join(' ');
  }
}

class StudentModel {
  final int id;
  final String name;
  final String nis;
  final String? nisn;
  final String? gender;
  final String? status;

  const StudentModel({
    required this.id,
    required this.name,
    required this.nis,
    required this.nisn,
    required this.gender,
    required this.status,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int,
      name: json['name'] as String,
      nis: json['nis']?.toString() ?? '-',
      nisn: json['nisn']?.toString(),
      gender: json['gender']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class StudentAttendanceModel {
  final int id;
  final int studentId;
  final String status;

  const StudentAttendanceModel({
    required this.id,
    required this.studentId,
    required this.status,
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentId = student is Map<String, dynamic>
        ? student['id'] as int
        : json['student_id'] as int;

    return StudentAttendanceModel(
      id: json['id'] as int,
      studentId: studentId,
      status: json['status'] as String,
    );
  }
}
