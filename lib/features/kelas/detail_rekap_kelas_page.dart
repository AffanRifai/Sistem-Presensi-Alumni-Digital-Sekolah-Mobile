import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import 'data/class_recap_models.dart';
import 'data/class_recap_service.dart';

class ClassRecapDetailPage extends StatefulWidget {
  final ClassRecapModel classData;

  const ClassRecapDetailPage({super.key, required this.classData});

  @override
  State<ClassRecapDetailPage> createState() => _ClassRecapDetailPageState();
}

class _ClassRecapDetailPageState extends State<ClassRecapDetailPage> {
  static const Color primaryBlue = Color(0xFF4A90D9);
  static const Color lightBlue = Color(0xFFBFE0F5);

  final ClassRecapService _classRecapService = ClassRecapService();

  List<StudentRecapModel> _students = const [];
  bool _isLoading = true;
  String? _errorMessage;

  ClassRecapModel get classData => widget.classData;

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
      final students = await _classRecapService.fetchStudents(classData.id);
      if (!mounted) return;

      setState(() {
        _students = students;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue, lightBlue],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Detail Rekap Kelas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _isLoading ? null : _loadStudents,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Data Kelas',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Nama Kelas', value: classData.name),
                        _InfoRow(label: 'Tingkat', value: classData.grade),
                        _InfoRow(label: 'Jurusan', value: classData.major),
                        _InfoRow(
                          label: 'Wali Kelas',
                          value: classData.homeroomTeacherName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data Siswa di Kelas (${_students.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StudentContent(
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    students: _students,
                    onRetry: _loadStudents,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ==========================================================
// Widget pendukung
// ==========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const Text(':  ', style: TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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

class _StudentContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<StudentRecapModel> students;
  final VoidCallback onRetry;

  const _StudentContent({
    required this.isLoading,
    required this.errorMessage,
    required this.students,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
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
      );
    }

    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Belum ada siswa di kelas ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return _StudentTable(students: students);
  }
}

class _StudentTable extends StatelessWidget {
  final List<StudentRecapModel> students;

  const _StudentTable({required this.students});

  static const Color headerBg = Color(0xFFE8F1FC);
  static const Color borderColor = Color(0xFFE1E7EF);
  static const Color activeBg = Color(0xFFD9F2E4);
  static const Color inactiveBg = Color(0xFFF5D9D9);
  static const Color activeText = Color(0xFF2E9E5B);
  static const Color inactiveText = Color(0xFFC94A4A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(headerBg),
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          dataTextStyle: const TextStyle(fontSize: 12, color: Colors.black87),
          columnSpacing: 18,
          horizontalMargin: 14,
          columns: const [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Nama Siswa')),
            DataColumn(label: Text('NIS')),
            DataColumn(label: Text('NISN')),
            DataColumn(label: Text('JK')),
            DataColumn(label: Text('Tanggal Lahir')),
            DataColumn(label: Text('Orang Tua')),
            DataColumn(label: Text('No WA Ortu')),
            DataColumn(label: Text('Status')),
          ],
          rows: List.generate(students.length, (index) {
            final student = students[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      student.fullName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(student.nis)),
                DataCell(Text(student.nisn)),
                DataCell(Text(student.gender)),
                DataCell(Text(student.birthDate)),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Text(
                      student.parentName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(student.parentPhone)),
                DataCell(_StatusBadge(isActive: student.isActive)),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? _StudentTable.activeBg : _StudentTable.inactiveBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive
              ? _StudentTable.activeText
              : _StudentTable.inactiveText,
        ),
      ),
    );
  }
}
