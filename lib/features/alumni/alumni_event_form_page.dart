import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'data/alumni_event_service.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/error_mapper.dart';

class AlumniEventFormPage extends StatefulWidget {
  final AlumniEvent? eventToEdit;

  const AlumniEventFormPage({super.key, this.eventToEdit});

  @override
  State<AlumniEventFormPage> createState() => _AlumniEventFormPageState();
}

class _AlumniEventFormPageState extends State<AlumniEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;
  bool _isLoading = false;

  final _service = AlumniEventService();

  bool get _isEditMode => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form jika dalam mode edit
    if (_isEditMode) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _selectedDate = event.startDate;
      _selectedTime = TimeOfDay.fromDateTime(event.startDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMapper.getMessage(
              error,
              fallback: 'Gambar belum dapat dipilih. Silakan coba lagi.',
              stackTrace: stackTrace,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih tanggal dan waktu event')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (_isEditMode) {
        await _service.updateEvent(
          id: widget.eventToEdit!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          eventDate: eventDate,
          bannerImagePath: _selectedImage?.path,
        );
      } else {
        await _service.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          eventDate: eventDate,
          bannerImagePath: _selectedImage?.path,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode 
                  ? 'Event berhasil diperbarui.' 
                  : 'Event berhasil diajukan dan menunggu persetujuan admin.'
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorMapper.getMessage(
                error,
                fallback: 'Event belum dapat disimpan. Silakan coba lagi.',
                stackTrace: stackTrace,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI HELPER WIDGETS ---
  InputDecoration _buildInputDecoration({required String label, required String hint, required IconData icon}) {
    const primaryColor = Color(0xFF1E88E5);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
  // -------------------------

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: Colors.white, // Background flat putih
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Event' : 'Ajukan Event', 
          style: const TextStyle(fontWeight: FontWeight.w500)
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header Text ---
                    Text(
                      _isEditMode ? 'Perbarui Informasi' : 'Informasi Event',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditMode
                          ? 'Silakan ubah detail event di bawah ini sesuai kebutuhan.'
                          : 'Lengkapi formulir berikut. Event yang Anda ajukan akan direview oleh Admin sebelum dipublikasikan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 24),

                    // --- Banner Image Picker ---
                    Text(
                      'Banner / Poster Event',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : (_isEditMode && widget.eventToEdit?.bannerImage != null)
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.eventToEdit!.bannerImage!.startsWith('http')
                                            ? widget.eventToEdit!.bannerImage!
                                            : '${ApiConfig.storageUrl}/${widget.eventToEdit!.bannerImage}',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _selectedImage == null && 
                               (!_isEditMode || widget.eventToEdit?.bannerImage == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: primaryColor.withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Pilih Banner (Opsional)',
                                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Format: JPG, PNG (Rekomendasi 16:9)',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Form Inputs ---
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        label: 'Judul Event',
                        hint: 'Contoh: Reuni Akbar Angkatan 2020',
                        icon: Icons.event_note_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationController,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        label: 'Lokasi',
                        hint: 'Contoh: Aula Utama, atau Link Zoom',
                        icon: Icons.location_on_outlined,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Lokasi tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- Date & Time Row (DIPERBAIKI AGAR SEIMBANG) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true, // Tidak bisa diketik manual
                            onTap: _pickDate, // Klik untuk membuka kalender
                            controller: TextEditingController(
                              text: _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : '',
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Tanggal',
                              hint: 'Pilih Tanggal',
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            readOnly: true, // Tidak bisa diketik manual
                            onTap: _pickTime, // Klik untuk membuka jam
                            controller: TextEditingController(
                              text: _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : '',
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Waktu',
                              hint: 'Pilih Waktu',
                              icon: Icons.access_time_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.done,
                      maxLines: 5,
                      decoration: _buildInputDecoration(
                        label: 'Deskripsi Event',
                        hint: 'Ceritakan detail rangkaian acara, pembicara, atau info penting lainnya...',
                        icon: Icons.description_outlined,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (v) => v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 40),

                    // --- Submit Button ---
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isEditMode ? 'Simpan Perubahan' : 'Ajukan Event',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
