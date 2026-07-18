import 'package:flutter_test/flutter_test.dart';
import 'package:sistem_presensi_digital_sekolah/features/presensi_sholat/data/prayer_models.dart';

void main() {
  test('memetakan jadwal sholat hari ini dari response Laravel', () {
    final summary = TodayPrayerSummary.fromJson({
      'date': '2026-07-18',
      'items': [
        {
          'prayer_type': 'dzuhur',
          'status': 'open',
          'is_enabled': true,
          'can_submit': true,
          'window_label': '12:00 - 13:30 WIB',
        },
      ],
    });

    expect(summary.date, DateTime(2026, 7, 18));
    expect(summary.items, hasLength(1));
    expect(summary.items.first.type, PrayerType.dzuhur);
    expect(summary.items.first.status, PrayerAttendanceStatus.open);
    expect(summary.items.first.canSubmit, isTrue);
  });

  test('memetakan riwayat dan catatan verifikasi guru', () {
    final item = PrayerAttendanceHistoryItem.fromJson({
      'id': 7,
      'student_id': 12,
      'student_name': 'Siswa Test',
      'student_number': '260001',
      'class_id': 3,
      'class_name': 'XI RPL 1',
      'prayer_type': 'ashar',
      'attendance_date': '2026-07-18',
      'submitted_at': '2026-07-18T15:25:00+07:00',
      'status': 'approved',
      'verified_by': 2,
      'verifier_name': 'Guru Wali',
      'verified_at': '2026-07-18T15:40:00+07:00',
      'teacher_note': 'Sudah dikonfirmasi.',
    });

    expect(item.prayerType, PrayerType.ashar);
    expect(item.status, PrayerAttendanceStatus.approved);
    expect(item.studentNumber, '260001');
    expect(item.verifierName, 'Guru Wali');
    expect(item.teacherNote, 'Sudah dikonfirmasi.');
  });
}
