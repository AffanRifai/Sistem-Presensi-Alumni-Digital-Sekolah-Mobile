import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data/job_vacancy_service.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/error_mapper.dart';

class JobVacancyPage extends StatefulWidget {
  final bool enablePullRefresh;

  const JobVacancyPage({super.key, this.enablePullRefresh = true});

  @override
  State<JobVacancyPage> createState() => _JobVacancyPageState();
}

class _JobVacancyPageState extends State<JobVacancyPage> {
  final _service = JobVacancyService();
  late Future<JobVacancyPageResult> _jobsFuture;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs({int? page}) {
    final requestedPage = page ?? _currentPage;
    setState(() {
      _currentPage = requestedPage;
      _jobsFuture = _service.fetchVacancies(page: requestedPage, perPage: 10);
    });
  }

  Future<void> _refreshJobs() async {
    _loadJobs(page: _currentPage);
    await _jobsFuture;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: Colors.white, // Background flat putih
      // Menghapus AppBar agar judul menyatu dengan konten yang bisa discroll
      body: FutureBuilder<JobVacancyPageResult>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            final message = ErrorMapper.getMessage(
              snapshot.error,
              fallback: 'Tidak bisa memuat lowongan pekerjaan.',
              stackTrace: snapshot.stackTrace,
            );
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFE57373),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadJobs,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final result = snapshot.data!;
          final jobs = result.items;

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Lowongan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saat ini belum ada lowongan kerja yang tersedia.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final content = CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lowongan Kerja',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Temukan peluang karir dan pekerjaan terbaik untukmu.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _JobCard(job: jobs[index]),
                    );
                  }, childCount: jobs.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: _JobPagination(
                    currentPage: result.currentPage,
                    lastPage: result.lastPage,
                    total: result.total,
                    onPageChanged: (page) => _loadJobs(page: page),
                  ),
                ),
              ),
              // Padding ekstra di bawah agar tidak tertutup Bottom Navigation Bar
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );

          if (!widget.enablePullRefresh) {
            return content;
          }

          return RefreshIndicator(
            color: primaryColor,
            displacement: 12,
            onRefresh: _refreshJobs,
            // Menggunakan CustomScrollView agar Header dan List bisa discroll bersamaan
            child: content,
          );
        },
      ),
    );
  }
}

class _JobPagination extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPageChanged;

  const _JobPagination({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPageChanged,
  });

  List<int> get _visiblePages {
    const maxVisiblePages = 3;
    var start = currentPage - 2;
    if (start < 1) start = 1;
    var end = start + maxVisiblePages - 1;
    if (end > lastPage) {
      end = lastPage;
      start = end - maxVisiblePages + 1;
      if (start < 1) start = 1;
    }
    return List.generate(end - start + 1, (index) => start + index);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E88E5);

    return Column(
      children: [
        Text(
          '$total lowongan | Halaman $currentPage dari $lastPage',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              onPressed: currentPage > 1
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Halaman sebelumnya',
            ),
            const SizedBox(width: 6),
            ..._visiblePages.map(
              (page) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: page == currentPage
                      ? FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: primaryColor,
                            disabledForegroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$page'),
                        )
                      : OutlinedButton(
                          onPressed: () => onPageChanged(page),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$page'),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: currentPage < lastPage
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Halaman berikutnya',
            ),
          ],
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobVacancy job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.2,
        ), // Layout flat dengan border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showJobDetail(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Logo + Judul)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child:
                          job.companyLogo != null && job.companyLogo!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                job.companyLogo!.startsWith('http')
                                    ? job.companyLogo!
                                    : '${ApiConfig.storageUrl}/${job.companyLogo}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.business,
                                      color: Colors.grey.shade400,
                                    ),
                              ),
                            )
                          : Icon(Icons.business, color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _JobMetaLine(
                  label: 'Tipe pekerjaan',
                  value: _formatJobType(job.jobType),
                ),
                const SizedBox(height: 6),
                _JobMetaLine(
                  label: 'Kategori',
                  value: _formatCategory(job.category),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),

                // Info footer (Lokasi & Gaji)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey.shade900,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on_outlined,
                                size: 16,
                                color: Colors.grey.shade900,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  job.formattedSalary,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (job.deadline != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Batas Akhir',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy').format(job.deadline!),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJobDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Detail
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child:
                            job.companyLogo != null &&
                                job.companyLogo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  job.companyLogo!.startsWith('http')
                                      ? job.companyLogo!
                                      : '${ApiConfig.storageUrl}/${job.companyLogo}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.business,
                                        color: Colors.grey.shade400,
                                        size: 40,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.business,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _JobDetailInfo(label: 'Lokasi', value: job.location),
                    const SizedBox(height: 12),
                    _JobDetailInfo(label: 'Gaji', value: job.formattedSalary),
                    const SizedBox(height: 12),
                    _JobDetailInfo(
                      label: 'Tipe pekerjaan',
                      value: _formatJobType(job.jobType),
                    ),
                    const SizedBox(height: 12),
                    _JobDetailInfo(
                      label: 'Kategori',
                      value: _formatCategory(job.category),
                    ),
                    const SizedBox(height: 12),
                    _JobDetailInfo(
                      label: 'Batas akhir pendaftaran',
                      value: job.deadline != null
                          ? DateFormat('dd MMM yyyy').format(job.deadline!)
                          : 'Tidak ada',
                      valueColor: job.deadline != null
                          ? Colors.red.shade700
                          : null,
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Deskripsi Pekerjaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description.replaceAll(
                        RegExp(r'<[^>]*>|&[^;]+;'),
                        '',
                      ),
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.grey.shade800,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const SizedBox(height: 24),

                    if (job.requirements != null &&
                        job.requirements!.isNotEmpty) ...[
                      const Text(
                        'Persyaratan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.requirements!.replaceAll(
                          RegExp(r'<[^>]*>|&[^;]+;'),
                          '',
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.grey.shade800,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (job.link != null && job.link!.isNotEmpty) ...[
                      const Text(
                        'Tautan Eksternal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          String linkString = job.link!;
                          if (!linkString.startsWith('http://') &&
                              !linkString.startsWith('https://')) {
                            linkString = 'https://$linkString';
                          }
                          final uri = Uri.tryParse(linkString);
                          if (uri != null) {
                            final launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tidak dapat membuka tautan'),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  job.link!,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatJobType(String type) {
    return switch (type.toLowerCase()) {
      'full_time' => 'Full Time',
      'part_time' => 'Part Time',
      'freelance' => 'Freelance',
      'internship' => 'Magang',
      _ => type,
    };
  }

  String _formatCategory(String category) {
    return switch (category.toLowerCase()) {
      'technology' => 'Teknologi',
      'education' => 'Pendidikan',
      'health' => 'Kesehatan',
      'business' => 'Bisnis',
      'creative' => 'Kreatif',
      'engineering' => 'Teknik',
      'others' => 'Lainnya',
      _ => category,
    };
  }
}

class _JobMetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _JobMetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: '$label : '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _JobDetailInfo({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
