import 'package:flutter/material.dart';

import '../data/prayer_models.dart';

const prayerHistoryPrimary = Color(0xFF1E88E5);

DateTime prayerDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime prayerWeekStart(DateTime value) {
  final date = prayerDateOnly(value);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

DateTime prayerWeekEnd(DateTime value) {
  return prayerWeekStart(value).add(const Duration(days: 6));
}

bool isSamePrayerDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String formatPrayerDate(DateTime date, {bool includeYear = true}) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return includeYear
      ? '${date.day} ${months[date.month - 1]} ${date.year}'
      : '${date.day} ${months[date.month - 1]}';
}

String formatPrayerMonth(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String formatPrayerTime(DateTime? date) {
  if (date == null) return '-';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute WIB';
}

String formatPrayerDateTime(DateTime? date) {
  if (date == null) return '-';
  return '${formatPrayerDate(date)} • ${formatPrayerTime(date)}';
}

Color prayerStatusColor(PrayerAttendanceStatus status) {
  return switch (status) {
    PrayerAttendanceStatus.approved => const Color(0xFF168A49),
    PrayerAttendanceStatus.pending => const Color(0xFFD97706),
    PrayerAttendanceStatus.rejected => const Color(0xFFDC2626),
    PrayerAttendanceStatus.late => const Color(0xFFB45309),
    PrayerAttendanceStatus.missed => const Color(0xFF6B7280),
    PrayerAttendanceStatus.expired => const Color(0xFF64748B),
    PrayerAttendanceStatus.open => prayerHistoryPrimary,
    PrayerAttendanceStatus.resubmissionAllowed => const Color(0xFF7C3AED),
    PrayerAttendanceStatus.cancelled => const Color(0xFF475569),
    PrayerAttendanceStatus.notAvailable => const Color(0xFF9CA3AF),
  };
}

IconData prayerStatusIcon(PrayerAttendanceStatus status) {
  return switch (status) {
    PrayerAttendanceStatus.approved => Icons.check_circle_outline_rounded,
    PrayerAttendanceStatus.pending => Icons.schedule_rounded,
    PrayerAttendanceStatus.rejected => Icons.cancel_outlined,
    PrayerAttendanceStatus.late => Icons.access_time_rounded,
    PrayerAttendanceStatus.missed => Icons.remove_circle_outline_rounded,
    PrayerAttendanceStatus.expired => Icons.timer_off_outlined,
    PrayerAttendanceStatus.open => Icons.lock_open_rounded,
    PrayerAttendanceStatus.resubmissionAllowed => Icons.replay_rounded,
    PrayerAttendanceStatus.cancelled => Icons.block_rounded,
    PrayerAttendanceStatus.notAvailable => Icons.horizontal_rule_rounded,
  };
}

class PrayerHistoryPeriodSelector extends StatelessWidget {
  final PrayerHistoryPeriod value;
  final ValueChanged<PrayerHistoryPeriod> onChanged;

  const PrayerHistoryPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PrayerHistoryPeriod.values.map((period) {
        return ChoiceChip(
          label: Text(_periodLabel(period)),
          selected: value == period,
          onSelected: (_) => onChanged(period),
          showCheckmark: false,
          selectedColor: prayerHistoryPrimary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: value == period
                ? prayerHistoryPrimary
                : const Color(0xFFD7DEE8),
          ),
          labelStyle: TextStyle(
            color: value == period ? Colors.white : Colors.black54,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }

  String _periodLabel(PrayerHistoryPeriod period) => switch (period) {
    PrayerHistoryPeriod.daily => 'Harian',
    PrayerHistoryPeriod.weekly => 'Mingguan',
    PrayerHistoryPeriod.monthly => 'Bulanan',
  };
}

class PrayerHistoryDateSelector extends StatelessWidget {
  final PrayerHistoryPeriod period;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  const PrayerHistoryDateSelector({
    super.key,
    required this.period,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE3EA)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Sebelumnya',
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: prayerHistoryPrimary,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Berikutnya',
          ),
        ],
      ),
    );
  }

  String get _label => switch (period) {
    PrayerHistoryPeriod.daily => formatPrayerDate(selectedDate),
    PrayerHistoryPeriod.weekly =>
      '${formatPrayerDate(prayerWeekStart(selectedDate), includeYear: false)}–${formatPrayerDate(prayerWeekEnd(selectedDate))}',
    PrayerHistoryPeriod.monthly => formatPrayerMonth(selectedDate),
  };
}

class PrayerHistoryStatusBadge extends StatelessWidget {
  final PrayerAttendanceStatus status;
  final bool compact;

  const PrayerHistoryStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = prayerStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prayerStatusIcon(status), size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerHistorySummary extends StatelessWidget {
  final List<PrayerAttendanceHistoryItem> items;

  const PrayerHistorySummary({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final approved = _count(PrayerAttendanceStatus.approved);
    final pending = _count(PrayerAttendanceStatus.pending);
    final rejected = _count(PrayerAttendanceStatus.rejected);
    final late = _count(PrayerAttendanceStatus.late);
    final missed = _count(PrayerAttendanceStatus.missed);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${items.length} data pada hasil saat ini',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryValue(label: 'Setuju', value: approved),
              _SummaryValue(label: 'Menunggu', value: pending),
              _SummaryValue(label: 'Ditolak', value: rejected),
              _SummaryValue(label: 'Terlambat', value: late),
              _SummaryValue(label: 'Tidak presensi', value: missed),
            ],
          ),
        ],
      ),
    );
  }

  int _count(PrayerAttendanceStatus status) {
    return items.where((item) => item.status == status).length;
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
    );
  }
}

class PrayerHistoryFilterResult {
  final PrayerType? prayerType;
  final PrayerAttendanceStatus? status;

  const PrayerHistoryFilterResult({this.prayerType, this.status});
}

Future<PrayerHistoryFilterResult?> showPrayerHistoryFilterSheet(
  BuildContext context, {
  PrayerType? prayerType,
  PrayerAttendanceStatus? status,
}) {
  return showModalBottomSheet<PrayerHistoryFilterResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _PrayerHistoryFilterSheet(
      initialPrayerType: prayerType,
      initialStatus: status,
    ),
  );
}

class _PrayerHistoryFilterSheet extends StatefulWidget {
  final PrayerType? initialPrayerType;
  final PrayerAttendanceStatus? initialStatus;

  const _PrayerHistoryFilterSheet({this.initialPrayerType, this.initialStatus});

  @override
  State<_PrayerHistoryFilterSheet> createState() =>
      _PrayerHistoryFilterSheetState();
}

class _PrayerHistoryFilterSheetState extends State<_PrayerHistoryFilterSheet> {
  PrayerType? _prayerType;
  PrayerAttendanceStatus? _status;

  static const _historyStatuses = [
    PrayerAttendanceStatus.approved,
    PrayerAttendanceStatus.pending,
    PrayerAttendanceStatus.rejected,
    PrayerAttendanceStatus.late,
    PrayerAttendanceStatus.missed,
    PrayerAttendanceStatus.expired,
  ];

  @override
  void initState() {
    super.initState();
    _prayerType = widget.initialPrayerType;
    _status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Riwayat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            const Text(
              'Jenis sholat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: PrayerType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _prayerType == type,
                  onSelected: (selected) {
                    setState(() => _prayerType = selected ? type : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _historyStatuses.map((value) {
                return ChoiceChip(
                  label: Text(value.label),
                  selected: _status == value,
                  onSelected: (selected) {
                    setState(() => _status = selected ? value : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _prayerType = null;
                        _status = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      PrayerHistoryFilterResult(
                        prayerType: _prayerType,
                        status: _status,
                      ),
                    ),
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerHistoryEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onReset;

  const PrayerHistoryEmptyState({
    super.key,
    required this.message,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Colors.black54),
          ),
          if (onReset != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onReset, child: const Text('Reset Filter')),
          ],
        ],
      ),
    );
  }
}

class PrayerHistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PrayerHistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
