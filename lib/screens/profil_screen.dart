import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: 120.0, // Large space for BottomNavBar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 24.0),
                  _buildGroupTitle('Menu Akun'),
                  const SizedBox(height: 8.0),
                  _buildMenuAkun(context),
                  const SizedBox(height: 24.0),
                  _buildGroupTitle('Menu Aplikasi'),
                  const SizedBox(height: 8.0),
                  _buildMenuAplikasi(context),
                  const SizedBox(height: 32.0),
                  _buildLogoutButton(context),
                  const SizedBox(height: 24.0),
                  _buildVersionText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header / Top Navigation Bar
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                'Profil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Header (Avatar, Name, Age)
  Widget _buildProfileHeader(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            // Profile image with edit badge overlay
            Stack(
              children: [
                Container(
                  width: 112.0,
                  height: 112.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                    border: Border.all(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.06),
                        blurRadius: 24,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999.0),
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuA_1YTqHXWf5mqy3yvQIxg9TQR4dt-DsZtg1Tqfbo64MEQpkLHxor3Xl3WofHQIC901BmCnOTfgFpHgC4ewnSLrvVLsgLy6BTft4_QHMyb3HpFXOGulajI2jCIetLihqHcBP38ajtlNPXaniIxFn3SIesnSOEwtBCc4-WQ1FH4bliYoJ_-bwFw0IybNJCtvvBjkwxbe4L4u6I32a7HIApqA8pxg1tu_zyrj0IpE6MhLoC_YgJ1c-fSbOfiBlNTecRrhOBalsCzvEUQP',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 48.0,
                      ),
                    ),
                  ),
                ),
                // Edit badge
                Positioned(
                  bottom: 0.0,
                  right: 0.0,
                  child: _SpringButton(
                    onTap: () {
                      _showToast(context, 'Ubah Foto Profil');
                    },
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Siti Aminah
            Text(
              'Siti Aminah',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4.0),
            // Age
            Text(
              'Umur: 68 Tahun',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Group Title
  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Account Menu Box (Grouped)
  Widget _buildMenuAkun(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
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
        children: [
          _buildRowItem(
            context: context,
            icon: Icons.person_rounded,
            iconColor: AppColors.primaryContainer,
            iconBgColor: AppColors.secondaryContainer,
            title: 'Informasi Pribadi',
            onTap: () {
              _showInformasiPribadi(context);
            },
          ),
        ],
      ),
    );
  }

  // App Menu Box (Grouped)
  Widget _buildMenuAplikasi(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
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
        children: [
          _buildRowItem(
            context: context,
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.onSurfaceVariant,
            iconBgColor: AppColors.surfaceContainer,
            title: 'Pusat Bantuan',
            onTap: () {
              _showPusatBantuan(context);
            },
          ),
          _buildDivider(),
          _buildRowItem(
            context: context,
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.onSurfaceVariant,
            iconBgColor: AppColors.surfaceContainer,
            title: 'Tentang Aplikasi',
            onTap: () {
              _showTentangAplikasi(context);
            },
          ),
          _buildDivider(),
          _buildRowItem(
            context: context,
            icon: Icons.security_rounded,
            iconColor: AppColors.onSurfaceVariant,
            iconBgColor: AppColors.surfaceContainer,
            title: 'Kebijakan Privasi',
            onTap: () {
              _showKebijakanPrivasi(context);
            },
          ),
        ],
      ),
    );
  }

  // Common Group List Item Row
  Widget _buildRowItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return _SpringButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outlineVariant,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  // Divider
  Widget _buildDivider() {
    return const Divider(
      height: 1.0,
      thickness: 0.5,
      color: AppColors.borderSubtle,
      indent: 16.0,
      endIndent: 16.0,
    );
  }

  // Logout Button
  Widget _buildLogoutButton(BuildContext context) {
    return _SpringButton(
      onTap: () {
        _showToast(context, 'Melakukan Keluar...');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Version Info Text
  Widget _buildVersionText() {
    return Center(
      child: Opacity(
        opacity: 0.6,
        child: Text(
          'Versi Aplikasi 2.4.0 (Cloud)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.0,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // Simple feedback utility
  void _showToast(BuildContext context, String message) {
    AppToast.show(
      context: context,
      message: message,
      type: AppToastType.info,
    );
  }

  // Beautiful Blurred Dialog for Informasi Pribadi
  void _showInformasiPribadi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         'Informasi Pribadi',
                         style: GoogleFonts.plusJakartaSans(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: AppColors.primary,
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close_rounded),
                         onPressed: () => Navigator.pop(context),
                       ),
                     ],
                  ),
                  const SizedBox(height: 16.0),
                  _buildInfoRow('NIK', '3201062408570001'),
                  _buildInfoDivider(),
                  _buildInfoRow('Nama Lengkap', 'Siti Aminah'),
                  _buildInfoDivider(),
                  _buildInfoRow('Jenis Kelamin', 'Perempuan'),
                  _buildInfoDivider(),
                  _buildInfoRow('Umur', '68 Tahun'),
                  _buildInfoDivider(),
                  _buildInfoRow('Tanggal Lahir', '24 Agustus 1957'),
                  _buildInfoDivider(),
                  _buildInfoRow('No. Telepon', '0812-8877-6655'),
                  _buildInfoDivider(),
                  _buildInfoRow('Alamat', 'RT 03 / RW 06, Sukamaju'),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12.0),
                       ),
                       padding: const EdgeInsets.symmetric(vertical: 14.0),
                     ),
                     onPressed: () => Navigator.pop(context),
                     child: Text(
                       'Tutup',
                       style: GoogleFonts.plusJakartaSans(
                         fontWeight: FontWeight.bold,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.0,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return const Divider(
      height: 1.0,
      thickness: 0.5,
      color: AppColors.borderSubtle,
    );
  }

  // Beautiful Blurred Dialog for Pusat Bantuan
  void _showPusatBantuan(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pusat Bantuan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Butuh bantuan atau memiliki pertanyaan mengenai layanan Posyandu Sakura? Silakan hubungi kami melalui saluran berikut:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  _buildHelpContactItem(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Hubungi via WhatsApp',
                    subtitle: '+62 812-3456-7890',
                    onTap: () {
                      Navigator.pop(context);
                      _showToast(context, 'Membuka WhatsApp Bantuan...');
                    },
                  ),
                  const SizedBox(height: 12.0),
                  _buildHelpContactItem(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Kirim Email',
                    subtitle: 'bantuan@posyandusakura.id',
                    onTap: () {
                      Navigator.pop(context);
                      _showToast(context, 'Membuka Email Client...');
                    },
                  ),
                  const SizedBox(height: 12.0),
                  _buildHelpContactItem(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: 'Panduan Penggunaan',
                    subtitle: 'Baca petunjuk aplikasi',
                    onTap: () {
                      Navigator.pop(context);
                      _showToast(context, 'Membuka Panduan Aplikasi...');
                    },
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
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

  Widget _buildHelpContactItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outlineVariant,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful Blurred Dialog for Tentang Aplikasi
  void _showTentangAplikasi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_florist_rounded,
                      color: AppColors.primary,
                      size: 48.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Posyandu Sakura',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Versi 2.4.0 (Cloud)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Aplikasi Posyandu Sakura dirancang untuk memantau kesehatan lansia secara berkala, mempermudah petugas posyandu dalam melakukan skrining bulanan, serta menyediakan visualisasi tren kesehatan secara real-time untuk mendukung kesejahteraan lansia di lingkungan RW 06.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const Divider(height: 1.0, color: AppColors.borderSubtle),
                  const SizedBox(height: 16.0),
                  Text(
                    '© 2026 Posyandu Sakura Team. Hak Cipta Dilindungi.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
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

  // Beautiful Blurred Dialog for Kebijakan Privasi
  void _showKebijakanPrivasi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kebijakan Privasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                         ),
                       ),
                       IconButton(
                         icon: const Icon(Icons.close_rounded),
                         onPressed: () => Navigator.pop(context),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12.0),
                   ConstrainedBox(
                     constraints: const BoxConstraints(maxHeight: 250),
                     child: Scrollbar(
                       thumbVisibility: true,
                       child: SingleChildScrollView(
                         physics: const BouncingScrollPhysics(),
                         child: Padding(
                           padding: const EdgeInsets.only(right: 12.0),
                           child: Text(
                             'Selamat datang di Aplikasi Posyandu Sakura.\n\n'
                             'Kami sangat berkomitmen untuk melindungi data pribadi dan medis Anda. Kebijakan ini menjelaskan bagaimana data Anda dikelola:\n\n'
                             '1. Pengumpulan Data\n'
                             'Kami mengumpulkan informasi pribadi seperti Nama, NIK, Umur, Alamat, serta hasil pemeriksaan fisik bulanan Anda (Tekanan Darah, Gula Darah, Kolesterol, dll).\n\n'
                             '2. Penggunaan Data\n'
                             'Data medis Anda digunakan murni untuk mencatat rekam medis pelayanan Posyandu Sakura, memantau tren perkembangan kesehatan lansia secara individu, dan menyajikan laporan kesehatan kumulatif tingkat RT/RW.\n\n'
                             '3. Keamanan Data\n'
                             'Data dienkripsi secara aman di cloud database dan hanya dapat diakses oleh bidan atau kader posyandu yang berwenang di RW 06.\n\n'
                             '4. Persetujuan\n'
                             'Dengan menggunakan aplikasi ini, Anda setuju bahwa data pemeriksaan posyandu Anda direkam secara digital untuk kepentingan pemantauan medis.\n\n'
                             'Jika Anda memiliki pertanyaan mengenai data pribadi Anda, hubungi tim bantuan posyandu kami.',
                             style: GoogleFonts.plusJakartaSans(
                               fontSize: 13,
                               color: AppColors.textSecondary,
                               height: 1.5,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 24.0),
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12.0),
                       ),
                       padding: const EdgeInsets.symmetric(vertical: 14.0),
                     ),
                     onPressed: () => Navigator.pop(context),
                     child: Text(
                       'Saya Mengerti',
                       style: GoogleFonts.plusJakartaSans(
                         fontWeight: FontWeight.bold,
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
}

// Custom spring button for crisp Apple/iOS click feel
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
