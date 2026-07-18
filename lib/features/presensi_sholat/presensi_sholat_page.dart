import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import 'data/prayer_attendance_service.dart';
import 'data/prayer_models.dart';
import 'prayer_attendance_form_page.dart';

class PresensiSholatPage extends StatefulWidget {
  const PresensiSholatPage({super.key});

  @override
  State<PresensiSholatPage> createState() => _PresensiSholatPageState();
}

class _PresensiSholatPageState extends State<PresensiSholatPage> {
  final PrayerAttendanceService _service = PrayerAttendanceService();

  bool _isLoading = true;
  String? _errorMessage;
  TodayPrayerSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _service.fetchTodaySummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Tidak bisa memuat data presensi sholat.',
        );
        _isLoading = false;
      });
    }
  }

  String _dateLabel(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      "Jum'at",
      'Sabtu',
      'Minggu',
    ];
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Presensi Sholat',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Coba Lagi')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    _dateLabel(_summary!.date),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ..._summary!.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PrayerStatusCard(
                        item: item,
                        onSubmitTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrayerAttendanceFormPage(
                                prayerType: item.type,
                              ),
                            ),
                          );
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PrayerStatusCard extends StatelessWidget {
  final TodayPrayerItem item;
  final VoidCallback onSubmitTap;

  const _PrayerStatusCard({required this.item, required this.onSubmitTap});

  static const Color primaryBlue = Color(0xFF1E88E5);

  _StatusVisual get _visual {
    // Fitur belum diaktifkan sekolah untuk sholat ini (fase 1) — beda pesan
    // dengan "belum masuk waktu" supaya siswa tidak bingung.
    if (!item.isEnabled) {
      return const _StatusVisual(
        icon: Icons.hourglass_disabled_rounded,
        color: Color(0xFF9E9E9E),
        label: 'Belum tersedia di fase ini',
      );
    }

    return switch (item.status) {
      PrayerAttendanceStatus.approved => const _StatusVisual(
        icon: Icons.check_circle_rounded,
        color: Color(0xFF16A34A),
        label: 'Disetujui',
      ),
      PrayerAttendanceStatus.pending => const _StatusVisual(
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFF59E0B),
        label: 'Menunggu verifikasi',
      ),
      PrayerAttendanceStatus.rejected => const _StatusVisual(
        icon: Icons.cancel_rounded,
        color: Color(0xFFDC2626),
        label: 'Ditolak',
      ),
      PrayerAttendanceStatus.resubmissionAllowed => const _StatusVisual(
        icon: Icons.replay_rounded,
        color: Color(0xFFDC2626),
        label: 'Ditolak — bisa kirim ulang',
      ),
      PrayerAttendanceStatus.open => const _StatusVisual(
        icon: Icons.mosque_rounded,
        color: primaryBlue,
        label: 'Presensi sedang dibuka',
      ),
      PrayerAttendanceStatus.late => const _StatusVisual(
        icon: Icons.warning_rounded,
        color: Color(0xFFEA580C),
        label: 'Terlambat — menunggu verifikasi',
      ),
      PrayerAttendanceStatus.missed => const _StatusVisual(
        icon: Icons.remove_circle_outline_rounded,
        color: Color(0xFF616161),
        label: 'Tidak presensi',
      ),
      PrayerAttendanceStatus.expired => const _StatusVisual(
        icon: Icons.lock_clock_rounded,
        color: Color(0xFF9E9E9E),
        label: 'Waktu presensi berakhir',
      ),
      PrayerAttendanceStatus.cancelled => const _StatusVisual(
        icon: Icons.block_rounded,
        color: Color(0xFF9E9E9E),
        label: 'Dibatalkan',
      ),
      PrayerAttendanceStatus.notAvailable => const _StatusVisual(
        icon: Icons.lock_clock_rounded,
        color: Color(0xFF9E9E9E),
        label: 'Belum masuk waktu',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visual.icon, color: visual.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      visual.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: visual.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.windowLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              item.windowLabel!,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ],
          if (item.isEnabled && item.canSubmit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmitTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Presensi Sekarang',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusVisual {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusVisual({
    required this.icon,
    required this.color,
    required this.label,
  });
}
