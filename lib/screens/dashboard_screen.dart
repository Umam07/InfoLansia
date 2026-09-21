import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'layanan_screen.dart';
import 'skrining_screen.dart';
import 'pasien_screen.dart';
import 'profil_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/sync_status_banner.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';
import '../services/network_connectivity_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  // Static cache so data persists in memory across tab switches and rebuilds
  static int _cachedTotalPatients = 0;
  static int _cachedScreenedPatients = 0;
  static bool _hasLoadedOnce = false;

  int _totalPatientsCount = _cachedTotalPatients;
  int _screenedPatientsCount = _cachedScreenedPatients;
  bool _isLoadingStats = !_hasLoadedOnce;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    SyncService.instance.refreshUnsyncedCount();
    if (_hasLoadedOnce) {
      // Data sudah ada di cache: perbarui hening di latar belakang
      _fetchStats(silent: true);
    } else {
      // Pertama kali dibuka: muat data pertama
      _fetchStats(silent: false);
    }
  }


  Future<void> _fetchStats({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoadingStats = true;
      });
    }
    try {
      // 1. Cek data lokal terlebih dahulu untuk render instan (Zero lag)
      final localPatients = await AppDatabase.instance.getAllPatients();
      final localScreenings = await AppDatabase.instance.getAllScreenings();
      if (localPatients.isNotEmpty || localScreenings.isNotEmpty) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final screenedThisMonth = localScreenings
            .where((s) {
              try {
                final d = DateTime.parse(s.date);
                return d.isAfter(startOfMonth) ||
                    (d.year == now.year && d.month == now.month);
              } catch (_) {
                return false;
              }
            })
            .map((s) => s.patientId)
            .toSet();

        _cachedTotalPatients = localPatients.length;
        _cachedScreenedPatients = screenedThisMonth.length;
        _hasLoadedOnce = true;

        if (mounted) {
          setState(() {
            _totalPatientsCount = localPatients.length;
            _screenedPatientsCount = screenedThisMonth.length;
            _isLoadingStats = false;
          });
        }
      }

      // 2. Jika online, ambil data segar dari Supabase
      if (NetworkConnectivityService.instance.isOnline.value) {
        final now = DateTime.now();
        final startOfMonth =
            DateTime(now.year, now.month, 1).toIso8601String().split('T').first;

        final results = await Future.wait([
          Supabase.instance.client.from('patients').select('id'),
          Supabase.instance.client
              .from('screenings')
              .select('patient_id, date')
              .gte('date', startOfMonth),
        ]);

        final patientsResponse = results[0] as List;
        final screeningsResponse = results[1] as List;

        final totalPatients = patientsResponse.length;
        final List<Map<String, dynamic>> screenings =
            List<Map<String, dynamic>>.from(screeningsResponse);

        final uniqueScreenedIds =
            screenings.map((s) => s['patient_id'] as String).toSet();

        final screenedCount = uniqueScreenedIds.length;

        // Update static memory cache
        _cachedTotalPatients = totalPatients;
        _cachedScreenedPatients = screenedCount;
        _hasLoadedOnce = true;

        if (mounted) {
          setState(() {
            _totalPatientsCount = totalPatients;
            _screenedPatientsCount = screenedCount;
            _isLoadingStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    if (index == _currentIndex) return;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Switch between active screen content using a PageView
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                if (index == 0) {
                  _fetchStats(silent: true);
                }
              },
              physics: const ClampingScrollPhysics(),
              children: [
                _buildDashboardContent(),
                const LayananScreen(),
                const SkriningScreen(),
                const PasienScreen(),
                const ProfilScreen(),
              ],
            ),
          ),

          // Shared Floating Bottom Navigation Bar (Telegram Style)
          // Gracefully hides offscreen when software keyboard is active to eliminate UI jumping and keyboard lag
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            left: 14.0,
            right: 14.0,
            bottom: isKeyboardOpen
                ? -100.0
                : (MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 10.0
                    : 18.0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              opacity: isKeyboardOpen ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: isKeyboardOpen,
                child: _buildBottomNavBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildHeader(),
        const SyncStatusBanner(),
        Expanded(
          child: AppPullToRefresh(
            onRefresh: () async {
              await SyncService.instance.syncAll();
              await _fetchStats(silent: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: 120.0, // Space for BottomNavBar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRingkasanLayanan(),
                  const SizedBox(height: 32.0),
                  _buildAksesCepat(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Header Widget (Clean, Minimalist TopAppBar)
  Widget _buildHeader() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Beranda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (_isLoadingStats)
              const LinearProgressIndicator(
                minHeight: 2.0,
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
              )
            else
              const SizedBox(height: 2.0),
          ],
        ),
      ),
    );
  }


  // Ringkasan Layanan Bento Grid
  Widget _buildRingkasanLayanan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (headline-md: 20px / 600)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Layanan',
              style: AppTypography.headlineMd(),
            ),
            _SpringButton(
              onTap: () {
                _navigateToPage(1);
              },
              child: Text(
                'Lihat Detail',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Bento Grid Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16.0) / 2;
            final remaining = (_totalPatientsCount - _screenedPatientsCount).clamp(0, _totalPatientsCount);
            final percentage = _totalPatientsCount > 0 
                ? ((_screenedPatientsCount / _totalPatientsCount) * 100).round()
                : 0;

            return Column(
              children: [
                // Top Row: 2 Squares
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Warga Card (White)
                    Container(
                      width: cardWidth,
                      height: cardWidth,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFF00875A),
                              size: 20,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Warga',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '$_totalPatientsCount',
                                style: AppTypography.displayNumber(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Terperiksa Card (Green Container)
                    Container(
                      width: cardWidth,
                      height: cardWidth,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 107, 71, 0.08),
                            blurRadius: 24,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.how_to_reg_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terperiksa',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '$_screenedPatientsCount',
                                style: AppTypography.displayNumber(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Bottom Row: Full Width Card
                Container(
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.statusWarning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: const Icon(
                                    Icons.pending_actions_rounded,
                                    color: AppColors.statusWarning,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Tersisa',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        '$remaining Warga',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
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
                          const SizedBox(width: 12.0),
                          Row(
                            children: [
                              Container(
                                width: 2.0,
                                height: 40.0,
                                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 20.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$percentage%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'SELESAI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: LinearProgressIndicator(
                          value: _totalPatientsCount > 0
                              ? (_screenedPatientsCount / _totalPatientsCount).clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 6.0,
                          backgroundColor: const Color(0xFFE8F5E9),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Akses Cepat Layanan (Apple-style list)
  Widget _buildAksesCepat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Akses Cepat Layanan',
            style: AppTypography.headlineMd(),
          ),
        ),
        const SizedBox(height: 16.0),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.3),
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
              _buildAppleListItem(
                icon: Icons.medical_services_rounded,
                title: 'Skrining Baru',
                subtitle: 'Input pemeriksaan rutin',
                onTap: () {
                  _navigateToPage(2);
                  AppToast.show(
                    context: context,
                    message: 'Pilih pasien terlebih dahulu untuk memulai skrining',
                    type: AppToastType.info,
                  );
                },
              ),
              _buildDivider(indent: 76.0),
              _buildAppleListItem(
                icon: Icons.groups_rounded,
                title: 'Data Lansia',
                subtitle: 'Manajemen biodata pasien',
                onTap: () {
                  _navigateToPage(3);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppleListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _SpringButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            // Unified secondary-container (#E8F5E9) with primary (#00875A) icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00875A),
                size: 22,
              ),
            ),
            const SizedBox(width: 16.0),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleCard(),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider({required double indent}) {
    return Divider(
      height: 1.0,
      thickness: 0.5,
      color: AppColors.borderSubtle,
      indent: indent,
      endIndent: 16.0,
    );
  }



  // Modern Floating Capsule Bottom Navigation Bar (Telegram Style)
  Widget _buildBottomNavBar() {
    return Container(
      height: 74.0,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(37.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            index: 0,
            activeIcon: Icons.grid_view_rounded,
            inactiveIcon: Icons.grid_view_outlined,
            label: 'Beranda',
          ),
          _buildNavBarItem(
            index: 1,
            activeIcon: Icons.medical_services_rounded,
            inactiveIcon: Icons.medical_services_outlined,
            label: 'Layanan',
          ),
          _buildNavBarItem(
            index: 2,
            activeIcon: Icons.assignment_turned_in_rounded,
            inactiveIcon: Icons.assignment_turned_in_outlined,
            label: 'Skrining',
          ),
          _buildNavBarItem(
            index: 3,
            activeIcon: Icons.groups_rounded,
            inactiveIcon: Icons.groups_outlined,
            label: 'Pasien',
          ),
          _buildNavBarItem(
            index: 4,
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            _navigateToPage(index);
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active Background Pill Visual (Telegram style)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 54,
                height: 33,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3.0),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Spring Button for High-end Touch Feel
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




