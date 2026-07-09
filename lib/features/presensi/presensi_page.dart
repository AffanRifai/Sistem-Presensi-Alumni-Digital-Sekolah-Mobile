import 'package:flutter/material.dart';

import '/features/home/home_page.dart';
import '../../core/network/api_exception.dart';
import 'data/presensi_models.dart';
import 'data/presensi_service.dart';

enum KehadiranStatus { hadir, terlambat, izin, sakit, alpha }

extension KehadiranStatusX on KehadiranStatus {
  String get label {
    switch (this) {
      case KehadiranStatus.hadir:
        return 'Hadir';
      case KehadiranStatus.terlambat:
        return 'Terlambat';
      case KehadiranStatus.izin:
        return 'Izin';
      case KehadiranStatus.sakit:
        return 'Sakit';
      case KehadiranStatus.alpha:
        return 'Alpha';
    }
  }

  String get apiValue {
    switch (this) {
      case KehadiranStatus.hadir:
        return 'present';
      case KehadiranStatus.terlambat:
        return 'late';
      case KehadiranStatus.izin:
        return 'permission';
      case KehadiranStatus.sakit:
        return 'sick';
      case KehadiranStatus.alpha:
        return 'absent';
    }
  }

  Color get color {
    switch (this) {
      case KehadiranStatus.hadir:
        return const Color(0xFF1E88E5);
      case KehadiranStatus.terlambat:
        return const Color(0xFFF39C12);
      case KehadiranStatus.izin:
        return const Color(0xFF8E44EC);
      case KehadiranStatus.sakit:
        return const Color(0xFF20C997);
      case KehadiranStatus.alpha:
        return const Color(0xFFE53935);
    }
  }

  static KehadiranStatus? fromApiValue(String? value) {
    switch (value) {
      case 'present':
        return KehadiranStatus.hadir;
      case 'late':
        return KehadiranStatus.terlambat;
      case 'permission':
        return KehadiranStatus.izin;
      case 'sick':
        return KehadiranStatus.sakit;
      case 'absent':
        return KehadiranStatus.alpha;
      default:
        return null;
    }
  }
}

class _Student {
  final int id;
  final String name;
  final String nim;
  KehadiranStatus? status;

  _Student({required this.id, required this.name, required this.nim});

  factory _Student.fromModel(StudentModel model) {
    return _Student(id: model.id, name: model.name, nim: model.nis);
  }
}

class StudentKehadiranPage extends StatefulWidget {
  final int classId;
  final String className;
  final DateTime date;

  const StudentKehadiranPage({
    super.key,
    required this.classId,
    required this.className,
    required this.date,
  });

  @override
  State<StudentKehadiranPage> createState() => _StudentKehadiranPageState();
}

class _StudentKehadiranPageState extends State<StudentKehadiranPage> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color softBlue = Color(0xFFEAF5FF);

  final PresensiService _presensiService = PresensiService();

  List<_Student> _students = const [];
  bool _tandaiHadirSemua = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _presensiService.fetchStudentsByClass(widget.classId),
        _presensiService.fetchClassAttendances(
          classId: widget.classId,
          date: widget.date,
        ),
      ]);
      if (!mounted) return;

      final students = results[0] as List<StudentModel>;
      final attendances = results[1] as List<StudentAttendanceModel>;
      final statusByStudentId = {
        for (final attendance in attendances)
          attendance.studentId: KehadiranStatusX.fromApiValue(
            attendance.status,
          ),
      };
      final studentRows = students.map(_Student.fromModel).toList();
      for (final student in studentRows) {
        student.status = statusByStudentId[student.id];
      }

      setState(() {
        _students = studentRows;
        _tandaiHadirSemua =
            studentRows.isNotEmpty &&
            studentRows.every(
              (student) => student.status == KehadiranStatus.hadir,
            );
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat data siswa.';
        _isLoading = false;
      });
    }
  }

  void _toggleHadirSemua(bool value) {
    setState(() {
      _tandaiHadirSemua = value;
      for (final student in _students) {
        student.status = value ? KehadiranStatus.hadir : null;
      }
    });
  }

  void _setStatus(_Student student, KehadiranStatus? status) {
    setState(() {
      student.status = status;
      _tandaiHadirSemua = _students.every(
        (student) => student.status == KehadiranStatus.hadir,
      );
    });
  }

  int _countStatus(KehadiranStatus status) =>
      _students.where((student) => student.status == status).length;

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleSimpan() async {
    final hasIncompleteStatus = _students.any(
      (student) => student.status == null,
    );
    if (hasIncompleteStatus) {
      _showMessage('Lengkapi status kehadiran semua siswa terlebih dahulu.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _presensiService.saveClassAttendance(
        classId: widget.classId,
        date: widget.date,
        attendances: _students
            .map(
              (student) => StudentAttendanceInput(
                studentId: student.id,
                status: student.status!.apiValue,
              ),
            )
            .toList(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      setState(() => _isSaving = false);
      return;
    } catch (_) {
      if (!mounted) return;
      _showMessage('Tidak bisa menyimpan presensi.');
      setState(() => _isSaving = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSuccessDialog();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: primaryBlue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Presensi Disimpan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data kehadiran siswa berhasil disimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Oke',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ManualHeader(
              className: widget.className,
              dateText: _formatDate(widget.date),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Tandai hadir semua',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.88,
                    child: Checkbox(
                      value: _tandaiHadirSemua,
                      activeColor: primaryBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: _isLoading || _isSaving
                          ? null
                          : (value) => _toggleHadirSemua(value ?? false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _StudentList(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                students: _students,
                isSaving: _isSaving,
                onRetry: _loadStudents,
                onStatusChanged: _setStatus,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Izin: ${_countStatus(KehadiranStatus.izin)}  '
                      'Sakit: ${_countStatus(KehadiranStatus.sakit)}  '
                      'Alpha: ${_countStatus(KehadiranStatus.alpha)}  '
                      'Terlambat: ${_countStatus(KehadiranStatus.terlambat)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading || _isSaving || _students.isEmpty
                        ? null
                        : _handleSimpan,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualHeader extends StatelessWidget {
  final String className;
  final String dateText;

  const _ManualHeader({required this.className, required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-60, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderBackButton(onTap: () => Navigator.pop(context)),
            const SizedBox(height: 18),
            const Text(
              'Presensi Manual',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$className • $dateText',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 24, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              'Kembali',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<_Student> students;
  final bool isSaving;
  final VoidCallback onRetry;
  final void Function(_Student student, KehadiranStatus? status)
  onStatusChanged;

  const _StudentList({
    required this.isLoading,
    required this.errorMessage,
    required this.students,
    required this.isSaving,
    required this.onRetry,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _StudentKehadiranPageState.primaryBlue,
        ),
      );
    }

    if (errorMessage != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (students.isEmpty) {
      return const _MessageState(
        icon: Icons.groups_rounded,
        message: 'Belum ada siswa di kelas ini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: students.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentRow(
          student: student,
          enabled: !isSaving,
          onStatusChanged: (status) => onStatusChanged(student, status),
        );
      },
    );
  }
}

class _StudentRow extends StatelessWidget {
  final _Student student;
  final bool enabled;
  final ValueChanged<KehadiranStatus?> onStatusChanged;

  const _StudentRow({
    required this.student,
    required this.enabled,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EDF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIS: ${student.nim}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 118,
            child: DropdownButtonFormField<KehadiranStatus>(
              key: ValueKey('${student.id}-${student.status?.name ?? 'empty'}'),
              initialValue: student.status,
              hint: const Text('Status', style: TextStyle(fontSize: 12)),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF6FAFD),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _StudentKehadiranPageState.primaryBlue,
                  ),
                ),
              ),
              items: KehadiranStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onStatusChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _StudentKehadiranPageState.primaryBlue, size: 46),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ],
        ),
      ),
    );
  }
}
