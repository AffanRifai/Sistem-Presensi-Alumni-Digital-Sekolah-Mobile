import 'package:flutter/material.dart';
import 'data/alumni_service.dart';
import 'alumni_profile_edit_page.dart';

import '../auth/data/auth_service.dart'; 
import '../auth/login_page.dart'; 

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

  // --- FUNGSI LOGOUT ---
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
            ),
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AuthService().logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A90D9);

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang flat dan bersih
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Profil Alumni',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: primaryColor),
            tooltip: 'Edit Profil',
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
          // Icon Logout di AppBar (Opsional, tapi bagus untuk akses cepat)
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<AlumniProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
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
          
          return _ProfileContent(
            profile: profile,
            onLogoutTap: _handleLogout, // Mengirimkan fungsi logout ke ProfileContent
          );
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
                fontWeight: FontWeight.w500,
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
                elevation: 0,
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
  final VoidCallback onLogoutTap;

  const _ProfileContent({required this.profile, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Avatar + Nama (Desain Baru) ──
          _buildHeader(),
          
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 24),

          // ── Biodata ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildSection(
                  title: 'Informasi Akun',
                  fontWeight: FontWeight.w500,
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
                
                _buildSection(
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
                
                if (profile.currentStatus != null)
                  _buildSection(
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
                
                _buildSection(
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
                
                _buildSection(
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

                const SizedBox(height: 16),
                
                // ── Tombol Logout Besar di Bawah ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogoutTap,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text(
                      'Keluar Akun',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Desain Header Baru Tanpa Gradient ---
  Widget _buildHeader() {
    const primaryColor = Color(0xFF4A90D9);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatRole(profile.role),
              style: const TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Layout Flat Pengganti _buildCard ---
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF4A90D9)),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: fontWeight,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 24),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 12), // Menghapus padding horizontal agar rata kiri
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
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