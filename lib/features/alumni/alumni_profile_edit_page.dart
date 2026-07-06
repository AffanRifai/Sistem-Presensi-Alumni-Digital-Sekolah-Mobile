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

  @override
  Widget build(BuildContext context) {
    final showStudyingFields = _currentStatus == 'studying' || _currentStatus == 'studying_working';
    final showWorkingFields = _currentStatus == 'working' || _currentStatus == 'studying_working';
    final showBusinessFields = _currentStatus == 'entrepreneur';

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Status Saat Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _currentStatus,
                  decoration: inputDecoration,
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
                
                if (showStudyingFields) ...[
                  const SizedBox(height: 24),
                  const Text('Pendidikan Lanjut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _universityNameController,
                    decoration: inputDecoration.copyWith(labelText: 'Nama Universitas / Kampus'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _studyProgramController,
                    decoration: inputDecoration.copyWith(labelText: 'Program Studi / Jurusan'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                if (showWorkingFields) ...[
                  const SizedBox(height: 24),
                  const Text('Pekerjaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: inputDecoration.copyWith(labelText: 'Nama Perusahaan / Instansi'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jobPositionController,
                    decoration: inputDecoration.copyWith(labelText: 'Jabatan / Posisi'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                if (showBusinessFields) ...[
                  const SizedBox(height: 24),
                  const Text('Usaha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: inputDecoration.copyWith(labelText: 'Nama Usaha / Bisnis'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                ],

                const SizedBox(height: 24),
                const Text('Lokasi & Kontak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: inputDecoration.copyWith(labelText: 'Kota/Kabupaten'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _provinceController,
                        decoration: inputDecoration.copyWith(labelText: 'Provinsi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration.copyWith(labelText: 'Nomor WhatsApp'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkedinUrlController,
                  keyboardType: TextInputType.url,
                  decoration: inputDecoration.copyWith(labelText: 'URL LinkedIn (Opsional)'),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4A90D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
