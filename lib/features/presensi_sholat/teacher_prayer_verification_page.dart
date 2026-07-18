import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../kelas/data/class_recap_models.dart';
import '../kelas/data/class_recap_service.dart';
import 'data/prayer_attendance_service.dart';
import 'data/prayer_models.dart';

class TeacherPrayerVerificationPage extends StatefulWidget {
  const TeacherPrayerVerificationPage({super.key});

  @override
  State<TeacherPrayerVerificationPage> createState() =>
      _TeacherPrayerVerificationPageState();
}

class _TeacherPrayerVerificationPageState
    extends State<TeacherPrayerVerificationPage> {
  static const Color primaryBlue = Color(0xFF1E88E5);

  final PrayerAttendanceService _prayerService = PrayerAttendanceService();
  final ClassRecapService _classService = ClassRecapService();

  bool _isLoading = true;
  bool _isBulkProcessing = false;
  String? _errorMessage;
  List<_TeacherPrayerVerificationRow> _rows = const [];
  int _classCount = 0;
  int? _processingId;

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
      final classes = await _classService.fetchClasses();
      final studentLists = await Future.wait(
        classes.map((classData) => _classService.fetchStudents(classData.id)),
      );
      final pendingItems = await _prayerService.fetchPendingVerifications();

      final membershipById = <int, _StudentClassMembership>{};
      final membershipByName = <String, _StudentClassMembership>{};
      for (var index = 0; index < classes.length; index++) {
        final classData = classes[index];
        for (final student in studentLists[index]) {
          final membership = _StudentClassMembership(
            student: student,
            classData: classData,
          );
          membershipById[student.id] = membership;
          membershipByName[_normalizeName(student.fullName)] = membership;
        }
      }

      final rows = <_TeacherPrayerVerificationRow>[];
      for (final attendance in pendingItems) {
        final membership =
            membershipById[attendance.studentId] ??
            membershipByName[_normalizeName(attendance.studentName)];
        if (membership == null) continue;

        rows.add(
          _TeacherPrayerVerificationRow(
            attendance: attendance,
            student: membership.student,
            classData: membership.classData,
          ),
        );
      }
      rows.sort(
        (a, b) => b.attendance.submittedAt.compareTo(a.attendance.submittedAt),
      );

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _classCount = classes.length;
        _processingId = null;
        _isBulkProcessing = false;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Tidak bisa memuat siswa dari kelas yang Anda ampu.',
        );
        _processingId = null;
        _isBulkProcessing = false;
        _isLoading = false;
      });
    }
  }

  String _normalizeName(String value) => value.trim().toLowerCase();

  Future<void> _openVerificationDialog(
    _TeacherPrayerVerificationRow row, {
    required bool approved,
  }) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(approved ? 'Setujui Presensi' : 'Tolak Presensi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${row.student.fullName} • ${row.attendance.prayerType.label}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Waktu input: ${_formatSubmittedAt(row.attendance.submittedAt)}',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLength: 150,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Tambahkan catatan untuk siswa',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approved
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(approved ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();

    if (confirmed == true) {
      await _verify(row, approved: approved, note: note);
    }
  }

  Future<void> _verify(
    _TeacherPrayerVerificationRow row, {
    required bool approved,
    String? note,
  }) async {
    setState(() => _processingId = row.attendance.id);
    try {
      await _prayerService.verifyAttendance(
        attendanceId: row.attendance.id,
        approved: approved,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Presensi berhasil disetujui.'
                : 'Presensi berhasil ditolak.',
          ),
        ),
      );
      await _load();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _processingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.getMessage(
              error,
              stackTrace: stackTrace,
              fallback: 'Tidak bisa memproses verifikasi. Coba lagi.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openVerifyAllDialog() async {
    if (_rows.isEmpty || _isBulkProcessing) return;

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Verifikasi Semua'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_rows.length} presensi siswa akan langsung disetujui.',
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLength: 150,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan untuk semua (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui Semua'),
          ),
        ],
      ),
    );
    final note = noteController.text;
    noteController.dispose();

    if (confirmed == true) {
      await _verifyAll(note: note);
    }
  }

  Future<void> _verifyAll({String? note}) async {
    setState(() => _isBulkProcessing = true);
    final total = _rows.length;
    try {
      await _prayerService.verifyAllAttendances(
        attendanceIds: _rows.map((row) => row.attendance.id),
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$total presensi berhasil disetujui.')),
      );
      await _load();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isBulkProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.getMessage(
              error,
              stackTrace: stackTrace,
              fallback: 'Tidak bisa memverifikasi semua presensi.',
            ),
          ),
        ),
      );
    }
  }

  String _formatSubmittedAt(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} • $hour:$minute WIB';
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
          'Verifikasi Presensi Sholat',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
            Text(
              _classCount == 0
                  ? 'Anda belum memiliki kelas yang diampu.'
                  : 'Belum ada presensi sholat dari siswa kelas Anda yang '
                        'menunggu verifikasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_rows.length} menunggu verifikasi • $_classCount kelas',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isBulkProcessing ? null : _openVerifyAllDialog,
                icon: _isBulkProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Verifikasi Semua'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return _VerificationListItem(
                  row: row,
                  submittedAt: _formatSubmittedAt(row.attendance.submittedAt),
                  isProcessing: _processingId == row.attendance.id,
                  actionsEnabled: !_isBulkProcessing,
                  onReject: () => _openVerificationDialog(row, approved: false),
                  onApprove: () => _openVerificationDialog(row, approved: true),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationListItem extends StatelessWidget {
  final _TeacherPrayerVerificationRow row;
  final String submittedAt;
  final bool isProcessing;
  final bool actionsEnabled;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _VerificationListItem({
    required this.row,
    required this.submittedAt,
    required this.isProcessing,
    required this.actionsEnabled,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.student.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS ${row.student.nis} • ${row.classData.name}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                row.attendance.prayerType.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Waktu input: $submittedAt',
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (isProcessing)
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: actionsEnabled ? onReject : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Tolak'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: actionsEnabled ? onApprove : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Setujui'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TeacherPrayerVerificationRow {
  final PrayerVerificationItem attendance;
  final StudentRecapModel student;
  final ClassRecapModel classData;

  const _TeacherPrayerVerificationRow({
    required this.attendance,
    required this.student,
    required this.classData,
  });
}

class _StudentClassMembership {
  final StudentRecapModel student;
  final ClassRecapModel classData;

  const _StudentClassMembership({
    required this.student,
    required this.classData,
  });
}
