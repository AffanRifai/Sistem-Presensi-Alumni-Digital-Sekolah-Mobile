import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import '../kelas/data/class_recap_models.dart';
import '../kelas/data/class_recap_service.dart';
import 'attendance_recap_page.dart';

class AttendanceRecapSelectClassPage extends StatefulWidget {
  const AttendanceRecapSelectClassPage({super.key});

  @override
  State<AttendanceRecapSelectClassPage> createState() =>
      _AttendanceRecapSelectClassPageState();
}

class _AttendanceRecapSelectClassPageState
    extends State<AttendanceRecapSelectClassPage> {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color borderColor = Color(0xFFE3E8F2);

  final ClassRecapService _classRecapService = ClassRecapService();

  List<ClassRecapModel> _classes = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classes = await _classRecapService.fetchClasses();
      if (!mounted) return;

      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat data kelas.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa memuat data kelas.',
          stackTrace: stackTrace,
        );
        _isLoading = false;
      });
    }
  }

  void _openRecap(ClassRecapModel classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceRecapPage(classData: classData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Kehadiran Siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading ? null : _loadClasses,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih kelas untuk melihat rekap kehadiran.',
                  style: TextStyle(fontSize: 14.5, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _ClassList(
                isLoading: _isLoading,
                errorMessage: _errorMessage,
                classes: _classes,
                onRetry: _loadClasses,
                onSelected: _openRecap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassList extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<ClassRecapModel> classes;
  final VoidCallback onRetry;
  final ValueChanged<ClassRecapModel> onSelected;

  const _ClassList({
    required this.isLoading,
    required this.errorMessage,
    required this.classes,
    required this.onRetry,
    required this.onSelected,
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

    if (classes.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada kelas.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: classes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final classData = classes[index];
        return _ClassCard(
          classData: classData,
          onTap: () => onSelected(classData),
        );
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassRecapModel classData;
  final VoidCallback onTap;

  const _ClassCard({required this.classData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _AttendanceRecapSelectClassPageState.borderColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${classData.studentCount} Siswa',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _AttendanceRecapSelectClassPageState.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
