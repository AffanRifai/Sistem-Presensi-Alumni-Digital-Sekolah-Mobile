import 'package:flutter/material.dart';

enum ChildAttendanceStatus { hadir, terlambat, izin, sakit, alpha, belumAbsen }

extension ChildAttendanceStatusX on ChildAttendanceStatus {
  String get label {
    switch (this) {
      case ChildAttendanceStatus.hadir:
        return 'Hadir';
      case ChildAttendanceStatus.terlambat:
        return 'Terlambat';
      case ChildAttendanceStatus.izin:
        return 'Izin';
      case ChildAttendanceStatus.sakit:
        return 'Sakit';
      case ChildAttendanceStatus.alpha:
        return 'Alpa';
      case ChildAttendanceStatus.belumAbsen:
        return 'Belum Absen';
    }
  }

  Color get color {
    switch (this) {
      case ChildAttendanceStatus.hadir:
        return const Color(0xFF2E9E5B);
      case ChildAttendanceStatus.terlambat:
        return const Color(0xFFE0983C);
      case ChildAttendanceStatus.izin:
        return const Color(0xFF3E87D8);
      case ChildAttendanceStatus.sakit:
        return const Color(0xFF9B6FD9);
      case ChildAttendanceStatus.alpha:
        return const Color(0xFFC94A4A);
      case ChildAttendanceStatus.belumAbsen:
        return Colors.black45;
    }
  }

  Color get bgColor => color.withOpacity(0.1);

  IconData get icon {
    switch (this) {
      case ChildAttendanceStatus.hadir:
        return Icons.check_circle;
      case ChildAttendanceStatus.terlambat:
        return Icons.access_time_filled;
      case ChildAttendanceStatus.izin:
        return Icons.info;
      case ChildAttendanceStatus.sakit:
        return Icons.local_hospital;
      case ChildAttendanceStatus.alpha:
        return Icons.cancel;
      case ChildAttendanceStatus.belumAbsen:
        return Icons.hourglass_empty;
    }
  }

  String get parentInfo {
    switch (this) {
      case ChildAttendanceStatus.hadir:
        return 'hadir di sekolah dan mengikuti pelajaran seperti biasa';
      case ChildAttendanceStatus.terlambat:
        return 'hadir di sekolah namun tercatat terlambat';
      case ChildAttendanceStatus.izin:
        return 'tidak hadir dengan keterangan izin';
      case ChildAttendanceStatus.sakit:
        return 'tidak hadir dengan keterangan sakit';
      case ChildAttendanceStatus.alpha:
        return 'tidak hadir tanpa keterangan (alpa)';
      case ChildAttendanceStatus.belumAbsen:
        return 'belum melakukan presensi hari ini';
    }
  }
}

class ChildProfile {
  final String name;
  final String grade;
  final String nis;
  final String nisn;
  final String gender;
  final String birthDate;
  final String? photoUrl;

  const ChildProfile({
    required this.name,
    required this.grade,
    required this.nis,
    required this.nisn,
    required this.gender,
    required this.birthDate,
    this.photoUrl,
  });
}

class ChildAttendanceStatusPage extends StatelessWidget {
  final ChildProfile child;
  final ChildAttendanceStatus status;
  final String? note; // catatan tambahan, misal keterangan izin/sakit
  final DateTime? statusTime; // jam presensi tercatat

  const ChildAttendanceStatusPage({
    super.key,
    this.child = const ChildProfile(
      name: 'Andi Pratama',
      grade: 'Kelas 10-A',
      nis: '12345',
      nisn: '0098765432',
      gender: 'Laki-laki',
      birthDate: '12 Jan 2008',
    ),
    this.status = ChildAttendanceStatus.hadir,
    this.note,
    this.statusTime,
  });

  static const Color primaryBlue = Color(0xFF3E87D8);
  static const Color pageBg = Color(0xFFEAF5FB);

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                    'Status kehadiran anak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu profil anak
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
                          backgroundImage: child.photoUrl != null
                              ? NetworkImage(child.photoUrl!)
                              : null,
                          child: child.photoUrl == null
                              ? const Icon(Icons.person,
                                  color: primaryBlue, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              child.grade,
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
                          child: _InfoField(label: 'NIS', value: child.nis),
                        ),
                        Expanded(
                          child: _InfoField(label: 'NISN', value: child.nisn),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoField(
                              label: 'Gender', value: child.gender),
                        ),
                        Expanded(
                          child: _InfoField(
                              label: 'Tanggal Lahir', value: child.birthDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kartu status hari ini
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
                        Icon(status.icon, color: status.color, size: 22),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              const TextSpan(text: 'Status Hari Ini: '),
                              TextSpan(
                                text: status.label,
                                style: TextStyle(
                                  color: status.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (statusTime != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(
                          'Tercatat pukul ${_formatTime(statusTime!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                              text: 'Informasi untuk Orang Tua: Status '
                                  'kehadiran '),
                          TextSpan(
                            text: child.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const TextSpan(text: ' hari ini adalah '),
                          TextSpan(
                            text: status.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
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
            fontSize: 12,
            color: Color(0xFFB0895B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}