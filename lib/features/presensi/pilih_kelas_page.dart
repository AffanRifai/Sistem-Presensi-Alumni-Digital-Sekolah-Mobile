import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import 'data/presensi_models.dart';
import 'data/presensi_service.dart';
import 'pilih_metode_presensi_page.dart';

class SelectClassDatePage extends StatefulWidget {
  const SelectClassDatePage({super.key});

  @override
  State<SelectClassDatePage> createState() => _SelectClassDatePageState();
}

class _SelectClassDatePageState extends State<SelectClassDatePage> {
  final PresensiService _presensiService = PresensiService();

  List<SchoolClassModel> _classes = const [];
  SchoolClassModel? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  static const Color primaryBlue = Color(0xFF3E87D8);

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
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tidak bisa memuat data kelas.';
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

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$day, $month ${dt.day}, ${dt.year}';
  }

  void _handleNext() {
    if (_selectedClass == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceMethodPage(
          classId: _selectedClass!.id,
          className: _selectedClass!.displayName,
          date: _selectedDate,
        ),
      ),
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
        title: const Text(
          'Select Class and Date',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black87,
            ),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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

            const SizedBox(height: 8),
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Field tanggal
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            // Tombol Next
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedClass == null ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClassTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color primaryBlue = Color(0xFF3E87D8);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F1FC) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primaryBlue : const Color(0xFFD9E2EC),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
              Icon(Icons.chevron_right, color: primaryBlue),
            ],
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
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

    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final schoolClass = classes[index];
        return _ClassTile(
          label: schoolClass.displayName,
          selected: schoolClass.id == selectedClass?.id,
          onTap: () => onSelected(schoolClass),
        );
      },
    );
  }
}
