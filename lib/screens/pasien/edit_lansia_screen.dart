import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;

import '../../theme.dart';
import '../../widgets/app_toast.dart';
import '../../database/app_database.dart';
import '../../services/sync_service.dart';

class EditLansiaScreen extends StatefulWidget {

  final String? id;
  final int index;
  final String initialName;
  final String initialGender;
  final DateTime initialBirthDate;
  final String initialAddress;
  final Color? avatarBg;
  final Color? avatarColor;
  final DateTime? createdAt;

  const EditLansiaScreen({
    super.key,
    this.id,
    required this.index,
    required this.initialName,
    required this.initialGender,
    required this.initialBirthDate,
    required this.initialAddress,
    this.avatarBg,
    this.avatarColor,
    this.createdAt,
  });

  @override
  State<EditLansiaScreen> createState() => _EditLansiaScreenState();
}

class _EditLansiaScreenState extends State<EditLansiaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _dateController;
  late final TextEditingController _addressController;

  // State Variables
  late String _gender; // 'Perempuan' or 'Laki-laki'
  late DateTime _selectedDate;

  // Submit Button State
  bool _isLoading = false;
  bool _isSuccess = false;
  late DateTime _lastUpdatedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedDate = widget.initialBirthDate;
    _dateController = TextEditingController(text: _formatDate(_selectedDate));
    _addressController = TextEditingController(text: widget.initialAddress);
    _gender = widget.initialGender;
    _lastUpdatedDate = widget.createdAt ?? DateTime.now();
  }

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

  String _formatLastUpdatedDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int get _calculatedAge {
    final now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month ||
        (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }
    return age;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Date Picker Handler
  Future<void> _selectDate(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

  // Submit Handler
  void _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final birthDateStr = _selectedDate.toIso8601String().split('T').first;
        final nameStr = _nameController.text.trim();
        final addressStr = _addressController.text.trim();

        // Cek duplikasi dengan pasien lain (excludeId: widget.id)
        final duplicate = await AppDatabase.instance.findDuplicatePatient(
          name: nameStr,
          birthDate: birthDateStr,
          gender: _gender,
          excludeId: widget.id,
        );

        if (duplicate != null) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            AppToast.show(
              context: context,
              message: 'Gagal mengubah: Data lansia lain dengan nama, tanggal lahir, dan jenis kelamin tersebut sudah ada.',
              type: AppToastType.warning,
            );
          }
          return;
        }

        final now = DateTime.now();

        if (widget.id != null) {
          // 1. Simpan ke database lokal Drift terlebih dahulu
          await AppDatabase.instance.upsertPatient(
            LocalPatientsCompanion(
              id: drift.Value(widget.id!),
              name: drift.Value(nameStr),
              gender: drift.Value(_gender),
              birthDate: drift.Value(birthDateStr),
              address: drift.Value(addressStr),
              category: const drift.Value('Rutin'),
              isSynced: const drift.Value(false),
              syncAction: const drift.Value('update'),
              updatedAt: drift.Value(now),
              createdAt: drift.Value(widget.createdAt ?? now),
            ),
          );

          // 2. Picu sinkronisasi di latar belakang
          SyncService.instance.syncAll();
        }

        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _lastUpdatedDate = now;
        });


        if (mounted) {
          AppToast.show(
            context: context,
            message: 'Data ${_nameController.text.trim()} berhasil diperbarui',
            type: AppToastType.success,
          );
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final updatedPatient = {
            'name': _nameController.text.trim(),
            'age': _calculatedAge.toString(),
            'address': _addressController.text.trim(),
            'gender': _gender,
            'birthDate': _selectedDate,
            'category': '',
            'avatarBg': widget.avatarBg ?? AppColors.secondaryContainer,
            'avatarColor': widget.avatarColor ?? AppColors.primary,
            'createdAt': _lastUpdatedDate,
          };

          Navigator.pop(context, updatedPatient);
        });
      } catch (e) {
        debugPrint('[EditLansia] Gagal memperbarui data lansia: $e');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          AppToast.show(
            context: context,
            message: 'Gagal memperbarui data lansia. Silakan coba lagi atau hubungi petugas teknis.',
            type: AppToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMale = _gender == 'Laki-laki';

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
                  // Profile Summary Card
                  _buildProfileOverviewCard(isMale),
                  const SizedBox(height: 18.0),

                  // Bento Card 1: Identitas Lansia
                  _buildIdentityCard(context, isMale),
                  const SizedBox(height: 18.0),

                  // Bento Card 2: Alamat Domisili
                  _buildAddressCard(),
                  const SizedBox(height: 14.0),

                  // Last updated timestamp
                  Center(
                    child: Text(
                      'Terakhir diperbarui: ${_formatLastUpdatedDate(_lastUpdatedDate)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Primary CTA Button
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
                      'Edit Data Lansia',
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
                      'Pembaruan Informasi Pasien RW 06',
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

  // Profile Overview Card
  Widget _buildProfileOverviewCard(bool isMale) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMale
                  ? AppColors.tertiary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: (isMale ? AppColors.tertiary : AppColors.primary)
                    .withValues(alpha: 0.25),
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(_nameController.text.isNotEmpty
                    ? _nameController.text
                    : widget.initialName),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
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
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : widget.initialName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  '$_calculatedAge Tahun • $_gender',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bento Card 1: Identitas Lansia
  Widget _buildIdentityCard(BuildContext context, bool isMale) {
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
          _buildFieldLabel('Nama Lengkap'),
          const SizedBox(height: 8.0),
          _buildNameField(),
          const SizedBox(height: 18.0),

          // 2. Jenis Kelamin Selector
          _buildFieldLabel('Jenis Kelamin'),
          const SizedBox(height: 8.0),
          _buildGenderSelector(isMale),
          const SizedBox(height: 18.0),

          // 3. Tanggal Lahir Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Tanggal Lahir'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
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
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: _buildInputDecoration(
        hint: 'Masukkan nama lengkap',
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
  Widget _buildGenderSelector(bool isMale) {
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
                  _gender = 'Laki-laki';
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
                  _gender = 'Perempuan';
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
        enabled: false,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: _buildInputDecoration(
          hint: 'Pilih tanggal lahir',
          prefixIcon: Icons.cake_outlined,
          suffixIcon: Icons.calendar_month_rounded,
        ),
        validator: (value) {
          if (_dateController.text.isEmpty) {
            return 'Tanggal lahir wajib diisi';
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
        hint: 'Masukkan alamat lengkap domisili',
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
                  Icon(
                    _isSuccess ? Icons.check_circle_rounded : Icons.save_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _isSuccess ? 'Perubahan Tersimpan' : 'Simpan Perubahan',
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
                alignment:
                    isDenseMultiLine ? Alignment.topCenter : Alignment.center,
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
