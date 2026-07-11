import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'data/alumni_event_service.dart';
import '../../core/config/api_config.dart';

class AlumniEventDetailPage extends StatelessWidget {
  final AlumniEvent event;

  const AlumniEventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(event.status);

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih bersih (flat design)
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Event',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1), // Garis pemisah flat
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Gambar Banner ---
            if (event.bannerImage != null && event.bannerImage!.isNotEmpty)
              Image.network(
                event.bannerImage!.startsWith('http')
                    ? event.bannerImage!
                    : '${ApiConfig.storageUrl}/${event.bannerImage}',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade400),
                ),
              ),
            
            // --- Konten Utama ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges (Status & Approval)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(8), // Sudut membulat modern
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusInfo.color,
                          ),
                        ),
                      ),
                      if (event.approvalStatus == 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_bottom_rounded, size: 14, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Menunggu Persetujuan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Judul Event
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 24),

                  // Detail Items
                  _buildDetailItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tanggal & Waktu',
                    content: _formatDateRange(event.startDate, event.endDate),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Lokasi',
                    content: event.location,
                  ),
                  if (event.organizer != null && event.organizer!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailItem(
                      icon: Icons.person_outline,
                      title: 'Penyelenggara / Pengaju',
                      content: event.organizer!,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 24),

                  // Deskripsi
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 22, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 10),
                      const Text(
                        'Deskripsi Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Html(
                    data: event.description,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14.5),
                        color: Colors.grey.shade800,
                        lineHeight: const LineHeight(1.6),
                      ),
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER WIDGET ---
  Widget _buildDetailItem({required IconData icon, required String title, required String content}) {
    const primaryColor = Color(0xFF1E88E5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGIC HELPER ---
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
          color: Color(0xFF1E88E5), // Disesuaikan dengan warna utama
          bgColor: Color(0xFFE3F2FD),
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