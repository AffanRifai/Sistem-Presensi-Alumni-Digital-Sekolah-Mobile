import 'package:flutter/material.dart';

import 'data/prayer_models.dart';
import 'widgets/prayer_history_widgets.dart';

class TeacherPrayerHistoryDetailPage extends StatelessWidget {
  final String title;
  final List<PrayerAttendanceHistoryItem> items;

  const TeacherPrayerHistoryDetailPage({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]
      ..sort((a, b) {
        final date = b.attendanceDate.compareTo(a.attendanceDate);
        return date != 0
            ? date
            : a.prayerType.index.compareTo(b.prayerType.index);
      });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Detail Riwayat Siswa',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sortedItems.isEmpty
                ? 'Tidak ada data pada periode ini.'
                : '${sortedItems.first.studentNumber ?? '-'} • ${sortedItems.first.className ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          PrayerHistorySummary(items: sortedItems),
          const SizedBox(height: 16),
          if (sortedItems.isEmpty)
            const PrayerHistoryEmptyState(
              message: 'Tidak ada riwayat untuk ditampilkan.',
            )
          else
            ...sortedItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TeacherHistoryDetailCard(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherHistoryDetailCard extends StatelessWidget {
  final PrayerAttendanceHistoryItem item;

  const _TeacherHistoryDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.prayerType.label} • ${formatPrayerDate(item.attendanceDate)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              PrayerHistoryStatusBadge(status: item.status, compact: true),
            ],
          ),
          const SizedBox(height: 11),
          _InfoLine(
            label: 'Waktu input',
            value: formatPrayerDateTime(item.submittedAt),
          ),
          _InfoLine(label: 'Verifikator', value: item.verifierName ?? '-'),
          _InfoLine(
            label: 'Waktu verifikasi',
            value: formatPrayerDateTime(item.verifiedAt),
          ),
          if (item.teacherNote?.trim().isNotEmpty == true) ...[
            const Divider(height: 20),
            Text(
              'Catatan: ${item.teacherNote}',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
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
