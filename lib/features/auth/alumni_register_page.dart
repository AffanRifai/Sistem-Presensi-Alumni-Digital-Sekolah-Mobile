import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/alumni_register_service.dart';
import 'data/auth_service.dart';
import 'pending_verification_page.dart';
import '../../../core/network/api_exception.dart';

class AlumniRegisterPage extends StatefulWidget {
  const AlumniRegisterPage({super.key});

  @override
  State<AlumniRegisterPage> createState() => _AlumniRegisterPageState();
}

class _AlumniRegisterPageState extends State<AlumniRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AlumniRegisterService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nisnController = TextEditingController();
  final _classController = TextEditingController();
  final _majorController = TextEditingController();

  List<Map<String, dynamic>> _schools = [];
  int? _selectedSchoolId;
  List<String> _availableClasses = [];
  List<String> _availableMajors = [];
  String? _selectedClass;
  String? _selectedMajor;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  bool _isLoadingSchools = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      final schools = await _service.fetchSchools();
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
      });
    } catch (e) {
      setState(() => _isLoadingSchools = false);
      if (mounted) _showMessage('Gagal memuat daftar sekolah: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchoolId == null) {
      _showMessage('Silakan pilih sekolah terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.registerAlumni(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        schoolId: _selectedSchoolId!,
        nisn: _nisnController.text.trim(),
        graduationYear: _selectedYear,
        className: _selectedClass ?? '',
        major: _selectedMajor ?? '',
      );

      if (!mounted) return;
      
      try {
        final authService = AuthService();
        await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingVerificationPage()),
          (route) => false,
        );
      } catch (_) {
        // Fallback jika auto-login gagal
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registrasi Berhasil', style: TextStyle(color: Colors.green)),
            content: const Text('Akun alumni Anda berhasil didaftarkan. Harap tunggu verifikasi dari Admin sekolah sebelum menggunakan aplikasi.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close register page (back to login)
                },
                child: const Text('Tutup'),
              )
            ],
          ),
        );
      }

    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: Color(0xFF3E87D8), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Registrasi Alumni'),
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
                  'Buat Akun Alumni Baru',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi data di bawah ini. Akun Anda perlu diverifikasi oleh admin sebelum dapat digunakan.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Data Diri
                const Text('Data Diri & Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration.copyWith(labelText: 'Nama Lengkap'),
                  validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration.copyWith(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: inputDecoration.copyWith(labelText: 'Nomor HP (WhatsApp)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nomor HP tidak boleh kosong';
                    if (v.length < 9) return 'Nomor HP terlalu pendek (minimal 9 angka)';
                    if (!v.startsWith('0') && !v.startsWith('62')) {
                      return 'Nomor HP harus diawali dengan 0 atau 62';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: inputDecoration.copyWith(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v != null && v.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 24),

                // Data Akademik
                const Text('Data Kelulusan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (_isLoadingSchools)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedSchoolId,
                    decoration: inputDecoration.copyWith(labelText: 'Pilih Sekolah'),
                    items: _schools.map((school) => DropdownMenuItem<int>(
                      value: school['id'] as int,
                      child: Text(
                        school['name'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSchoolId = val;
                        final school = _schools.firstWhere((s) => s['id'] == val);
                        final classes = (school['classes'] as List?) ?? [];
                        
                        _availableClasses = classes
                            .map((c) => c['name']?.toString() ?? '')
                            .where((s) => s.isNotEmpty)
                            .toSet()
                            .toList();
                            
                        _availableMajors = classes
                            .map((c) => c['major']?.toString() ?? '')
                            .where((s) => s.isNotEmpty)
                            .toSet()
                            .toList();
                            
                        _selectedClass = null;
                        _selectedMajor = null;
                      });
                    },
                    validator: (v) => v == null ? 'Pilih sekolah' : null,
                  ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nisnController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: inputDecoration.copyWith(labelText: 'NISN'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'NISN tidak boleh kosong';
                    if (v.length != 10) return 'NISN harus tepat 10 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _selectedYear,
                        decoration: inputDecoration.copyWith(labelText: 'Tahun Lulus'),
                        items: List.generate(40, (index) => DateTime.now().year - index)
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString(), overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedYear = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedClass,
                        decoration: inputDecoration.copyWith(labelText: 'Kelas (Misal: XII-1)'),
                        items: _availableClasses.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            )).toList(),
                        onChanged: (val) => setState(() => _selectedClass = val),
                        validator: (v) => v == null ? 'Pilih kelas' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedMajor,
                        decoration: inputDecoration.copyWith(labelText: 'Jurusan (Misal: IPA)'),
                        items: _availableMajors.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            )).toList(),
                        onChanged: (val) => setState(() => _selectedMajor = val),
                        validator: (v) => v == null ? 'Pilih jurusan' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF3E87D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
