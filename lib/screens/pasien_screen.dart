import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'pasien/detail_pasien_screen.dart';
import 'pasien/tambah_lansia_screen.dart';
import 'pasien/edit_lansia_screen.dart';
import '../widgets/app_toast.dart';

class PasienScreen extends StatefulWidget {
  const PasienScreen({super.key});

  @override
  State<PasienScreen> createState() => _PasienScreenState();
}

class _PasienScreenState extends State<PasienScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = ['Semua', 'Hipertensi', 'Diabetes', 'Rutin'];

  List<Map<String, dynamic>> _allPatients = [];
  int _unscreenedPatientsCount = 0;
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
          .select('patient_id, date, status, blood_pressure, blood_sugar');

      final List<Map<String, dynamic>> screenings = List<Map<String, dynamic>>.from(screeningResponse);

      final Map<String, List<DateTime>> screeningDatesMap = {};
      final Map<String, Map<String, dynamic>> latestScreeningMap = {};
      
      for (final s in screenings) {
        final pid = s['patient_id'] as String;
        final dateStr = s['date'] as String;
        final date = DateTime.parse(dateStr);
        
        if (!screeningDatesMap.containsKey(pid)) {
          screeningDatesMap[pid] = [];
        }
        screeningDatesMap[pid]!.add(date);
        
        final currentLatest = latestScreeningMap[pid];
        if (currentLatest == null || date.isAfter(DateTime.parse(currentLatest['date'] as String))) {
          latestScreeningMap[pid] = s;
        }
      }

      final now = DateTime.now();
      int unscreenedCount = 0;

      final mappedPatients = patients.map((patient) {
        final pid = patient['id'] as String;
        final birthDateStr = patient['birth_date'] as String;
        final birthDate = DateTime.parse(birthDateStr);
        final age = (DateTime.now().difference(birthDate).inDays / 365).floor().toString();
        final gender = patient['gender'] as String;
        
        final patientScreeningDates = screeningDatesMap[pid] ?? [];
        final isScreenedThisMonth = patientScreeningDates.any((date) => date.year == now.year && date.month == now.month);
        
        if (!isScreenedThisMonth) {
          unscreenedCount++;
        }
        
        String healthStatus = 'Kesehatan Stabil';
        final latestS = latestScreeningMap[pid];
        if (latestS != null) {
          final bpStr = latestS['blood_pressure'] as String?;
          final sugarVal = latestS['blood_sugar'] != null ? double.tryParse(latestS['blood_sugar'].toString()) : null;
          
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
          'name': patient['name'],
          'age': age,
          'address': patient['address'],
          'gender': gender,
          'birthDate': birthDate,
          'category': patient['category'] ?? 'Rutin',
          'healthStatus': healthStatus,
          'createdAt': patient['created_at'] != null ? DateTime.parse(patient['created_at'] as String) : DateTime.now(),
          'avatarBg': gender == 'Laki-laki' 
              ? const Color(0x1BBA5855) 
              : AppColors.secondaryContainer,
          'avatarColor': gender == 'Laki-laki' 
              ? AppColors.tertiary 
              : AppColors.primary,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allPatients = mappedPatients;
          _unscreenedPatientsCount = unscreenedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppToast.show(
          context: context,
          message: 'Gagal memuat data pasien: $e',
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPatients {
    return _allPatients.where((patient) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          patient['category'] == _selectedCategory;
      final matchesSearch =
          patient['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
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
                    padding: EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 24.0,
                      bottom: 140.0 + MediaQuery.of(context).padding.bottom, // Space for BottomNavBar & FAB
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsOverview(),
                        const SizedBox(height: 32.0),
                        _buildPatientListHeader(),
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
          ),

          // Contextual FAB for adding a patient
          Positioned(
            right: 20.0,
            bottom: 108.0 + MediaQuery.of(context).padding.bottom, // Just above BottomNavigationBar
            child: _buildAddFAB(),
          ),
        ],
      ),
    );
  }

  // Header Widget (TopAppBar style matching Posyandu Cloud layout)
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
              // Brand Title
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

  // Search & Filter Section
  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        // Search Input Box
        Expanded(
          child: Container(
            height: 52.0, // fixed height for perfect alignment
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

        // Dropdown Filter Button
        _buildDropdownFilter(),
      ],
    );
  }

  Widget _buildDropdownFilter() {
    return Container(
      height: 52.0, // Match search field height exactly
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

  // Bento Summary Stats
  Widget _buildStatsOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16.0) / 2;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Lansia Card (Green Primary)
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
                    Icons.groups_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 24.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Total Lansia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${_allPatients.length}',
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

            // Belum Skrining Card (White/Warning)
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
                  const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.statusWarning,
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
                    '$_unscreenedPatientsCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
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

  // Patient List Title Header
  Widget _buildPatientListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Data Pasien',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // Dynamic Card List
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filtered.isEmpty)
          Center(
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
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final patient = filtered[index];
              return _buildPatientCard(patient);
            },
          ),
      ],
    );
  }

  // Premium Patient Card
  Widget _buildPatientCard(Map<String, dynamic> patient) {
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
                  color: patient['avatarBg'] as Color,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: patient['avatarColor'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16.0),

              // Title and Address details
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
                            patient['name'] as String,
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
                            '${patient['age']} Thn',
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
                            patient['address'] as String,
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

          // Action buttons divider & row
          Container(
            height: 1.0,
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              // Edit Button (Outline/Low Emphasis)
              Expanded(
                child: _SpringButton(
                  onTap: () async {
                    // Derive initial values if they don't exist
                    final gender = patient['gender'] ?? 
                        (patient['name'].toString().toLowerCase().contains('bambang') 
                            ? 'Laki-laki' 
                            : 'Perempuan');
                    
                    final birthDate = patient['birthDate'] ?? 
                        (patient['name'] == 'Siti Rahayu' 
                            ? DateTime(1955, 4, 14) 
                            : patient['name'] == 'Bambang Wijaya' 
                                ? DateTime(1951, 11, 23) 
                                : DateTime(1958, 9, 8));

                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditLansiaScreen(
                          id: patient['id'],
                          index: _allPatients.indexOf(patient),
                          initialName: patient['name'] as String,
                          initialGender: gender as String,
                          initialBirthDate: birthDate as DateTime,
                          initialAddress: patient['address'] as String,
                          avatarBg: patient['avatarBg'] as Color?,
                          avatarColor: patient['avatarColor'] as Color?,
                          createdAt: patient['createdAt'] as DateTime?,
                        ),
                      ),
                    );

                    if (result != null && mounted) {
                      _fetchPatients();
                    }
                  },
                  child: Container(
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Edit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Detail Button (Filled Primary/High Emphasis)
              Expanded(
                child: _SpringButton(
                  onTap: () async {
                    final name = patient['name'] as String;
                    final age = patient['age'] as String;
                    final address = patient['address'] as String;
                    final gender = patient['gender'] ?? (name.toLowerCase().contains('bambang') ? 'Laki-laki' : 'Perempuan');
                    
                    // Format Indonesian birth date for initial presentation
                    final bDate = patient['birthDate'] as DateTime?;
                    String birthDateStr = '';
                    if (bDate != null) {
                      final months = [
                        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                      ];
                      birthDateStr = '${bDate.day} ${months[bDate.month - 1]} ${bDate.year}';
                    } else {
                      birthDateStr = name == 'Siti Rahayu' 
                          ? '14 April 1955' 
                          : name == 'Bambang Wijaya' 
                              ? '23 November 1951' 
                              : '08 September 1958';
                    }

                    final healthStatus = patient['healthStatus'] as String? ?? 'Kesehatan Stabil';

                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPasienScreen(
                          id: patient['id'],
                          name: name,
                          age: age,
                          gender: gender as String,
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

                    if (result != null && mounted) {
                      _fetchPatients();
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
                    child: Text(
                      'Lihat Detail',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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
    );
  }

  // Floating Action Button matching HTML "Tambah Lansia Baru"
  Widget _buildAddFAB() {
    return _SpringButton(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const TambahLansiaScreen(),
          ),
        );

        if (result != null && mounted) {
          _fetchPatients();
        }
      },
      child: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28.0,
        ),
      ),
    );
  }
}

// Reusable Spring Button for Premium Apple/iOS Feel
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
