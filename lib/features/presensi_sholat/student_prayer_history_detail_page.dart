import 'package:flutter/material.dart';

import 'data/prayer_models.dart';
import 'widgets/prayer_history_widgets.dart';

class StudentPrayerHistoryDetailPage extends StatelessWidget {
  final PrayerAttendanceHistoryItem item;

  const StudentPrayerHistoryDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Detail Riwayat Sholat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: prayerStatusColor(item.status).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: prayerStatusColor(item.status).withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mosque_outlined,
                      color: prayerHistoryPrimary,
                      size: 27,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.prayerType.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    PrayerHistoryStatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  formatPrayerDate(item.attendanceDate),
                  style: const TextStyle(fontSize: 13.5, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailSection(
            title: 'Informasi Presensi',
            children: [
              _DetailRow(
                label: 'Waktu pengiriman',
                value: formatPrayerDateTime(item.submittedAt),
              ),
              _DetailRow(
                label: 'Diverifikasi oleh',
                value: item.verifierName ?? '-',
              ),
              _DetailRow(
                label: 'Waktu verifikasi',
                value: formatPrayerDateTime(item.verifiedAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Catatan Guru',
            children: [
              Text(
                item.teacherNote?.trim().isNotEmpty == true
                    ? item.teacherNote!
                    : 'Tidak ada catatan dari guru.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HistoryTimeline(item: item),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final PrayerAttendanceHistoryItem item;

  const _HistoryTimeline({required this.item});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        title: item.submittedAt == null ? 'Tidak ada pengiriman' : 'Dikirim',
        value: formatPrayerDateTime(item.submittedAt),
        completed: item.submittedAt != null,
      ),
      _TimelineStep(
        title: item.status.label,
        value: item.verifiedAt == null
            ? 'Belum ada waktu verifikasi'
            : formatPrayerDateTime(item.verifiedAt),
        completed: item.status != PrayerAttendanceStatus.pending,
      ),
    ];

    return _DetailSection(
      title: 'Timeline Status',
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                step.completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: step.completed
                    ? prayerHistoryPrimary
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineStep {
  final String title;
  final String value;
  final bool completed;

  const _TimelineStep({
    required this.title,
    required this.value,
    required this.completed,
  });
}
