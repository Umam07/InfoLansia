import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

import 'skrining/skrining_baru_screen.dart';
import 'pasien/detail_pasien_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/sync_status_badge.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';
import '../services/network_connectivity_service.dart';

class SkriningScreen extends StatefulWidget {
  const SkriningScreen({super.key});

  @override
  State<SkriningScreen> createState() => _SkriningScreenState();
}

class _SkriningScreenState extends State<SkriningScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

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

      // 2. Jika online, jalankan sinkronisasi
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
    final Map<String, List<DateTime>> screeningMap = {};
    for (final s in screenings) {
      final pid = s.patientId;
      try {
        final date = DateTime.parse(s.date);
        if (!screeningMap.containsKey(pid)) {
          screeningMap[pid] = [];
        }
        screeningMap[pid]!.add(date);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _allPatients = patients.map((patient) {
        final pid = patient.id;
        DateTime birthDate;
        try {
          birthDate = DateTime.parse(patient.birthDate);
        } catch (_) {
          birthDate = DateTime.now();
        }
        final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
        final gender = patient.gender;

        return {
          'id': pid,
          'name': patient.name,
          'age': age,
          'address': patient.address,
          'gender': gender,
          'birthDate': birthDate,
          'category': patient.category,
          'isSynced': patient.isSynced,

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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        body: Column(
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
                    bottom: isKeyboardOpen ? 24.0 : 120.0, // Clear space for bottom bar when keyboard closed
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsOverview(),
                    const SizedBox(height: 22.0),
                    _buildSectionHeader(),
                    const SizedBox(height: 12.0),
                    _buildSearchBar(),
                    const SizedBox(height: 14.0),
                    _buildPatientList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

  // Bento-style Stats Overview with Interactive Toggle Filters (Option 1)
  Widget _buildStatsOverview() {
    final isScreenedSelected = _selectedCategory == 'Sudah Skrining';
    final isUnscreenedSelected = _selectedCategory == 'Belum Skrining';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 14.0) / 2;
        return Row(
          children: [
            // 1. Warga Terpantau (Sudah Skrining) Card
            _SpringButton(
              onTap: () {
                setState(() {
                  if (isScreenedSelected) {
                    _selectedCategory = 'Semua';
                  } else {
                    _selectedCategory = 'Sudah Skrining';
                  }
                });
              },
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isScreenedSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isScreenedSelected
                        ? AppColors.primary
                        : AppColors.borderSubtle,
                    width: isScreenedSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isScreenedSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: isScreenedSelected ? Colors.white : AppColors.primary,
                            size: 20.0,
                          ),
                        ),
                        if (isScreenedSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  'Aktif',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Warga Terpantau',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isScreenedSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$_screenedCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isScreenedSelected ? Colors.white : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Sudah skrining bulan ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isScreenedSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14.0),

            // 2. Belum Skrining Card
            _SpringButton(
              onTap: () {
                setState(() {
                  if (isUnscreenedSelected) {
                    _selectedCategory = 'Semua';
                  } else {
                    _selectedCategory = 'Belum Skrining';
                  }
                });
              },
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isUnscreenedSelected
                      ? AppColors.statusWarning
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isUnscreenedSelected
                        ? AppColors.statusWarning
                        : AppColors.borderSubtle,
                    width: isUnscreenedSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isUnscreenedSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppColors.statusWarning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(
                            Icons.pending_actions_rounded,
                            color: isUnscreenedSelected ? Colors.white : AppColors.statusWarning,
                            size: 20.0,
                          ),
                        ),
                        if (isUnscreenedSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  'Aktif',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Belum Skrining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUnscreenedSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '$_remainingCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isUnscreenedSelected ? Colors.white : AppColors.statusWarning,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Perlu diperiksa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isUnscreenedSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
          hintText: 'Cari nama pasien...',
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

  // Section Header with dynamic filter reset
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _selectedCategory == 'Semua'
                ? 'Daftar Skrining Warga'
                : 'Daftar • $_selectedCategory',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8.0),
        if (_selectedCategory != 'Semua')
          _SpringButton(
            onTap: () {
              setState(() {
                _selectedCategory = 'Semua';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
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
                    'Tampilkan Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          )
        else
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
    final isSynced = patient['isSynced'] as bool? ?? true;

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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                      // Dismiss focus before opening new screen
                      _searchFocusNode.unfocus();
                      FocusManager.instance.primaryFocus?.unfocus();

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

                      // Ensure search field is not focused upon returning
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

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

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
      _searchFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
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
