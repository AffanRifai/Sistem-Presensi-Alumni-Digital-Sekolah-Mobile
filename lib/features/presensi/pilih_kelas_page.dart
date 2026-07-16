import 'package:flutter/material.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import 'data/presensi_models.dart';
import 'data/presensi_service.dart';
import 'data/qr_attendance_service.dart';
import 'presensi_page.dart';
import 'qr_attendance_page.dart';

enum PresensiEntryMode { manual, qr }

class SelectClassDatePage extends StatefulWidget {
  final PresensiEntryMode mode;

  const SelectClassDatePage({super.key, this.mode = PresensiEntryMode.manual});

  @override
  State<SelectClassDatePage> createState() => _SelectClassDatePageState();
}

class _SelectClassDatePageState extends State<SelectClassDatePage> {
  static const Color primaryBlue = Color(0xFF1E88E5);

  final PresensiService _presensiService = PresensiService();
  final QrAttendanceService _qrAttendanceService = QrAttendanceService();

  List<SchoolClassModel> _classes = const [];
  SchoolClassModel? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isOpeningQr = false;
  String? _errorMessage;

  bool get _isQrMode => widget.mode == PresensiEntryMode.qr;

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
      final classes = await _presensiService.fetchClasses();
      if (!mounted) return;

      setState(() {
        _classes = classes;
        _selectedClass = classes.isNotEmpty ? classes.first : null;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleNext() async {
    final selectedClass = _selectedClass;
    if (selectedClass == null) return;

    if (!_isQrMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentKehadiranPage(
            classId: selectedClass.id,
            className: selectedClass.displayName,
            date: _selectedDate,
          ),
        ),
      );
      return;
    }

    setState(() => _isOpeningQr = true);

    try {
      final session = await _qrAttendanceService.openSession(
        classId: selectedClass.id,
        date: _selectedDate,
      );
      final token = await _qrAttendanceService.generateQr(session.id);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrAttendancePage(
            sessionId: session.id,
            className: selectedClass.displayName,
            initialToken: token,
          ),
        ),
      );
    } on ApiException catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa membuka sesi QR.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      if (!mounted) return;
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Tidak bisa membuka sesi QR.',
          stackTrace: stackTrace,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningQr = false);
    }
  }

  String _formatDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isQrMode ? 'Presensi QR' : 'Presensi Siswa';
    final subtitle = _isQrMode
        ? 'Pilih kelas dan tanggal untuk membuka sesi QR.'
        : 'Pilih kelas dan tanggal untuk input presensi manual.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: title, subtitle: subtitle),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      title: 'Pilih Kelas',
                      subtitle: 'Kelas yang tampil mengikuti akses guru.',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _ClassList(
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        classes: _classes,
                        selectedClass: _selectedClass,
                        onRetry: _loadClasses,
                        onSelected: (schoolClass) {
                          setState(() => _selectedClass = schoolClass);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SectionTitle(
                      title: 'Tanggal Presensi',
                      subtitle: 'Tanggal otomatis mengikuti hari ini.',
                    ),
                    const SizedBox(height: 12),
                    _DatePickerCard(
                      dateText: _formatDate(_selectedDate),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            _selectedClass == null || _isLoading || _isOpeningQr
                            ? null
                            : _handleNext,
                        icon: _isOpeningQr
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isQrMode
                                    ? Icons.qr_code_2_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                        label: Text(_isQrMode ? 'Buka Sesi QR' : 'Lanjutkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final offsetX = title == 'Presensi QR' ? -22.0 : -12.0;

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderBackButton(onTap: () => Navigator.pop(context)),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitle,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String dateText;
  final VoidCallback onTap;

  const _DatePickerCard({required this.dateText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color.fromARGB(255, 168, 170, 173)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final SchoolClassModel schoolClass;
  final bool selected;
  final VoidCallback onTap;

  const _ClassTile({
    required this.schoolClass,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.black54 : const Color(0xFFD9E2EC),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    schoolClass.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? Colors.green : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassList extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<SchoolClassModel> classes;
  final SchoolClassModel? selectedClass;
  final VoidCallback onRetry;
  final ValueChanged<SchoolClassModel> onSelected;

  const _ClassList({
    required this.isLoading,
    required this.errorMessage,
    required this.classes,
    required this.selectedClass,
    required this.onRetry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _SelectClassDatePageState.primaryBlue,
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

    if (classes.isEmpty) {
      return const _MessageState(
        icon: Icons.class_outlined,
        message: 'Belum ada kelas.',
      );
    }

    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final schoolClass = classes[index];
        return _ClassTile(
          schoolClass: schoolClass,
          selected: schoolClass.id == selectedClass?.id,
          onTap: () => onSelected(schoolClass),
        );
      },
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
            Icon(icon, color: _SelectClassDatePageState.primaryBlue, size: 46),
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
