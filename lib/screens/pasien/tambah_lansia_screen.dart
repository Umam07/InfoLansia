import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;

import '../../theme.dart';
import '../../widgets/app_toast.dart';
import '../../database/app_database.dart';
import '../../services/sync_service.dart';
import '../../utils/uuid_generator.dart';
import 'import_pasien_screen.dart';
import 'detail_pasien_screen.dart';

class TambahLansiaScreen extends StatefulWidget {

  const TambahLansiaScreen({super.key});

  @override
  State<TambahLansiaScreen> createState() => _TambahLansiaScreenState();
}

class _TambahLansiaScreenState extends State<TambahLansiaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Selected State
  String _selectedGender = 'L'; // 'L' = Laki-laki, 'P' = Perempuan
  DateTime? _selectedDate;

  // Submit Button State
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Indonesian Date Formatter
  String _formatDate(DateTime date) {
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Calculate age from selected birth date
  int? get _calculatedAge {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  // Date Picker Handler
  Future<void> _selectDate(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1955, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
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

  // Form Submission
  void _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        AppToast.show(
          context: context,
          message: 'Tanggal lahir wajib dipilih',
          type: AppToastType.warning,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final birthDateStr = _selectedDate!.toIso8601String().split('T').first;
        final genderStr = _selectedGender == 'L' ? 'Laki-laki' : 'Perempuan';
        final nameStr = _nameController.text.trim();
        final addressStr = _addressController.text.trim();

        // Cek duplikasi: hanya jika Nama + Tanggal Lahir + Jenis Kelamin sama persis
        final duplicate = await AppDatabase.instance.findDuplicatePatient(
          name: nameStr,
          birthDate: birthDateStr,
          gender: genderStr,
        );

        if (duplicate != null) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            _showDuplicateWarningDialog(duplicate);
          }
          return;
        }

        final newId = UuidGenerator.generate();
        final now = DateTime.now();

        // 1. Simpan ke database lokal Drift (Offline-First)
        await AppDatabase.instance.upsertPatient(
          LocalPatientsCompanion(
            id: drift.Value(newId),
            name: drift.Value(nameStr),
            gender: drift.Value(genderStr),
            birthDate: drift.Value(birthDateStr),
            address: drift.Value(addressStr),
            category: const drift.Value('Rutin'),
            isSynced: const drift.Value(false),
            syncAction: const drift.Value('insert'),
            updatedAt: drift.Value(now),
            createdAt: drift.Value(now),
          ),
        );

        // 2. Memicu sinkronisasi di latar belakang jika ada internet
        SyncService.instance.syncAll();

        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showSuccessDialog();
          }
        });
      } catch (e) {
        debugPrint('[TambahLansia] Gagal menyimpan data lansia: $e');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          AppToast.show(
            context: context,
            message: 'Gagal menyimpan data lansia. Silakan coba lagi atau hubungi petugas teknis.',
            type: AppToastType.error,
          );
        }
      }
    }
  }

  // Dialog Peringatan Duplikasi Data Lansia
  void _showDuplicateWarningDialog(LocalPatient existing) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: Text(
                      'Data Lansia Sudah Terdaftar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Warga lansia dengan kombinasi Nama, Tanggal Lahir, dan Jenis Kelamin berikut sudah tersimpan di sistem:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDuplicateInfoRow(Icons.person_outline_rounded, 'Nama:', existing.name),
                        const SizedBox(height: 6.0),
                        _buildDuplicateInfoRow(Icons.cake_outlined, 'Tgl Lahir:', existing.birthDate),
                        const SizedBox(height: 6.0),
                        _buildDuplicateInfoRow(Icons.wc_outlined, 'Kelamin:', existing.gender),
                        const SizedBox(height: 6.0),
                        _buildDuplicateInfoRow(Icons.location_on_outlined, 'Alamat:', existing.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Untuk mencegah data ganda, pendaftaran baru dengan identitas identik tidak dapat diproses.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPasienScreen(
                              id: existing.id,
                              name: existing.name,
                              gender: existing.gender,
                              birthDate: existing.birthDate,
                              address: existing.address,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Profil Lansia Terdaftar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Tutup & Periksa Kembali',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  Widget _buildDuplicateInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }


  // Clean Success Dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                    'Pendaftaran Berhasil!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Data lansia baru atas nama "${_nameController.text.trim()}" telah berhasil disimpan ke database Posyandu.',
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
                      Navigator.pop(dialogContext); // Close dialog
                      Navigator.pop(context, {'success': true}); // Pop screen back to PasienScreen
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
                        'Kembali ke Menu Pasien',
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
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: AppColors.backgroundAlt,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64.0),
            child: _buildAppBar(context),
          ),
          body: Form(
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
                  // Shortcut Impor Massal Excel
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push<int>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImportPasienScreen(),
                        ),
                      );
                      if (result != null && result > 0 && context.mounted) {
                        Navigator.pop(context, {'success': true});
                      }
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.table_chart_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Punya Banyak Data Warga?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Impor sekaligus lewat file Excel (.xlsx)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Bento Card 1: Data Identitas Lansia
                  _buildIdentityCard(context),
                  const SizedBox(height: 18.0),

                  // Bento Card 2: Alamat Domisili
                  _buildAddressCard(),
                  const SizedBox(height: 18.0),

                  // Info Disclaimer Card
                  _buildInfoCard(),
                  const SizedBox(height: 28.0),

                  // Primary CTA Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Top App Bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _SpringButton(
                onTap: () => Navigator.pop(context),
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
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Lansia Baru',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      'Pendaftaran Warga Lansia RW 06',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bento Card 1: Identitas Lansia (Nama, Gender, Tanggal Lahir)
  Widget _buildIdentityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Identitas Warga Lansia'),
          const SizedBox(height: 18.0),

          // 1. Nama Lengkap Field
          _buildFieldLabel('Nama Lengkap Sesuai KTP'),
          const SizedBox(height: 8.0),
          _buildNameField(),
          const SizedBox(height: 18.0),

          // 2. Jenis Kelamin Selector
          _buildFieldLabel('Jenis Kelamin'),
          const SizedBox(height: 8.0),
          _buildGenderSelector(),
          const SizedBox(height: 18.0),

          // 3. Tanggal Lahir Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Tanggal Lahir'),
              if (_calculatedAge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '$_calculatedAge Tahun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          _buildDateField(context),
        ],
      ),
    );
  }

  // Bento Card 2: Alamat Domisili
  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Alamat Tempat Tinggal'),
          const SizedBox(height: 18.0),

          // 4. Alamat Lengkap Field
          _buildFieldLabel('Alamat Lengkap Domisili'),
          const SizedBox(height: 8.0),
          _buildAddressField(),
        ],
      ),
    );
  }

  // Card Header with vertical accent
  Widget _buildCardHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Nama Lengkap Field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: _buildInputDecoration(
        hint: 'Contoh: Siti Aminah',
        prefixIcon: Icons.person_outline_rounded,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama lengkap wajib diisi';
        }
        if (value.trim().length < 3) {
          return 'Nama minimal 3 karakter';
        }
        return null;
      },
    );
  }

  // Segmented Gender Selector (Zero Glow, Clean Active State)
  Widget _buildGenderSelector() {
    final isMale = _selectedGender == 'L';

    return Container(
      height: 48.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Laki-laki
          Expanded(
            child: _SpringButton(
              onTap: () {
                setState(() {
                  _selectedGender = 'L';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isMale ? AppColors.tertiary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.male_rounded,
                      size: 18,
                      color: isMale ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Laki-laki',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: isMale ? FontWeight.w700 : FontWeight.w600,
                        color: isMale ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4.0),

          // Perempuan
          Expanded(
            child: _SpringButton(
              onTap: () {
                setState(() {
                  _selectedGender = 'P';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isMale ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.female_rounded,
                      size: 18,
                      color: !isMale ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Perempuan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: !isMale ? FontWeight.w700 : FontWeight.w600,
                        color: !isMale ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tanggal Lahir Field
  Widget _buildDateField(BuildContext context) {
    return _SpringButton(
      onTap: () => _selectDate(context),
      child: TextFormField(
        controller: _dateController,
        enabled: false, // User taps the block to trigger calendar
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: _buildInputDecoration(
          hint: 'Pilih tanggal lahir warga',
          prefixIcon: Icons.cake_outlined,
          suffixIcon: Icons.calendar_month_rounded,
        ),
        validator: (value) {
          if (_selectedDate == null) {
            return 'Tanggal lahir wajib dipilih';
          }
          return null;
        },
      ),
    );
  }

  // Alamat Lengkap Field
  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      maxLines: 3,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      decoration: _buildInputDecoration(
        hint: 'Contoh: Jl. Mawar No. 12, RT 04/RW 02, Kec. Sukasari',
        prefixIcon: Icons.location_on_outlined,
        isDenseMultiLine: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Alamat lengkap wajib diisi';
        }
        return null;
      },
    );
  }

  // Info Disclaimer Card
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Pastikan data yang dimasukkan sesuai dengan KTP untuk memudahkan integrasi riwayat skrining dan rekam medis Posyandu.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Primary CTA Button (Strict Squircle, height: 52, zero glow, zero gradient)
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52.0,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || _isSuccess ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _isSuccess ? 'Data Tersimpan' : 'Daftar Lansia Baru',
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

  // Premium Input Decoration
  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool isDenseMultiLine = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.outline.withValues(alpha: 0.7),
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: EdgeInsets.only(
                left: 14.0,
                right: 10.0,
                top: isDenseMultiLine ? 14.0 : 0.0,
              ),
              child: Align(
                alignment: isDenseMultiLine ? Alignment.topCenter : Alignment.center,
                widthFactor: 1.0,
                child: Icon(
                  prefixIcon,
                  color: AppColors.primary,
                  size: 20.0,
                ),
              ),
            )
          : null,
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Icon(
                suffixIcon,
                color: AppColors.outline,
                size: 20.0,
              ),
            )
          : null,
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
    );
  }
}

// Spring Button
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
