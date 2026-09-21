import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../pasien/detail_pasien_screen.dart';
import '../../widgets/app_pull_to_refresh.dart';
import '../../widgets/medical_disclaimer_card.dart';
import '../../constants/medical_guidelines.dart';

class LayananAsamUratScreen extends StatefulWidget {
  const LayananAsamUratScreen({super.key});

  @override
  State<LayananAsamUratScreen> createState() => _LayananAsamUratScreenState();
}

class _LayananAsamUratScreenState extends State<LayananAsamUratScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Normal', 'Waspada', 'Tinggi'];

  List<Map<String, dynamic>> _allPatients = [];
  int _totalPatientsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAsamUratRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAsamUratRecords() async {
    if (!mounted) return;
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
          .not('uric_acid', 'is', null)
          .order('date', ascending: false);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      final List<Map<String, dynamic>> patients = [];
      for (final item in data) {
        final patientMap = item['patients'] as Map<String, dynamic>?;
        if (patientMap == null) continue;

        final uricVal = item['uric_acid'] != null ? num.tryParse(item['uric_acid'].toString())?.toDouble() : null;
        if (uricVal == null) continue;

        final gender = patientMap['gender'] as String? ?? 'Laki-laki';
        final eval = MedicalGuidelines.evaluateUricAcid(uricVal, gender: gender);
        final uricStatus = eval.shortLabel;

        final birthDateStr = patientMap['birth_date'] as String;
        final birthDate = DateTime.parse(birthDateStr);
        final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
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
          'uricAcid': uricVal,
          'uricStatus': uricStatus,
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
            content: Text('Gagal memuat data asam urat: $e'),
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
      final filterMatches = _selectedFilter == 'Semua' || p['uricStatus'] == _selectedFilter;
      return nameMatches && filterMatches;
    }).toList();
  }

  int get _totalAsamUrat => _allPatients.length;
  int get _highCount => _allPatients.where((p) => p['uricStatus'] == 'Tinggi').length;
  int get _warningCount => _allPatients.where((p) => p['uricStatus'] == 'Waspada').length;
  int get _normalCount => _allPatients.where((p) => p['uricStatus'] == 'Normal').length;

  double get _avgUric {
    if (_allPatients.isEmpty) return 5.5;
    final sum = _allPatients.map((p) => p['uricAcid'] as double).reduce((a, b) => a + b);
    return double.parse((sum / _allPatients.length).toStringAsFixed(1));
  }

  double get _normalPct => _allPatients.isEmpty ? 0.75 : _normalCount / _totalAsamUrat;
  double get _warningPct => _allPatients.isEmpty ? 0.15 : _warningCount / _totalAsamUrat;
  double get _highPct => _allPatients.isEmpty ? 0.10 : _highCount / _totalAsamUrat;
  int get _riskRate => _allPatients.isEmpty ? 0 : ((_highCount + _warningCount) / _totalAsamUrat * 100).round();
  int get _uricCoverageRate => _totalPatientsCount > 0 ? (_totalAsamUrat / _totalPatientsCount * 100).clamp(0, 100).round() : 0;

  // Status color helper (Strictly solid, clean)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary;
      case 'Waspada':
        return AppColors.statusWarning;
      case 'Tinggi':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getStatusLightBg(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.primary.withValues(alpha: 0.1);
      case 'Waspada':
        return AppColors.statusWarning.withValues(alpha: 0.1);
      case 'Tinggi':
        return AppColors.error.withValues(alpha: 0.1);
      default:
        return AppColors.primary.withValues(alpha: 0.1);
    }
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
              onRefresh: _fetchAsamUratRecords,
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
                    const MedicalDisclaimerCard(source: MedicalGuidelines.uricAcidSource),
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
                  'Cek Asam Urat',
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
        // Main Bento Block: Total Pemeriksaan Asam Urat
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
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: Color(0xFF00695C),
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
                      '$_uricCoverageRate% Cakupan Warga',
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
                '$_totalAsamUrat',
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
                    ? 'Total skrining asam urat tercatat dari $_totalPatientsCount lansia'
                    : 'Total skrining asam urat tercatat',
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
            // Rata-rata Asam Urat
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
                        Icons.analytics_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Rata-rata Asam Urat',
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
                          '$_avgUric',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'mg/dL',
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

            // Laju Risiko Asam Urat Tinggi
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
                        color: AppColors.statusWarning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.statusWarning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Risiko Asam Urat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.0,
                      children: [
                        Text(
                          '$_riskRate%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _riskRate > 30 ? AppColors.statusWarning : AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Waspada/Tinggi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
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

  // 3. Distribution Graphic Card (Solid Canvas, Clean Horizontal Stacked Breakdown)
  Widget _buildDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
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
              Expanded(
                child: Text(
                  'Distribusi Asam Urat Komunitas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'Standar Medis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Proporsi lansia berdasarkan nilai kadar asam urat darah',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16.0),

          // Solid Multi-Segment Progress Bar (Zero overflow)
          ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Container(
              height: 10.0,
              width: double.infinity,
              color: AppColors.surfaceContainerLow,
              child: (_totalAsamUrat > 0 && (_normalPct > 0 || _warningPct > 0 || _highPct > 0))
                  ? Row(
                      children: [
                        if (_normalPct > 0)
                          Expanded(
                            flex: (_normalPct * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.primary),
                          ),
                        if (_warningPct > 0)
                          Expanded(
                            flex: (_warningPct * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.statusWarning),
                          ),
                        if (_highPct > 0)
                          Expanded(
                            flex: (_highPct * 100).round().clamp(1, 100),
                            child: Container(color: AppColors.error),
                          ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14.0),

          // Legend Items (Expanded, no overflow)
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  label: 'Normal',
                  count: _normalCount,
                  pct: (_normalPct * 100).round(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildLegendItem(
                  label: 'Waspada',
                  count: _warningCount,
                  pct: (_warningPct * 100).round(),
                  color: AppColors.statusWarning,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildLegendItem(
                  label: 'Tinggi',
                  count: _highCount,
                  pct: (_highPct * 100).round(),
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required int pct,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        Padding(
          padding: const EdgeInsets.only(left: 11.0),
          child: Text(
            '$count ($pct%)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 4. Section Header
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Pemeriksaan Lansia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          '${_filteredPatients.length} Pasien',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 5. Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 46.0,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.outline,
            size: 20,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari nama pasien...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.outline,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // 6. Filter Chips
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _SpringButton(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
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
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
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
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.outline,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Tidak ada data pemeriksaan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Coba ubah kata kunci pencarian atau filter status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPatients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final p = _filteredPatients[index];
        final uricVal = p['uricAcid'] as double;
        final status = p['uricStatus'] as String;
        final statusColor = _getStatusColor(status);
        final statusBg = _getStatusLightBg(status);
        final name = p['name'] as String;
        final age = p['age'].toString();
        final checkDate = p['checkDate'] as String;

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

                  // Uric Acid Value Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        uricVal.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
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
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
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
                      final ageStr = p['age'].toString();

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
                                ? 'Asam Urat Normal'
                                : status == 'Waspada'
                                    ? 'Asam Urat Waspada'
                                    : 'Asam Urat Tinggi Perlu Tindakan',
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
