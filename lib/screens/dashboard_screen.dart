import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'layanan_screen.dart';
import 'skrining_screen.dart';
import 'pasien_screen.dart';
import 'profil_screen.dart';
import '../widgets/app_toast.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  int _totalPatientsCount = 0;
  int _screenedPatientsCount = 0;
  int _screenedTodayCount = 0;
  int _targetTodayCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStats = true;
    });
    try {
      final patientsResponse = await Supabase.instance.client
          .from('patients')
          .select('id');
      
      final totalPatients = patientsResponse.length;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
      final todayStr = now.toIso8601String().split('T').first;
      
      final screeningsResponse = await Supabase.instance.client
          .from('screenings')
          .select('patient_id, date')
          .gte('date', startOfMonth);

      final List<Map<String, dynamic>> screenings = List<Map<String, dynamic>>.from(screeningsResponse);

      final uniqueScreenedIds = screenings
          .map((s) => s['patient_id'] as String)
          .toSet();

      final screenedCount = uniqueScreenedIds.length;

      // Calculate screened today (unique patients screened today)
      final uniqueScreenedTodayIds = screenings
          .where((s) => (s['date'] as String).startsWith(todayStr))
          .map((s) => s['patient_id'] as String)
          .toSet();

      final screenedTodayCount = uniqueScreenedTodayIds.length;

      // Remaining is patients not screened this month
      final remaining = (totalPatients - screenedCount).clamp(0, totalPatients);

      // Target today = screened today + remaining patients
      final targetToday = screenedTodayCount + remaining;

      if (mounted) {
        setState(() {
          _totalPatientsCount = totalPatients;
          _screenedPatientsCount = screenedCount;
          _screenedTodayCount = screenedTodayCount;
          _targetTodayCount = targetToday;
          _isLoadingStats = false;
        });
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
    if ((index - _currentIndex).abs() > 1) {
      _pageController.jumpToPage(index > _currentIndex ? index - 1 : index + 1);
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
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
                  _fetchStats();
                }
              },
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDashboardContent(),
                const LayananScreen(),
                const SkriningScreen(),
                const PasienScreen(),
                const ProfilScreen(),
              ],
            ),
          ),

          // Shared Bottom Navigation Bar
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

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchStats,
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
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
                  _buildWelcomeSection(),
                  const SizedBox(height: 32.0),
                  _buildRingkasanLayanan(),
                  const SizedBox(height: 32.0),
                  _buildAksesCepat(),
                  const SizedBox(height: 32.0),
                  _buildFeaturedCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Header Widget (TopAppBar style)
  Widget _buildHeader() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Title
                  Text(
                    'Posyandu Sakura',
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

  // Welcome Section
  Widget _buildWelcomeSection() {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = user?.userMetadata?['full_name'] ?? 
                        user?.userMetadata?['name'] ?? 
                        user?.email?.split('@').first ?? 
                        'Bidan SIU';

    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 11) {
      timeGreeting = 'Selamat pagi';
    } else if (hour < 15) {
      timeGreeting = 'Selamat siang';
    } else if (hour < 18) {
      timeGreeting = 'Selamat sore';
    } else {
      timeGreeting = 'Selamat malam';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $displayName',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          '$timeGreeting, mari bantu lansia tetap sehat hari ini.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Ringkasan Layanan Bento Grid
  Widget _buildRingkasanLayanan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ringkasan Layanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            _SpringButton(
              onTap: () {},
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
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppColors.secondary,
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  height: 1.0,
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
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.0,
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
                  child: Row(
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
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
                iconColor: AppColors.primary,
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
                icon: Icons.history_rounded,
                iconColor: AppColors.tertiary,
                title: 'Riwayat',
                subtitle: 'Cek data sebelumnya',
                onTap: () {
                  _navigateToPage(3);
                  AppToast.show(
                    context: context,
                    message: 'Pilih pasien untuk melihat riwayat pemeriksaan',
                    type: AppToastType.info,
                  );
                },
              ),
              _buildDivider(indent: 76.0),
              _buildAppleListItem(
                icon: Icons.groups_rounded,
                iconColor: AppColors.secondary,
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
    required Color iconColor,
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
            // Colored container for icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
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

  // Featured Card (Target Hari Ini)
  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 107, 71, 0.12),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background soft decor circles (glass overlay effect)
          Positioned(
            top: -64,
            right: -64,
            width: 180,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Hari Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _targetTodayCount == 0
                              ? 'Semua warga selesai diskrining'
                              : 'Selesaikan skrining $_targetTodayCount warga hari ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progres Skrining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_screenedTodayCount/$_targetTodayCount Warga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Premium Progress Bar
                Container(
                  height: 10.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _targetTodayCount > 0 
                        ? (_screenedTodayCount / _targetTodayCount).clamp(0.0, 1.0) 
                        : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Premium Bottom Navigation Bar (Glassmorphic style)
  Widget _buildBottomNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 80.0 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding,
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
              ),
              _buildNavBarItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
              ),
            ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required IconData icon,
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
              // Active Background Pill Visual
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
