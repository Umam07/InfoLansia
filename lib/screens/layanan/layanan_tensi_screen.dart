import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../pasien/detail_pasien_screen.dart';

class LayananTensiScreen extends StatefulWidget {
  const LayananTensiScreen({super.key});

  @override
  State<LayananTensiScreen> createState() => _LayananTensiScreenState();
}

class _LayananTensiScreenState extends State<LayananTensiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Normal', 'Pre-Hipertensi', 'Hipertensi'];

  List<Map<String, dynamic>> _allPatients = [];
  int _totalPatientsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTensiRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTensiRecords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final patientsResponse = await Supabase.instance.client
          .from('patients')
          .select('id');
      final totalPatients = patientsResponse.length;

      final response = await Supabase.instance.client
          .from('screenings')
          .select('*, patients(*)')
          .not('blood_pressure', 'is', null)
          .order('date', ascending: false);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      final List<Map<String, dynamic>> patients = [];
      for (final item in data) {
        final patientMap = item['patients'] as Map<String, dynamic>?;
        if (patientMap == null) continue;

        final bp = item['blood_pressure'] as String;
        final parts = bp.split('/');
        if (parts.length != 2) continue;

        final sys = int.tryParse(parts[0].trim());
        final dia = int.tryParse(parts[1].trim());
        if (sys == null || dia == null) continue;

        String bpStatus = 'Normal';
        if (sys >= 140 || dia >= 90) {
          bpStatus = 'Hipertensi';
        } else if (sys >= 120 || dia >= 80) {
          bpStatus = 'Pre-Hipertensi';
        }

        final birthDateStr = patientMap['birth_date'] as String;
        final birthDate = DateTime.parse(birthDateStr);
        final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
        final gender = patientMap['gender'] as String;
        final dateStr = item['date'] as String;
        final date = DateTime.parse(dateStr);
        
        final months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        final checkDateFormatted = '${date.day} ${months[date.month - 1]} ${date.year}';

        patients.add({
          'id': patientMap['id'],
          'name': patientMap['name'],
          'age': age,
          'address': patientMap['address'],
          'gender': gender,
          'birthDate': birthDate,
          'systolic': sys,
          'diastolic': dia,
          'bpStatus': bpStatus,
          'checkDate': checkDateFormatted,
          'avatarBg': gender == 'Laki-laki' 
              ? const Color(0x1BBA5855) 
              : AppColors.secondaryContainer,
          'avatarColor': gender == 'Laki-laki' 
              ? AppColors.tertiary 
              : AppColors.primary,
        });
      }

      setState(() {
        _totalPatientsCount = totalPatients;
        _allPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data tensi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Filter logic
  List<Map<String, dynamic>> get _filteredPatients {
    return _allPatients.where((p) {
      final nameMatches = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final filterMatches = _selectedFilter == 'Semua' || p['bpStatus'] == _selectedFilter;
      return nameMatches && filterMatches;
    }).toList();
  }

  int get _totalTensi => _allPatients.length;
  int get _highCount => _allPatients.where((p) => p['bpStatus'] == 'Hipertensi').length;
  int get _preCount => _allPatients.where((p) => p['bpStatus'] == 'Pre-Hipertensi').length;
  int get _normalCount => _allPatients.where((p) => p['bpStatus'] == 'Normal').length;

  int get _avgSys {
    if (_allPatients.isEmpty) return 120;
    final sum = _allPatients.map((p) => p['systolic'] as int).reduce((a, b) => a + b);
    return (sum / _allPatients.length).round();
  }

  int get _avgDia {
    if (_allPatients.isEmpty) return 80;
    final sum = _allPatients.map((p) => p['diastolic'] as int).reduce((a, b) => a + b);
    return (sum / _allPatients.length).round();
  }

  double get _normalPct => _allPatients.isEmpty ? 0.60 : _normalCount / _totalTensi;
  double get _prePct => _allPatients.isEmpty ? 0.25 : _preCount / _totalTensi;
  double get _highPct => _allPatients.isEmpty ? 0.15 : _highCount / _totalTensi;
  int get _hipertensionRate => _allPatients.isEmpty ? 28 : (_highCount / _totalTensi * 100).round();
  int get _tensiRate => _totalPatientsCount > 0 ? (_totalTensi / _totalPatientsCount * 100).round() : 0;

  // BP Color helper
  Color _getBPColor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary;
      case 'Pre-Hipertensi':
        return AppColors.statusWarning;
      case 'Hipertensi':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  // BP Light Background helper
  Color _getBPLightBg(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary.withValues(alpha: 0.08);
      case 'Pre-Hipertensi':
        return AppColors.statusWarning.withValues(alpha: 0.08);
      case 'Hipertensi':
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

            // Patient List Section Header
            _buildSectionHeader(),
            const SizedBox(height: 16.0),

            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16.0),

            // Filter Chips
            _buildFilterChips(),
            const SizedBox(height: 20.0),

            // Patient Cards List
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
                  'Pemeriksaan Tensi',
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
        // Main Bento Stats (Total checked)
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
                        Icons.monitor_heart_rounded,
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
                          'Info Lansia',
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
                    'Total Layanan Tensi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$_totalTensi',
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
                        '$_tensiRate% dari target bulanan selesai',
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
            // Rata-rata Tekanan
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
                        Icons.insights_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Rata-rata Tekanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$_avgSys/$_avgDia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'mmHg',
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

            // Laju Hipertensi (Warning indicator)
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
                        Icons.warning_amber_rounded,
                        color: AppColors.tertiary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Laju Hipertensi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$_hipertensionRate%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Butuh Perhatian',
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

  // Distribution Graphic Card
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
                    'Status Kesehatan Tensi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Distribusi tingkat tekanan darah lansia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 28.0),

          // Custom bar distribution painter with animations
          SizedBox(
            height: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _BPDistributionPainter(
                    normalPct: _normalPct,
                    preHipertensiPct: _prePct,
                    hipertensiPct: _highPct,
                    animVal: value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16.0),

          // Legend details
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16.0,
            runSpacing: 8.0,
            children: [
              _buildLegendItem('Normal (<120/80)', AppColors.primary),
              _buildLegendItem('Pre-Hipertensi (120-139/80-89)', AppColors.statusWarning),
              _buildLegendItem('Hipertensi (>=140/90)', AppColors.error),
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

  // Patient List Section Header
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

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
        final String status = p['bpStatus'];
        final int sys = p['systolic'];
        final int dia = p['diastolic'];
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

                  // Blood Pressure large text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sys/$dia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _getBPColor(status),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'mmHg',
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

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Tag Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getBPLightBg(status),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _getBPColor(status),
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
                                ? 'Kesehatan Normal'
                                : status == 'Pre-Hipertensi'
                                    ? 'Pre-Hipertensi Terkontrol'
                                    : 'Hipertensi Perlu Perhatian',
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

// BPDistributionPainter draws a premium vertical bar chart indicating blood pressure levels
class _BPDistributionPainter extends CustomPainter {
  final double normalPct;
  final double preHipertensiPct;
  final double hipertensiPct;
  final double animVal;

  _BPDistributionPainter({
    required this.normalPct,
    required this.preHipertensiPct,
    required this.hipertensiPct,
    required this.animVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double padding = 16.0;

    // Draw background grid lines (3 horizontal dashed or thin lines)
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
      {'label': '60%', 'value': normalPct, 'color1': const Color(0xFF00875A), 'color2': AppColors.primary},
      {'label': '25%', 'value': preHipertensiPct, 'color1': const Color(0xFFF59E0B), 'color2': AppColors.statusWarning},
      {'label': '15%', 'value': hipertensiPct, 'color1': const Color(0xFFEF4444), 'color2': AppColors.error},
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
  bool shouldRepaint(covariant _BPDistributionPainter oldDelegate) {
    return oldDelegate.animVal != animVal ||
        oldDelegate.normalPct != normalPct ||
        oldDelegate.preHipertensiPct != preHipertensiPct ||
        oldDelegate.hipertensiPct != hipertensiPct;
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
