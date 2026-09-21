import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

import 'pasien/detail_pasien_screen.dart';
import 'pasien/tambah_lansia_screen.dart';
import 'pasien/edit_lansia_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/sync_status_badge.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';
import '../services/network_connectivity_service.dart';

class PasienScreen extends StatefulWidget {

  const PasienScreen({super.key});

  @override
  State<PasienScreen> createState() => _PasienScreenState();
}

class _PasienScreenState extends State<PasienScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<String> get _categories => const [
    'Semua',
    'Laki-laki',
    'Perempuan',
    'Hipertensi',
    'Diabetes',
  ];

  List<Map<String, dynamic>> _allPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoading = _allPatients.isEmpty;
    });

    try {
      // 1. Ambil data lokal terlebih dahulu untuk render instan
      final localPatients = await AppDatabase.instance.getAllPatients();
      final localScreenings = await AppDatabase.instance.getAllScreenings();
      if (localPatients.isNotEmpty) {
        _populateFromLocal(localPatients, localScreenings);
      }

      // 2. Jika online, jalankan sinkronisasi dua arah
      if (NetworkConnectivityService.instance.isOnline.value) {
        await SyncService.instance.syncAll();
        final freshPatients = await AppDatabase.instance.getAllPatients();
        final freshScreenings = await AppDatabase.instance.getAllScreenings();
        _populateFromLocal(freshPatients, freshScreenings);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Jika terjadi galat jaringan, tetap pertahankan data lokal
      final fallbackPatients = await AppDatabase.instance.getAllPatients();
      final fallbackScreenings = await AppDatabase.instance.getAllScreenings();
      if (fallbackPatients.isNotEmpty) {
        _populateFromLocal(fallbackPatients, fallbackScreenings);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFromLocal(List<LocalPatient> patients, List<LocalScreening> screenings) {
    final Map<String, LocalScreening> latestScreeningMap = {};
    for (final s in screenings) {
      final pid = s.patientId;
      try {
        final date = DateTime.parse(s.date);
        final currentLatest = latestScreeningMap[pid];
        if (currentLatest == null || date.isAfter(DateTime.parse(currentLatest.date))) {
          latestScreeningMap[pid] = s;
        }
      } catch (_) {}
    }

    final mappedPatients = patients.map((patient) {
      final pid = patient.id;
      DateTime birthDate;
      try {
        birthDate = DateTime.parse(patient.birthDate);
      } catch (_) {
        birthDate = DateTime.now();
      }
      final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
      final gender = patient.gender;

      String healthStatus = 'Kesehatan Stabil';
      final latestS = latestScreeningMap[pid];
      if (latestS != null) {
        final bpStr = latestS.bloodPressure;
        final sugarVal = latestS.bloodSugar;

        bool hasHighBP = false;
        bool hasPreBP = false;
        if (bpStr != null && bpStr.contains('/')) {
          final parts = bpStr.split('/');
          if (parts.length == 2) {
            final sys = int.tryParse(parts[0].trim());
            final dia = int.tryParse(parts[1].trim());
            if (sys != null && dia != null) {
              if (sys >= 140 || dia >= 90) {
                hasHighBP = true;
              } else if (sys >= 120 || dia >= 80) {
                hasPreBP = true;
              }
            }
          }
        }

        bool hasHighSugar = sugarVal != null && sugarVal >= 200;
        bool hasPreSugar = sugarVal != null && sugarVal >= 140;

        if (hasHighBP || hasHighSugar) {
          healthStatus = 'Perlu Perhatian';
        } else if (hasPreBP || hasPreSugar) {
          healthStatus = 'Pantauan Sedang';
        } else {
          healthStatus = 'Kesehatan Stabil';
        }
      } else {
        healthStatus = 'Belum Ada Skrining';
      }

      return {
        'id': pid,
        'name': patient.name,
        'age': age,
        'address': patient.address,
        'gender': gender,
        'birthDate': birthDate,
        'category': patient.category == 'Rutin' ? '' : patient.category,
        'healthStatus': healthStatus,

        'isSynced': patient.isSynced,
        'createdAt': patient.updatedAt,
        'avatarBg': gender == 'Laki-laki'
            ? AppColors.tertiary.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12),
        'avatarColor': gender == 'Laki-laki'
            ? AppColors.tertiary
            : AppColors.primary,
      };
    }).toList();

    if (mounted) {
      setState(() {
        _allPatients = mappedPatients;
        _isLoading = false;
      });
    }
  }

  // Statistics for patient management
  int get _totalPatients => _allPatients.length;

  int get _maleCount => _allPatients.where((p) => p['gender'] == 'Laki-laki').length;
  int get _femaleCount => _allPatients.where((p) => p['gender'] == 'Perempuan').length;

  List<Map<String, dynamic>> get _filteredPatients {
    return _allPatients.where((patient) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          patient['name'].toString().toLowerCase().contains(q) ||
          patient['address'].toString().toLowerCase().contains(q);
      if (!matchesSearch) return false;

      if (_selectedCategory == 'Semua') return true;
      if (_selectedCategory == 'Laki-laki' || _selectedCategory == 'Perempuan') {
        return patient['gender'] == _selectedCategory;
      }
      return patient['category'] == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        body: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: Column(
                children: [
                  _buildHeader(),
                  const SyncStatusBanner(),
                  Expanded(
                    child: AppPullToRefresh(
                      onRefresh: () async {
                        await SyncService.instance.syncAll();
                        await _fetchPatients();
                      },
                      child: SingleChildScrollView(

                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 20.0,
                          bottom: isKeyboardOpen
                              ? 24.0
                              : 140.0 + MediaQuery.of(context).padding.bottom, // Space for BottomNavBar & FAB
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Bento Demographic Stats (Patient Management)
                            _buildStatsOverview(),
                            const SizedBox(height: 22.0),

                            // 2. Section Header
                            _buildPatientListHeader(),
                            const SizedBox(height: 12.0),

                            // 3. Search Bar
                            _buildSearchBar(),
                            const SizedBox(height: 12.0),

                            // 4. Filter Chips
                            _buildFilterChips(),
                            const SizedBox(height: 16.0),

                            // 5. Patient List
                            _buildPatientList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contextual FAB for adding a patient (animates offscreen while typing/searching)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              right: 20.0,
              bottom: isKeyboardOpen
                  ? -80.0
                  : 108.0 + MediaQuery.of(context).padding.bottom, // Just above BottomNavigationBar
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                opacity: isKeyboardOpen ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: isKeyboardOpen,
                  child: _buildAddFAB(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Widget (TopAppBar style matching app branding)
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
                  'Data Pasien',
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

  // Bento Demographic Stats (Patient Management Overview, Zero Glow & Zero Gradient)
  Widget _buildStatsOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 14.0) / 2;
        return Row(
          children: [
            // Card 1: Total Lansia Terdaftar
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    'Total Lansia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$_totalPatients',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Warga RW 06 Terdaftar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14.0),

            // Card 2: Demografi Gender (Laki-laki & Perempuan)
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16.0),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.wc_rounded,
                      color: AppColors.textPrimary,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    'Jenis Kelamin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_maleCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tertiary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          'L',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '•',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '$_femaleCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          'P',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$_maleCount Laki-laki • $_femaleCount Perempuan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Patient List Title Header with Count Badge
  Widget _buildPatientListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Warga Lansia',
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

  // Full-width Search Bar
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
        focusNode: _searchFocusNode,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama atau alamat warga...',
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
                    setState(() {
                      _searchController.clear();
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

  // Filter Chips (Horizontal Scrollable, Solid Active States, Zero Glow)
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        key: ValueKey('pasien_chips_${_categories.length}_${_categories.join('_')}'),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return _SpringButton(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Dynamic Patient List
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
                'Data pasien tidak ditemukan',
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

  // Clean Patient Management Card with Detail, Edit, and Delete Actions
  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] as String;
    final age = patient['age'] as String;
    final address = patient['address'] as String;
    final gender = patient['gender'] as String;
    final category = patient['category'] as String? ?? '';
    final isMale = gender == 'Laki-laki';
    final isSynced = patient['isSynced'] as bool? ?? true;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Initials
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMale 
                      ? AppColors.tertiary.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isMale ? AppColors.tertiary : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14.0),

              // Patient Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isSynced) ...[
                                const SizedBox(width: 6.0),
                                const SyncStatusBadge(isSynced: false),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // Age & Gender Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$age Tahun',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              isMale ? 'Laki-laki' : 'Perempuan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isMale ? AppColors.tertiary : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14.0,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category == 'Hipertensi' || category == 'Diabetes') ...[
                          const SizedBox(width: 6.0),
                          // Condition pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: category == 'Hipertensi'
                                  ? AppColors.statusWarning.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: category == 'Hipertensi'
                                    ? AppColors.statusWarning
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Divider
          Container(
            height: 1.0,
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12.0),

          // Action Buttons: Detail, Edit, Hapus
          Row(
            children: [
              // 1. Detail Button (Primary solid)
              Expanded(
                flex: 5,
                child: _SpringButton(
                  onTap: () => _navigateToDetail(patient),
                  child: Container(
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'Detail',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // 2. Edit Button (Outline/Surface)
              Expanded(
                flex: 4,
                child: _SpringButton(
                  onTap: () => _navigateToEdit(patient),
                  child: Container(
                    height: 38.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          'Edit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // 3. Hapus Button (Danger/Error soft)
              _SpringButton(
                onTap: () => _showDeleteConfirmationDialog(patient),
                child: Container(
                  height: 38.0,
                  width: 38.0,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Navigation to Detail Screen
  Future<void> _navigateToDetail(Map<String, dynamic> patient) async {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final name = patient['name'] as String;
    final age = patient['age'] as String;
    final address = patient['address'] as String;
    final gender = patient['gender'] as String;
    final bDate = patient['birthDate'] as DateTime?;

    String birthDateStr = '';
    if (bDate != null) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      birthDateStr = '${bDate.day} ${months[bDate.month - 1]} ${bDate.year}';
    }

    final healthStatus = patient['healthStatus'] as String? ?? 'Kesehatan Stabil';

    final result = await Navigator.push<Map<String, dynamic>>(
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
          index: _allPatients.indexOf(patient),
          avatarBg: patient['avatarBg'] as Color?,
          avatarColor: patient['avatarColor'] as Color?,
          createdAt: patient['createdAt'] as DateTime?,
        ),
      ),
    );

    if (mounted) {
      _searchFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }

    if (result != null && mounted) {
      _fetchPatients();
    }
  }

  // Navigation to Edit Screen
  Future<void> _navigateToEdit(Map<String, dynamic> patient) async {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final gender = patient['gender'] as String;
    final birthDate = patient['birthDate'] as DateTime? ?? DateTime(1955, 1, 1);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditLansiaScreen(
          id: patient['id'] as String?,
          index: _allPatients.indexOf(patient),
          initialName: patient['name'] as String,
          initialGender: gender,
          initialBirthDate: birthDate,
          initialAddress: patient['address'] as String,
          avatarBg: patient['avatarBg'] as Color?,
          avatarColor: patient['avatarColor'] as Color?,
          createdAt: patient['createdAt'] as DateTime?,
        ),
      ),
    );

    if (mounted) {
      _searchFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }

    if (result != null && mounted) {
      _fetchPatients();
    }
  }

  // Delete Confirmation Dialog (Zero Glow, Safe Confirmation)
  void _showDeleteConfirmationDialog(Map<String, dynamic> patient) {
    final patientId = patient['id'] as String?;
    final name = patient['name'] as String;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    'Hapus Data Pasien?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Apakah Anda yakin ingin menghapus data "$name"? Semua riwayat skrining pasien ini juga akan terhapus dari sistem.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: _SpringButton(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(
                                color: AppColors.borderSubtle,
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Batal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Confirm delete button
                      Expanded(
                        child: _SpringButton(
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            if (patientId != null) {
                              try {
                                await AppDatabase.instance.markPatientDeleted(patientId);
                                SyncService.instance.syncAll();
                                await _fetchPatients();

                                if (mounted) {
                                  AppToast.show(
                                    context: context,
                                    message: 'Data pasien $name berhasil dihapus',
                                    type: AppToastType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  AppToast.show(
                                    context: context,
                                    message: 'Gagal menghapus data: $e',
                                    type: AppToastType.error,
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Hapus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Floating Action Button for adding new patient (Strictly Squircle 16, Zero Glow)
  Widget _buildAddFAB() {
    return _SpringButton(
      onTap: () async {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();

        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const TambahLansiaScreen(),
          ),
        );

        if (mounted) {
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _searchFocusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            }
          });
        }

        if (result != null && mounted) {
          _fetchPatients();
        }
      },
      child: Container(
        width: 54.0,
        height: 54.0,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 26.0,
        ),
      ),
    );
  }
}

// Reusable Spring Button for Premium Tactile Feel
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

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
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
