import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'skrining/skrining_baru_screen.dart';
import 'pasien/detail_pasien_screen.dart';
import '../widgets/app_toast.dart';

class SkriningScreen extends StatefulWidget {
  const SkriningScreen({super.key});

  @override
  State<SkriningScreen> createState() => _SkriningScreenState();
}

class _SkriningScreenState extends State<SkriningScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Belum Skrining',
    'Sudah Skrining',
  ];

  List<Map<String, dynamic>> _allPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final patientResponse = await Supabase.instance.client
          .from('patients')
          .select()
          .order('name', ascending: true);

      final List<Map<String, dynamic>> patients = List<Map<String, dynamic>>.from(patientResponse);

      final screeningResponse = await Supabase.instance.client
          .from('screenings')
          .select('patient_id, date');

      final List<Map<String, dynamic>> screenings = List<Map<String, dynamic>>.from(screeningResponse);

      final Map<String, List<DateTime>> screeningMap = {};
      for (final s in screenings) {
        final pid = s['patient_id'] as String;
        final dateStr = s['date'] as String;
        final date = DateTime.parse(dateStr);
        if (!screeningMap.containsKey(pid)) {
          screeningMap[pid] = [];
        }
        screeningMap[pid]!.add(date);
      }

      if (!mounted) return;
      setState(() {
        _allPatients = patients.map((patient) {
          final pid = patient['id'] as String;
          final birthDateStr = patient['birth_date'] as String;
          final birthDate = DateTime.parse(birthDateStr);
          final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
          final gender = patient['gender'] as String;

          return {
            'id': pid,
            'name': patient['name'] as String,
            'age': age,
            'address': patient['address'] as String,
            'gender': gender,
            'birthDate': birthDate,
            'category': patient['category'] ?? 'Rutin',
            'avatarBg': gender == 'Laki-laki'
                ? const Color(0x1BBA5855)
                : AppColors.secondaryContainer,
            'avatarColor': gender == 'Laki-laki'
                ? AppColors.tertiary
                : AppColors.primary,
            'screenings': screeningMap[pid] ?? <DateTime>[],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppToast.show(
        context: context,
        message: 'Gagal memuat data skrining: $e',
        type: AppToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check if a patient has been screened in the current month & year
  bool _isAlreadyScreenedThisMonth(List<DateTime> screenings) {
    final now = DateTime.now();
    return screenings.any((date) => date.year == now.year && date.month == now.month);
  }

  // Calculate statistics dynamically
  int get _totalPatients => _allPatients.length;
  int get _screenedCount => _allPatients.where((p) => _isAlreadyScreenedThisMonth(p['screenings'] as List<DateTime>)).length;
  int get _remainingCount => _totalPatients - _screenedCount;

  List<Map<String, dynamic>> get _filteredPatients {
    return _allPatients.where((patient) {
      final matchesSearch =
          patient['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final screenings = patient['screenings'] as List<DateTime>;
      final isScreened = _isAlreadyScreenedThisMonth(screenings);

      if (_selectedCategory == 'Belum Skrining') {
        return !isScreened;
      } else if (_selectedCategory == 'Sudah Skrining') {
        return isScreened;
      }
      return true; // 'Semua'
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: 120.0, // Clear space for bottom bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsOverview(),
                  const SizedBox(height: 32.0),
                  _buildSectionTitle(),
                  const SizedBox(height: 16.0),
                  _buildSearchAndFilter(),
                  const SizedBox(height: 20.0),
                  _buildPatientList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top header matching premium styling
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
              Expanded(
                child: Text(
                  'Skrining Kesehatan',
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

  // Bento-style Stats Overview
  Widget _buildStatsOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16.0) / 2;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Terpantau Card
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 107, 71, 0.04),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 24.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Warga Terpantau',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$_totalPatients',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Belum Skrining Card
            Container(
              width: cardWidth,
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
                children: [
                  Icon(
                    Icons.pending_actions_rounded,
                    color: _remainingCount > 0 ? AppColors.statusWarning : AppColors.primary,
                    size: 24.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Belum Skrining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$_remainingCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _remainingCount > 0 ? AppColors.statusWarning : AppColors.primary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      'Daftar Skrining Warga',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }

  // Search & Filter
  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52.0,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama pasien...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppColors.outline,
                  fontSize: 14.0,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.outline,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.outline),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.onSurface,
                fontSize: 14.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        _buildDropdownFilter(),
      ],
    );
  }

  Widget _buildDropdownFilter() {
    return Container(
      height: 52.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: const Icon(
            Icons.filter_list_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.onSurface,
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
          ),
          borderRadius: BorderRadius.circular(16.0),
          dropdownColor: AppColors.surfaceContainerLowest,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          items: _categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }
    final filtered = _filteredPatients;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Column(
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 48.0,
                color: AppColors.outlineVariant,
              ),
              const SizedBox(height: 12.0),
              Text(
                'Pasien tidak ditemukan',
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
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final patient = filtered[index];
        return _buildPatientCard(patient);
      },
    );
  }

  // Patient Card with dynamic action button
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] as String;
    final age = patient['age'] as String;
    final address = patient['address'] as String;
    final avatarBg = patient['avatarBg'] as Color;
    final avatarColor = patient['avatarColor'] as Color;
    final List<DateTime> screenings = patient['screenings'] as List<DateTime>;
    final isScreened = _isAlreadyScreenedThisMonth(screenings);

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
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
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
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: avatarColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16.0),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Age Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            '$age Thn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16.0,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              height: 1.3,
                            ),
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
          Container(
            height: 1.0,
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              // Show checkup status or action buttons
              if (isScreened) ...[
                // Already Screened Status
                Expanded(
                  child: Container(
                    height: 40.0,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Premium light green
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'SUDAH SKRINING BULAN INI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                // See Detail button
                _SpringButton(
                  onTap: () {
                    _navigateToDetail(patient);
                  },
                  child: Container(
                    height: 40.0,
                    width: 48.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ] else ...[
                // Not Screened yet: Start screening action button
                Expanded(
                  child: _SpringButton(
                    onTap: () async {
                      // Navigate to new screening
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SkriningBaruScreen(
                            patientId: patient['id'] as String,
                            name: name,
                            age: age,
                            gender: patient['gender'] as String,
                            existingScreenings: screenings,
                          ),
                        ),
                      );

                      if (result == true && mounted) {
                        _fetchPatients();
                        AppToast.show(
                          context: context,
                          message: 'Hasil skrining untuk $name berhasil disimpan',
                          type: AppToastType.success,
                        );
                      }
                    },
                    child: Container(
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white,
                            size: 16.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Mulai Skrining',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Navigate to patient detail
  void _navigateToDetail(Map<String, dynamic> patient) async {
    final name = patient['name'] as String;
    final age = patient['age'] as String;
    final address = patient['address'] as String;
    final gender = patient['gender'] as String;
    final bDate = patient['birthDate'] as DateTime;

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final birthDateStr = '${bDate.day} ${months[bDate.month - 1]} ${bDate.year}';

    final healthStatus = name == 'Siti Rahayu'
        ? 'Hipertensi Terkontrol'
        : name == 'Bambang Wijaya'
            ? 'Diabetes Terkontrol'
            : 'Kesehatan Stabil';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPasienScreen(
          id: patient['id'] as String?,
          name: name,
          age: age,
          gender: gender,
          address: address,
          birthDate: birthDateStr,
          birthDateTime: bDate,
          healthStatus: healthStatus,
          avatarBg: patient['avatarBg'] as Color?,
          avatarColor: patient['avatarColor'] as Color?,
        ),
      ),
    );
    if (mounted) {
      _fetchPatients();
    }
  }
}

// Spring button component for high-fidelity tactile feel
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
