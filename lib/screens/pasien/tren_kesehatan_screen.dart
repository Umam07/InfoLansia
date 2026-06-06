import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';

class MonthlyHealthData {
  final String monthName;
  final DateTime date;
  final double systolic;
  final double diastolic;
  final double bloodSugar;
  final double cholesterol;
  final double uricAcid;
  final double weight;
  final String updateDate;

  MonthlyHealthData({
    required this.monthName,
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.bloodSugar,
    required this.cholesterol,
    required this.uricAcid,
    required this.weight,
    required this.updateDate,
  });
}

class TrenKesehatanScreen extends StatefulWidget {
  final String patientId;
  final String name;
  final String age;
  final String gender;

  const TrenKesehatanScreen({
    super.key,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
  });

  @override
  State<TrenKesehatanScreen> createState() => _TrenKesehatanScreenState();
}

class _TrenKesehatanScreenState extends State<TrenKesehatanScreen> {
  // All monthly data (populated dynamically)
  final List<MonthlyHealthData> _allMonthlyData = [];
  bool _isLoading = true;

  // Dynamic filter state (Indices of selected range)
  late int _startMonthIndex;
  late int _endMonthIndex;
  late List<MonthlyHealthData> _filteredData;

  @override
  void initState() {
    super.initState();
    _startMonthIndex = 0;
    _endMonthIndex = 0;
    _filteredData = [];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('screenings')
          .select()
          .eq('patient_id', widget.patientId)
          .gte('date', '2026-01-01')
          .lte('date', '2026-12-31')
          .order('date', ascending: true);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      final List<MonthlyHealthData> parsedScreenings = data.map((item) {
        final dateStr = item['date'] as String;
        final date = DateTime.parse(dateStr);
        final bp = _parseBloodPressure(item['blood_pressure'] as String?);
        final monthName = months[date.month - 1];

        return MonthlyHealthData(
          monthName: monthName,
          date: date,
          systolic: bp['systolic']!,
          diastolic: bp['diastolic']!,
          bloodSugar: _parseDouble(item['blood_sugar'], 100.0),
          cholesterol: _parseDouble(item['cholesterol'], 180.0),
          uricAcid: _parseDouble(item['uric_acid'], 5.0),
          weight: _parseDouble(item['weight'], 60.0),
          updateDate: '${date.day} ${monthName.substring(0, 3)}',
        );
      }).toList();

      final List<MonthlyHealthData> monthlyList = [];

      // Find the month of the last checkup in 2026
      int endMonth = 1; // Default to Jan if no records
      if (parsedScreenings.isNotEmpty) {
        endMonth = parsedScreenings.last.date.month;
      }

      for (int m = 1; m <= endMonth; m++) {
        // Find checkups in this month
        final screeningsInMonth = parsedScreenings.where((s) => s.date.month == m).toList();

        if (screeningsInMonth.isNotEmpty) {
          // Take the latest screening in this month
          monthlyList.add(screeningsInMonth.last);
        } else {
          // If no screening in this month, carry forward from the closest previous month in parsedScreenings
          final priorScreenings = parsedScreenings.where((s) => s.date.month < m).toList();
          if (priorScreenings.isNotEmpty) {
            final lastPrior = priorScreenings.last;
            monthlyList.add(MonthlyHealthData(
              monthName: months[m - 1],
              date: DateTime(2026, m, 15),
              systolic: lastPrior.systolic,
              diastolic: lastPrior.diastolic,
              bloodSugar: lastPrior.bloodSugar,
              cholesterol: lastPrior.cholesterol,
              uricAcid: lastPrior.uricAcid,
              weight: lastPrior.weight,
              updateDate: 'Tidak periksa',
            ));
          } else {
            // If no prior screening, use the closest future screening in parsedScreenings
            final futureScreenings = parsedScreenings.where((s) => s.date.month > m).toList();
            if (futureScreenings.isNotEmpty) {
              final firstFuture = futureScreenings.first;
              monthlyList.add(MonthlyHealthData(
                monthName: months[m - 1],
                date: DateTime(2026, m, 15),
                systolic: firstFuture.systolic,
                diastolic: firstFuture.diastolic,
                bloodSugar: firstFuture.bloodSugar,
                cholesterol: firstFuture.cholesterol,
                uricAcid: firstFuture.uricAcid,
                weight: firstFuture.weight,
                updateDate: 'Belum periksa',
              ));
            } else {
              // Fallback default values
              monthlyList.add(MonthlyHealthData(
                monthName: months[m - 1],
                date: DateTime(2026, m, 15),
                systolic: 120,
                diastolic: 80,
                bloodSugar: 100,
                cholesterol: 180,
                uricAcid: 5.0,
                weight: 60.0,
                updateDate: '-',
              ));
            }
          }
        }
      }

      setState(() {
        _allMonthlyData.clear();
        _allMonthlyData.addAll(monthlyList);
        if (_allMonthlyData.isNotEmpty) {
          _startMonthIndex = 0; // Januari 2026
          _endMonthIndex = _allMonthlyData.length - 1; // latest checked month
          _filteredData = _allMonthlyData.sublist(_startMonthIndex, _endMonthIndex + 1);
        } else {
          _startMonthIndex = 0;
          _endMonthIndex = 0;
          _filteredData = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allMonthlyData.clear();
        _filteredData = [];
        _isLoading = false;
      });
    }
  }

  static Map<String, double> _parseBloodPressure(String? bp) {
    double systolic = 120.0;
    double diastolic = 80.0;
    if (bp != null && bp.contains('/')) {
      final parts = bp.split('/');
      if (parts.length == 2) {
        systolic = double.tryParse(parts[0].trim()) ?? 120.0;
        diastolic = double.tryParse(parts[1].trim()) ?? 80.0;
      }
    }
    return {'systolic': systolic, 'diastolic': diastolic};
  }

  static double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }

  void _applyFilter() {
    if (_allMonthlyData.isEmpty) {
      setState(() {
        _filteredData = [];
      });
      return;
    }
    setState(() {
      _filteredData = _allMonthlyData.sublist(_startMonthIndex, _endMonthIndex + 1);
    });
  }

  String _getPeriodDisplayString() {
    if (_allMonthlyData.isEmpty) return '-';
    final start = _allMonthlyData[_startMonthIndex];
    final end = _allMonthlyData[_endMonthIndex];
    return '${start.monthName} 2026 - ${end.monthName} 2026';
  }

  // Calculate averages for statistics
  double _calculateAverageSystolic() {
    if (_filteredData.isEmpty) return 0;
    final total = _filteredData.fold<double>(0, (sum, item) => sum + item.systolic);
    return total / _filteredData.length;
  }

  double _calculateAverageDiastolic() {
    if (_filteredData.isEmpty) return 0;
    final total = _filteredData.fold<double>(0, (sum, item) => sum + item.diastolic);
    return total / _filteredData.length;
  }

  double _calculateAverageUricAcid() {
    if (_filteredData.isEmpty) return 0.0;
    final total = _filteredData.fold<double>(0, (sum, item) => sum + item.uricAcid);
    return total / _filteredData.length;
  }

  double _calculateWeightChange() {
    if (_filteredData.length < 2) return 0.0;
    final first = _filteredData.first.weight;
    final last = _filteredData.last.weight;
    return last - first;
  }

  // Ubah Periode Bottom Sheet Modal (Premium Custom Month Range Selection)
  void _showPeriodBottomSheet() {
    int tempStart = _startMonthIndex;
    int tempEnd = _endMonthIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: 8.0,
                left: 20.0,
                right: 20.0,
                bottom: 24.0 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull indicator
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubah Periode Tren',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      _SpringButton(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Month ranges
                  Text(
                    'Bulan Mulai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(_allMonthlyData.length, (index) {
                      final item = _allMonthlyData[index];
                      final isSelected = tempStart == index;
                      final isPastEnd = index > tempEnd;

                      return ChoiceChip(
                        label: Text(
                          item.monthName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        disabledColor: AppColors.surfaceContainerLow,
                        backgroundColor: AppColors.surfaceContainerLow,
                        onSelected: isPastEnd
                            ? null
                            : (selected) {
                                if (selected) {
                                  setModalState(() {
                                    tempStart = index;
                                  });
                                }
                              },
                      );
                    }),
                  ),
                  const SizedBox(height: 20.0),

                  Text(
                    'Bulan Selesai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: List.generate(_allMonthlyData.length, (index) {
                      final item = _allMonthlyData[index];
                      final isSelected = tempEnd == index;
                      final isBeforeStart = index < tempStart;

                      return ChoiceChip(
                        label: Text(
                          item.monthName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerLow,
                        disabledColor: AppColors.surfaceContainerLow,
                        onSelected: isBeforeStart
                            ? null
                            : (selected) {
                                if (selected) {
                                  setModalState(() {
                                    tempEnd = index;
                                  });
                                }
                              },
                      );
                    }),
                  ),
                  const SizedBox(height: 32.0),

                  // Actions
                  _SpringButton(
                    onTap: () {
                      setState(() {
                        _startMonthIndex = tempStart;
                        _endMonthIndex = tempEnd;
                        _applyFilter();
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Terapkan Periode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBar(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _filteredData.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
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
                      // Filter Indicator Row
                      _buildFilterIndicatorRow(),
                      const SizedBox(height: 20.0),

                      // Patient profile summary card
                      _buildPatientProfileCard(),
                      const SizedBox(height: 24.0),

                      // Blood Pressure Trend Card
                      _buildBloodPressureCard(),
                      const SizedBox(height: 24.0),

                      // Blood Sugar & Cholesterol Card
                      _buildBloodSugarCholesterolCard(),
                      const SizedBox(height: 24.0),

                      // Uric Acid Card
                      _buildUricAcidCard(),
                      const SizedBox(height: 24.0),

                      // Weight Trend Card
                      _buildWeightTrendCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      margin: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Tidak Ada Data Tren',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Tidak ada catatan pemeriksaan ditemukan untuk pasien ini pada tahun 2026.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20.0),
          _SpringButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Kembali',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top App Bar
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
                  'Tren Kesehatan',
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
              const SizedBox(width: 40.0), // Spacer for centering
            ],
          ),
        ),
      ),
    );
  }

  // Filter Indicator Row
  Widget _buildFilterIndicatorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primary,
                  size: 16.0,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    _getPeriodDisplayString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        _SpringButton(
          onTap: _showPeriodBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              children: [
                Text(
                  'Ubah Periode',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2.0),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.primary,
                  size: 18.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Patient Profile Summary Card
  Widget _buildPatientProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.gender == 'Laki-laki' 
                  ? const Color(0x1BBA5855) 
                  : AppColors.secondaryContainer,
              border: Border.all(
                color: AppColors.primaryFixed,
                width: 2.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: _buildInitialsAvatar(),
            ),
          ),
          const SizedBox(width: 16.0),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '${widget.age} Tahun',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Control
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2.0),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Terkontrol',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = widget.name.isNotEmpty
        ? widget.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.gender == 'Laki-laki' 
              ? AppColors.tertiary 
              : AppColors.primary,
        ),
      ),
    );
  }

  // Blood Pressure Trend Card
  Widget _buildBloodPressureCard() {
    final systolicPoints = _filteredData.map((e) => e.systolic).toList();
    final diastolicPoints = _filteredData.map((e) => e.diastolic).toList();
    final monthLabels = _filteredData.map((e) => e.monthName.substring(0, 3)).toList();

    final avgSys = _calculateAverageSystolic().toStringAsFixed(0);
    final avgDia = _calculateAverageDiastolic().toStringAsFixed(0);

    double minY = 60.0;
    double maxY = 150.0;
    if (systolicPoints.isNotEmpty) {
      final minSys = systolicPoints.reduce((a, b) => a < b ? a : b);
      final maxSys = systolicPoints.reduce((a, b) => a > b ? a : b);
      final minDia = diastolicPoints.reduce((a, b) => a < b ? a : b);
      final maxDia = diastolicPoints.reduce((a, b) => a > b ? a : b);
      final overallMin = minSys < minDia ? minSys : minDia;
      final overallMax = maxSys > maxDia ? maxSys : maxDia;
      minY = (overallMin - 15.0).clamp(30.0, 100.0);
      maxY = (overallMax + 15.0).clamp(130.0, 220.0);
    }
    if (maxY == minY) {
      maxY += 20;
      minY -= 20;
    }

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
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header with Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Tekanan Darah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Satuan: mmHg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.tertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Sistolik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Diastolik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Custom Curves Chart Graphic
          SizedBox(
            height: 160,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_filteredData),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, animValue, child) {
                return CustomPaint(
                  painter: CurveChartPainter(
                    systolicPoints: systolicPoints,
                    diastolicPoints: diastolicPoints,
                    monthLabels: monthLabels,
                    minY: minY,
                    maxY: maxY,
                    animProgress: animValue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20.0),

          // Bottom Stats Boxes (2 Columns)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rata-rata Sistolik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        avgSys,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rata-rata Diastolik',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        avgDia,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
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
  }

  // Blood Sugar & Cholesterol Progress Bar Indicator Card
  Widget _buildBloodSugarCholesterolCard() {
    // We use the latest month's records for this section
    final latestRecord = _filteredData.last;

    // Persentase fills (Gula darah range 0-200+, Kolesterol range 0-300+)
    final sugarPercentage = (latestRecord.bloodSugar / 200.0).clamp(0.0, 1.0);
    final cholPercentage = (latestRecord.cholesterol / 300.0).clamp(0.0, 1.0);

    // Dynamic warning status text
    final sugarStatus = latestRecord.bloodSugar < 140 ? 'Stabil' : 'Tinggi';
    final cholStatus = latestRecord.cholesterol < 200 ? 'Normal' : 'Waspada';
    final cholColor = latestRecord.cholesterol < 200 ? AppColors.primary : AppColors.statusWarning;

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
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gula Darah & Kolesterol',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Blood Sugar Horizontal Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gula Darah (mg/dL)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${latestRecord.bloodSugar.toStringAsFixed(0)} mg/dL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Animated progress bar
              TweenAnimationBuilder<double>(
                key: ValueKey(sugarPercentage),
                tween: Tween<double>(begin: 0.0, end: sugarPercentage),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, val, child) {
                  return Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: val,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sugarStatus,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Update: ${latestRecord.updateDate}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Cholesterol Horizontal Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kolesterol (mg/dL)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${latestRecord.cholesterol.toStringAsFixed(0)} mg/dL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cholColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              // Animated progress bar
              TweenAnimationBuilder<double>(
                key: ValueKey(cholPercentage),
                tween: Tween<double>(begin: 0.0, end: cholPercentage),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, val, child) {
                  return Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: val,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cholColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cholStatus,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cholColor,
                    ),
                  ),
                  Text(
                    'Update: ${latestRecord.updateDate}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Uric Acid Line Curve Card
  Widget _buildUricAcidCard() {
    final uricAcidPoints = _filteredData.map((e) => e.uricAcid).toList();
    final monthLabels = _filteredData.map((e) => e.monthName.substring(0, 3)).toList();
    final avgUric = _calculateAverageUricAcid().toStringAsFixed(1);

    double minY = 4.0;
    double maxY = 8.0;
    if (uricAcidPoints.isNotEmpty) {
      final minUric = uricAcidPoints.reduce((a, b) => a < b ? a : b);
      final maxUric = uricAcidPoints.reduce((a, b) => a > b ? a : b);
      minY = (minUric - 1.0).clamp(1.0, 6.0);
      maxY = (maxUric + 1.0).clamp(7.0, 15.0);
    }
    if (maxY == minY) {
      maxY += 2.0;
      minY -= 2.0;
    }

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
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Asam Urat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Satuan: mg/dL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Asam Urat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Custom Uric Acid Graph Painter
          SizedBox(
            height: 160,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_filteredData),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, animValue, child) {
                return CustomPaint(
                  painter: CurveChartPainter(
                    systolicPoints: uricAcidPoints,
                    monthLabels: monthLabels,
                    minY: minY,
                    maxY: maxY,
                    animProgress: animValue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20.0),

          // Average Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              children: [
                Text(
                  'Rata-rata Asam Urat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  avgUric,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Weight Trend Vertical Bar Chart Card
  Widget _buildWeightTrendCard() {
    final latestWeight = _filteredData.last.weight;
    final changeVal = _calculateWeightChange();
    final isDown = changeVal <= 0;

    double minWeight = 40.0;
    double maxWeight = 80.0;
    if (_filteredData.isNotEmpty) {
      final minW = _filteredData.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
      final maxW = _filteredData.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
      minWeight = (minW - 5.0).clamp(30.0, 120.0);
      maxWeight = (maxW + 5.0).clamp(50.0, 180.0);
    }
    if (maxWeight == minWeight) {
      maxWeight += 10;
      minWeight -= 10;
    }

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
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Tren Berat Badan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 28.0),

          // Vertical Bars Layout
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_filteredData.length, (index) {
                final item = _filteredData[index];
                final percentHeight = ((item.weight - minWeight) / (maxWeight - minWeight)).clamp(0.15, 1.0);
                final isLast = index == _filteredData.length - 1;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(_filteredData),
                            tween: Tween<double>(begin: 0.0, end: percentHeight),
                            duration: const Duration(milliseconds: 650),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    item.weight.toStringAsFixed(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isLast ? AppColors.primary : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    height: 70 * scale,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: isLast ? AppColors.primary : AppColors.primaryFixed,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        item.monthName.substring(0, 3),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20.0),

          // Divider
          const Divider(color: AppColors.borderSubtle, height: 1.0),
          const SizedBox(height: 16.0),

          // Weight Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terakhir',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${latestWeight.toStringAsFixed(1)} kg',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
              const SizedBox(width: 8.0),

              // Change badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isDown
                      ? AppColors.primaryContainer.withValues(alpha: 0.1)
                      : AppColors.statusWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                      size: 16,
                      color: isDown ? AppColors.primary : AppColors.statusWarning,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${changeVal >= 0 ? "+" : ""}${changeVal.toStringAsFixed(1)}kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDown ? AppColors.primary : AppColors.statusWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

// Reusable premium iOS spring animation button
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

// Custom Painter for Premium Curved Line Chart with horizontal grid lines and gradient fills
class CurveChartPainter extends CustomPainter {
  final List<double> systolicPoints;
  final List<double>? diastolicPoints;
  final List<String> monthLabels;
  final double minY;
  final double maxY;
  final double animProgress;

  CurveChartPainter({
    required this.systolicPoints,
    this.diastolicPoints,
    required this.monthLabels,
    required this.minY,
    required this.maxY,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 36.0;
    const double rightPadding = 16.0;
    const double topPadding = 20.0;
    const double bottomPadding = 24.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // Draw Grid Lines and Y Axis Labels
    final gridPaint = Paint()
      ..color = AppColors.onSurface.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const int gridCount = 4;
    for (int i = 0; i < gridCount; i++) {
      final double fraction = i / (gridCount - 1);
      final double value = minY + fraction * (maxY - minY);
      final double y = topPadding + chartHeight - (fraction * chartHeight);

      // Draw grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      // Draw Y-axis label text on the left
      final yLabelPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      yLabelPainter.layout();
      yLabelPainter.paint(
        canvas,
        Offset(leftPadding - yLabelPainter.width - 6, y - yLabelPainter.height / 2),
      );
    }

    if (systolicPoints.isEmpty) return;

    // Calculate dynamic screen coordinates for points
    double getX(int index, int total) {
      if (total <= 1) return leftPadding + chartWidth / 2;
      return leftPadding + index * chartWidth / (total - 1);
    }

    double getY(double val) {
      if (maxY == minY) return topPadding + chartHeight / 2;
      final double normalizedY = (val - minY) / (maxY - minY);
      return topPadding + chartHeight - (normalizedY * chartHeight * animProgress);
    }

    List<Offset> getScreenCoords(List<double> data) {
      final coords = <Offset>[];
      for (int i = 0; i < data.length; i++) {
        coords.add(Offset(getX(i, data.length), getY(data[i])));
      }
      return coords;
    }

    final sysCoords = getScreenCoords(systolicPoints);
    final diaCoords = diastolicPoints != null ? getScreenCoords(diastolicPoints!) : null;

    // Helper to paint line curve and gradient fill
    void paintLineCurve(List<Offset> coords, List<double> originalData, Color color, {bool isDiastolic = false}) {
      if (coords.isEmpty) return;

      final curvePath = Path();
      curvePath.moveTo(coords.first.dx, coords.first.dy);

      if (coords.length == 1) {
        curvePath.lineTo(leftPadding + chartWidth, coords.first.dy);
      } else {
        // Generate beautiful cubic bezier curves
        for (int i = 0; i < coords.length - 1; i++) {
          final p0 = coords[i];
          final p1 = coords[i + 1];
          final controlX = p0.dx + (p1.dx - p0.dx) / 2;
          curvePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }
      }

      // Draw Gradient Fill beneath curve (filling down to bottom of the chart area, i.e., topPadding + chartHeight)
      final fillPath = Path.from(curvePath);
      fillPath.lineTo(coords.last.dx, topPadding + chartHeight);
      fillPath.lineTo(coords.first.dx, topPadding + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.00),
          ],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Draw Main Stroke Path
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(curvePath, strokePaint);

      // Draw circles and values at data point vertices
      final dotStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final dotFillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (int i = 0; i < coords.length; i++) {
        final pt = coords[i];
        final val = originalData[i];

        canvas.drawCircle(pt, 5.0, dotFillPaint);
        canvas.drawCircle(pt, 2.5, dotStrokePaint);

        // Draw value label text
        final textPainter = TextPainter(
          text: TextSpan(
            text: val.toStringAsFixed(val % 1 == 0 ? 0 : 1),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // If diastolic, offset downwards; systolic, offset upwards
        final double yOffset = isDiastolic ? 8.0 : -20.0;
        textPainter.paint(
          canvas,
          Offset(pt.dx - textPainter.width / 2, pt.dy + yOffset),
        );
      }
    }

    // Paint Diastolic (drawn below Systolic)
    if (diaCoords != null && diastolicPoints != null) {
      paintLineCurve(diaCoords, diastolicPoints!, AppColors.primary, isDiastolic: true);
    }

    // Paint Systolic or single Asam Urat curve
    paintLineCurve(sysCoords, systolicPoints, diastolicPoints != null ? AppColors.tertiary : AppColors.primary);

    // Draw Month Labels at the bottom of the chart
    for (int i = 0; i < monthLabels.length; i++) {
      final double x = getX(i, monthLabels.length);
      final double y = size.height - 12.0;

      final labelPainter = TextPainter(
        text: TextSpan(
          text: monthLabels[i],
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, y - labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CurveChartPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.systolicPoints != systolicPoints ||
        oldDelegate.diastolicPoints != diastolicPoints ||
        oldDelegate.monthLabels != monthLabels ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}
