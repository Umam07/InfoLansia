import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

import 'riwayat_pemeriksaan_screen.dart';
import 'edit_lansia_screen.dart';
import '../widgets/app_toast.dart';

class DetailPasienScreen extends StatefulWidget {
  final String name;
  final String age;
  final String gender;
  final String address;
  final String birthDate;
  final DateTime? birthDateTime;
  final String healthStatus;
  final String? imageUrl;
  final int? index;
  final Color? avatarBg;
  final Color? avatarColor;

  const DetailPasienScreen({
    super.key,
    this.name = 'Siti Aminah',
    this.age = '72',
    this.gender = 'Perempuan',
    this.address = 'Jl. Mawar No. 12, RT 04/RW 02, Kec. Sukasari, Kota Bogor',
    this.birthDate = '12 Mei 1951',
    this.birthDateTime,
    this.healthStatus = 'Kesehatan Stabil',
    this.imageUrl = 'https://lh3.googleusercontent.com/aida-public/AB6AXuC1pkYWk8hvJp2FHHaEy3TugSHz_LoeAU3adSRShRJgKXfd53YoszCieyRtB4Nx0EPK0BCXaTQnL4dBBHIMTDQVHoUUsfGNkfNaduGPwUciamTnNGkD0iKiQboImtfq_xPv6QYYeySCkjvfhVEBDb77m7svEE-unyd49C11nFC4PVn6S8U-gfsECIc-EUg0Z75jOYEdI7zZEi4No0YfqjCxhFwSaNwlEc8mEQn6v2S-clCMzL5E4Nsk5ufNhqTcb0NILEI3zFtkzMQ_',
    this.index,
    this.avatarBg,
    this.avatarColor,
  });

  @override
  State<DetailPasienScreen> createState() => _DetailPasienScreenState();
}

class _DetailPasienScreenState extends State<DetailPasienScreen> {
  // Local state to keep track of edited fields
  late String _name;
  late String _age;
  late String _gender;
  late String _address;
  late String _birthDate;
  late DateTime _birthDateTime;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _age = widget.age;
    _gender = widget.gender;
    _address = widget.address;
    _birthDate = widget.birthDate;
    _birthDateTime = widget.birthDateTime ?? _parseBirthDateString(widget.birthDate);
  }

  // Parse Indonesian date format like "12 Mei 1951" to a DateTime
  DateTime _parseBirthDateString(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final year = int.parse(parts[2]);
        int month = 1;
        final monthStr = parts[1].toLowerCase();
        if (monthStr.startsWith('jan')) {
          month = 1;
        } else if (monthStr.startsWith('feb')) {
          month = 2;
        } else if (monthStr.startsWith('mar')) {
          month = 3;
        } else if (monthStr.startsWith('apr')) {
          month = 4;
        } else if (monthStr.startsWith('mei') || monthStr.startsWith('may')) {
          month = 5;
        } else if (monthStr.startsWith('jun')) {
          month = 6;
        } else if (monthStr.startsWith('jul')) {
          month = 7;
        } else if (monthStr.startsWith('agu') || monthStr.startsWith('aug')) {
          month = 8;
        } else if (monthStr.startsWith('sep')) {
          month = 9;
        } else if (monthStr.startsWith('okt') || monthStr.startsWith('oct')) {
          month = 10;
        } else if (monthStr.startsWith('nov')) {
          month = 11;
        } else if (monthStr.startsWith('des') || monthStr.startsWith('dec')) {
          month = 12;
        }
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime(1950, 1, 1);
  }

  // Format DateTime to Indonesian format (e.g., "12 Mei 1951")
  String _formatIndonesianDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Handle back button action to pop screen with updated patient data if edited
  void _popWithData(BuildContext context) {
    if (_isEdited) {
      Navigator.pop(context, {
        'action': 'edit',
        'name': _name,
        'age': _age,
        'gender': _gender,
        'address': _address,
        'birthDate': _birthDateTime,
      });
    } else {
      Navigator.pop(context);
    }
  }

  // Trigger edit lansia screen
  Future<void> _triggerEditPatient(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditLansiaScreen(
          index: widget.index ?? 0,
          initialName: _name,
          initialGender: _gender,
          initialBirthDate: _birthDateTime,
          initialAddress: _address,
          imageUrl: widget.imageUrl,
          avatarBg: widget.avatarBg,
          avatarColor: widget.avatarColor,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _name = result['name'] ?? _name;
        _age = result['age'] ?? _age;
        _address = result['address'] ?? _address;
        _gender = result['gender'] ?? _gender;
        if (result['birthDate'] != null) {
          _birthDateTime = result['birthDate'];
          _birthDate = _formatIndonesianDate(_birthDateTime);
        }
        _isEdited = true;
      });
    }
  }

  // Show dialog to confirm patient deletion
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
          backgroundColor: AppColors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Header Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 32.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                
                // Title
                Text(
                  'Hapus Data Pasien?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                
                // Content Description
                Text(
                  'Apakah Anda yakin ingin menghapus data $_name? Tindakan ini tidak dapat dibatalkan dan semua riwayat pemeriksaan pasien akan terhapus secara permanen.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28.0),
                
                // Action Buttons
                Row(
                  children: [
                    // Batal Button
                    Expanded(
                      child: _SpringButton(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    
                    // Ya, Hapus Button
                    Expanded(
                      child: _SpringButton(
                        onTap: () {
                          // Close dialog first
                          Navigator.pop(dialogContext);
                          // Then pop screen back to patient list with delete instruction
                          Navigator.pop(context, {
                            'action': 'delete',
                            'name': _name,
                          });
                        },
                        child: Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(14.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Ya, Hapus',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with WillPopScope to intercept physical device back button
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _popWithData(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64.0),
          child: _buildAppBar(context),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 24.0),
              _buildProfileHeader(context),
              const SizedBox(height: 24.0),
              _buildPersonalInfoCard(context),
              const SizedBox(height: 24.0),
              _buildScreeningHistory(context),
              const SizedBox(height: 32.0),
              const SizedBox(height: 48.0),
            ],
          ),
        ),
      ),
    );
  }

  // Top App Bar with PopupMenuButton containing Edit & Delete options
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
                onTap: () => _popWithData(context),
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
                  'Detail Pasien',
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
              // Popup Menu Button for Patient options (Edit and Delete)
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.primary,
                  size: 24.0,
                ),
                color: AppColors.surfaceContainerLowest,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(
                    color: AppColors.borderSubtle.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _triggerEditPatient(context);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20.0,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Edit Data Pasien',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20.0,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'Hapus Data Pasien',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Section Header
  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Avatar with custom checked badge
          Center(
            child: Stack(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.avatarBg ?? AppColors.primaryContainer,
                    border: Border.all(
                      color: AppColors.surfaceContainerLowest,
                      width: 4.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(52.0),
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
                Positioned(
                  bottom: 2.0,
                  right: 2.0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Name and Age
          Text(
            _name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            '$_age Tahun',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // Health Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light green background
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00875A), // Active Green Dot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  widget.healthStatus,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00875A), // PrimaryContainer green text
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
    final initials = _name.isNotEmpty
        ? _name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Personal Info Card
  Widget _buildPersonalInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Informasi Pribadi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                _SpringButton(
                  onTap: () {
                    AppToast.show(
                      context: context,
                      message: 'Membuka biodata lengkap $_name',
                      type: AppToastType.info,
                    );
                  },
                  child: Text(
                    'Detail',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Info rows
            _buildInfoRow(
              icon: Icons.wc_rounded,
              title: 'Jenis Kelamin',
              value: _gender,
            ),
            const SizedBox(height: 16.0),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Alamat',
              value: _address,
            ),
            const SizedBox(height: 16.0),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              title: 'Tanggal Lahir',
              value: _birthDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded container for icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16.0),

        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Screening History Card
  Widget _buildScreeningHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Pemeriksaan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                _SpringButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiwayatPemeriksaanScreen(
                          name: _name,
                          age: _age,
                          imageUrl: widget.imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Column(
                children: [
                  _buildHistoryItem(
                    context: context,
                    icon: Icons.medical_information_rounded,
                    iconBg: AppColors.primary.withValues(alpha: 0.1),
                    iconColor: AppColors.primary,
                    title: 'Pemeriksaan Rutin',
                    date: '12 Okt 2026',
                    badgeText: 'NORMAL',
                    badgeBg: const Color(0xFFE8F5E9),
                    badgeTextColor: const Color(0xFF2E7D32),
                  ),
                  _buildHistoryDivider(),
                  _buildHistoryItem(
                    context: context,
                    icon: Icons.monitor_heart_rounded,
                    iconBg: AppColors.statusWarning.withValues(alpha: 0.1),
                    iconColor: AppColors.statusWarning,
                    title: 'Skrining Hipertensi',
                    date: '15 Sep 2026',
                    badgeText: 'HIPERTENSI\nRINGAN',
                    badgeBg: const Color(0xFFFFF8E1),
                    badgeTextColor: AppColors.statusWarning,
                    isTwoLineBadge: true,
                  ),
                  _buildHistoryDivider(),
                  _buildHistoryItem(
                    context: context,
                    icon: Icons.medical_information_rounded,
                    iconBg: AppColors.primary.withValues(alpha: 0.1),
                    iconColor: AppColors.primary,
                    title: 'Pemeriksaan Rutin',
                    date: '20 Agt 2026',
                    badgeText: 'NORMAL',
                    badgeBg: const Color(0xFFE8F5E9),
                    badgeTextColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    bool isTwoLineBadge = false,
  }) {
    return _SpringButton(
      onTap: () {
        AppToast.show(
          context: context,
          message: 'Menampilkan hasil pemeriksaan $title ($date)',
          type: AppToastType.success,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Circular container for icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16.0),

            // Title and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    date,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // Health Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeTextColor,
                  letterSpacing: 0.5,
                  height: isTwoLineBadge ? 1.1 : 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDivider() {
    return Divider(
      height: 1.0,
      thickness: 0.5,
      color: AppColors.borderSubtle.withValues(alpha: 0.5),
      indent: 16.0,
      endIndent: 16.0,
    );
  }

}

// Premium Spring Button for iOS tactile feel
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
