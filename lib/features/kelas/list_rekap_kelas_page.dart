import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'data/class_recap_models.dart';
import 'data/class_recap_service.dart';
import 'detail_rekap_kelas_page.dart';
import 'kelas_theme.dart';

class ClassRecapListPage extends StatefulWidget {
  const ClassRecapListPage({super.key});

  @override
  State<ClassRecapListPage> createState() => _ClassRecapListPageState();
}

class _ClassRecapListPageState extends State<ClassRecapListPage> {
  final ClassRecapService _classRecapService = ClassRecapService();
  final TextEditingController _searchController = TextEditingController();

  List<ClassRecapModel> _classes = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedJurusan = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openDetail(ClassRecapModel classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassRecapDetailPage(classData: classData),
      ),
    );
  }

  int get _totalStudents =>
      _classes.fold<int>(0, (sum, c) => sum + c.studentCount);

  List<String> get _jurusanOptions {
    final set = <String>{'Semua'};
    for (final c in _classes) {
      if (c.major.trim().isNotEmpty) set.add(c.major);
    }
    return set.toList();
  }

  List<ClassRecapModel> get _filteredClasses {
    final query = _searchController.text.trim().toLowerCase();
    return _classes.where((c) {
      final matchesQuery =
          query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.major.toLowerCase().contains(query) ||
          c.homeroomTeacherName.toLowerCase().contains(query);
      final matchesJurusan =
          _selectedJurusan == 'Semua' || c.major == _selectedJurusan;
      return matchesQuery && matchesJurusan;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredClasses;
    final showFilters =
        !_isLoading && _errorMessage == null && _classes.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(
            isLoading: _isLoading,
            totalClasses: _classes.length,
            totalStudents: _totalStudents,
            onRefresh: _loadClasses,
          ),
          if (showFilters) ...[
            const SizedBox(height: 14),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: RecapSearchField(
            //     controller: _searchController,
            //     hintText: 'Cari nama kelas, atau jurusan',
            //   ),
            // ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _jurusanOptions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _jurusanOptions[index];
                  return RecapFilterPill(
                    label: label,
                    selected: label == _selectedJurusan,
                    onTap: () => setState(() => _selectedJurusan = label),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const _ClassListSkeleton()
                : _errorMessage != null
                ? RecapErrorState(
                    message: _errorMessage!,
                    onRetry: _loadClasses,
                  )
                : filtered.isEmpty
                ? RecapEmptyState(
                    icon: _classes.isEmpty
                        ? Icons.school_outlined
                        : Icons.search_off_rounded,
                    title: _classes.isEmpty
                        ? 'Belum ada kelas'
                        : 'Kelas tidak ditemukan',
                    subtitle: _classes.isEmpty
                        ? 'Data kelas akan muncul di sini setelah admin menambahkannya.'
                        : 'Coba ubah kata kunci pencarian atau filter jurusan.',
                  )
                : RefreshIndicator(
                    color: KelasPalette.primary,
                    onRefresh: _loadClasses,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final classData = filtered[index];
                        return _ClassCard(
                          classData: classData,
                          onTap: () => _openDetail(classData),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// Header
// ==========================================================

class _Header extends StatelessWidget {
  final bool isLoading;
  final int totalClasses;
  final int totalStudents;
  final VoidCallback onRefresh;

  const _Header({
    required this.isLoading,
    required this.totalClasses,
    required this.totalStudents,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Kelas Anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Pilih kelas untuk melihat detail lengkap.',
                style: TextStyle(fontSize: 14, color: KelasPalette.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// Skeleton loading
// ==========================================================

class _ClassListSkeleton extends StatelessWidget {
  const _ClassListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KelasPalette.border),
        ),
        child: Row(
          children: [
            const ShimmerBox(
              height: 52,
              width: 52,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 14, width: 140),
                  SizedBox(height: 8),
                  ShimmerBox(height: 11, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// Kartu kelas
// ==========================================================

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
          border: Border.all(color: KelasPalette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: KelasPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classData.grade} ${classData.major}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: KelasPalette.slate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wali kelas: ${classData.homeroomTeacherName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: KelasPalette.slate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${classData.studentCount} siswa',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: KelasPalette.ink,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: KelasPalette.slateMuted,
            ),
          ],
        ),
      ),
    );
  }
}
