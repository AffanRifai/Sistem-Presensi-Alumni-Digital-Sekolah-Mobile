import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import 'data/class_recap_models.dart';
import 'data/class_recap_service.dart';
import 'kelas_theme.dart';

class ClassRecapDetailPage extends StatefulWidget {
  final ClassRecapModel classData;

  const ClassRecapDetailPage({super.key, required this.classData});

  @override
  State<ClassRecapDetailPage> createState() => _ClassRecapDetailPageState();
}

class _ClassRecapDetailPageState extends State<ClassRecapDetailPage> {
  final ClassRecapService _classRecapService = ClassRecapService();
  final TextEditingController _searchController = TextEditingController();

  List<StudentRecapModel> _students = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'Semua';

  ClassRecapModel get classData => widget.classData;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat data siswa.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat data siswa.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    }
  }

  List<StudentRecapModel> get _visibleStudents {
    final query = _searchController.text.trim().toLowerCase();

    Iterable<StudentRecapModel> list = _students;
    if (query.isNotEmpty) {
      list = list.where(
        (s) =>
            s.fullName.toLowerCase().contains(query) ||
            s.nis.toLowerCase().contains(query) ||
            s.nisn.toLowerCase().contains(query),
      );
    }

    if (_statusFilter == 'Aktif') {
      list = list.where((s) => s.isActive);
    } else if (_statusFilter == 'Nonaktif') {
      list = list.where((s) => !s.isActive);
    }

    final sorted = list.toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final visibleStudents = _visibleStudents;
    final showFilters =
        !_isLoading && _errorMessage == null && _students.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(isLoading: _isLoading, onRefresh: _loadStudents),
            Expanded(
              child: RefreshIndicator(
                color: KelasPalette.primary,
                onRefresh: _loadStudents,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _ClassInfo(
                      classData: classData,
                      totalStudents: _students.length,
                    ),
                    const SizedBox(height: 12),
                    if (showFilters) ...[
                      const SizedBox(height: 12),
                      RecapSearchField(
                        controller: _searchController,
                        hintText: 'Cari nama, NIS, atau NISN',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          RecapFilterPill(
                            label: 'Semua',
                            selected: _statusFilter == 'Semua',
                            onTap: () =>
                                setState(() => _statusFilter = 'Semua'),
                          ),
                          const SizedBox(width: 8),
                          RecapFilterPill(
                            label: 'Aktif',
                            selected: _statusFilter == 'Aktif',
                            onTap: () =>
                                setState(() => _statusFilter = 'Aktif'),
                          ),
                          const SizedBox(width: 8),
                          RecapFilterPill(
                            label: 'Nonaktif',
                            selected: _statusFilter == 'Nonaktif',
                            onTap: () =>
                                setState(() => _statusFilter = 'Nonaktif'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _StudentContent(
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      students: visibleStudents,
                      hasAnyStudents: _students.isNotEmpty,
                      onRetry: _loadStudents,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const _Header({required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Detail Kelas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: KelasPalette.ink,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _ClassInfo extends StatelessWidget {
  final ClassRecapModel classData;
  final int totalStudents;

  const _ClassInfo({required this.classData, required this.totalStudents});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KelasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Informasi Kelas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KelasPalette.ink,
              ),
            ),
          ),
          const Divider(height: 1, color: KelasPalette.border),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoValue(label: 'Nama Kelas', value: classData.name),
                _InfoValue(label: 'Program Studi', value: classData.major),
                _InfoValue(label: 'Tingkat', value: classData.grade),
                _InfoValue(
                  label: 'Wali Kelas',
                  value: classData.homeroomTeacherName,
                ),
                _InfoValue(
                  label: 'Jumlah Siswa',
                  value: '$totalStudents Siswa',
                  bottomSpacing: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoValue extends StatelessWidget {
  final String label;
  final String value;
  final double bottomSpacing;

  const _InfoValue({
    required this.label,
    required this.value,
    this.bottomSpacing = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLabel(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: KelasPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String text;

  const _InfoLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w400,
        color: KelasPalette.slate,
      ),
    );
  }
}

class _StudentContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<StudentRecapModel> students;
  final bool hasAnyStudents;
  final VoidCallback onRetry;

  const _StudentContent({
    required this.isLoading,
    required this.errorMessage,
    required this.students,
    required this.hasAnyStudents,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: KelasPalette.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return RecapErrorState(message: errorMessage!, onRetry: onRetry);
    }

    if (students.isEmpty) {
      return RecapEmptyState(
        icon: hasAnyStudents ? Icons.search_off_rounded : Icons.groups_outlined,
        title: hasAnyStudents ? 'Siswa tidak ditemukan' : 'Belum ada siswa',
        subtitle: hasAnyStudents
            ? 'Coba ubah kata kunci pencarian atau filter status.'
            : 'Data siswa akan muncul di sini setelah ditambahkan.',
      );
    }

    return _StudentTable(students: students);
  }
}

class _StudentTable extends StatelessWidget {
  final List<StudentRecapModel> students;

  const _StudentTable({required this.students});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KelasPalette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(KelasPalette.surface),
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: KelasPalette.ink,
          ),
          dataTextStyle: const TextStyle(fontSize: 12, color: KelasPalette.ink),
          dividerThickness: 0.5,
          columnSpacing: 18,
          horizontalMargin: 14,
          columns: const [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Nama Siswa')),
            DataColumn(label: Text('NIS')),
            DataColumn(label: Text('NISN')),
            DataColumn(label: Text('JK')),
            DataColumn(label: Text('Tgl Lahir')),
            DataColumn(label: Text('Orang Tua')),
            DataColumn(label: Text('No WA Ortu')),
            DataColumn(label: Text('Status')),
          ],
          rows: List.generate(students.length, (index) {
            final student = students[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(_SizedText(student.fullName, width: 150)),
                DataCell(Text(student.nis)),
                DataCell(Text(student.nisn)),
                DataCell(Text(student.gender)),
                DataCell(Text(student.birthDate)),
                DataCell(_SizedText(student.parentName, width: 130)),
                DataCell(Text(student.parentPhone)),
                DataCell(Text(student.isActive ? 'Aktif' : 'Nonaktif')),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SizedText extends StatelessWidget {
  final String value;
  final double width;

  const _SizedText(this.value, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }
}
