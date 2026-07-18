// Model data untuk fitur Presensi Sholat.
// Struktur mengikuti bagian 9 & 14.3 pada dokumentasi blueprint, supaya saat
// backend Laravel siap, mapping JSON -> model ini tidak perlu diubah.

enum PrayerType { subuh, dzuhur, ashar, maghrib, isya }

enum PrayerHistoryPeriod { daily, weekly, monthly }

extension PrayerTypeX on PrayerType {
  String get apiValue => switch (this) {
    PrayerType.subuh => 'subuh',
    PrayerType.dzuhur => 'dzuhur',
    PrayerType.ashar => 'ashar',
    PrayerType.maghrib => 'maghrib',
    PrayerType.isya => 'isya',
  };

  String get label => switch (this) {
    PrayerType.subuh => 'Subuh',
    PrayerType.dzuhur => 'Dzuhur',
    PrayerType.ashar => 'Ashar',
    PrayerType.maghrib => 'Maghrib',
    PrayerType.isya => 'Isya',
  };

  static PrayerType fromApiValue(String value) {
    return PrayerType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => PrayerType.dzuhur,
    );
  }
}

// Nilai persis mengikuti kolom `status` pada tabel prayer_attendances
// (lihat blueprint bagian 9 "Status Presensi").
enum PrayerAttendanceStatus {
  notAvailable,
  open,
  pending,
  approved,
  rejected,
  resubmissionAllowed,
  expired,
  late,
  missed,
  cancelled,
}

extension PrayerAttendanceStatusX on PrayerAttendanceStatus {
  String get apiValue => switch (this) {
    PrayerAttendanceStatus.notAvailable => 'not_available',
    PrayerAttendanceStatus.open => 'open',
    PrayerAttendanceStatus.pending => 'pending',
    PrayerAttendanceStatus.approved => 'approved',
    PrayerAttendanceStatus.rejected => 'rejected',
    PrayerAttendanceStatus.resubmissionAllowed => 'resubmission_allowed',
    PrayerAttendanceStatus.expired => 'expired',
    PrayerAttendanceStatus.late => 'late',
    PrayerAttendanceStatus.missed => 'missed',
    PrayerAttendanceStatus.cancelled => 'cancelled',
  };

  static PrayerAttendanceStatus fromApiValue(String value) {
    return switch (value) {
      'open' => PrayerAttendanceStatus.open,
      'pending' => PrayerAttendanceStatus.pending,
      'approved' => PrayerAttendanceStatus.approved,
      'rejected' => PrayerAttendanceStatus.rejected,
      'resubmission_allowed' => PrayerAttendanceStatus.resubmissionAllowed,
      'expired' => PrayerAttendanceStatus.expired,
      'late' => PrayerAttendanceStatus.late,
      'missed' => PrayerAttendanceStatus.missed,
      'cancelled' => PrayerAttendanceStatus.cancelled,
      _ => PrayerAttendanceStatus.notAvailable,
    };
  }

  String get label => switch (this) {
    PrayerAttendanceStatus.notAvailable => 'Belum tersedia',
    PrayerAttendanceStatus.open => 'Dibuka',
    PrayerAttendanceStatus.pending => 'Menunggu',
    PrayerAttendanceStatus.approved => 'Disetujui',
    PrayerAttendanceStatus.rejected => 'Ditolak',
    PrayerAttendanceStatus.resubmissionAllowed => 'Bisa kirim ulang',
    PrayerAttendanceStatus.expired => 'Kedaluwarsa',
    PrayerAttendanceStatus.late => 'Terlambat',
    PrayerAttendanceStatus.missed => 'Tidak presensi',
    PrayerAttendanceStatus.cancelled => 'Dibatalkan',
  };
}

// Satu baris jadwal + status sholat pada hari berjalan (lihat contoh respons
// GET /api/v1/prayer-attendances/today pada blueprint bagian 14.3).
class TodayPrayerItem {
  final PrayerType type;
  final PrayerAttendanceStatus status;

  // false untuk Subuh/Maghrib/Isya selama fase 1 — beda arti dengan
  // "belum masuk waktu" (notAvailable), karena ini soal fitur belum
  // diaktifkan sekolah, bukan soal jadwal harian.
  final bool isEnabled;

  final bool canSubmit;
  final String?
  windowLabel; // contoh: "15:00 - 17:30" atau "Dibuka pukul 15:00"
  final String? verifiedAtLabel; // contoh: "07:10"
  final String? submittedAtLabel;
  final String? rejectionReason;
  final bool resubmissionAllowed;

  const TodayPrayerItem({
    required this.type,
    required this.status,
    required this.isEnabled,
    required this.canSubmit,
    this.windowLabel,
    this.verifiedAtLabel,
    this.submittedAtLabel,
    this.rejectionReason,
    this.resubmissionAllowed = false,
  });

  factory TodayPrayerItem.fromJson(Map<String, dynamic> json) {
    return TodayPrayerItem(
      type: PrayerTypeX.fromApiValue(json['prayer_type']?.toString() ?? ''),
      status: PrayerAttendanceStatusX.fromApiValue(
        json['status']?.toString() ?? '',
      ),
      isEnabled: json['is_enabled'] == true,
      canSubmit: json['can_submit'] == true,
      windowLabel: _nullableString(json['window_label']),
      verifiedAtLabel: _nullableString(json['verified_at']),
      submittedAtLabel: _nullableString(json['submitted_at']),
      rejectionReason: _nullableString(json['rejection_reason']),
      resubmissionAllowed: json['resubmission_allowed'] == true,
    );
  }
}

class TodayPrayerSummary {
  final DateTime date;
  final List<TodayPrayerItem> items;

  const TodayPrayerSummary({required this.date, required this.items});

  factory TodayPrayerSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return TodayPrayerSummary(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      TodayPrayerItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  int get approvedCount => items
      .where((item) => item.status == PrayerAttendanceStatus.approved)
      .length;

  int get activeTotal => items.where((item) => item.isEnabled).length;

  // Sholat aktif berikutnya yang bisa dipresensikan sekarang, kalau ada.
  TodayPrayerItem? get nextActionable {
    for (final item in items) {
      if (item.isEnabled && item.canSubmit) return item;
    }
    return null;
  }
}

class PrayerVerificationItem {
  final int id;
  final int studentId;
  final String studentName;
  final PrayerType prayerType;
  final DateTime submittedAt;
  final PrayerAttendanceStatus status;
  final String? teacherNote;

  const PrayerVerificationItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.prayerType,
    required this.submittedAt,
    required this.status,
    this.teacherNote,
  });

  factory PrayerVerificationItem.fromJson(Map<String, dynamic> json) {
    return PrayerVerificationItem(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id']),
      studentName: json['student_name']?.toString() ?? '-',
      prayerType: PrayerTypeX.fromApiValue(
        json['prayer_type']?.toString() ?? '',
      ),
      submittedAt:
          DateTime.tryParse(json['submitted_at']?.toString() ?? '') ??
          DateTime.now(),
      status: PrayerAttendanceStatusX.fromApiValue(
        json['status']?.toString() ?? '',
      ),
      teacherNote: _nullableString(json['teacher_note']),
    );
  }

  PrayerVerificationItem copyWith({
    PrayerAttendanceStatus? status,
    String? teacherNote,
  }) {
    return PrayerVerificationItem(
      id: id,
      studentId: studentId,
      studentName: studentName,
      prayerType: prayerType,
      submittedAt: submittedAt,
      status: status ?? this.status,
      teacherNote: teacherNote ?? this.teacherNote,
    );
  }
}

class PrayerAttendanceHistoryItem {
  final int id;
  final int studentId;
  final String studentName;
  final String? studentNumber;
  final int? classId;
  final String? className;
  final PrayerType prayerType;
  final DateTime attendanceDate;
  final DateTime? submittedAt;
  final PrayerAttendanceStatus status;
  final int? verifiedBy;
  final String? verifierName;
  final DateTime? verifiedAt;
  final String? teacherNote;

  const PrayerAttendanceHistoryItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentNumber,
    this.classId,
    this.className,
    required this.prayerType,
    required this.attendanceDate,
    this.submittedAt,
    required this.status,
    this.verifiedBy,
    this.verifierName,
    this.verifiedAt,
    this.teacherNote,
  });

  factory PrayerAttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return PrayerAttendanceHistoryItem(
      id: _asInt(json['id']),
      studentId: _asInt(json['student_id']),
      studentName: json['student_name']?.toString() ?? '-',
      studentNumber: _nullableString(json['student_number']),
      classId: _asNullableInt(json['class_id']),
      className: _nullableString(json['class_name']),
      prayerType: PrayerTypeX.fromApiValue(
        json['prayer_type']?.toString() ?? '',
      ),
      attendanceDate:
          DateTime.tryParse(json['attendance_date']?.toString() ?? '') ??
          DateTime.now(),
      submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
      status: PrayerAttendanceStatusX.fromApiValue(
        json['status']?.toString() ?? '',
      ),
      verifiedBy: _asNullableInt(json['verified_by']),
      verifierName: _nullableString(json['verifier_name']),
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      teacherNote: _nullableString(json['teacher_note']),
    );
  }

  PrayerAttendanceHistoryItem copyWith({
    int? id,
    int? studentId,
    String? studentName,
    String? studentNumber,
    int? classId,
    String? className,
    PrayerType? prayerType,
    DateTime? attendanceDate,
    DateTime? submittedAt,
    PrayerAttendanceStatus? status,
    int? verifiedBy,
    String? verifierName,
    DateTime? verifiedAt,
    String? teacherNote,
  }) {
    return PrayerAttendanceHistoryItem(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      prayerType: prayerType ?? this.prayerType,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifierName: verifierName ?? this.verifierName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      teacherNote: teacherNote ?? this.teacherNote,
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

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
