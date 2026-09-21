import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;

import '../../theme.dart';
import '../../widgets/medical_disclaimer_card.dart';
import '../../constants/medical_guidelines.dart';
import '../../database/app_database.dart';
import '../../services/sync_service.dart';
import '../../utils/uuid_generator.dart';

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

  // Blood pressure split into 2 numeric fields (Sistolik & Diastolik)
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final FocusNode _systolicFocusNode = FocusNode();
  final FocusNode _diastolicFocusNode = FocusNode();

  // Controllers for Hasil Laboratorium (Hb removed)
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _uricAcidController = TextEditingController();

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
    _systolicController.dispose();
    _diastolicController.dispose();
    _systolicFocusNode.dispose();
    _diastolicFocusNode.dispose();
    _cholesterolController.dispose();
    _bloodSugarController.dispose();
    _uricAcidController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const List<String> months = [
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
        final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
        final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
        final cholesterol = double.tryParse(_cholesterolController.text.trim().replaceAll(',', '.'));
        final sugar = double.tryParse(_bloodSugarController.text.trim().replaceAll(',', '.'));
        final uricAcid = double.tryParse(_uricAcidController.text.trim().replaceAll(',', '.'));

        final sysStr = _systolicController.text.trim();
        final diaStr = _diastolicController.text.trim();
        String? bp;
        int? sys;
        int? dia;
        if (sysStr.isNotEmpty && diaStr.isNotEmpty) {
          bp = '$sysStr/$diaStr';
          sys = int.tryParse(sysStr);
          dia = int.tryParse(diaStr);
        } else if (sysStr.isNotEmpty) {
          bp = sysStr;
        }

        final overall = MedicalGuidelines.evaluateOverallScreening(
          systolic: sys,
          diastolic: dia,
          cholesterol: cholesterol?.round(),
          sugar: sugar?.round(),
          uricAcid: uricAcid,
          gender: widget.gender,
        );
        final status = overall.statusType == HealthStatusType.normal ? 'Normal' : 'Perlu Perhatian';
        final newId = UuidGenerator.generate();
        final now = DateTime.now();
        final dateStr = _selectedDate.toIso8601String().split('T').first;

        // 1. Simpan ke database lokal Drift (Offline-First)
        await AppDatabase.instance.upsertScreening(
          LocalScreeningsCompanion(
            id: drift.Value(newId),
            patientId: drift.Value(widget.patientId),
            date: drift.Value(dateStr),
            weight: drift.Value(weight),
            height: drift.Value(height),
            bloodPressure: drift.Value(bp),
            cholesterol: drift.Value(cholesterol),
            bloodSugar: drift.Value(sugar),
            uricAcid: drift.Value(uricAcid),
            hemoglobin: const drift.Value(null),
            status: drift.Value(status),
            isSynced: const drift.Value(false),
            syncAction: const drift.Value('insert'),
            updatedAt: drift.Value(now),
            createdAt: drift.Value(now),
          ),
        );

        // 2. Memicu sinkronisasi di latar belakang
        SyncService.instance.syncAll();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showSuccessDialog();
        }
      } catch (e) {
        debugPrint('[SkriningBaru] Gagal menyimpan hasil skrining: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan hasil skrining. Silakan coba lagi atau hubungi petugas teknis.'),
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
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.statusWarning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusWarning,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'Skrining Sudah Ada',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Pasien ${widget.name} sudah melakukan skrining pada bulan $monthName ${_selectedDate.year}.\n\nSkrining rutin lansia dilakukan 1 kali per bulan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _SpringButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.statusWarning,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ubah Tanggal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'Skrining Berhasil!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Data pemeriksaan skrining untuk ${widget.name} berhasil disimpan ke sistem.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _SpringButton(
                    onTap: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context, true); // Pop screen back to list/detail with true
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        body: Column(
          children: [
            _buildAppBar(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: 32.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Header Card
                    _buildPatientProfileCard(),
                    const SizedBox(height: 20.0),

                    // Service Date Section
                    _buildSectionHeader('Tanggal Pemeriksaan'),
                    const SizedBox(height: 8.0),
                    _buildServiceDateCard(),
                    const SizedBox(height: 20.0),

                    // Vital Signs Section
                    _buildSectionHeader('Tanda Vital'),
                    const SizedBox(height: 8.0),
                    _buildVitalSignsCard(),
                    const SizedBox(height: 20.0),

                    // Lab Results Section (Hb removed)
                    _buildSectionHeader('Hasil Laboratorium (Opsional)'),
                    const SizedBox(height: 8.0),
                    _buildLabResultsCard(),
                    const SizedBox(height: 28.0),

                    // Save Button (Squircle, height: 52, zero glow, zero gradient)
                    _buildSaveButton(),
                    const SizedBox(height: 16.0),
                    const MedicalDisclaimerCard(showSourcesList: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Header App Bar (Solid, Minimalist, Matching Sub-screens)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              _SpringButton(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20.0,
                  ),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Text(
                  'Input Skrining Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Patient Profile Header Card
  Widget _buildPatientProfileCard() {
    final isMale = widget.gender == 'Laki-laki';
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMale 
                  ? AppColors.tertiary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                _getInitials(widget.name),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isMale ? AppColors.tertiary : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  '${widget.age} Tahun • ${widget.gender}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Lansia RW 06',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Section Label Heading
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // Service Date Selection Card
  Widget _buildServiceDateCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: _SpringButton(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _dateController.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Ubah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vital Signs Form Card with Separated Blood Pressure Fields
  Widget _buildVitalSignsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Weight Input
              Expanded(
                child: _buildInputField(
                  label: 'Berat Badan',
                  hint: '0',
                  suffixText: 'kg',
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12.0),
              // Height Input
              Expanded(
                child: _buildInputField(
                  label: 'Tinggi Badan',
                  hint: '0',
                  suffixText: 'cm',
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Blood Pressure (Tekanan Darah) Section with Split Numeric Fields
          _buildSplitBloodPressureField(),
        ],
      ),
    );
  }

  // Split Blood Pressure: Sistolik & Diastolik in separate numeric fields
  Widget _buildSplitBloodPressureField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tekanan Darah',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'mmHg',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Row(
          children: [
            // Sistolik (Atas / SYS)
            Expanded(
              child: Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _systolicController,
                        focusNode: _systolicFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (val) {
                          // Auto-focus next field when 3 digits are reached (e.g. 120)
                          if (val.length == 3) {
                            _diastolicFocusNode.requestFocus();
                          }
                          setState(() {});
                        },
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '120',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.outline,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      margin: const EdgeInsets.only(right: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'SYS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Separator Badge /
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '/',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.outline,
                ),
              ),
            ),

            // Diastolik (Bawah / DIA)
            Expanded(
              child: Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _diastolicController,
                        focusNode: _diastolicFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (val) {
                          setState(() {});
                        },
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '80',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.outline,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      margin: const EdgeInsets.only(right: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'DIA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'Ketik angka Sistolik (SYS) lalu Diastolik (DIA) tanpa perlu simbol garis miring.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Lab Results Form Card (Hb removed: Kolesterol, Gula Darah, Asam Urat)
  Widget _buildLabResultsCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Kolesterol Input
              Expanded(
                child: _buildInputField(
                  label: 'Kolesterol',
                  hint: '0',
                  suffixText: 'mg/dL',
                  controller: _cholesterolController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12.0),
              // Gula Darah Input
              Expanded(
                child: _buildInputField(
                  label: 'Gula Darah',
                  hint: '0',
                  suffixText: 'mg/dL',
                  controller: _bloodSugarController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          // Asam Urat Input
          _buildInputField(
            label: 'Asam Urat',
            hint: '0.0',
            suffixText: 'mg/dL',
            controller: _uricAcidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  // Reusable text input field builder (Minimalist, Solid, Zero Glow)
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
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          height: 48.0,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.outline,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      suffixText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }

  // Save Button Action (Strictly Follows Button Style Guidelines)
  // Height: 52, Squircle BorderRadius: 16, Solid AppColors.primary, Zero Glow & Zero Gradient
  Widget _buildSaveButton() {
    return _SpringButton(
      onTap: _isLoading ? () {} : _handleSave,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _isLoading ? AppColors.outlineVariant : AppColors.primary,
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Simpan Hasil Skrining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
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
