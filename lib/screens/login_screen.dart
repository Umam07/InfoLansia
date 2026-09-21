import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import '../services/kader_auth_service.dart';
import '../widgets/kader_access_denied_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Client ID Web yang digunakan untuk mengambil ID Token
      const webClientId =
          '86620544451-qp7qh8s27svb37qevk7695nmhinl8c6r.apps.googleusercontent.com';

      // Inisialisasi Google Sign-In
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Gagal mendapatkan ID Token dari Google.');
      }

      // Autentikasi ke Supabase dengan ID Token Google
      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final userEmail = authResponse.user?.email ?? googleUser.email;

      // Pengecekan Whitelist: Pastikan email terdaftar di kader_terdaftar dan berstatus aktif
      final validation = await KaderAuthService.validateKaderOnline(userEmail);

      if (!validation.isAllowed) {
        // Tolak akses: Sign out dari Supabase dan Google Sign-In
        await Supabase.instance.client.auth.signOut();
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          KaderAccessDeniedSheet.show(
            context,
            email: userEmail,
            message: validation.errorMessage ??
                'Email Anda belum terdaftar sebagai kader. Hubungi admin Posyandu Sakura untuk pendaftaran.',
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Tampilkan modal sukses flat
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.25),
          isScrollControlled: true,
          builder: (context) => const _LoginSuccessSheet(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Gagal masuk menggunakan Google. Silakan coba kembali.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16.0),

            // Expanded Content (Superlist Minimalist Layout)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // 1. Transparent Healthcare Worker & Elderly Illustration (Seamlessly blending with background)
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Image.asset(
                        'assets/images/Healthcare_worker_and_elderly_wo…_2K_202609080031.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Large Display Headline (Superlist typography style)
                    Text(
                      'Selamat Datang\ndi Info Lansia',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. Themed Posyandu Sakura Doodles + Centered Tagline
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SakuraPosyanduDoodlesPainter(),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Dibuat untuk kader.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Peduli kesehatan lansia.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: -0.2,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Area (Pinned to Bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sleek Full-Width Google Pill Button (Superlist style)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Menghubungkan...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // White circular container with Google Logo
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.network(
                                    'https://developers.google.com/identity/images/g-logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.g_mobiledata,
                                        size: 18,
                                        color: Colors.red,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Lanjutkan dengan Google',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Microcopy
                  Text(
                    'Khusus Kader & Tenaga Kesehatan Posyandu Sakura RW 06',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
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

// Hand-crafted delicate doodles tailored to the Posyandu Sakura theme
class _SakuraPosyanduDoodlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft Sage Green (Posyandu theme)
    final greenPaint = Paint()
      ..color = const Color(0xFFCCE2D5)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Soft Sakura Blush Pink (Sakura theme)
    final sakuraPaint = Paint()
      ..color = const Color(0xFFECCED2)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Left Upper: 5-Petal Sakura Blossom (Pink)
    _drawSakuraFlower(canvas, Offset(w * 0.14, h * 0.30), sakuraPaint);

    // 2. Left Lower: Caring Heart Outline (Green)
    _drawHeart(canvas, Offset(w * 0.18, h * 0.74), 16, greenPaint);

    // 3. Left Side: Floating Sakura Petal (Pink)
    _drawPetal(canvas, Offset(w * 0.08, h * 0.58), -0.4, sakuraPaint);

    // 4. Right Upper: Pulse Heartbeat ECG Line (Green)
    _drawPulse(canvas, Offset(w * 0.68, h * 0.28), w * 0.24, greenPaint);

    // 5. Right Lower: Medical Health Cross (Green)
    _drawMedicalCross(canvas, Offset(w * 0.82, h * 0.74), 10, greenPaint);

    // 6. Right Side: Health Capsule (Pink)
    _drawCapsule(canvas, Offset(w * 0.90, h * 0.52), 0.5, sakuraPaint);

    // 7. Subtle floating blossom dots
    canvas.drawCircle(
        Offset(w * 0.32, h * 0.18), 2.5, greenPaint..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(w * 0.68, h * 0.78), 2.0, sakuraPaint..style = PaintingStyle.fill);
    greenPaint.style = PaintingStyle.stroke;
    sakuraPaint.style = PaintingStyle.stroke;
  }

  void _drawSakuraFlower(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    const petals = 5;
    const baseR = 10.0;
    const depth = 5.0;
    for (int i = 0; i <= 360; i += 6) {
      final rad = i * math.pi / 180;
      final r = baseR + depth * math.cos(petals * rad);
      final x = center.dx + r * math.cos(rad);
      final y = center.dy + r * math.sin(rad);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Tiny pistil center
    canvas.drawCircle(center, 1.8, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    path.moveTo(x, y + size * 0.2);
    path.cubicTo(
      x - size * 0.65,
      y - size * 0.55,
      x - size,
      y + size * 0.15,
      x,
      y + size * 0.9,
    );
    path.cubicTo(
      x + size,
      y + size * 0.15,
      x + size * 0.65,
      y - size * 0.55,
      x,
      y + size * 0.2,
    );
    canvas.drawPath(path, paint);
  }

  void _drawPetal(Canvas canvas, Offset center, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path();
    path.moveTo(0, -8);
    path.cubicTo(-5, -4, -5, 4, 0, 8);
    path.cubicTo(5, 4, 5, -4, 0, -8);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPulse(Canvas canvas, Offset start, double width, Paint paint) {
    final path = Path();
    final y = start.dy;
    final x = start.dx;
    path.moveTo(x, y);
    path.lineTo(x + width * 0.20, y);
    path.lineTo(x + width * 0.35, y - 13);
    path.lineTo(x + width * 0.50, y + 15);
    path.lineTo(x + width * 0.65, y - 5);
    path.lineTo(x + width * 0.75, y);
    path.lineTo(x + width, y);
    canvas.drawPath(path, paint);
  }

  void _drawMedicalCross(
      Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  void _drawCapsule(Canvas canvas, Offset center, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 10),
      const Radius.circular(5.0),
    );
    canvas.drawRRect(rrect, paint);
    canvas.drawLine(const Offset(0, -5.0), const Offset(0, 5.0), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Flat, Clean Success Bottom Sheet (Zero Gradient, Zero Glow)
class _LoginSuccessSheet extends StatelessWidget {
  const _LoginSuccessSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24.0),

            // Animated Lottie Success Indicator
            SizedBox(
              width: 88,
              height: 88,
              child: Lottie.asset(
                'assets/success_animation.json',
                frameRate: FrameRate.max,
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Lottie.asset(
                    'assets/Succes.lottie',
                    frameRate: FrameRate.max,
                    repeat: false,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error2, stackTrace2) {
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14.0),

            // Title
            Text(
              'Autentikasi Berhasil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8.0),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'Selamat datang kembali! Akun Anda telah terverifikasi untuk mengakses rekam medis lansia.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24.0),

            // Solid Primary CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashboardScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Lanjutkan ke Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}
