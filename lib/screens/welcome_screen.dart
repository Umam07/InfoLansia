import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.05, 0.0);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curve),
            child: FadeTransition(
              opacity: curve,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable collage body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Top Mosaic Row (Staggered: Left is higher, Right is shifted lower)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Vignette: Konsultasi Dokter (Starts high)
                        Expanded(
                          child: _CollageVignette(
                            imagePath:
                                'assets/images/63_MjExMi53MDA5Lm4wMDEuNzfQoS5wNi43Nw.webp',
                            height: 175,
                            badge: _PillBadge(
                              icon: Icons.medical_services_outlined,
                              label: 'Konsultasi',
                              backgroundColor: Color(0xFFFBF4E8),
                              borderColor: Color(0xFFF3E2C4),
                              textColor: Color(0xFF945B0A),
                            ),
                            badgeAlignment: Alignment.bottomLeft,
                          ),
                        ),
                        SizedBox(width: 14),
                        // Right Vignette: Pencatatan Digital Kader (Shifted lower so they are not parallel)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 38.0),
                            child: _CollageVignette(
                              imagePath:
                                  'assets/images/Healthcare_worker_using_mobile_p…_202609081451.webp',
                              height: 170,
                              badge: _PillBadge(
                                icon: Icons.phone_android_rounded,
                                label: 'Skrining Digital',
                                backgroundColor: Color(0xFFEAF7EE),
                                borderColor: Color(0xFFC6E7D2),
                                textColor: Color(0xFF1B6E44),
                              ),
                              badgeAlignment: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Central Emotional Headline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bersama,\n',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textPrimary,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'kita jaga.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    height: 1.15,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Mendampingi kesehatan dan senyum hangat warga lansia RW 06 dalam satu genggaman kader.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bottom Mosaic Row (Staggered: Left is shifted lower, Right is higher)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Vignette: Kunjungan Kader (Shifted lower)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 36.0),
                            child: _CollageVignette(
                              imagePath:
                                  'assets/images/Healthcare_worker_comforting_eld…_202609081457.webp',
                              height: 170,
                              badge: _PillBadge(
                                icon: Icons.volunteer_activism_outlined,
                                label: 'Kunjungan Kader',
                                backgroundColor: Color(0xFFFDF2F4),
                                borderColor: Color(0xFFF7D4DA),
                                textColor: Color(0xFF9E2A4B),
                              ),
                              badgeAlignment: Alignment.topLeft,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        // Right Vignette: Senam Bersama Lansia (Starts high)
                        Expanded(
                          child: _CollageVignette(
                            imagePath:
                                'assets/images/Group_exercising_in_park_202609081511.webp',
                            height: 175,
                            badge: _PillBadge(
                              icon: Icons.directions_run_rounded,
                              label: 'Senam Lansia',
                              backgroundColor: Color(0xFFFFF7ED),
                              borderColor: Color(0xFFFED7AA),
                              textColor: Color(0xFFC2410C),
                            ),
                            badgeAlignment: Alignment.topRight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Pinned Bottom CTA Section (Zero Glow, Squircle 16, height 52)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _navigateToLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mulai Skrining Sekarang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khusus Kader & Tenaga Kesehatan Posyandu Sakura RW 06',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A seamless photo vignette without container box or background borders
class _CollageVignette extends StatelessWidget {
  final String imagePath;
  final double height;
  final Widget badge;
  final Alignment badgeAlignment;

  const _CollageVignette({
    required this.imagePath,
    required this.height,
    required this.badge,
    required this.badgeAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Seamless Image Container (No harsh background or border so white illustration edges blend 100%)
        SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            cacheHeight: 600,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Pill Badge (Zero Glow)
        Positioned(
          left: badgeAlignment == Alignment.bottomLeft ||
                  badgeAlignment == Alignment.topLeft
              ? 4
              : null,
          right: badgeAlignment == Alignment.bottomRight ||
                  badgeAlignment == Alignment.topRight
              ? 4
              : null,
          top: badgeAlignment == Alignment.topLeft ||
                  badgeAlignment == Alignment.topRight
              ? 4
              : null,
          bottom: badgeAlignment == Alignment.bottomLeft ||
                  badgeAlignment == Alignment.bottomRight
              ? 4
              : null,
          child: badge,
        ),
      ],
    );
  }
}

/// Pill badge for vignettes with soft pastel styling, hairline border, and ZERO glow
class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _PillBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: textColor,
          ),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
