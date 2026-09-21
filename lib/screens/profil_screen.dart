import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/medical_disclaimer_card.dart';
import '../services/kader_auth_service.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';
import 'welcome_screen.dart';


class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  User? _user;
  String _name = '';
  String _gender = '';
  String _birthDate = ''; // YYYY-MM-DD format
  String _address = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _user = Supabase.instance.client.auth.currentUser;
    if (_user != null) {
      final meta = _user!.userMetadata ?? {};
      _name = meta['full_name'] ?? meta['name'] ?? '';
      _gender = meta['gender'] ?? '';
      _birthDate = meta['birth_date'] ?? '';
      _address = meta['address'] ?? '';
    }
  }

  // Indonesian Date Formatter for text display (e.g. "1957-08-24" -> "24 Agustus 1957")
  String _formatBirthDate(String isoDateStr) {
    if (isoDateStr.isEmpty) return '-';
    try {
      final parts = isoDateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.parse(parts[2]).toString().padLeft(2, '0');

        const months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember'
        ];
        final monthName = months[monthNum - 1];
        return '$day $monthName $year';
      }
    } catch (_) {}
    return isoDateStr;
  }

  // Format date to dd/mm/yyyy for text field
  String _formatDisplayDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.outline.withValues(alpha: 0.6),
        fontSize: 13.5,
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: AppPullToRefresh(
              onRefresh: () async {
                setState(() {
                  _loadUserData();
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: 120.0, // Space for shared floating bottom nav
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
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          alignment: Alignment.centerLeft,
          child: Text(
            'Profil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final avatarUrl = _user?.userMetadata?['avatar_url'] ??
        _user?.userMetadata?['picture'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsOrIcon(),
      );
    }
    return _buildInitialsOrIcon();
  }

  Widget _buildInitialsOrIcon() {
    if (_name.isNotEmpty) {
      final initials = _name
          .trim()
          .split(' ')
          .map((e) => e.isEmpty ? '' : e[0])
          .take(2)
          .join('')
          .toUpperCase();
      if (initials.isNotEmpty) {
        return Container(
          color: AppColors.primary.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        );
      }
    }
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 48.0,
      ),
    );
  }

  // Profile Header (Avatar, Name, Role Badge, Email)
  Widget _buildProfileHeader(BuildContext context) {
    final email = _user?.email ?? 'kader@posyandusakura.id';

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0, bottom: 20.0),
        child: Column(
          children: [
            // Profile image with clean minimal border, strictly zero blur glow
            Container(
              width: 88.0,
              height: 88.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerLowest,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 2.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44.0),
                child: _buildAvatarWidget(),
              ),
            ),
            const SizedBox(height: 14.0),

            // User Name
            Text(
              _name.isNotEmpty ? _name : 'Kader Posyandu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6.0),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 13.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    'Kader Posyandu Sakura RW 06',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6.0),

            // User Email
            Text(
              email,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Account Menu Box (Grouped Bento)
  Widget _buildMenuAkun(BuildContext context) {
    return Container(
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
        children: [
          _buildRowItem(
            context: context,
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            title: 'Informasi Pribadi',
            onTap: () {
              _showInformasiPribadi(context);
            },
          ),
        ],
      ),
    );
  }

  // App Menu Box (Grouped Bento)
  Widget _buildMenuAplikasi(BuildContext context) {
    return Container(
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
        children: [
          _buildRowItem(
            context: context,
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.surfaceContainerLow,
            title: 'Pusat Bantuan',
            onTap: () {
              _showPusatBantuan(context);
            },
          ),
          _buildDivider(),
          _buildRowItem(
            context: context,
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.surfaceContainerLow,
            title: 'Tentang Aplikasi',
            onTap: () {
              _showTentangAplikasi(context);
            },
          ),
          _buildDivider(),
          _buildRowItem(
            context: context,
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.surfaceContainerLow,
            title: 'Kebijakan Privasi',
            onTap: () {
              _showKebijakanPrivasi(context);
            },
          ),
          _buildDivider(),
          _buildRowItem(
            context: context,
            icon: Icons.cleaning_services_outlined,
            iconColor: AppColors.tertiary,
            iconBgColor: AppColors.tertiary.withValues(alpha: 0.1),
            title: 'Bersihkan Data & Sinkron Ulang',
            onTap: () {
              _showBersihkanDataDialog(context);
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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

  // Logout Button with Confirmation Dialog Trigger
  Widget _buildLogoutButton(BuildContext context) {
    return _SpringButton(
      onTap: () {
        _showLogoutConfirmationDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
              'Keluar dari Akun',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.0,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
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
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'Konfirmasi Keluar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Apakah Anda yakin ingin keluar dari akun kader? Anda harus masuk kembali untuk mengelola data skrining warga.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext); // Close dialog
                            try {
                              await KaderAuthService.clearLocalSession();
                              await AppDatabase.instance.clearAllData();
                              try {
                                await GoogleSignIn.instance.signOut();
                              } catch (_) {}
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const WelcomeScreen()),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppToast.show(
                                  context: context,
                                  message: 'Gagal keluar: $e',
                                  type: AppToastType.error,
                                );
                              }
                            }
                          },

                          child: Text(
                            'Ya, Keluar',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog Bersihkan Data Pengujian & Sinkron Ulang
  void _showBersihkanDataDialog(BuildContext context) {
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
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cleaning_services_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'Bersihkan Data Uji Coba?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tindakan ini akan mengosongkan seluruh data lokal di perangkat dan memperbarui data dari server Posyandu Sakura RW 06.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              try {
                                await AppDatabase.instance.clearAllData();
                                await SyncService.instance.syncAll();
                                if (context.mounted) {
                                  AppToast.show(
                                    context: context,
                                    message: 'Data berhasil dibersihkan dan disinkronkan',
                                    type: AppToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.show(
                                    context: context,
                                    message: 'Gagal membersihkan data: $e',
                                    type: AppToastType.error,
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Ya, Bersihkan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
          ),
        );
      },
    );
  }

  // Version Info Text
  Widget _buildVersionText() {
    return Center(
      child: Column(
        children: [
          Text(
            'Info Lansia • Versi 2.0.0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            'Khusus Kader & Tenaga Kesehatan Posyandu Sakura RW 06',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.0,
              color: AppColors.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog for Informasi Pribadi (No redundant (X) button, only bottom buttons)
  void _showInformasiPribadi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Informasi Pribadi Kader',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  _buildInfoRow('Nama Lengkap', _name.isNotEmpty ? _name : '-'),
                  _buildInfoDivider(),
                  _buildInfoRow(
                      'Jenis Kelamin', _gender.isNotEmpty ? _gender : '-'),
                  _buildInfoDivider(),
                  _buildInfoRow(
                      'Tanggal Lahir',
                      _birthDate.isNotEmpty
                          ? _formatBirthDate(_birthDate)
                          : '-'),
                  _buildInfoDivider(),
                  _buildInfoRow(
                      'Alamat Domisili', _address.isNotEmpty ? _address : '-'),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Tutup',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditInformasiPribadi(context);
                          },
                          child: Text(
                            'Ubah Data',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog for Edit Informasi Pribadi (Redesigned: Clean, Minimalist, Squircle)
  void _showEditInformasiPribadi(BuildContext context) {
    String tempName = _name;
    String tempGender = _gender.isNotEmpty ? _gender : 'Perempuan';
    String tempBirthDate = _birthDate;
    String tempAddress = _address;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: tempName);
    final dateController = TextEditingController(
        text: tempBirthDate.isNotEmpty
            ? _formatDisplayDate(DateTime.parse(tempBirthDate))
            : '');
    final addressController = TextEditingController(text: tempAddress);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            Future<void> selectDate() async {
              DateTime initialDate = tempBirthDate.isNotEmpty
                  ? DateTime.tryParse(tempBirthDate) ?? DateTime(1985)
                  : DateTime(1985);

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1940),
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

              if (picked != null) {
                setStateBuilder(() {
                  tempBirthDate =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  dateController.text = _formatDisplayDate(picked);
                });
              }
            }

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Icon Badge + Title + Subtitle
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.primary,
                                  size: 22.0,
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ubah Data Kader',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Perbarui identitas profil kader',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18.0),
                          const Divider(height: 1.0, color: AppColors.borderSubtle),
                          const SizedBox(height: 18.0),

                          // Nama Lengkap
                          Text(
                            'NAMA LENGKAP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: _buildInputDecoration(
                              hint: 'Masukkan nama lengkap',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.outline,
                                size: 20.0,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // Jenis Kelamin Segmented Selector
                          Text(
                            'JENIS KELAMIN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
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
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setStateBuilder(() {
                                        tempGender = 'Laki-laki';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: tempGender == 'Laki-laki'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male_rounded,
                                            size: 16.0,
                                            color: tempGender == 'Laki-laki'
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            'Laki-laki',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.0,
                                              fontWeight: tempGender == 'Laki-laki'
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: tempGender == 'Laki-laki'
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setStateBuilder(() {
                                        tempGender = 'Perempuan';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: tempGender == 'Perempuan'
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female_rounded,
                                            size: 16.0,
                                            color: tempGender == 'Perempuan'
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            'Perempuan',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.0,
                                              fontWeight: tempGender == 'Perempuan'
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: tempGender == 'Perempuan'
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Tanggal Lahir
                          Text(
                            'TANGGAL LAHIR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          GestureDetector(
                            onTap: selectDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: dateController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _buildInputDecoration(
                                  hint: 'dd/mm/yyyy',
                                  prefixIcon: const Icon(
                                    Icons.cake_outlined,
                                    color: AppColors.outline,
                                    size: 20.0,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.primary,
                                    size: 20.0,
                                  ),
                                ),
                                validator: (value) {
                                  if (dateController.text.isEmpty) {
                                    return 'Tanggal lahir wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Alamat Lengkap
                          Text(
                            'ALAMAT DOMISILI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          TextFormField(
                            controller: addressController,
                            maxLines: 3,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: _buildInputDecoration(
                              hint: 'Masukkan alamat lengkap domisili',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 36.0),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.outline,
                                  size: 20.0,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Alamat domisili wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),

                          // Actions: Batal and Simpan (Squircle styled)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.borderSubtle),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14.0),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showInformasiPribadi(context);
                                  },
                                  child: Text(
                                    'Batal',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14.0),
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            setStateBuilder(() {
                                              _isSaving = true;
                                            });
                                            try {
                                              await Supabase
                                                  .instance.client.auth
                                                  .updateUser(
                                                UserAttributes(
                                                  data: {
                                                    'full_name': nameController
                                                        .text
                                                        .trim(),
                                                    'gender': tempGender,
                                                    'birth_date': tempBirthDate,
                                                    'address': addressController
                                                        .text
                                                        .trim(),
                                                  },
                                                ),
                                              );

                                              setState(() {
                                                _loadUserData();
                                              });

                                              if (context.mounted) {
                                                AppToast.show(
                                                  context: context,
                                                  message:
                                                      'Profil berhasil diperbarui',
                                                  type: AppToastType.success,
                                                );
                                                Navigator.pop(context);
                                                _showInformasiPribadi(context);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                AppToast.show(
                                                  context: context,
                                                  message:
                                                      'Gagal memperbarui profil: $e',
                                                  type: AppToastType.error,
                                                );
                                              }
                                            } finally {
                                              setStateBuilder(() {
                                                _isSaving = false;
                                              });
                                            }
                                          }
                                        },
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Simpan',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
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

  // Dialog for Pusat Bantuan (No redundant (X), only bottom "Tutup")
  void _showPusatBantuan(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pusat Bantuan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Butuh bantuan atau memiliki pertanyaan seputar operasional aplikasi Info Lansia? Silakan hubungi saluran berikut:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  _buildHelpContactItem(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Email Dukungan Teknis',
                    subtitle: 'muhammadumamsyafiul@gmail.com',
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(
                            text: 'muhammadumamsyafiul@gmail.com'),
                      );
                      AppToast.show(
                        context: context,
                        message: 'Alamat email disalin ke clipboard',
                        type: AppToastType.info,
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
        padding: const EdgeInsets.all(14.0),
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
                color: AppColors.primary.withValues(alpha: 0.1),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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

  // Dialog for Tentang Aplikasi (Updated icon, version 2.0.0, and branding)
  void _showTentangAplikasi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Icon: Healthcare worker and elderly woman illustration
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19.0),
                        child: Image.asset(
                          'assets/images/Healthcare_worker_and_elderly_wo…_2K_202609080031.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: AppColors.primary,
                              size: 40.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Info Lansia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'Versi 2.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Aplikasi Info Lansia dirancang khusus untuk Kader dan Tenaga Kesehatan Posyandu Sakura RW 06 guna memantau kesehatan warga lansia secara berkala, mempermudah pencatatan skrining bulanan, serta menyajikan visualisasi data kesehatan secara akurat.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Medical Guidelines & Disclaimer
                    const MedicalDisclaimerCard(
                      showSourcesList: true,
                      margin: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 18.0),
                    const Divider(height: 1.0, color: AppColors.borderSubtle),
                    const SizedBox(height: 12.0),
                    Text(
                      '© 2026 Posyandu Sakura RW 06. Hak Cipta Dilindungi.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog for Kebijakan Privasi (Polished wording, no redundant (X), bottom "Tutup")
  void _showKebijakanPrivasi(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kebijakan Privasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            'Selamat datang di aplikasi Info Lansia (Layanan Lansia RW 06 Posyandu Sakura).\n\n'
                            'Kami berkomitmen penuh untuk menjaga keamanan data pribadi dan informasi medis warga lansia. Kebijakan ini menjelaskan bagaimana data dikelola:\n\n'
                            '1. Pengumpulan Data\n'
                            'Kami mencatat data identitas warga lansia (Nama, Jenis Kelamin, Tanggal Lahir, Alamat) serta hasil pemeriksaan kesehatan bulanan (Tekanan Darah dan Gula Darah Sewaktu).\n\n'
                            '2. Penggunaan Data\n'
                            'Data digunakan secara khusus untuk pencatatan rekam medis pelayanan Posyandu Sakura RW 06, pemantauan tren kondisi kesehatan lansia secara berkelanjutan, dan memfasilitasi rujukan medis jika terdeteksi faktor risiko tinggi.\n\n'
                            '3. Hak Akses & Keamanan\n'
                            'Akses terhadap data dibatasi secara ketat khusus untuk kader posyandu dan tenaga kesehatan wilayah RW 06 yang telah terotentikasi. Seluruh data disimpan secara aman pada infrastruktur cloud database terenkripsi.\n\n'
                            '4. Kerahasiaan Medis\n'
                            'Informasi kesehatan warga bersifat rahasia dan tidak akan diperjualbelikan maupun dibagikan kepada pihak luar di luar kebutuhan pelayanan kesehatan masyarakat.\n\n'
                            'Jika terdapat pertanyaan mengenai privasi atau pengelolaan data, silakan hubungi tim kader Posyandu Sakura RW 06.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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

// Spring Button for tactile click feel
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
