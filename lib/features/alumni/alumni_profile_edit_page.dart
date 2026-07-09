import 'package:flutter/material.dart';
import 'data/alumni_service.dart';
import '../../../core/network/api_exception.dart';

class AlumniProfileEditPage extends StatefulWidget {
  final AlumniProfile currentProfile;

  const AlumniProfileEditPage({super.key, required this.currentProfile});

  @override
  State<AlumniProfileEditPage> createState() => _AlumniProfileEditPageState();
}

class _AlumniProfileEditPageState extends State<AlumniProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AlumniService();

  late String _currentStatus;
  
  final _universityNameController = TextEditingController();
  final _studyProgramController = TextEditingController();
  
  final _companyNameController = TextEditingController();
  final _jobPositionController = TextEditingController();
  
  final _businessNameController = TextEditingController();
  
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _linkedinUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    
    _currentStatus = p.currentStatus ?? 'unemployed';
    
    _universityNameController.text = p.universityName ?? '';
    _studyProgramController.text = p.studyProgram ?? '';
    
    _companyNameController.text = p.companyName ?? '';
    _jobPositionController.text = p.jobPosition ?? '';
    
    _businessNameController.text = p.businessName ?? '';
    
    _cityController.text = p.city ?? '';
    _provinceController.text = p.province ?? '';
    _whatsappController.text = p.whatsapp ?? p.phone ?? '';
    _linkedinUrlController.text = p.linkedinUrl ?? '';
  }

  @override
  void dispose() {
    _universityNameController.dispose();
    _studyProgramController.dispose();
    _companyNameController.dispose();
    _jobPositionController.dispose();
    _businessNameController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _whatsappController.dispose();
    _linkedinUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'current_status': _currentStatus,
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'linkedin_url': _linkedinUrlController.text.trim(),
      };

      if (_currentStatus == 'studying' || _currentStatus == 'studying_working') {
        data['university_name'] = _universityNameController.text.trim();
        data['study_program'] = _studyProgramController.text.trim();
      }
      
      if (_currentStatus == 'working' || _currentStatus == 'studying_working') {
        data['company_name'] = _companyNameController.text.trim();
        data['job_position'] = _jobPositionController.text.trim();
      }
      
      if (_currentStatus == 'entrepreneur') {
        data['business_name'] = _businessNameController.text.trim();
      }

      await _service.updateProfile(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context, true); // true indicates success
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI HELPER WIDGETS ---
  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    const primaryColor = Color(0xFF4A90D9);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A90D9), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  // -------------------------

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A90D9);
    final showStudyingFields = _currentStatus == 'studying' || _currentStatus == 'studying_working';
    final showWorkingFields = _currentStatus == 'working' || _currentStatus == 'studying_working';
    final showBusinessFields = _currentStatus == 'entrepreneur';

    return Scaffold(
      backgroundColor: Colors.white, // Layout flat dan bersih dengan latar belakang putih penuh
      appBar: AppBar(
        title: const Text('Profil Alumni', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header Section ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.manage_accounts_outlined, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Informasi Alumni',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pastikan data aktivitas dan kontak Anda selalu up-to-date agar tetap terhubung dengan sekolah dan sesama alumni.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 24),

                // --- Section: Status & Aktivitas ---
                _buildSectionHeader(title: 'Status & Aktivitas', icon: Icons.work_history_outlined),
                
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _currentStatus,
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                  decoration: _buildInputDecoration(
                    label: 'Status Saat Ini',
                    icon: Icons.info_outline,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'unemployed', child: Text('Belum bekerja')),
                    DropdownMenuItem(value: 'studying', child: Text('Kuliah / Pendidikan Lanjut')),
                    DropdownMenuItem(value: 'working', child: Text('Bekerja')),
                    DropdownMenuItem(value: 'studying_working', child: Text('Kuliah Sambil Bekerja')),
                    DropdownMenuItem(value: 'entrepreneur', child: Text('Wirausaha')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _currentStatus = val);
                    }
                  },
                ),

                // Dynamic Fields: Kuliah
                if (showStudyingFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _universityNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(label: 'Nama Universitas / Kampus', icon: Icons.account_balance_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _studyProgramController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(label: 'Program Studi / Jurusan', icon: Icons.menu_book_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                // Dynamic Fields: Bekerja
                if (showWorkingFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _companyNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(label: 'Nama Perusahaan / Instansi', icon: Icons.business_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _jobPositionController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(label: 'Jabatan / Posisi', icon: Icons.badge_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                // Dynamic Fields: Wirausaha
                if (showBusinessFields) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessNameController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(label: 'Nama Usaha / Bisnis', icon: Icons.storefront_outlined),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                const SizedBox(height: 32),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 24),

                // --- Section: Lokasi & Kontak ---
                _buildSectionHeader(title: 'Lokasi & Kontak', icon: Icons.contact_mail_outlined),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(label: 'Kota/Kab', icon: Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _provinceController,
                        textInputAction: TextInputAction.next,
                        decoration: _buildInputDecoration(label: 'Provinsi', icon: Icons.map_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(label: 'Nomor WhatsApp', icon: Icons.phone_android_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _linkedinUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: _buildInputDecoration(label: 'URL LinkedIn (Opsional)', icon: Icons.link_outlined),
                ),

                const SizedBox(height: 48),

                // --- Submit Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Mengurangi sedikit lengkungan agar senada dengan layout flat
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}