import 'package:flutter_test/flutter_test.dart';
import 'package:sistem_presensi_digital_sekolah/features/kelas/data/class_recap_models.dart';
import 'package:sistem_presensi_digital_sekolah/features/rekap_kehadiran/data/attendance_recap_models.dart';

void main() {
  group('Model response production', () {
    test('kelas menerima id dan jumlah siswa dalam bentuk string', () {
      final model = ClassRecapModel.fromJson({
        'id': '7',
        'name': 'XI RPL 1',
        'grade': 'XI',
        'major': 'RPL',
        'students_count': '32',
        'homeroom_teacher': {'id': '4', 'name': 'Ahmad Fauzi'},
      });

      expect(model.id, 7);
      expect(model.studentCount, 32);
      expect(model.homeroomTeacherId, 4);
      expect(model.homeroomTeacherName, 'Ahmad Fauzi');
    });

    test('rekap bulanan menerima angka dalam bentuk string', () {
      final model = MonthlyAttendanceRow.fromJson({
        'student_id': '12',
        'name': 'Siti Rahayu',
        'nis': 'NIS012',
        'summary': {
          'present': '18',
          'late': '2',
          'permission': '1',
          'sick': 1,
          'absent': '0',
        },
      });

      expect(model.studentId, 12);
      expect(model.hadir, 18);
      expect(model.terlambat, 2);
      expect(model.izin, 1);
      expect(model.sakit, 1);
      expect(model.alpha, 0);
    });
  });
}
