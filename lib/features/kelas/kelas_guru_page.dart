import 'package:flutter/material.dart';

class _ClassData {
  final String name;
  final int studentCount;

  const _ClassData({required this.name, required this.studentCount});
}

class TeacherClassesPage extends StatelessWidget {
  final String teacherName;
  final String academicYear;

  const TeacherClassesPage({
    super.key,
    this.teacherName = 'Budi Santoso, S.Pd.',
    this.academicYear = '2023/2024',
  });

  static const Color primaryBlue = Color(0xFF4A90D9);
  static const Color lightBlue = Color(0xFFBFE0F5);

  static const List<_ClassData> _classes = [
    _ClassData(name: 'Kelas 10 IPA 1', studentCount: 32),
    _ClassData(name: 'Kelas 11 IPS 2', studentCount: 28),
    _ClassData(name: 'Kelas 11 IPS 3', studentCount: 28),
    _ClassData(name: 'Kelas 12 Bahasa 1', studentCount: 30),
    _ClassData(name: 'Kelas 12 Bahasa 2', studentCount: 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightBlue, Color(0xFFEAF5FB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Data Kelas Diampu',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // penyeimbang icon back
                  ],
                ),
              ),

              // Kartu info guru
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: primaryBlue),
                        // Ganti dengan:
                        // backgroundImage: NetworkImage('URL_FOTO_GURU'),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guru: $teacherName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tahun Ajaran: $academicYear',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // List kelas
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final classData = _classes[index];
                    return _ClassCard(
                      classData: classData,
                      onTap: () {
                        // TODO: navigasi ke halaman detail/presensi kelas ini
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final _ClassData classData;
  final VoidCallback onTap;

  const _ClassCard({required this.classData, required this.onTap});

  static const Color iconBg = Color(0xFFDDEEF8);
  static const Color iconColor = Color(0xFF3E87D8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_outlined,
                  color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${classData.studentCount} Siswa',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}