import 'package:flutter/material.dart';

import 'alumni_event_detail_page.dart';
import 'alumni_event_form_page.dart';
import 'data/alumni_event_service.dart';
import '../auth/data/auth_service.dart';
import '../../core/config/api_config.dart';

class AlumniEventPage extends StatefulWidget {
  const AlumniEventPage({super.key});

  @override
  State<AlumniEventPage> createState() => _AlumniEventPageState();
}

class _AlumniEventPageState extends State<AlumniEventPage> {
  final _service = AlumniEventService();
  late Future<List<AlumniEvent>> _eventsFuture;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndEvents();
  }

  Future<void> _loadUserAndEvents() async {
    try {
      final user = await AuthService().readUser();
      if (mounted) {
        setState(() => _currentUserId = user?.id);
      }
    } catch (e) {
      debugPrint('Gagal memuat user: $e');
    }

    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = _service.fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E88E5); // Disesuaikan dengan HomePage

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Latar belakang sangat lembut agar flat card putih terlihat
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Event Alumni',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1), // Garis flat pemisah appBar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Event', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        onPressed: () async {
          // Pastikan user sudah diload
          if (_currentUserId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tunggu sebentar, sedang memuat data akun...')),
            );
            return;
          }

          try {
            // Ambil daftar event yang saat ini ada di layar
            final events = await _eventsFuture;
            
            // Hitung berapa banyak event yang diposting oleh user yang sedang login
            final myEventCount = events.where((e) => e.postedById == _currentUserId).length;

            // Cek apakah sudah mencapai batas maksimal (misal: 5)
            if (myEventCount >= 5) {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Batas Tercapai', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text(
                      'Kamu sudah mengajukan 5 event. Untuk saat ini, kamu tidak dapat mengajukan event baru lagi.',
                      style: TextStyle(color: Colors.black87, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: primaryColor),
                        child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
              return; // Hentikan proses, jangan buka form
            }

            // Jika belum mencapai batas, buka form pengajuan
            if (mounted) {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlumniEventFormPage()),
              );
              
              if (result == true) {
                _loadEvents();
              }
            }
          } catch (e) {
            // Tangani jika _eventsFuture gagal dimuat
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal memverifikasi jumlah event.')),
              );
            }
          }
        },
      ),
      body: FutureBuilder<List<AlumniEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _loadEvents,
            );
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const _EmptyView();
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              _loadEvents();
              await _eventsFuture;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), // Bottom padding untuk area FAB
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _EventCard(
                event: events[index],
                currentUserId: _currentUserId,
                onRefresh: _loadEvents,
              ),
            ),
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
    const primaryColor = Color(0xFF1E88E5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 48, color: Color(0xFFE57373)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Saat ini belum ada event alumni yang tersedia. Jadilah yang pertama membuat event!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final AlumniEvent event;
  final int? currentUserId;
  final VoidCallback onRefresh;

  const _EventCard({
    required this.event,
    this.currentUserId,
    required this.onRefresh,
  });

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus event ini? Aksi ini tidak dapat dibatalkan.'),
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
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await AlumniEventService().deleteEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event berhasil dihapus')),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus event: $e')),
          );
        }
      }
    }
  }

  void _handleEdit(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlumniEventFormPage(eventToEdit: event),
      ),
    );
    if (result == true) {
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(event.status);
    final canEditOrDelete = event.postedById == currentUserId && event.approvalStatus == 'pending';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlumniEventDetailPage(event: event),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2), // Layout flat dengan border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris Atas: Badge Status & Menu Opsi ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Badge Status Event (Akan Datang, Berlangsung, dll)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusInfo.color,
                          ),
                        ),
                      ),
                      // Badge Pending Approval
                      if (event.approvalStatus == 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_bottom_rounded, size: 12, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Menunggu Persetujuan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (canEditOrDelete)
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') _handleEdit(context);
                        if (value == 'delete') _handleDelete(context);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1E88E5)),
                              SizedBox(width: 10),
                              Text('Edit Event', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ── Judul ──
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // ── Gambar Banner (Jika Ada) ──
            if (event.bannerImage != null && event.bannerImage!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.bannerImage!.startsWith('http')
                      ? event.bannerImage!
                      : '${ApiConfig.storageUrl}/${event.bannerImage}',
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Deskripsi ──
            if (event.description.isNotEmpty) ...[
              Text(
                event.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Info Singkat (Tanggal & Lokasi) ──
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              text: _formatDateRange(event.startDate, event.endDate),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on_outlined,
              text: event.location,
            ),
            if (event.organizer != null && event.organizer!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.person_outline,
                text: event.organizer!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final startStr = '${start.day} ${months[start.month - 1]} ${start.year}';
    if (end == null || end == start) return startStr;
    final endStr = '${end.day} ${months[end.month - 1]} ${end.year}';
    return '$startStr – $endStr';
  }

  _StatusInfo _getStatusInfo(String status) {
    return switch (status.toLowerCase()) {
      'upcoming' => const _StatusInfo(
          label: 'Akan Datang',
          color: Color(0xFF1E88E5), // Menggunakan primaryBlue
          bgColor: Color(0xFFE3F2FD), // Blue.shade50
        ),
      'ongoing' => const _StatusInfo(
          label: 'Berlangsung',
          color: Color(0xFF43A047),
          bgColor: Color(0xFFE8F5E9),
        ),
      'done' || 'completed' => _StatusInfo(
          label: 'Selesai',
          color: Colors.grey.shade600,
          bgColor: Colors.grey.shade100,
        ),
      'cancelled' => const _StatusInfo(
          label: 'Dibatalkan',
          color: Color(0xFFE53935),
          bgColor: Color(0xFFFFEBEE),
        ),
      _ => _StatusInfo(
          label: status,
          color: Color(0xFFF57C00),
          bgColor: Color(0xFFFFF3E0),
        ),
    };
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}