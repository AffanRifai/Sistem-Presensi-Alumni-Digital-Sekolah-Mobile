import 'package:flutter/material.dart';
import 'data/alumni_service.dart';
import 'alumni_profile_edit_page.dart';

class AlumniProfilePage extends StatefulWidget {
  const AlumniProfilePage({super.key});

  @override
  State<AlumniProfilePage> createState() => _AlumniProfilePageState();
}

class _AlumniProfilePageState extends State<AlumniProfilePage> {
  final _service = AlumniService();
  late Future<AlumniProfile> _profileFuture;
  AlumniProfile? snapshotData;

  @override
  void initState() {
    super.initState();
    _profileFuture = _service.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        foregroundColor: Colors.white,
        title: const Text(
          'Profil Alumni',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              if (snapshotData == null) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlumniProfileEditPage(currentProfile: snapshotData!),
                ),
              );
              
              if (result == true && mounted) {
                setState(() {
                  _profileFuture = _service.fetchProfile();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<AlumniProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {
                _profileFuture = _service.fetchProfile();
              }),
            );
          }

          final profile = snapshot.data!;
          snapshotData = profile;
          return _ProfileContent(profile: profile);
        },
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE57373)),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Content ──────────────────────────────────────────────────────────
class _ProfileContent extends StatelessWidget {
  final AlumniProfile profile;

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header kartu avatar + nama ──
          _buildHeader(),
          const SizedBox(height: 16),
          // ── Biodata ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCard(
                  title: 'Informasi Akun',
                  icon: Icons.account_circle_outlined,
                  children: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'NISN',
                      value: profile.nisn ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      value: profile.name,
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email,
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'No. Telepon',
                      value: profile.phone ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCard(
                  title: 'Informasi Sekolah',
                  icon: Icons.school_outlined,
                  children: [
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Sekolah',
                      value: profile.schoolName ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tahun Lulus',
                      value: profile.graduationYear ?? '-',
                    ),
                  ],
                ),
                if (profile.currentStatus != null) ...[
                  const SizedBox(height: 12),
                  _buildCard(
                    title: 'Status Saat Ini',
                    icon: Icons.work_outline,
                    children: [
                      _InfoRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: _formatCurrentStatus(profile.currentStatus!),
                      ),
                      _InfoRow(
                        icon: Icons.school_outlined,
                        label: 'Pendidikan Lanjut',
                        value: (profile.universityName != null || profile.studyProgram != null) 
                            ? '${profile.universityName ?? ''} - ${profile.studyProgram ?? ''}'.trim().replaceAll(RegExp(r'^-|-$'), '').trim()
                            : '-',
                      ),
                      _InfoRow(
                        icon: Icons.business_outlined,
                        label: 'Pekerjaan',
                        value: (profile.companyName != null || profile.jobPosition != null)
                            ? '${profile.companyName ?? ''} - ${profile.jobPosition ?? ''}'.trim().replaceAll(RegExp(r'^-|-$'), '').trim()
                            : '-',
                      ),
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        label: 'Usaha/Bisnis',
                        value: profile.businessName ?? '-',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildCard(
                  title: 'Kontak & Lokasi',
                  icon: Icons.location_on_outlined,
                  children: [
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'Lokasi',
                      value: (profile.city != null || profile.province != null)
                          ? '${profile.city ?? ''}, ${profile.province ?? ''}'.trim().replaceAll(RegExp(r'^,|,$'), '').trim()
                          : '-',
                    ),
                    _InfoRow(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      value: profile.whatsapp ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.link_outlined,
                      label: 'LinkedIn',
                      value: profile.linkedinUrl ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCard(
                  title: 'Status',
                  icon: Icons.verified_outlined,
                  children: [
                    _InfoRow(
                      icon: Icons.info_outline,
                      label: 'Status Akun',
                      value: _formatStatus(profile.status),
                    ),
                    _InfoRow(
                      icon: Icons.group_outlined,
                      label: 'Role',
                      value: _formatRole(profile.role),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90D9), Color(0xFFBFE0F5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90D9),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatRole(profile.role),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF4A90D9)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A90D9),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatStatus(String status) {
    return switch (status.toLowerCase()) {
      'active' => 'Aktif',
      'inactive' => 'Tidak Aktif',
      _ => status,
    };
  }

  String _formatCurrentStatus(String status) {
    return switch (status) {
      'studying' => 'Kuliah',
      'working' => 'Bekerja',
      'entrepreneur' => 'Wirausaha',
      'unemployed' => 'Belum bekerja',
      'studying_working' => 'Kuliah sambil bekerja',
      _ => status,
    };
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}