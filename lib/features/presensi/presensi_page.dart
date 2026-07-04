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
  static const Color primaryBlue = Color(0xFF3E87D8);

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
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9F2E4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF34B36A),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Presensi Disimpan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
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
                  height: 46,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Oke',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          children: [
            const Text(
              'Student Kehadiran List',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.className} • ${_formatDate(widget.date)}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_students.length} Anggota',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Tandai Hadir Semua',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    Checkbox(
                      value: _tandaiHadirSemua,
                      activeColor: const Color(0xFF34B36A),
                      onChanged: _isLoading || _isSaving
                          ? null
                          : (value) => _toggleHadirSemua(value ?? false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hadir: ${_countStatus(KehadiranStatus.hadir)}  '
                    'Terlambat: ${_countStatus(KehadiranStatus.terlambat)}  '
                    'Izin: ${_countStatus(KehadiranStatus.izin)}\n'
                    'Sakit: ${_countStatus(KehadiranStatus.sakit)}  '
                    'Alpha: ${_countStatus(KehadiranStatus.alpha)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading || _isSaving || _students.isEmpty
                      ? null
                      : _handleSimpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34B36A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada siswa di kelas ini.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: students.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                student.nim,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 145,
          child: DropdownButtonFormField<KehadiranStatus>(
            key: ValueKey('${student.id}-${student.status?.name ?? 'empty'}'),
            initialValue: student.status,
            hint: const Text('Pilih Status'),
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3E87D8)),
              ),
            ),
            items: KehadiranStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
            onChanged: enabled ? onStatusChanged : null,
          ),
        ),
      ],
    );
  }
}
