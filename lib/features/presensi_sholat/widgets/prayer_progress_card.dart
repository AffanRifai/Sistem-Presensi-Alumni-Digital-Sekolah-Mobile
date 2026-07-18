import 'package:flutter/material.dart';

import '../data/prayer_attendance_service.dart';
import '../data/prayer_models.dart';
import '../presensi_sholat_page.dart';

// Kartu ringkasan sholat untuk Beranda siswa (lihat wireframe 16 pada
// blueprint). Hanya menghitung sholat yang aktif di fase ini (Dzuhur & Ashar).
class PrayerProgressCard extends StatefulWidget {
  const PrayerProgressCard({super.key});

  @override
  State<PrayerProgressCard> createState() => _PrayerProgressCardState();
}

class _PrayerProgressCardState extends State<PrayerProgressCard> {
  static const Color primaryBlue = Color(0xFF1E88E5);

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat progress sholat hari ini.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openPresensiSholat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PresensiSholatPage()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator()),
            )
          : _errorMessage != null
          ? _buildError()
          : GestureDetector(onTap: _openPresensiSholat, child: _buildContent()),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: const Text('Coba Lagi')),
      ],
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final approved = summary.approvedCount;
    final activeTotal = summary.activeTotal;
    final progress = activeTotal == 0 ? 0.0 : approved / activeTotal;
    final next = summary.nextActionable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.mosque_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Progress Sholat Hari Ini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '$approved/$activeTotal',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFEDEFF3),
            valueColor: const AlwaysStoppedAnimation(primaryBlue),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${next.type.label} sedang dibuka',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (next.windowLabel != null)
                      Text(
                        next.windowLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _openPresensiSholat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Presensi'),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lihat detail presensi sholat',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ],
      ],
    );
  }
}
