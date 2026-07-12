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
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
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
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  // --- UI HELPER WIDGETS ---

  InputDecoration _buildInputDecoration({required String label, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF3E87D8).withOpacity(0.7)),
      suffixIcon: suffixIcon,
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
        borderSide: const BorderSide(color: Color(0xFF3E87D8), width: 2),
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E87D8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3E87D8), size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // --- BAGIAN HEADER YANG BARU ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E87D8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3E87D8).withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, color: Color(0xFF3E87D8), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Portal Alumni',
                          style: TextStyle(
                            color: Color(0xFF3E87D8), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pendaftaran Alumni',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.w800, 
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Silakan lengkapi data diri Anda. Akun yang didaftarkan akan melalui proses verifikasi oleh Admin sebelum dapat digunakan.',
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.blue.shade900, 
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // --------------------------------

                // Data Diri Section
                _buildSectionCard(
                  title: 'Data Diri & Akun',
                  icon: Icons.person_outline,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(label: 'Nama Lengkap', icon: Icons.badge_outlined),
                      validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(label: 'Email', icon: Icons.email_outlined),
                      validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: _buildInputDecoration(label: 'Nomor HP (WhatsApp)', icon: Icons.phone_android_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nomor HP tidak boleh kosong';
                        if (v.length < 9) return 'Nomor HP terlalu pendek (minimal 9 angka)';
                        if (!v.startsWith('0') && !v.startsWith('62')) {
                          return 'Nomor HP harus diawali dengan 0 atau 62';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: _buildInputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => v != null && v.length < 6 ? 'Password minimal 6 karakter' : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data Akademik Section
                _buildSectionCard(
                  title: 'Data Kelulusan',
                  icon: Icons.school_outlined,
                  children: [
                    if (_isLoadingSchools)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _selectedSchoolId,
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                        decoration: _buildInputDecoration(label: 'Pilih Sekolah', icon: Icons.account_balance_outlined),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nisnController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _buildInputDecoration(label: 'NISN', icon: Icons.pin_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'NISN tidak boleh kosong';
                        if (v.length != 10) return 'NISN harus tepat 10 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _selectedYear,
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                      decoration: _buildInputDecoration(label: 'Tahun Lulus', icon: Icons.calendar_today_outlined),
                      items: List.generate(40, (index) => DateTime.now().year - index)
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString(), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedClass,
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                            decoration: _buildInputDecoration(label: 'Kelas', icon: Icons.meeting_room_outlined),
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
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey),
                            decoration: _buildInputDecoration(label: 'Jurusan', icon: Icons.book_outlined),
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
                  ],
                ),

                const SizedBox(height: 36),

                // Submit Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3E87D8).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF3E87D8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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