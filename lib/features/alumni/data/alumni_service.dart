import '../../../core/network/api_client.dart';

class AlumniProfile {
  final String name;
  final String email;
  final String? nisn;
  final String? phone;
  final String? schoolName;
  final String? graduationYear;
  final String status;
  final String role;

  final String? currentStatus;
  final String? universityName;
  final String? studyProgram;
  final String? companyName;
  final String? jobPosition;
  final String? businessName;
  final String? city;
  final String? province;
  final String? whatsapp;
  final String? linkedinUrl;
  final String? profileCompletedAt;

  const AlumniProfile({
    required this.name,
    required this.email,
    this.nisn,
    this.phone,
    this.schoolName,
    this.graduationYear,
    required this.status,
    required this.role,
    this.currentStatus,
    this.universityName,
    this.studyProgram,
    this.companyName,
    this.jobPosition,
    this.businessName,
    this.city,
    this.province,
    this.whatsapp,
    this.linkedinUrl,
    this.profileCompletedAt,
  });

  bool get isComplete {
    if (_hasValue(profileCompletedAt)) return true;

    final status = currentStatus;
    if (!_hasValue(status) ||
        !_hasValue(city) ||
        !_hasValue(province) ||
        !_hasValue(whatsapp)) {
      return false;
    }

    if (status == 'studying' || status == 'studying_working') {
      if (!_hasValue(universityName) || !_hasValue(studyProgram)) return false;
    }

    if (status == 'working' || status == 'studying_working') {
      if (!_hasValue(companyName) || !_hasValue(jobPosition)) return false;
    }

    if (status == 'entrepreneur' && !_hasValue(businessName)) return false;

    return true;
  }

  static bool _hasValue(String? value) => value?.trim().isNotEmpty == true;

  factory AlumniProfile.fromJson(Map<String, dynamic> json) {
    dynamic getField(String key) =>
        json[key] ??
        json['profile']?[key] ??
        json['alumni_profile']?[key] ??
        json['alumni']?[key];

    // Helper untuk mengekstrak data dari root, alumni, atau user
    String? getUserField(String key) {
      return json[key]?.toString() ??
          json['alumni']?[key]?.toString() ??
          json['alumni']?['user']?[key]?.toString() ??
          json['user']?[key]?.toString();
    }

    return AlumniProfile(
      name: getUserField('name') ?? 'Tanpa Nama',
      email: getUserField('email') ?? '-',
      nisn: getField('nisn')?.toString(),
      phone: getUserField('phone') ?? getField('whatsapp')?.toString(),
      schoolName:
          json['alumni']?['school']?['name']?.toString() ??
          getField('school_name')?.toString() ??
          getField('schoolName')?.toString(),
      graduationYear: getField('graduation_year')?.toString(),
      status:
          getUserField('verification_status') ??
          getUserField('status') ??
          'active',
      role: getUserField('role') ?? 'alumni',
      currentStatus: getField('current_status')?.toString(),
      universityName: getField('university_name')?.toString(),
      studyProgram: getField('study_program')?.toString(),
      companyName: getField('company_name')?.toString(),
      jobPosition: getField('job_position')?.toString(),
      businessName: getField('business_name')?.toString(),
      city: getField('city')?.toString(),
      province: getField('province')?.toString(),
      whatsapp: getField('whatsapp')?.toString(),
      linkedinUrl: getField('linkedin_url')?.toString(),
      profileCompletedAt: getField('profile_completed_at')?.toString(),
    );
  }
}

class AlumniService {
  AlumniService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AlumniProfile> fetchProfile() async {
    final response = await _apiClient.get(
      '/alumni/profile',
    ); // Changed to /alumni/profile
    final data = response['data'] ?? response; // Handle varying API responses
    return AlumniProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<AlumniProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put('/alumni/profile', body: data);
    // Asumsikan backend mengembalikan data alumni di response['data']['alumni']
    final responseData =
        response['data']?['alumni'] ?? response['data'] ?? response;
    return AlumniProfile.fromJson(responseData as Map<String, dynamic>);
  }
}
