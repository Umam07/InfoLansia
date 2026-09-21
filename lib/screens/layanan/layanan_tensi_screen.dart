import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../pasien/detail_pasien_screen.dart';
import '../../widgets/app_pull_to_refresh.dart';
import '../../widgets/medical_disclaimer_card.dart';
import '../../constants/medical_guidelines.dart';

class LayananTensiScreen extends StatefulWidget {
  const LayananTensiScreen({super.key});

  @override
  State<LayananTensiScreen> createState() => _LayananTensiScreenState();
}

class _LayananTensiScreenState extends State<LayananTensiScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Normal',
    'Waspada (Elevated)',
    'Hipertensi 1',
    'Hipertensi 2',
    'Hipotensi',
  ];

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

        final eval = MedicalGuidelines.evaluateBloodPressure(sys, dia);
        final bpStatus = eval.label;
        final bpShortStatus = eval.shortLabel;

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
          'address': patientMap['address'] ?? '-',
          'gender': gender,
          'birthDate': birthDate,
          'systolic': sys,
          'diastolic': dia,
          'bpStatus': bpStatus,
          'bpShortStatus': bpShortStatus,
          'checkDate': checkDateFormatted,
          'avatarBg': gender == 'Laki-laki' 
              ? const Color(0xFFE8EEF5) 
              : AppColors.secondaryContainer,
          'avatarColor': gender == 'Laki-laki' 
              ? const Color(0xFF2B5B84) 
              : AppColors.primary,
        });
      }

      if (mounted) {
        setState(() {
          _totalPatientsCount = totalPatients;
          _allPatients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      final filterMatches = _selectedFilter == 'Semua' ||
          p['bpStatus'] == _selectedFilter ||
          p['bpShortStatus'] == _selectedFilter ||
          (p['bpStatus'] as String).contains(_selectedFilter);
      return nameMatches && filterMatches;
    }).toList();
  }

  int get _totalTensi => _allPatients.length;
  int get _highCount => _allPatients.where((p) => p['bpShortStatus'] == 'Hipertensi 2').length;
  int get _preCount => _allPatients.where((p) => p['bpShortStatus'] == 'Waspada' || p['bpShortStatus'] == 'Hipertensi 1' || p['bpShortStatus'] == 'Hipotensi').length;
  int get _normalCount => _allPatients.where((p) => p['bpShortStatus'] == 'Normal').length;

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
  int get _hipertensionRate => _allPatients.isEmpty ? 0 : (_highCount / _totalTensi * 100).round();
  int get _tensiCoverageRate => _totalPatientsCount > 0 ? (_totalTensi / _totalPatientsCount * 100).clamp(0, 100).round() : 0;

  // BP Color helper (Strictly solid, clean)
  Color _getBPColor(String status) {
    if (status == 'Normal') return AppColors.primary;
    if (status.contains('Hipertensi 2') || status.contains('Tahap 2') || status == 'Tinggi') {
      return AppColors.error;
    }
    return AppColors.statusWarning;
  }

  // BP Light Background helper
  Color _getBPLightBg(String status) {
    return _getBPColor(status).withValues(alpha: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: AppPullToRefresh(
              onRefresh: _fetchTensiRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  top: 20.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 32.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bento Stats Overview
                    _buildStatsOverview(),
                    const SizedBox(height: 20.0),

                    // Distribution Graphic Card
                    _buildDistributionCard(),
                    const SizedBox(height: 24.0),

                    // Patient List Section Header
                    _buildSectionHeader(),
                    const SizedBox(height: 14.0),

                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 12.0),

                    // Filter Chips
                    _buildFilterChips(),
                    const SizedBox(height: 18.0),

                    // Patient Cards List
                    _buildPatientList(),
                    const SizedBox(height: 16.0),
                    const MedicalDisclaimerCard(source: MedicalGuidelines.bpSource),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top App Bar (Minimalist, Solid, Clean)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              _SpringButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20.0,
                  ),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Text(
                  'Pemeriksaan Tensi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
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

  // 2. Bento Stats Overview (Strictly Zero Glow & Zero Gradient)
  Widget _buildStatsOverview() {
    return Column(
      children: [
        // Main Bento Block: Total Layanan Tensi (Solid Clean Container)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '$_tensiCoverageRate% Cakupan Warga',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                '$_totalTensi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                _totalPatientsCount > 0
                    ? 'Total riwayat skrining tensi tercatat dari $_totalPatientsCount lansia'
                    : 'Total riwayat skrining tensi tercatat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        // Row containing two smaller bento blocks
        Row(
          children: [
            // Rata-rata Tekanan Darah
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: AppColors.textPrimary,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_avgSys/$_avgDia',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'mmHg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Laju Hipertensi (Warning indicator)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_hipertensionRate%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Waspada',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

  // 3. Distribution Graphic Card (Solid Modern Bars, Zero Glow)
  Widget _buildDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
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
                    'Distribusi Tingkat Tekanan Darah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Perbandingan proporsi kondisi tensi lansia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Custom solid bar distribution painter with smooth animation
          SizedBox(
            height: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _BPDistributionSolidPainter(
                    normalPct: _normalPct,
                    preHipertensiPct: _prePct,
                    hipertensiPct: _highPct,
                    normalCount: _normalCount,
                    preCount: _preCount,
                    highCount: _highCount,
                    animVal: value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18.0),

          // Legend details with solid indicators
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16.0,
            runSpacing: 8.0,
            children: [
              _buildLegendItem('Normal (<120/80)', AppColors.primary),
              _buildLegendItem('Pre-Hipertensi (120-139)', AppColors.statusWarning),
              _buildLegendItem('Hipertensi (>=140/90)', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
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

  // 4. Patient List Section Header
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Hasil Pemeriksaan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Text(
            '${_filteredPatients.length} Lansia',
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

  // 5. Search Bar (Clean Solid Input with Clear Button)
  Widget _buildSearchBar() {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama lansia...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.outline,
            fontSize: 13.0,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.outline,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        ),
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 13.0,
        ),
      ),
    );
  }

  // 6. Filter Chips (Solid Pills, Zero Glow)
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
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 7. Patient Cards List
  Widget _buildPatientList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final list = _filteredPatients;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 40,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(height: 10.0),
              Text(
                'Lansia tidak ditemukan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Coba sesuaikan kata kunci pencarian atau filter status.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 12.0,
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
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
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
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Initials Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p['avatarBg'] as Color? ?? AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p['avatarColor'] as Color? ?? AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Name & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3.0),
                        Row(
                          children: [
                            Text(
                              '$age Tahun',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _getBPColor(status),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
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
              const SizedBox(height: 12.0),
              const Divider(
                height: 1.0,
                thickness: 1.0,
                color: AppColors.borderSubtle,
              ),
              const SizedBox(height: 10.0),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Tag Pill (Solid, Clean)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: _getBPLightBg(status),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _getBPColor(status),
                        letterSpacing: 0.3,
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

                      final months = [
                        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                      ];
                      final birthDateStr = '${bDate.day} ${months[bDate.month - 1]} ${bDate.year}';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPasienScreen(
                            id: p['id'] as String?,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
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

// BPDistributionSolidPainter draws a clean, solid, modern bar chart indicating blood pressure levels
class _BPDistributionSolidPainter extends CustomPainter {
  final double normalPct;
  final double preHipertensiPct;
  final double hipertensiPct;
  final int normalCount;
  final int preCount;
  final int highCount;
  final double animVal;

  _BPDistributionSolidPainter({
    required this.normalPct,
    required this.preHipertensiPct,
    required this.hipertensiPct,
    required this.normalCount,
    required this.preCount,
    required this.highCount,
    required this.animVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double bottomPadding = 24.0;
    const double topPadding = 24.0;
    final double chartHeight = height - topPadding - bottomPadding;

    // Draw background subtle grid lines
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 2; i++) {
      final double y = topPadding + i * (chartHeight / 2);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Bar layout metrics
    final double barSpacing = width * 0.12;
    final double barWidth = (width - (4 * barSpacing)) / 3;

    final categories = [
      {
        'label': '${(normalPct * 100).round()}%',
        'sublabel': '$normalCount lansia',
        'value': normalPct,
        'color': AppColors.primary,
      },
      {
        'label': '${(preHipertensiPct * 100).round()}%',
        'sublabel': '$preCount lansia',
        'value': preHipertensiPct,
        'color': AppColors.statusWarning,
      },
      {
        'label': '${(hipertensiPct * 100).round()}%',
        'sublabel': '$highCount lansia',
        'value': hipertensiPct,
        'color': AppColors.error,
      },
    ];

    for (int i = 0; i < 3; i++) {
      final cat = categories[i];
      final double pct = (cat['value'] as double).clamp(0.05, 1.0);
      final Color color = cat['color'] as Color;
      final String label = cat['label'] as String;
      final String sublabel = cat['sublabel'] as String;

      final double x = barSpacing + i * (barWidth + barSpacing);
      final double targetBarHeight = chartHeight * pct;
      final double animatedBarHeight = targetBarHeight * animVal;
      final double y = height - bottomPadding - animatedBarHeight;

      if (animatedBarHeight > 0) {
        // Rounded Solid Bar (Strictly Zero Gradient & Zero Glow)
        final RRect rrect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, animatedBarHeight),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
        );

        final Paint barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rrect, barPaint);

        // Percentage text on top of the bar
        if (animVal >= 0.6) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(x + (barWidth - textPainter.width) / 2, y - textPainter.height - 4.0),
          );

          // Sublabel count below the bar
          final subTextPainter = TextPainter(
            text: TextSpan(
              text: sublabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          subTextPainter.layout();
          subTextPainter.paint(
            canvas,
            Offset(x + (barWidth - subTextPainter.width) / 2, height - bottomPadding + 6.0),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BPDistributionSolidPainter oldDelegate) {
    return oldDelegate.animVal != animVal ||
        oldDelegate.normalPct != normalPct ||
        oldDelegate.preHipertensiPct != preHipertensiPct ||
        oldDelegate.hipertensiPct != hipertensiPct ||
        oldDelegate.normalCount != normalCount;
  }
}

// Private tactile spring button
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
      duration: const Duration(milliseconds: 90),
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
