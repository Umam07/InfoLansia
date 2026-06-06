import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'layanan/layanan_tensi_screen.dart';
import 'layanan/layanan_gula_darah_screen.dart';
import 'layanan/visualisasi_tahunan_screen.dart';
import '../widgets/app_toast.dart';

class LayananScreen extends StatefulWidget {
  const LayananScreen({
    super.key,
  });

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> with TickerProviderStateMixin {
  String _selectedMonth = 'Oktober';
  String _selectedYear = '2026';
  bool _isLoading = false;

  // Animation controller for progress bars
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _years = ['2025', '2026', '2027'];

  final Map<String, int> _monthMap = {
    'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4, 'Mei': 5, 'Juni': 6,
    'Juli': 7, 'Agustus': 8, 'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12
  };

  int _totalScreeningsCount = 0;
  int _growthPct = 0;
  int _normalCount = 0;
  int _warningCount = 0;
  int _dangerCount = 0;
  double _normalPct = 0.0;
  double _warningPct = 0.0;
  double _dangerPct = 0.0;
  int _totalTensi = 0;
  int _tensiRate = 0;
  int _totalGula = 0;
  int _gulaRate = 0;

  @override
  void initState() {
    super.initState();
    // Set current month and year dynamically
    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    _selectedMonth = months[now.month - 1];
    _selectedYear = now.year.toString();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _fetchReportData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final patientsResponse = await Supabase.instance.client
          .from('patients')
          .select('id');
      final totalPatients = patientsResponse.length;

      int monthInt = _monthMap[_selectedMonth] ?? 1;
      int yearInt = int.tryParse(_selectedYear) ?? DateTime.now().year;

      final startOfMonth = DateTime(yearInt, monthInt, 1).toIso8601String().split('T').first;
      final endOfMonth = DateTime(yearInt, monthInt + 1, 1).subtract(const Duration(days: 1)).toIso8601String().split('T').first;

      final screeningsResponse = await Supabase.instance.client
          .from('screenings')
          .select()
          .gte('date', startOfMonth)
          .lte('date', endOfMonth);

      final List<Map<String, dynamic>> screenings = List<Map<String, dynamic>>.from(screeningsResponse);

      final lastMonth = monthInt == 1 ? 12 : monthInt - 1;
      final lastMonthYear = monthInt == 1 ? yearInt - 1 : yearInt;
      final startOfLastMonth = DateTime(lastMonthYear, lastMonth, 1).toIso8601String().split('T').first;
      final endOfLastMonth = DateTime(lastMonthYear, lastMonth + 1, 1).subtract(const Duration(days: 1)).toIso8601String().split('T').first;

      final lastMonthResponse = await Supabase.instance.client
          .from('screenings')
          .select('id')
          .gte('date', startOfLastMonth)
          .lte('date', endOfLastMonth);

      final lastMonthCount = lastMonthResponse.length;
      final thisMonthCount = screenings.length;

      int growthPct = 0;
      if (lastMonthCount > 0) {
        growthPct = (((thisMonthCount - lastMonthCount) / lastMonthCount) * 100).round();
      } else if (thisMonthCount > 0) {
        growthPct = 100;
      }

      int normalCount = 0;
      int warningCount = 0;
      int dangerCount = 0;

      int totalTensi = 0;
      int totalGula = 0;

      for (final s in screenings) {
        final bpStr = s['blood_pressure'] as String?;
        String bpStatus = 'Normal';
        if (bpStr != null && bpStr.contains('/')) {
          final parts = bpStr.split('/');
          if (parts.length == 2) {
            final sys = int.tryParse(parts[0].trim());
            final dia = int.tryParse(parts[1].trim());
            if (sys != null && dia != null) {
              totalTensi++;
              if (sys >= 140 || dia >= 90) {
                bpStatus = 'Hipertensi';
              } else if (sys >= 120 || dia >= 80) {
                bpStatus = 'Pre-Hipertensi';
              }
            }
          }
        }

        final sugarVal = s['blood_sugar'] != null ? int.tryParse(s['blood_sugar'].toString()) : null;
        String sugarStatus = 'Normal';
        if (sugarVal != null) {
          totalGula++;
          if (sugarVal >= 200) {
            sugarStatus = 'Diabetes';
          } else if (sugarVal >= 140) {
            sugarStatus = 'Pre-Diabetes';
          }
        }

        if (bpStatus == 'Hipertensi' || sugarStatus == 'Diabetes') {
          dangerCount++;
        } else if (bpStatus == 'Pre-Hipertensi' || sugarStatus == 'Pre-Diabetes') {
          warningCount++;
        } else {
          normalCount++;
        }
      }

      final totalScreened = screenings.length;
      final normalPct = totalScreened > 0 ? normalCount / totalScreened : 0.0;
      final warningPct = totalScreened > 0 ? warningCount / totalScreened : 0.0;
      final dangerPct = totalScreened > 0 ? dangerCount / totalScreened : 0.0;

      final tensiRate = totalPatients > 0 ? (totalTensi / totalPatients * 100).round() : 0;
      final gulaRate = totalPatients > 0 ? (totalGula / totalPatients * 100).round() : 0;

      if (mounted) {
        setState(() {
          _totalScreeningsCount = thisMonthCount;
          _growthPct = growthPct;
          _normalCount = normalCount;
          _warningCount = warningCount;
          _dangerCount = dangerCount;
          _normalPct = normalPct;
          _warningPct = warningPct;
          _dangerPct = dangerPct;
          _totalTensi = totalTensi;
          _tensiRate = tensiRate;
          _totalGula = totalGula;
          _gulaRate = gulaRate;
          _isLoading = false;
        });

        _progressController.reset();
        _progressController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppToast.show(
          context: context,
          message: 'Gagal memuat data laporan: $e',
          type: AppToastType.error,
        );
      }
    }
  }

  void _handleSearch() {
    _fetchReportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 24.0,
                      bottom: 120.0, // Space for shared BottomNavBar and FAB
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(),
                        const SizedBox(height: 24.0),
                        _buildStatsOverview(),
                        const SizedBox(height: 32.0),
                        _buildDetailedBreakdownHeader(),
                        const SizedBox(height: 16.0),
                        _buildBentoCardsList(),
                        const SizedBox(height: 32.0),
                        _buildVisualisasiBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contextual floating action button for download
          Positioned(
            right: 20.0,
            bottom: 100.0, // Just above BottomNavigationBar
            child: _buildDownloadFAB(),
          ),
        ],
      ),
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
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              // Screen Title
              Expanded(
                child: Text(
                  'Laporan Bulanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter Panel (Month & Year select cards)
  Widget _buildFilterSection() {
    return Container(
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
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selectors Row
          Row(
            children: [
              // Month Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Bulan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildDropdownCard(
                      value: _selectedMonth,
                      items: _months,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Year Selector
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tahun',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildDropdownCard(
                      value: _selectedYear,
                      items: _years,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          // Search Button
          _SpringButton(
            onTap: _isLoading ? () {} : _handleSearch,
            child: Container(
              height: 48.0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8.0),
                        Text(
                          'Tampilkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.outline,
            size: 20,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
          borderRadius: BorderRadius.circular(16.0),
          dropdownColor: AppColors.surfaceContainerLowest,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Stats Overview with Asymmetric Bento Grid
  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Skrining Card (Green Card)
        Container(
          height: 160,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract light circle background graphic
              Positioned(
                right: -40,
                bottom: -40,
                width: 140,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Total Skrining',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$_totalScreeningsCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        _growthPct >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: AppColors.primaryFixed,
                        size: 16,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${_growthPct >= 0 ? '+' : ''}$_growthPct% dari bulan lalu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryFixed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Distribusi Status Kesehatan Card (Progress Bars)
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.03),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribusi Status Kesehatan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20.0),
              // Normal Bar
              _buildHealthProgressBar(
                label: 'Normal',
                count: '$_normalCount Pasien (${(_normalPct * 100).round()}%)',
                percentage: _normalPct,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20.0),
              // Risiko Sedang Bar
              _buildHealthProgressBar(
                label: 'Risiko Sedang',
                count: '$_warningCount Pasien (${(_warningPct * 100).round()}%)',
                percentage: _warningPct,
                color: AppColors.statusWarning,
              ),
              const SizedBox(height: 20.0),
              // Risiko Tinggi Bar
              _buildHealthProgressBar(
                label: 'Risiko Tinggi',
                count: '$_dangerCount Pasien (${(_dangerPct * 100).round()}%)',
                percentage: _dangerPct,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthProgressBar({
    required String label,
    required String count,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              count,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        // Progress Track & Indicator
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 12.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value * percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Detailed Breakdown Header (Export buttons)
  Widget _buildDetailedBreakdownHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Rincian Per Layanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 12.0),
        Row(
          children: [
            _buildExportButton(
              label: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              onTap: () => _handleExport('PDF'),
            ),
            const SizedBox(width: 8.0),
            _buildExportButton(
              label: 'Excel',
              icon: Icons.table_view_rounded,
              onTap: () => _handleExport('Excel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 14),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExport(String type) {
    AppToast.show(
      context: context,
      message: 'Mengekspor laporan ke format $type...',
      type: AppToastType.info,
    );
  }

  // Bento List Cards for services
  Widget _buildBentoCardsList() {
    return Column(
      children: [
        // Card 1: Pemeriksaan Tensi
        _buildBentoCard(
          icon: Icons.monitor_heart_rounded,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          statusLabel: _tensiRate >= 80 ? 'Aktif' : 'Perlu Perhatian',
          statusBg: _tensiRate >= 80 
              ? AppColors.primary.withValues(alpha: 0.08) 
              : AppColors.statusWarning.withValues(alpha: 0.08),
          statusTextColor: _tensiRate >= 80 ? AppColors.primary : AppColors.statusWarning,
          title: 'Pemeriksaan Tensi',
          subtitle: 'Skrining tekanan darah rutin lansia.',
          total: '$_totalTensi',
          rate: '$_tensiRate%',
          rateColor: _tensiRate >= 80 ? AppColors.primary : AppColors.statusWarning,
        ),
        const SizedBox(height: 16.0),
        // Card 2: Cek Gula Darah
        _buildBentoCard(
          icon: Icons.medical_information_rounded,
          iconBg: AppColors.tertiaryFixed,
          iconColor: AppColors.tertiary,
          statusLabel: _gulaRate >= 80 ? 'Aktif' : 'Perhatian',
          statusBg: _gulaRate >= 80 
              ? AppColors.primary.withValues(alpha: 0.08) 
              : AppColors.statusWarning.withValues(alpha: 0.08),
          statusTextColor: _gulaRate >= 80 ? AppColors.primary : AppColors.statusWarning,
          title: 'Cek Gula Darah',
          subtitle: 'Pemantauan glukosa bulanan.',
          total: '$_totalGula',
          rate: '$_gulaRate%',
          rateColor: _gulaRate >= 80 ? AppColors.primary : AppColors.statusWarning,
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String statusLabel,
    required Color statusBg,
    required Color statusTextColor,
    required String title,
    required String subtitle,
    required String total,
    required String rate,
    required Color rateColor,
  }) {
    return _SpringButton(
      onTap: () {
        if (title == 'Pemeriksaan Tensi') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LayananTensiScreen(),
            ),
          );
          return;
        } else if (title == 'Cek Gula Darah') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LayananGulaDarahScreen(),
            ),
          );
          return;
        }
        AppToast.show(
          context: context,
          message: 'Membuka rincian $title',
          type: AppToastType.info,
        );
      },
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
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Icon & Tag)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Middle Section (Text)
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20.0),
            // Divider
            Divider(
              height: 1.0,
              thickness: 0.5,
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16.0),
            // Bottom Section (Stats)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Selesai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      total,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  rate,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: rateColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Visualisasi Data Tahunan Banner
  Widget _buildVisualisasiBanner() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF004D33),
            Color(0xFF007A51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D33).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.5),
        child: Stack(
          children: [
            // Decorative subtle background grid circles
            Positioned(
              right: -60,
              top: -60,
              width: 220,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 2.0,
                  ),
                ),
              ),
            ),
            // Beautiful interactive mini trend chart on the right side of the card
            Positioned(
              right: -10,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.45,
              height: 180,
              child: const _MiniChartWidget(),
            ),
            // Gradient overlay to fade the chart into the left text
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.5,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF004D33),
                        const Color(0xFF004D33).withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
            // Text & Action Content on the left
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dynamic Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primaryFixed,
                                size: 12,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                'Fitur Analitik',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryFixed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Main Title
                        Text(
                          'Visualisasi Data Tahunan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        // Subtitle
                        Text(
                          'Pantau tren pertumbuhan, kesehatan, dan keaktifan lansia sepanjang tahun dalam bentuk chart interaktif.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12.0),
                        // CTA Action Button with glowing shadow
                        _SpringButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VisualisasiTahunanScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Tren Analitik',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF004D33),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF004D33),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // download Floating Action Button
  Widget _buildDownloadFAB() {
    return _SpringButton(
      onTap: () {
        AppToast.show(
          context: context,
          message: 'Menyiapkan berkas unduhan laporan...',
          type: AppToastType.success,
        );
      },
      child: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.download_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// Beautiful interactive mini trend chart on the right side of the card
class _MiniChartWidget extends StatefulWidget {
  const _MiniChartWidget();

  @override
  State<_MiniChartWidget> createState() => _MiniChartWidgetState();
}

class _MiniChartWidgetState extends State<_MiniChartWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _MiniChartPainter(progress: _animation.value),
        );
      },
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final double progress;

  _MiniChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF8DF7C1).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    // Draw some subtle grid lines
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double gridSpacing = size.height / 4;
    for (int i = 1; i < 4; i++) {
      final double y = i * gridSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Chart points
    final List<Offset> points = [
      Offset(size.width * 0.0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.15),
      Offset(size.width * 1.0, size.height * 0.25),
    ];

    if (points.isEmpty) return;

    // Calculate animated path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Cubic bezier control points for smooth curves
      final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlY1 = p1.dy;
      final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlY2 = p2.dy;

      if (progress >= (i + 1) / (points.length - 1)) {
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p2.dx, p2.dy);
      } else {
        final double segmentProgress = (progress - (i / (points.length - 1))) * (points.length - 1);
        if (segmentProgress > 0) {
          final double currentX = p1.dx + (p2.dx - p1.dx) * segmentProgress;
          final double currentY = p1.dy + (p2.dy - p1.dy) * segmentProgress;
          
          final ctrlX1 = p1.dx + (currentX - p1.dx) / 2;
          final ctrlY1 = p1.dy;
          final ctrlX2 = p1.dx + (currentX - p1.dx) / 2;
          final ctrlY2 = currentY;

          path.cubicTo(ctrlX1, ctrlY1, ctrlX2, ctrlY2, currentX, currentY);
        }
        break;
      }
    }

    // Draw filling gradient under the line
    if (progress > 0) {
      final fillPath = Path.from(path);
      final double lastX = size.width * progress;
      fillPath.lineTo(lastX, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      paintFill.shader = LinearGradient(
        colors: [
          const Color(0xFF8DF7C1).withValues(alpha: 0.18),
          const Color(0xFF8DF7C1).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, paintFill);
    }

    // Draw the glowing line itself
    canvas.drawPath(path, paintLine);

    // Draw glowing circles at some key points (e.g. highest peaks)
    final paintOuterDot = Paint()
      ..color = const Color(0xFF8DF7C1).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final paintInnerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw dot for the peak
    if (progress >= 0.8) {
      final Offset peakPoint = points[4];
      canvas.drawCircle(peakPoint, 8.0, paintOuterDot);
      canvas.drawCircle(peakPoint, 4.0, paintInnerDot);
    }

    // Draw end pulsing point
    if (progress > 0) {
      final double lastX = size.width * progress;
      double lastY = size.height * 0.5;
      for (int i = 0; i < points.length - 1; i++) {
        if (lastX >= points[i].dx && lastX <= points[i + 1].dx) {
          final double ratio = (lastX - points[i].dx) / (points[i + 1].dx - points[i].dx);
          lastY = points[i].dy + (points[i + 1].dy - points[i].dy) * ratio;
          break;
        }
      }
      final Offset currentEnd = Offset(lastX, lastY);
      canvas.drawCircle(currentEnd, 6.0, paintOuterDot);
      canvas.drawCircle(currentEnd, 3.0, paintInnerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Private Spring Button for tactile clicks
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
      lowerBound: 0.95,
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
