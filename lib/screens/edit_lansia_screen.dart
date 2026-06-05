import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class EditLansiaScreen extends StatefulWidget {
  final int index;
  final String initialName;
  final String initialGender;
  final DateTime initialBirthDate;
  final String initialAddress;
  final String? imageUrl;
  final Color? avatarBg;
  final Color? avatarColor;

  const EditLansiaScreen({
    super.key,
    required this.index,
    required this.initialName,
    required this.initialGender,
    required this.initialBirthDate,
    required this.initialAddress,
    this.imageUrl,
    this.avatarBg,
    this.avatarColor,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedDate = widget.initialBirthDate;
    _dateController = TextEditingController(text: _formatDisplayDate(_selectedDate));
    _addressController = TextEditingController(text: widget.initialAddress);
    _gender = widget.initialGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Indonesian Date Formatter for text display
  String _formatDisplayDate(DateTime date) {
    // Show in dd/mm/yyyy format as in mockup screen
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // Date Picker Trigger
  Future<void> _selectDate(BuildContext context) async {
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
        _dateController.text = _formatDisplayDate(picked);
      });
    }
  }

  // Submit Handler
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Mimic HTML micro-interaction delay (1.2 seconds)
      Future.delayed(const Duration(milliseconds: 1200), () {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        // After success label delay (2 seconds), pop back with updated data
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          final age = (DateTime.now().difference(_selectedDate).inDays / 365).floor().toString();
          
          final updatedPatient = {
            'name': _nameController.text,
            'age': age,
            'address': _addressController.text,
            'gender': _gender,
            'birthDate': _selectedDate,
            'category': 'Rutin',
            'avatarBg': widget.avatarBg ?? AppColors.secondaryContainer,
            'avatarColor': widget.avatarColor ?? AppColors.primary,
          };

          Navigator.pop(context, updatedPatient);
        });
      });
    }
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
                  bottom: 120.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Overview Card
                    _buildProfileOverviewCard(),
                    const SizedBox(height: 24.0),

                    // Inputs Card Container
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 24,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nama Lengkap Input
                          _buildSectionLabel('Nama Lengkap'),
                          const SizedBox(height: 6.0),
                          _buildNameField(),
                          const SizedBox(height: 20.0),

                          // Jenis Kelamin Option
                          _buildSectionLabel('Jenis Kelamin'),
                          const SizedBox(height: 6.0),
                          _buildGenderSelector(),
                          const SizedBox(height: 20.0),

                          // Tanggal Lahir Option
                          _buildSectionLabel('Tanggal Lahir'),
                          const SizedBox(height: 6.0),
                          _buildDateField(context),
                          const SizedBox(height: 20.0),

                          // Alamat Option
                          _buildSectionLabel('Alamat'),
                          const SizedBox(height: 6.0),
                          _buildAddressField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Submit Button & Caption
                    _buildSubmitButton(),
                    const SizedBox(height: 8.0),
                    Center(
                      child: Text(
                        'Terakhir diperbarui: 12 Okt 2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shared Bottom Navigation Bar (Mocked for design accuracy)
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

  // Header App Bar matching design mock exactly
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
                  'Edit Data Lansia',
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

  // Profile Overview Card
  Widget _buildProfileOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
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
          // Profile Photo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.avatarBg ?? AppColors.secondaryContainer,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32.0),
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(),
                    )
                  : _buildInitialsAvatar(),
            ),
          ),
          const SizedBox(width: 16.0),
          // Name details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Pasien Terdaftar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildInitialsAvatar() {
    final initials = widget.initialName.isNotEmpty
        ? widget.initialName.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: widget.avatarColor ?? AppColors.primary,
        ),
      ),
    );
  }

  // Section Labels matching designs
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  // Nama Lengkap Field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      decoration: _buildInputDecoration(
        hint: 'Masukkan nama lengkap',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama lengkap wajib diisi';
        }
        return null;
      },
    );
  }

  // Custom Active-Border Gender selector
  Widget _buildGenderSelector() {
    return Row(
      children: [
        // Perempuan Option
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _gender = 'Perempuan';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: _gender == 'Perempuan'
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _gender == 'Perempuan'
                      ? AppColors.primary
                      : AppColors.borderSubtle,
                  width: _gender == 'Perempuan' ? 2.0 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Perempuan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.0,
                  fontWeight: _gender == 'Perempuan' ? FontWeight.bold : FontWeight.normal,
                  color: _gender == 'Perempuan'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        // Laki-laki Option
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _gender = 'Laki-laki';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: _gender == 'Laki-laki'
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _gender == 'Laki-laki'
                      ? AppColors.primary
                      : AppColors.borderSubtle,
                  width: _gender == 'Laki-laki' ? 2.0 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Laki-laki',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.0,
                  fontWeight: _gender == 'Laki-laki' ? FontWeight.bold : FontWeight.normal,
                  color: _gender == 'Laki-laki'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
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
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        decoration: _buildInputDecoration(
          hint: 'dd/mm/yyyy',
        ).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.outline,
            size: 20.0,
          ),
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

  // Alamat Field
  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      maxLines: 4,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      decoration: _buildInputDecoration(
        hint: 'Masukkan alamat lengkap',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Alamat lengkap wajib diisi';
        }
        return null;
      },
    );
  }

  // Animated Submit Button matching design
  Widget _buildSubmitButton() {
    Color btnColor = AppColors.primary;
    if (_isSuccess) {
      btnColor = const Color(0xFF16A34A); // bg-green-600
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: _SpringButton(
        onTap: _isLoading || _isSuccess ? () {} : _handleSubmit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56.0,
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Menyimpan...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.save_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      _isSuccess ? 'Berhasil Disimpan' : 'Simpan Perubahan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Premium Custom Input Decoration
  InputDecoration _buildInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.outline.withValues(alpha: 0.6),
        fontSize: 14.0,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
    );
  }

  // Bottom Navigation Bar matching screenshot design
  Widget _buildBottomNavBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: 80.0 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
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
                isActive: true,
              ),
              _buildNavBarItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
    required String label,
    bool isActive = false,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (!isActive) {
              Navigator.pop(context);
            }
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

// Spring Button custom implementation
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

class _SpringButtonState extends State<_SpringButton> with SingleTickerProviderStateMixin {
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
