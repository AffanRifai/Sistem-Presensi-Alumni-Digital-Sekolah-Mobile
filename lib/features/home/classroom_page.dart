import 'package:flutter/material.dart';
import '../kelas/list_rekap_kelas_page.dart';
import '../rekap_kehadiran/attendance_recap_select_class_page.dart';

class ClassroomPage extends StatelessWidget {
  const ClassroomPage({super.key});

  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFEAF5FF);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SimplePageHeader(
              title: 'Ruang Kelas',
              subtitle: 'Akses cepat ke data kelas yang kamu ampu.',
              icon: Icons.class_rounded,
            ),
            const SizedBox(height: 14),
            _ClassroomActionCard(
              title: 'Rekap Kelas',
              subtitle: 'Buka rekap data siswa dan wali kelas.',
              icon: Icons.assignment_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassRecapListPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ClassroomActionCard(
              title: 'Rekap Kehadiran',
              subtitle: 'Pantau rangkuman kehadiran kelas.',
              icon: Icons.analytics_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AttendanceRecapSelectClassPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassroomActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ClassroomActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD8ECFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ClassroomPage.softBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: ClassroomPage.primaryBlue, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ClassroomPage.darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: ClassroomPage.primaryBlue,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimplePageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SimplePageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClassroomPage.primaryBlue,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
