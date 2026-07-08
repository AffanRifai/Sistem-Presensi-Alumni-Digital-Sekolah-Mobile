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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Detail Event'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.bannerImage != null && event.bannerImage!.isNotEmpty)
              Image.network(
                event.bannerImage!.startsWith('http')
                    ? event.bannerImage!
                    : '${ApiConfig.storageUrl}/${event.bannerImage}',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusInfo.color,
                          ),
                        ),
                      ),
                      if (event.approvalStatus == 'pending') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'Menunggu Persetujuan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tanggal & Waktu',
                    content: _formatDateRange(event.startDate, event.endDate),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Lokasi',
                    content: event.location,
                  ),
                  if (event.organizer != null && event.organizer!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      icon: Icons.person_outline,
                      title: 'Penyelenggara / Pengaju',
                      content: event.organizer!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(
                    data: event.description,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(14.0),
                        color: Colors.black87,
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

  Widget _buildDetailItem({required IconData icon, required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4A90D9), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
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
                ),
              ),
            ],
          ),
        ),
      ],
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
