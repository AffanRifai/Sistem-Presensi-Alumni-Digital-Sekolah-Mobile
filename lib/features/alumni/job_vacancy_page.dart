import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'data/job_vacancy_service.dart';

class JobVacancyPage extends StatefulWidget {
  const JobVacancyPage({super.key});

  @override
  State<JobVacancyPage> createState() => _JobVacancyPageState();
}

class _JobVacancyPageState extends State<JobVacancyPage> {
  final _service = JobVacancyService();
  late Future<List<JobVacancy>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _service.fetchVacancies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Lowongan Kerja',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<JobVacancy>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Gagal memuat lowongan: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadJobs,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada lowongan kerja.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadJobs(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _JobCard(job: jobs[index]),
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobVacancy job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getJobTypeColor(job.jobType);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: job.companyLogo != null && job.companyLogo!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                job.companyLogo!.startsWith('http')
                                    ? job.companyLogo!
                                    : 'http://192.168.100.12:8000/storage/${job.companyLogo}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.business, color: Colors.grey.shade400),
                              ),
                            )
                          : Icon(Icons.business, color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
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
                
                // Info badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      text: _formatJobType(job.jobType),
                      color: typeColor,
                      icon: Icons.work_outline,
                    ),
                    _Badge(
                      text: _formatCategory(job.category),
                      color: Colors.purple,
                      icon: Icons.category_outlined,
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
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
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.formattedSalary,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Batas Akhir',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(job.deadline!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header Detail
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: job.companyLogo != null && job.companyLogo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  job.companyLogo!.startsWith('http')
                                      ? job.companyLogo!
                                      : 'http://192.168.100.12:8000/storage/${job.companyLogo}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.business, color: Colors.grey.shade400, size: 40),
                                ),
                              )
                            : Icon(Icons.business, color: Colors.grey.shade400, size: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      job.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.companyName,
                      style: TextStyle(fontSize: 16, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Quick Info Grid
                    Row(
                      children: [
                        Expanded(child: _InfoBox(icon: Icons.location_on, label: 'Lokasi', value: job.location, color: Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoBox(icon: Icons.monetization_on, label: 'Gaji', value: job.formattedSalary, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoBox(icon: Icons.work, label: 'Tipe', value: _formatJobType(job.jobType), color: Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _InfoBox(icon: Icons.calendar_today, label: 'Batas', value: job.deadline != null ? DateFormat('dd MMM yyyy').format(job.deadline!) : 'Tidak ada', color: Colors.red)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text('Deskripsi Pekerjaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      job.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (job.requirements != null && job.requirements!.isNotEmpty) ...[
                      const Text('Persyaratan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        job.requirements!.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
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

  Color _getJobTypeColor(String type) {
    return switch(type.toLowerCase()) {
      'full_time' => Colors.blue,
      'part_time' => Colors.orange,
      'freelance' => Colors.teal,
      'internship' => Colors.indigo,
      _ => Colors.grey,
    };
  }

  String _formatJobType(String type) {
    return switch(type.toLowerCase()) {
      'full_time' => 'Full Time',
      'part_time' => 'Part Time',
      'freelance' => 'Freelance',
      'internship' => 'Magang',
      _ => type,
    };
  }
  
  String _formatCategory(String category) {
    return switch(category.toLowerCase()) {
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Badge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  const _InfoBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color.shade700),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: color.shade700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
