import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    // Start the entrance animation after a slight delay (atmosphere effect)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Pastikan Client ID Web yang digunakan untuk mengambil ID Token
      const webClientId =
          '86620544451-qp7qh8s27svb37qevk7695nmhinl8c6r.apps.googleusercontent.com';

      // Menggunakan pola singleton untuk google_sign_in 7.0.0+
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

      // Melakukan login ke Supabase dengan ID Token Google
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Tampilkan bottom sheet sukses
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.12),
          isScrollControlled: true,
          builder: (context) => const _LoginSuccessSheet(),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Stack(
        children: [
          // 1. Mesh Gradient Background with dynamic drifting blobs
          const Positioned.fill(
            child: _BackgroundMesh(),
          ),

          // 2. Main Login Content with entrance animation
          Positioned.fill(
            child: SafeArea(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(),

                                  // Centralized iOS-style premium card with glassmorphism
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 380,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28.0),
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(
                                            sigmaX: 16.0, sigmaY: 16.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24.0, vertical: 36.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainerLowest
                                                .withValues(alpha: 0.75),
                                            borderRadius:
                                                BorderRadius.circular(28.0),
                                            border: Border.all(
                                              color: AppColors.borderSubtle
                                                  .withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.03),
                                                blurRadius: 32,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Logo Section
                                              _buildLogo(),
                                              const SizedBox(height: 28.0),

                                              // Typography Section
                                              _buildWelcomeTypography(),
                                              const SizedBox(height: 28.0),

                                              // Action Section (Google button)
                                              _buildGoogleButton(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Footer Section
                                  _buildFooter(),
                                  const SizedBox(height: 24.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida/ADBb0uhjvhapHm24hoFRkZeTrgKXRyQfUDl1pRV9D-L8am18obb613Fg_MBdemLywPO593Qr6BgWchzZQkum1eiJEhWZwGtj_zZDyQoV_PZZIElCmY41yFRe1xseaCC2q5eWOPT4OpAwi_hCPWvRd6wNJFiJMBU5yoLCYzTMT7d66kmcTbeJXyP401RfF94-CiXxGFeypbK55iFmBVVAb5uCEWD2V-nMYJ2e3Z0_1LlQmu_Qbys0vFjBH1hY5t52',
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback beautiful medical cross if network image fails
                return const Icon(
                  Icons.local_hospital_rounded,
                  size: 36,
                  color: AppColors.primary,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeTypography() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'POSYANDU SAKURA',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Info Lansia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 34 / 28,
            color: AppColors.onSurface,
            letterSpacing: -0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Sistem informasi skrining dan pemantauan tren kesehatan lansia terintegrasi.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 20 / 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return _SpringButton(
      onTap: _handleGoogleSignIn,
      isEnabled: !_isLoading,
      borderRadius: 16.0,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _isLoading
                ? AppColors.borderSubtle
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12.0),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Menghubungkan...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: 24,
                height: 24,
                child: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.red,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Lanjutkan dengan Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        'Sistem informasi Posyandu Sakura mendukung pelayanan kesehatan masyarakat',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          height: 16 / 12,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Custom widget to create soft radial mesh gradients
class _BackgroundMesh extends StatefulWidget {
  const _BackgroundMesh();

  @override
  State<_BackgroundMesh> createState() => _BackgroundMeshState();
}

class _BackgroundMeshState extends State<_BackgroundMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(color: AppColors.backgroundAlt),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * 2 * math.pi;
            final dx1 = 60 * math.sin(angle);
            final dy1 = 40 * math.cos(angle);
            final dx2 = 50 * math.cos(angle + math.pi / 2);
            final dy2 = 60 * math.sin(angle + math.pi / 2);
            final dx3 = 40 * math.sin(angle * 2);
            final dy3 = 45 * math.cos(angle * 2);

            return Stack(
              children: [
                // Blob 1: Top Left - Primary Mint Green
                Positioned(
                  top: -150 + dy1,
                  left: -150 + dx1,
                  width: size.width * 0.9,
                  height: size.width * 0.9,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Blob 2: Middle Right - Soft Emerald
                Positioned(
                  top: size.height * 0.25 + dy2,
                  right: -180 + dx2,
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                // Blob 3: Bottom Left - Pastel Teal
                Positioned(
                  bottom: -150 + dy3,
                  left: -80 + dx3,
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // High-intensity blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

// Spring animated button for premium iOS touch feel
class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isEnabled;
  final double borderRadius;

  const _SpringButton({
    required this.child,
    required this.onTap,
    this.isEnabled = true,
    this.borderRadius = 16.0,
  });

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _scaleController.reverse(); // Scale down to 0.95
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _scaleController.forward(); // Spring back to 1.0
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) {
      _scaleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _isHovering && widget.isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Custom animated success checkmark widget
class _AnimatedSuccessCheckmark extends StatefulWidget {
  final double size;
  const _AnimatedSuccessCheckmark({this.size = 80});

  @override
  State<_AnimatedSuccessCheckmark> createState() =>
      _AnimatedSuccessCheckmarkState();
}

class _AnimatedSuccessCheckmarkState extends State<_AnimatedSuccessCheckmark>
    with TickerProviderStateMixin {
  late final AnimationController _circleController;
  late final AnimationController _checkController;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkDraw;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _circleScale = CurvedAnimation(
      parent: _circleController,
      curve: Curves.elasticOut,
    );

    _checkDraw = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    // Play animations sequentially: circle scaling, then checkmark drawing
    _circleController.forward().then((_) {
      _checkController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsating ring
          _PulseRing(size: widget.size),

          // Inner circle scaling up with shadow
          ScaleTransition(
            scale: _circleScale,
            child: Container(
              width: widget.size * 0.75,
              height: widget.size * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color(0xFF00875A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

          // Custom checkmark drawing on top
          ScaleTransition(
            scale: _circleScale,
            child: AnimatedBuilder(
              animation: _checkDraw,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.size * 0.35, widget.size * 0.35),
                  painter: _CheckmarkPainter(_checkDraw.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatefulWidget {
  final double size;
  const _PulseRing({required this.size});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _opacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.75, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  _CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    final startX = size.width * 0.15;
    final startY = size.height * 0.52;
    final midX = size.width * 0.44;
    final midY = size.height * 0.8;
    final endX = size.width * 0.88;
    final endY = size.height * 0.28;

    path.moveTo(startX, startY);

    if (progress <= 0.4) {
      final segmentProgress = progress / 0.4;
      final currentX = startX + (midX - startX) * segmentProgress;
      final currentY = startY + (midY - startY) * segmentProgress;
      path.lineTo(currentX, currentY);
    } else {
      path.lineTo(midX, midY);
      final segmentProgress = (progress - 0.4) / 0.6;
      final currentX = midX + (endX - midX) * segmentProgress;
      final currentY = midY + (endY - midY) * segmentProgress;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Success bottom sheet with premium staggered entrance animations
class _LoginSuccessSheet extends StatefulWidget {
  const _LoginSuccessSheet();

  @override
  State<_LoginSuccessSheet> createState() => _LoginSuccessSheetState();
}

class _LoginSuccessSheetState extends State<_LoginSuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimationController;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Title animation: starts at 300ms, runs for 400ms
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Subtitle animation: starts at 450ms, runs for 400ms
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutBack),
      ),
    );

    // Button animation: starts at 600ms, runs for 400ms
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _sheetAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Play sheet entrance animations after 200ms delay to let the modal fully slide up
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _sheetAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 32.0),

          // Beautiful animated success checkmark
          const _AnimatedSuccessCheckmark(size: 88),
          const SizedBox(height: 24.0),

          // Staggered Title
          FadeTransition(
            opacity: _titleOpacity,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                'Autentikasi Berhasil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Staggered Subtitle
          FadeTransition(
            opacity: _subtitleOpacity,
            child: SlideTransition(
              position: _subtitleSlide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Selamat datang kembali! Anda berhasil masuk ke Info Lansia menggunakan Akun Google.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 20 / 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32.0),

          // Staggered Dashboard Action Button
          FadeTransition(
            opacity: _buttonOpacity,
            child: SlideTransition(
              position: _buttonSlide,
              child: _SpringButton(
                borderRadius: 16.0,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DashboardScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF00875A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Lanjutkan ke Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
