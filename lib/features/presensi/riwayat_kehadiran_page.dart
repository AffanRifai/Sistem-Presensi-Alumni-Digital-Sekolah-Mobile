import 'package:flutter/material.dart';

class AttendanceLogItem {
  final int no;
  final String dayDate;
  final String status; // HADIR, IZIN, SAKIT, ALPA, TERLAMBAT

  const AttendanceLogItem({
    required this.no,
    required this.dayDate,
    required this.status,
  });
}

class StudentProfile {
  final String name;
  final String grade;
  final String nis;
  final String nisn;
  final String gender;
  final String birthDate;
  final String? photoUrl;

  const StudentProfile({
    required this.name,
    required this.grade,
    required this.nis,
    required this.nisn,
    required this.gender,
    required this.birthDate,
    this.photoUrl,
  });
}

class AttendanceHistoryPage extends StatelessWidget {
  final StudentProfile student;
  final List<AttendanceLogItem> logs;

  const AttendanceHistoryPage({
    super.key,
    this.student = const StudentProfile(
      name: 'Andi Pratama',
      grade: 'Kelas 10-A',
      nis: '12345',
      nisn: '0098765432',
      gender: 'Laki-laki',
      birthDate: '12 Jan 2008',
    ),
    this.logs = const [
      AttendanceLogItem(no: 1, dayDate: 'Senin, 23 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 2, dayDate: 'Jumat, 20 Okt 2026', status: 'IZIN'),
      AttendanceLogItem(no: 3, dayDate: 'Kamis, 19 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 4, dayDate: 'Rabu, 18 Okt 2026', status: 'ALPA'),
      AttendanceLogItem(no: 5, dayDate: 'Selasa, 17 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 6, dayDate: 'Senin, 16 Okt 2026', status: 'SAKIT'),
      AttendanceLogItem(no: 7, dayDate: 'Minggu, 15 Okt 2026', status: 'TERLAMBAT'),
      AttendanceLogItem(no: 8, dayDate: 'Sabtu, 14 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 9, dayDate: 'Jumat, 13 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 10, dayDate: 'Kamis, 12 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 11, dayDate: 'Rabu, 11 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 12, dayDate: 'Selasa, 10 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 13, dayDate: 'Senin, 09 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 14, dayDate: 'Minggu, 08 Okt 2026', status: 'HADIR'),
      AttendanceLogItem(no: 15, dayDate: 'Sabtu, 07 Okt 2026', status: 'HADIR'),
    ],
  });

  static const Color primaryBlue = Color(0xFF3E87D8);
  static const Color pageBg = Color(0xFFEAF5FB);

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Riwayat Kehadiran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu profil siswa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFDDEEF8),
                          backgroundImage: student.photoUrl != null
                              ? NetworkImage(student.photoUrl!)
                              : null,
                          child: student.photoUrl == null
                              ? const Icon(Icons.person,
                                  color: primaryBlue, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.grade,
                              style: const TextStyle(
                                fontSize: 13,
                                color: primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoField(label: 'NIS', value: student.nis),
                        ),
                        Expanded(
                          child: _InfoField(label: 'NISN', value: student.nisn),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoField(
                              label: 'Gender', value: student.gender),
                        ),
                        Expanded(
                          child: _InfoField(
                              label: 'Tanggal Lahir',
                              value: student.birthDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Kartu riwayat log
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log Riwayat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                            'Presensi Bulan Ini',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Header tabel
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              'NO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'HARI/TANGGAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    ...logs.map((log) => Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${log.no}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      log.dayDate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    log.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(log.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}