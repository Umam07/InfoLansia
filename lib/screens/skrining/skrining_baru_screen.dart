import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class SkriningBaruScreen extends StatefulWidget {
  final String patientId;
  final String name;
  final String age;
  final String gender;
  final List<DateTime> existingScreenings;

  const SkriningBaruScreen({
    super.key,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    this.existingScreenings = const [],
  });

  @override
  State<SkriningBaruScreen> createState() => _SkriningBaruScreenState();
}

class _SkriningBaruScreenState extends State<SkriningBaruScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Date field
  late DateTime _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  // Controllers for Tanda Vital
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bloodPressureController = TextEditingController();

  // Controllers for Hasil Laboratorium
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _uricAcidController = TextEditingController();
  final TextEditingController _hbController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Automatically set default date to today's date
    _selectedDate = DateTime.now();
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bloodPressureController.dispose();
    _cholesterolController.dispose();
    _bloodSugarController.dispose();
    _uricAcidController.dispose();
    _hbController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _handleSave() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      // Check if patient already has a checkup in the selected month & year
      final hasDuplicate = widget.existingScreenings.any((d) =>
          d.year == _selectedDate.year && d.month == _selectedDate.month);

      if (hasDuplicate) {
        _showDuplicateWarningDialog();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final weight = double.tryParse(_weightController.text);
        final height = double.tryParse(_heightController.text);
        final cholesterol = double.tryParse(_cholesterolController.text);
        final sugar = double.tryParse(_bloodSugarController.text);
        final uricAcid = double.tryParse(_uricAcidController.text);
        final hb = double.tryParse(_hbController.text);

        String status = 'Normal';
        if ((sugar != null && sugar > 140) ||
            (cholesterol != null && cholesterol > 200) ||
            (uricAcid != null && uricAcid > 7.0)) {
          status = 'Perlu Perhatian';
        }

        final bp = _bloodPressureController.text.trim();
        if (bp.isNotEmpty) {
          final parts = bp.split('/');
          if (parts.length == 2) {
            final sys = int.tryParse(parts[0].trim());
            final dia = int.tryParse(parts[1].trim());
            if (sys != null && dia != null) {
              if (sys >= 140 || dia >= 90) {
                status = 'Perlu Perhatian';
              }
            }
          }
        }

        await Supabase.instance.client.from('screenings').insert({
          'patient_id': widget.patientId,
          'date': _selectedDate.toIso8601String().split('T').first,
          'weight': weight,
          'height': height,
          'blood_pressure': bp.isEmpty ? null : bp,
          'cholesterol': cholesterol,
          'blood_sugar': sugar,
          'uric_acid': uricAcid,
          'hemoglobin': hb,
          'status': status,
        });

        setState(() {
          _isLoading = false;
        });

        _showSuccessDialog();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan hasil skrining: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showDuplicateWarningDialog() {
    final monthName = _getMonthName(_selectedDate.month);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Styled Warning Circle (Amber/Orange accent)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.statusWarning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusWarning,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Skrining Sudah Ada',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Pasien ${widget.name} sudah melakukan skrining pada bulan $monthName ${_selectedDate.year}.\n\nSkrining hanya dapat dilakukan 1 kali per bulan sesuai protokol.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  _SpringButton(
                    onTap: () {
                      Navigator.pop(context); // Pop warning dialog
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.statusWarning,
                        borderRadius: BorderRadius.circular(14.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusWarning.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ubah Tanggal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated or styled Success Circle
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Skrining Berhasil!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Data skrining baru untuk ${widget.name} telah berhasil disimpan ke database.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  _SpringButton(
                    onTap: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context, true); // Pop screen back to Detail with "true" result to refresh
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Kembali ke Detail',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBar(context),
      ),
      body: Stack(
        children: [
          // Scrollable Form Content
          Positioned.fill(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 24.0,
                  bottom: 120.0 + MediaQuery.of(context).padding.bottom, // padding to clear bottom bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Header Card
                    _buildPatientProfileCard(),
                    const SizedBox(height: 24.0),

                    // Service Date Section
                    _buildSectionHeader('Tanggal Layanan'),
                    const SizedBox(height: 8.0),
                    _buildServiceDateCard(),
                    const SizedBox(height: 24.0),

                    // Vital Signs Section
                    _buildSectionHeader('Tanda Vital'),
                    const SizedBox(height: 8.0),
                    _buildVitalSignsCard(),
                    const SizedBox(height: 24.0),

                    // Lab Results Section
                    _buildSectionHeader('Hasil Laboratorium'),
                    const SizedBox(height: 8.0),
                    _buildLabResultsCard(),
                    const SizedBox(height: 32.0),

                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),

          // Shared Bottom Navigation Bar (Matching HTML Screenshot)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  // Header App Bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpringButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.primary,
                    size: 24.0,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Skrining Baru',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 40.0), // Spacer for centering
            ],
          ),
        ),
      ),
    );
  }

  // Patient Profile Header Card
  Widget _buildPatientProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.gender == 'Laki-laki' 
                  ? const Color(0x1BBA5855) 
                  : AppColors.secondaryContainer,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: _buildInitialsAvatar(),
            ),
          ),
          const SizedBox(width: 16.0),
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '${widget.age} Tahun • Pemeriksaan Rutin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = widget.name.isNotEmpty
        ? widget.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.gender == 'Laki-laki' 
              ? AppColors.tertiary 
              : AppColors.primary,
        ),
      ),
    );
  }

  // Section Label Heading
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Service Date Selection Card
  Widget _buildServiceDateCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              'Pilih Tanggal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          _SpringButton(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateController.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vital Signs Form Card
  Widget _buildVitalSignsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weight Input
              Expanded(
                child: _buildInputField(
                  label: 'Berat Badan',
                  hint: '0',
                  suffixText: 'kg',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16.0),
              // Height Input
              Expanded(
                child: _buildInputField(
                  label: 'Tinggi Badan',
                  hint: '0',
                  suffixText: 'cm',
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Blood Pressure Input
          _buildInputField(
            label: 'Tekanan Darah',
            hint: '120/80',
            suffixText: 'mmHg',
            controller: _bloodPressureController,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  // Lab Results Form Card
  Widget _buildLabResultsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Cholesterol Input
              Expanded(
                child: _buildInputField(
                  label: 'Kolesterol',
                  hint: '0',
                  suffixText: 'mg/dL',
                  controller: _cholesterolController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16.0),
              // Blood Sugar Input
              Expanded(
                child: _buildInputField(
                  label: 'Gula Darah',
                  hint: '0',
                  suffixText: 'mg/dL',
                  controller: _bloodSugarController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              // Uric Acid Input
              Expanded(
                child: _buildInputField(
                  label: 'Asam Urat',
                  hint: '0',
                  suffixText: 'mg/dL',
                  controller: _uricAcidController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16.0),
              // Hb Input
              Expanded(
                child: _buildInputField(
                  label: 'Hb',
                  hint: '0',
                  suffixText: 'g/dL',
                  controller: _hbController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable text input field builder
  Widget _buildInputField({
    required String label,
    required String hint,
    required String suffixText,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.iconInactive,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.backgroundAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    suffixText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minHeight: 0,
              minWidth: 0,
            ),
          ),
        ),
      ],
    );
  }

  // Save Button Action
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _SpringButton(
        onTap: _isLoading ? () {} : _handleSave,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            color: _isLoading ? AppColors.outlineVariant : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
              : Text(
                  'Simpan Hasil Skrining',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 80.0 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 16.0,
        right: 16.0,
      ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(
                index: 0,
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
              ),
              _buildNavBarItem(
                index: 1,
                icon: Icons.medical_services_outlined,
                label: 'Layanan',
              ),
              _buildNavBarItem(
                index: 2,
                icon: Icons.assignment_turned_in_outlined,
                label: 'Skrining',
              ),
              _buildNavBarItem(
                index: 3,
                icon: Icons.groups_outlined,
                label: 'Pasien',
              ),
              _buildNavBarItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
              ),
            ],
          ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    // Skrining (index 2) is active in this mockup
    final isActive = index == 2;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            // Tapping tab bar pops back to dashboard and sets the respective index
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.iconInactive,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4.0),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.iconInactive,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Spring Button for Premium Tactile Feel
class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SpringButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
