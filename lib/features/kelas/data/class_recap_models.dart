class ClassRecapModel {
  final int id;
  final String name;
  final String grade;
  final String major;
  final int studentCount;
  final int? homeroomTeacherId;
  final String homeroomTeacherName;

  const ClassRecapModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.major,
    required this.studentCount,
    required this.homeroomTeacherId,
    required this.homeroomTeacherName,
  });

  factory ClassRecapModel.fromJson(Map<String, dynamic> json) {
    final homeroomTeacher = json['homeroom_teacher'];

    return ClassRecapModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '-',
      grade: json['grade']?.toString() ?? '-',
      major: json['major']?.toString() ?? '-',
      studentCount: _asInt(json['students_count']),
      homeroomTeacherId: homeroomTeacher is Map<String, dynamic>
          ? _asNullableInt(homeroomTeacher['id'])
          : null,
      homeroomTeacherName: homeroomTeacher is Map<String, dynamic>
          ? homeroomTeacher['name']?.toString() ?? '-'
          : '-',
    );
  }
}

class StudentRecapModel {
  final int id;
  final String nis;
  final String nisn;
  final String fullName;
  final String gender;
  final String birthDate;
  final bool isActive;
  final String parentName;
  final String parentPhone;

  const StudentRecapModel({
    required this.id,
    required this.nis,
    required this.nisn,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.isActive,
    required this.parentName,
    required this.parentPhone,
  });

  factory StudentRecapModel.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'];
    final parentName = parent is Map<String, dynamic>
        ? parent['name']?.toString()
        : json['parent_name']?.toString();
    final parentPhone = parent is Map<String, dynamic>
        ? parent['phone']?.toString()
        : json['parent_phone']?.toString();
    final gender = json['gender']?.toString();

    return StudentRecapModel(
      id: _asInt(json['id']),
      nis: json['nis']?.toString() ?? '-',
      nisn: json['nisn']?.toString() ?? '-',
      fullName: json['name']?.toString() ?? '-',
      gender: gender == 'male' ? 'L' : 'P',
      birthDate: json['birth_date']?.toString() ?? '-',
      isActive: json['status'] == 'active',
      parentName: parentName?.isNotEmpty == true ? parentName! : '-',
      parentPhone: parentPhone?.isNotEmpty == true ? parentPhone! : '-',
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value);
  return parsed == 0 ? null : parsed;
}
