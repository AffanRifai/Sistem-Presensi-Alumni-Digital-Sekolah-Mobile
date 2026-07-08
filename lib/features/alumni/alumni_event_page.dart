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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Event Alumni',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A90D9),
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
                    title: const Text('Batas Pengajuan Tercapai'),
                    content: const Text(
                      'Kamu sudah mengajukan 5 event. Untuk saat ini, kamu tidak dapat mengajukan event baru lagi.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Mengerti'),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<AlumniEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
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
            color: const Color(0xFF4A90D9),
            onRefresh: () async {
              _loadEvents();
              await _eventsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE57373)),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat event',
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

// ─── Empty View ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'Belum ada event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Saat ini belum ada event alumni yang tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black45),
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
        title: const Text('Hapus Event'),
        content: const Text('Apakah Anda yakin ingin menghapus event ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // ── Header berwarna sesuai status ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: statusInfo.bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 18, color: statusInfo.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusInfo.color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusInfo.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusInfo.color,
                      ),
                    ),
                  ),
                  // Tombol Opsi (Edit / Delete)
                  if (canEditOrDelete) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_vert, size: 20, color: statusInfo.color),
                        onSelected: (value) {
                          if (value == 'edit') _handleEdit(context);
                          if (value == 'delete') _handleDelete(context);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Body detail ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.approvalStatus == 'pending') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Menunggu Persetujuan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (event.bannerImage != null && event.bannerImage!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event.bannerImage!.startsWith('http')
                            ? event.bannerImage!
                            : '${ApiConfig.storageUrl}/${event.bannerImage}',
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (event.description.isNotEmpty) ...[
                    Text(
                      event.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDateRange(event.startDate, event.endDate),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                  if (event.organizer != null && event.organizer!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.person_outline,
                      text: event.organizer!,
                    ),
                  ],
                ],
              ),
            ),
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
      'upcoming' => _StatusInfo(
          label: 'Akan Datang',
          color: const Color(0xFF4A90D9),
          bgColor: const Color(0xFFE3EEFF),
        ),
      'ongoing' => _StatusInfo(
          label: 'Berlangsung',
          color: const Color(0xFF2E9E5B),
          bgColor: const Color(0xFFD9F2E4),
        ),
      'done' || 'completed' => _StatusInfo(
          label: 'Selesai',
          color: const Color(0xFF9E9E9E),
          bgColor: const Color(0xFFF0F0F0),
        ),
      'cancelled' => _StatusInfo(
          label: 'Dibatalkan',
          color: const Color(0xFFE57373),
          bgColor: const Color(0xFFFFEBEB),
        ),
      _ => _StatusInfo(
          label: status,
          color: const Color(0xFFE0983C),
          bgColor: const Color(0xFFFCEBD3),
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
        Icon(icon, size: 15, color: Colors.black38),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}