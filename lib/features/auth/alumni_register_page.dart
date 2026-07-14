import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/network/api_exception.dart';
import 'data/alumni_register_service.dart';
import 'data/auth_service.dart';
import 'pending_verification_page.dart';
import 'widgets/auth_page_components.dart';

class AlumniRegisterPage extends StatefulWidget {
  const AlumniRegisterPage({super.key});

  @override
  State<AlumniRegisterPage> createState() => _AlumniRegisterPageState();
}

class _AlumniRegisterPageState extends State<AlumniRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AlumniRegisterService();
  final _scrollController = ScrollController();

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
  String? _schoolErrorMessage;
  bool _obscurePassword = true;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nisnController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoadingSchools = true;
      _schoolErrorMessage = null;
    });
    try {
      final schools = await _service.fetchSchools();
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _isLoadingSchools = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
        _schoolErrorMessage = ErrorMapper.getMessage(
          error,
          fallback: 'Daftar sekolah belum dapat dimuat. Silakan coba lagi.',
          stackTrace: stackTrace,
        );
      });
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
      } catch (error, stackTrace) {
        ErrorMapper.getMessage(error, stackTrace: stackTrace);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Registrasi Berhasil'),
            content: const Text(
              'Akun alumni berhasil didaftarkan. Silakan tunggu verifikasi dari admin sekolah.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.maybePop(context);
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (error, stackTrace) {
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Registrasi belum berhasil. Silakan periksa kembali data Anda.',
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      _showMessage(
        ErrorMapper.getMessage(
          error,
          fallback: 'Registrasi belum berhasil. Silakan coba lagi.',
          stackTrace: stackTrace,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 1);
    _scrollToFormTop();
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 0);
    _scrollToFormTop();
  }

  void _scrollToFormTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        245,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: AuthUi.muted, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _fieldBorder(AuthUi.border),
      enabledBorder: _fieldBorder(AuthUi.border),
      focusedBorder: _fieldBorder(AuthUi.primary),
      errorBorder: _fieldBorder(const Color(0xFFD64545)),
      focusedErrorBorder: _fieldBorder(const Color(0xFFD64545)),
    );
  }

  OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }

  void _selectSchool(int? schoolId) {
    if (schoolId == null) return;
    setState(() {
      _selectedSchoolId = schoolId;
      final school = _schools.firstWhere((school) => school['id'] == schoolId);
      final classes = (school['classes'] as List?) ?? [];
      _availableClasses = classes
          .map((item) => (item as Map?)?['name']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      _availableMajors = classes
          .map((item) => (item as Map?)?['major']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      _selectedClass = null;
      _selectedMajor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double headerImageHeight = 310;
    const double scrollableHeaderHeight = 255;
    const double registerButtonWidth = 200;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerImageHeight,
              child: Image.asset(
                'assets/images/home/splash/splashwelcome.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
              ),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.zero,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: scrollableHeaderHeight,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.paddingOf(context).top + 10,
                            left: 12,
                          ),
                          child: TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 19,
                            ),
                            label: const Text('Kembali'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.2,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 38, 24, 0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(34),
                          topRight: Radius.circular(34),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Daftar Alumni',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: AuthUi.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lengkapi data berikut untuk mengajukan akun alumni.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AuthUi.muted),
                          ),
                          const SizedBox(height: 30),
                          if (_currentStep == 0) ...[
                            const _SectionTitle(title: 'Data Akun'),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                label: 'Nama Lengkap',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Nama tidak boleh kosong.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(label: 'Email'),
                              validator: (value) =>
                                  value == null || !value.contains('@')
                                  ? 'Email tidak valid.'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                              decoration: _inputDecoration(
                                label: 'Nomor HP/WhatsApp',
                              ),
                              validator: (value) {
                                final phone = value ?? '';
                                if (phone.isEmpty) {
                                  return 'Nomor HP tidak boleh kosong.';
                                }
                                if (phone.length < 9) {
                                  return 'Nomor HP minimal 9 angka.';
                                }
                                if (!phone.startsWith('0') &&
                                    !phone.startsWith('62')) {
                                  return 'Nomor HP harus diawali 0 atau 62.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                label: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AuthUi.muted,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value != null && value.length >= 6
                                  ? null
                                  : 'Password minimal 6 karakter.',
                            ),
                          ] else ...[
                            const _SectionTitle(title: 'Data Kelulusan'),
                            const SizedBox(height: 16),
                            if (_isLoadingSchools)
                              const SizedBox(
                                height: 54,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_schoolErrorMessage != null)
                              _SchoolLoadError(
                                message: _schoolErrorMessage!,
                                onRetry: _loadSchools,
                              )
                            else
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _selectedSchoolId,
                                decoration: _inputDecoration(label: 'Sekolah'),
                                items: _schools
                                    .map(
                                      (school) => DropdownMenuItem<int>(
                                        value: school['id'] as int,
                                        child: Text(
                                          school['name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _selectSchool,
                                validator: (value) =>
                                    value == null ? 'Pilih sekolah.' : null,
                              ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nisnController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _inputDecoration(label: 'NISN'),
                              validator: (value) {
                                final nisn = value ?? '';
                                if (nisn.isEmpty) {
                                  return 'NISN tidak boleh kosong.';
                                }
                                if (nisn.length != 10) {
                                  return 'NISN harus 10 digit.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: _selectedYear,
                              decoration: _inputDecoration(
                                label: 'Tahun Lulus',
                              ),
                              items:
                                  List.generate(
                                        40,
                                        (index) => DateTime.now().year - index,
                                      )
                                      .map(
                                        (year) => DropdownMenuItem<int>(
                                          value: year,
                                          child: Text(year.toString()),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedYear = value);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedClass,
                              decoration: _inputDecoration(label: 'Kelas'),
                              items: _availableClasses
                                  .map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedClass = value),
                              validator: (value) =>
                                  value == null ? 'Pilih kelas.' : null,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedMajor,
                              decoration: _inputDecoration(label: 'Jurusan'),
                              items: _availableMajors
                                  .map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedMajor = value),
                              validator: (value) =>
                                  value == null ? 'Pilih jurusan.' : null,
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (_currentStep == 0)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: SizedBox(
                                  width: registerButtonWidth,
                                  child: AuthPrimaryButton(
                                    label: 'Lanjutkan',
                                    onPressed: _nextStep,
                                  ),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _previousStep,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AuthUi.primary,
                                        side: const BorderSide(
                                          color: AuthUi.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Kembali'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: AuthPrimaryButton(
                                      label: 'Daftar Alumni',
                                      onPressed: _submit,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AuthUi.text,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: AuthUi.border)),
      ],
    );
  }
}

class _SchoolLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SchoolLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: AuthUi.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AuthUi.muted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
