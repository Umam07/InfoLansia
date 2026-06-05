import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'detail_pasien_screen.dart';

class LayananGulaDarahScreen extends StatefulWidget {
  const LayananGulaDarahScreen({super.key});

  @override
  State<LayananGulaDarahScreen> createState() => _LayananGulaDarahScreenState();
}

class _LayananGulaDarahScreenState extends State<LayananGulaDarahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Normal', 'Pre-Diabetes', 'Diabetes'];

  // Mock patient data with specific glucose parameters matching general list
  final List<Map<String, dynamic>> _patients = [
    {
      'name': 'Siti Rahayu',
      'age': '68',
      'address': 'Jl. Melati No. 42, RT 05/02',
      'gender': 'Perempuan',
      'birthDate': DateTime(1955, 4, 14),
      'glucose': 110,
      'sugarStatus': 'Normal',
      'checkDate': '25 Mei 2026',
      'avatarBg': AppColors.secondaryContainer,
      'avatarColor': AppColors.primary,
    },
    {
      'name': 'Bambang Wijaya',
      'age': '72',
      'address': 'Perum Griya Indah, Blok C9',
      'gender': 'Laki-laki',
      'birthDate': DateTime(1951, 11, 23),
      'glucose': 205,
      'sugarStatus': 'Diabetes',
      'checkDate': '24 Mei 2026',
      'avatarBg': const Color(0x1BBA5855),
      'avatarColor': AppColors.tertiary,
    },
    {
      'name': 'Aminah Sulastri',
      'age': '65',
      'address': 'Kp. Baru, Gg. Sayur No. 12',
      'gender': 'Perempuan',
      'birthDate': DateTime(1958, 9, 8),
      'glucose': 106,
      'sugarStatus': 'Normal',
      'checkDate': '23 Mei 2026',
      'avatarBg': AppColors.secondaryContainer,
      'avatarColor': AppColors.primary,
    },
    {
      'name': 'Supardi',
      'age': '70',
      'address': 'Jl. Anggrek Raya No. 15, RT 01/04',
      'gender': 'Laki-laki',
      'birthDate': DateTime(1953, 7, 19),
      'glucose': 152,
      'sugarStatus': 'Pre-Diabetes',
      'checkDate': '22 Mei 2026',
      'avatarBg': const Color(0xFFE3F2FD),
      'avatarColor': Colors.blue,
    },
    {
      'name': 'Kustini',
      'age': '67',
      'address': 'Kp. Salak No. 88, RT 03/05',
      'gender': 'Perempuan',
      'birthDate': DateTime(1956, 12, 5),
      'glucose': 114,
      'sugarStatus': 'Normal',
      'checkDate': '20 Mei 2026',
      'avatarBg': AppColors.secondaryContainer,
      'avatarColor': AppColors.primary,
    },
    {
      'name': 'Suryadi',
      'age': '69',
      'address': 'Jl. Kenanga No. 7, RT 02/03',
      'gender': 'Laki-laki',
      'birthDate': DateTime(1957, 3, 10),
      'glucose': 148,
      'sugarStatus': 'Pre-Diabetes',
      'checkDate': '18 Mei 2026',
      'avatarBg': const Color(0xFFFFF3E0),
      'avatarColor': Colors.orange,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter logic
  List<Map<String, dynamic>> get _filteredPatients {
    return _patients.where((p) {
      final nameMatches = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final filterMatches = _selectedFilter == 'Semua' || p['sugarStatus'] == _selectedFilter;
      return nameMatches && filterMatches;
    }).toList();
  }

  // Status color helper
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary;
      case 'Pre-Diabetes':
        return AppColors.statusWarning;
      case 'Diabetes':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  // Status light background helper
  Color _getStatusLightBg(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary.withValues(alpha: 0.08);
      case 'Pre-Diabetes':
        return AppColors.statusWarning.withValues(alpha: 0.08);
      case 'Diabetes':
        return AppColors.error.withValues(alpha: 0.08);
      default:
        return AppColors.primary.withValues(alpha: 0.08);
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 20.0,
          left: 20.0,
          right: 20.0,
          bottom: 24.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bento Stats Overview
            _buildStatsOverview(),
            const SizedBox(height: 24.0),

            // Distribution Graphic Card
            _buildDistributionCard(),
            const SizedBox(height: 32.0),

            // Section Header
            _buildSectionHeader(),
            const SizedBox(height: 16.0),

            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16.0),

            // Filter Chips
            _buildFilterChips(),
            const SizedBox(height: 20.0),

            // Patient cards list
            _buildPatientList(),
          ],
        ),
      ),
    );
  }

  // App Bar
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
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
                  'Cek Gula Darah',
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
              const SizedBox(width: 40.0), // Spacer to balance back button
            ],
          ),
        ),
      ),
    );
  }

  // Bento Stats Grid
  Widget _buildStatsOverview() {
    return Column(
      children: [
        // Main Bento Stats Card
        Container(
          width: double.infinity,
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
              Positioned(
                right: -30,
                bottom: -30,
                width: 120,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.medical_information_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 28,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Mei 2026',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Total Cek Gula Darah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '482',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.primaryFixed,
                        size: 16,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '76% dari target bulanan selesai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
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
        const SizedBox(height: 14.0),

        // Row containing two smaller bento blocks
        Row(
          children: [
            // Rata-rata Glukosa
            Expanded(
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
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Rata-rata Glukosa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '112',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'mg/dL (Normal)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14.0),

            // Pre-Diabetes + Diabetes rate
            Expanded(
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
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bubble_chart_rounded,
                        color: AppColors.tertiary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Butuh Perhatian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '24%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Laju Risiko Tinggi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Distribution Card
  Widget _buildDistributionCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Gula Darah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Distribusi glukosa lansia di komunitas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 28.0),

          // Bar distribution CustomPainter
          SizedBox(
            height: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _GlucoseDistributionPainter(
                    normalPct: 0.76,
                    preDiabetesPct: 0.18,
                    diabetesPct: 0.06,
                    animVal: value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Normal (<140)', AppColors.primary),
              _buildLegendItem('Pre-Diabetes (140-199)', AppColors.statusWarning),
              _buildLegendItem('Diabetes (>=200)', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // List section header
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Hasil Lansia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            '${_filteredPatients.length} Orang',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Search input
  Widget _buildSearchBar() {
    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama lansia...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.outline,
            fontSize: 14.0,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.outline,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.onSurface,
          fontSize: 14.0,
        ),
      ),
    );
  }

  // Filter Chips
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _SpringButton(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Patient Card Lists
  Widget _buildPatientList() {
    final list = _filteredPatients;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(height: 12.0),
              Text(
                'Lansia tidak ditemukan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14.0),
      itemBuilder: (context, index) {
        final p = list[index];
        final String name = p['name'];
        final String age = p['age'];
        final String status = p['sugarStatus'];
        final int glucose = p['glucose'];
        final String checkDate = p['checkDate'];

        return Container(
          padding: const EdgeInsets.all(16.0),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beautiful Initials Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p['avatarBg'] as Color? ?? AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: p['avatarColor'] as Color? ?? AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // Name & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Text(
                              '$age Thn',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              width: 3.0,
                              height: 3.0,
                              decoration: const BoxDecoration(
                                color: AppColors.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              checkDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Glucose large text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$glucose',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(status),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'mg/dL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              Divider(
                height: 1.0,
                thickness: 0.5,
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12.0),

              // Action row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Tag Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getStatusLightBg(status),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _getStatusColor(status),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // View detail action button
                  _SpringButton(
                    onTap: () {
                      final address = p['address'] as String;
                      final gender = p['gender'] as String;
                      final bDate = p['birthDate'] as DateTime;
                      final ageStr = p['age'] as String;

                      // Format birthdate
                      final months = [
                        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                      ];
                      final birthDateStr = '${bDate.day} ${months[bDate.month - 1]} ${bDate.year}';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPasienScreen(
                            name: name,
                            age: ageStr,
                            gender: gender,
                            address: address,
                            birthDate: birthDateStr,
                            birthDateTime: bDate,
                            healthStatus: status == 'Normal'
                                ? 'Diabetes Terkontrol'
                                : status == 'Pre-Diabetes'
                                    ? 'Pre-Diabetes Dipantau'
                                    : 'Diabetes Perlu Perhatian',
                            avatarBg: p['avatarBg'] as Color?,
                            avatarColor: p['avatarColor'] as Color?,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Lihat Detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// GlucoseDistributionPainter draws a premium vertical bar chart indicating blood sugar levels
class _GlucoseDistributionPainter extends CustomPainter {
  final double normalPct;
  final double preDiabetesPct;
  final double diabetesPct;
  final double animVal;

  _GlucoseDistributionPainter({
    required this.normalPct,
    required this.preDiabetesPct,
    required this.diabetesPct,
    required this.animVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double padding = 16.0;

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = AppColors.onSurface.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final double y = padding + i * (height - 2 * padding) / 3;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Bar variables
    final double barSpacing = width * 0.12;
    final double barWidth = (width - (4 * barSpacing)) / 3;

    final categories = [
      {'label': '76%', 'value': normalPct, 'color1': const Color(0xFF00875A), 'color2': AppColors.primary},
      {'label': '18%', 'value': preDiabetesPct, 'color1': const Color(0xFFF59E0B), 'color2': AppColors.statusWarning},
      {'label': '6%', 'value': diabetesPct, 'color1': const Color(0xFFEF4444), 'color2': AppColors.error},
    ];

    for (int i = 0; i < 3; i++) {
      final cat = categories[i];
      final double pct = cat['value'] as double;
      final Color color1 = cat['color1'] as Color;
      final Color color2 = cat['color2'] as Color;
      final String label = cat['label'] as String;

      // Position calculations
      final double x = barSpacing + i * (barWidth + barSpacing);
      final double targetBarHeight = (height - 2 * padding) * pct;
      final double animatedBarHeight = targetBarHeight * animVal;
      final double y = height - padding - animatedBarHeight;

      if (animatedBarHeight > 0) {
        // Draw elegant rounded bar
        final RRect rrect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, animatedBarHeight),
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        );

        final Paint barPaint = Paint()
          ..shader = LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, y, barWidth, animatedBarHeight))
          ..style = PaintingStyle.fill;

        // Draw shadow glow behind the bar
        canvas.drawRRect(
          rrect.shift(const Offset(0, 3)),
          Paint()
            ..color = color2.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
            ..style = PaintingStyle.fill,
        );

        canvas.drawRRect(rrect, barPaint);

        // Draw percentage text on top of the bar
        if (animVal >= 0.7) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                color: color2,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(x + (barWidth - textPainter.width) / 2, y - textPainter.height - 6.0),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlucoseDistributionPainter oldDelegate) {
    return oldDelegate.animVal != animVal ||
        oldDelegate.normalPct != normalPct ||
        oldDelegate.preDiabetesPct != preDiabetesPct ||
        oldDelegate.diabetesPct != diabetesPct;
  }
}

// private spring button to give nice tactile clicks
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
      duration: const Duration(milliseconds: 80),
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
