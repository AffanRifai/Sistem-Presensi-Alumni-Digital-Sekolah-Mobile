import 'package:flutter/material.dart';

import '../auth/data/auth_service.dart';
import '../auth/welcome_page.dart';

class UserProfilePage extends StatelessWidget {
  final Future<AuthUser?> userFuture;
  final AuthService authService;

  const UserProfilePage({
    super.key,
    required this.userFuture,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A90D9);

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang flat dan bersih
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<AuthUser?>(
        future: _loadUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final user = snapshot.data;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Profil (Avatar & Nama Utama) ──
                _buildHeader(context, user),
                
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),

                // ── Informasi Akun & Kontak ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // ── Card 1: Informasi Akun ──
                      _buildSection(
                        title: 'Informasi Akun',
                        icon: Icons.person_outline_rounded,
                        initiallyExpanded: true,
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Nama Lengkap',
                            value: user?.name ?? '-',
                          ),
                          _buildInfoRow(
                            icon: Icons.school_outlined,
                            label: 'Role / Peran',
                            value: _localizeRole(user?.role),
                          ),
                        ],
                      ),

                      // ── Card 2: Kontak & Status ──
                      _buildSection(
                        title: 'Kontak & Status',
                        icon: Icons.contact_mail_outlined,
                        children: [
                          _buildInfoRow(
                            icon: Icons.alternate_email_rounded,
                            label: 'Alamat Email',
                            value: user?.email ?? '-',
                          ),
                          _buildInfoRow(
                            icon: Icons.phone_android_rounded,
                            label: 'Nomor WhatsApp / HP',
                            value: user?.phone?.isNotEmpty == true ? user!.phone! : '-',
                          ),
                          _buildInfoRow(
                            icon: Icons.verified_user_outlined,
                            label: 'Status Akun',
                            value: '',
                            valueWidget: _buildStatusWidget(context, user?.status),
                          ),
                        ],
                      ),

                      // ── FAQ Khusus Guru/Siswa ──
                      if (user?.role.toLowerCase() == 'teacher')
                        _buildSection(
                          title: 'Tanya Jawab & Bantuan (FAQ)',
                          icon: Icons.help_outline_rounded,
                          children: [
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara membuka presensi kelas?',
                              answer: 'Pilih kelas aktif Anda di dashboard utama, lalu tekan tombol "Mulai Presensi" untuk menghasilkan QR Code presensi yang dapat dipindai oleh siswa.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara melihat jadwal mengajar saya?',
                              answer: 'Jadwal mengajar harian Anda tercantum pada menu "Jadwal Mengajar" di dashboard utama yang dikelola oleh admin kurikulum sekolah.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara melihat rekap presensi kelas?',
                              answer: 'Anda dapat masuk ke menu "Rekap Presensi" di dashboard utama untuk meninjau riwayat dan presentase kehadiran siswa Anda.',
                            ),
                          ],
                        )
                      else if (user?.role.toLowerCase() == 'student')
                        _buildSection(
                          title: 'Tanya Jawab & Bantuan (FAQ)',
                          icon: Icons.help_outline_rounded,
                          children: [
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara melakukan presensi harian?',
                              answer: 'Anda dapat melakukan pencatatan kehadiran secara digital langsung dari halaman utama dengan memindai kode QR kelas atau menekan tombol Presensi yang disediakan oleh guru.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara melihat riwayat absensi saya?',
                              answer: 'Pilih menu "Riwayat Presensi" atau tinjau ringkasan statistik kehadiran bulanan Anda langsung dari halaman dashboard utama.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Apa yang harus saya lakukan jika data profil salah?',
                              answer: 'Apabila terdapat kekeliruan data (seperti penulisan nama lengkap atau nomor WhatsApp), silakan hubungi admin sekolah atau staf Tata Usaha untuk melakukan koreksi.',
                            ),
                          ],
                        )
                      else if (user?.role.toLowerCase() == 'parent')
                        _buildSection(
                          title: 'Tanya Jawab & Bantuan (FAQ)',
                          icon: Icons.help_outline_rounded,
                          children: [
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana cara memantau kehadiran anak?',
                              answer: 'Anda dapat memantau riwayat kehadiran harian anak Anda secara real-time langsung melalui dashboard menu utama Orang Tua.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Apakah saya menerima notifikasi ketidakhadiran?',
                              answer: 'Ya, sistem akan mengirimkan notifikasi instan melalui aplikasi atau WhatsApp jika anak Anda tercatat Tidak Hadir (Alpa) atau Terlambat masuk kelas.',
                            ),
                            _buildFaqTile(
                              context,
                              question: 'Bagaimana melihat laporan absensi anak pada bulan lain?',
                              answer: 'Anda dapat menekan tombol filter bulan di bawah profil anak pada halaman utama Orang Tua, lalu pilih bulan dan tahun laporan yang ingin Anda tinjau.',
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // ── Tombol Keluar ──
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Widget Header Profil ──
  Widget _buildHeader(BuildContext context, AuthUser? user) {
    const primaryColor = Color(0xFF4A90D9);
    
    final initials = user?.name.trim().isNotEmpty == true
        ? user!.name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Right: Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  user?.name ?? 'Nama Pengguna',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _localizeRole(user?.role),
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builder ──
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    const primaryColor = Color(0xFF4A90D9);

    return Column(
      children: [
        Theme(
          data: ThemeData().copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            leading: Icon(icon, size: 24, color: primaryColor),
            iconColor: primaryColor,
            collapsedIconColor: Colors.grey.shade600,
            textColor: Colors.black87,
            collapsedTextColor: Colors.black87,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(left: 40, bottom: 12),
            initiallyExpanded: initiallyExpanded,
            children: children,
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Info Row Builder ──
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                valueWidget ??
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

  // ── FAQ Tile Builder ──
  Widget _buildFaqTile(BuildContext context, {required String question, required String answer}) {
    const primaryColor = Color(0xFF4A90D9);
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconColor: primaryColor,
        collapsedIconColor: Colors.grey.shade600,
        textColor: primaryColor,
        collapsedTextColor: Colors.black87,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Status Akun ──
  Widget _buildStatusWidget(BuildContext context, String? status) {
    final theme = Theme.of(context);
    final localized = _localizeStatus(status);
    final isActive = status?.toLowerCase() == 'active';
    final dotColor = isActive
        ? (theme.brightness == Brightness.dark
            ? Colors.greenAccent
            : Colors.green)
        : theme.colorScheme.outline;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          localized,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Tombol Logout ──
  Widget _buildLogoutButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 140,
        height: 48,
        child: FilledButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await authService.logout();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }

  Future<AuthUser?> _loadUser() async {
    try {
      return await authService.refreshCurrentUser();
    } catch (_) {
      return userFuture;
    }
  }

  String _localizeRole(String? role) {
    if (role == null) return '-';
    switch (role.toLowerCase()) {
      case 'teacher':
        return 'Guru / Pengajar';
      case 'student':
        return 'Siswa';
      case 'parent':
        return 'Orang Tua / Wali';
      case 'alumni':
        return 'Alumni';
      case 'admin':
        return 'Admin Sekolah';
      case 'super_admin':
        return 'Super Admin';
      default:
        return _formatRole(role);
    }
  }

  String _localizeStatus(String? status) {
    if (status == null) return '-';
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Nonaktif';
      case 'pending':
        return 'Menunggu Verifikasi';
      default:
        return _formatRole(status);
    }
  }

  String _formatRole(String? value) {
    if (value == null || value.isEmpty) return '-';

    return value
        .split('_')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
