import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

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
  final String name;
  final String age;
  final String? imageUrl;

  const TrenKesehatanScreen({
    super.key,
    required this.name,
    required this.age,
    this.imageUrl,
  });

  @override
  State<TrenKesehatanScreen> createState() => _TrenKesehatanScreenState();
}

class _TrenKesehatanScreenState extends State<TrenKesehatanScreen> {
  // All monthly data for Jan - Jun 2026
  final List<MonthlyHealthData> _allMonthlyData = [
    MonthlyHealthData(
      monthName: 'Januari',
      date: DateTime(2026, 1, 15),
      systolic: 116,
      diastolic: 78,
      bloodSugar: 105,
      cholesterol: 185,
      uricAcid: 5.4,
      weight: 59.5,
      updateDate: '15 Jan',
    ),
    MonthlyHealthData(
      monthName: 'Februari',
      date: DateTime(2026, 2, 15),
      systolic: 124,
      diastolic: 84,
      bloodSugar: 118,
      cholesterol: 198,
      uricAcid: 6.1,
      weight: 59.2,
      updateDate: '15 Feb',
    ),
    MonthlyHealthData(
      monthName: 'Maret',
      date: DateTime(2026, 3, 15),
      systolic: 122,
      diastolic: 80,
      bloodSugar: 108,
      cholesterol: 180,
      uricAcid: 5.6,
      weight: 59.0,
      updateDate: '15 Mar',
    ),
    MonthlyHealthData(
      monthName: 'April',
      date: DateTime(2026, 4, 15),
      systolic: 120,
      diastolic: 82,
      bloodSugar: 112,
      cholesterol: 190,
      uricAcid: 5.9,
      weight: 58.5,
      updateDate: '15 Apr',
    ),
    MonthlyHealthData(
      monthName: 'Mei',
      date: DateTime(2026, 5, 25),
      systolic: 125,
      diastolic: 84,
      bloodSugar: 110,
      cholesterol: 205,
      uricAcid: 5.8,
      weight: 58.5,
      updateDate: '25 Mei',
    ),
    MonthlyHealthData(
      monthName: 'Juni',
      date: DateTime(2026, 6, 15),
      systolic: 121,
      diastolic: 79,
      bloodSugar: 106,
      cholesterol: 195,
      uricAcid: 5.7,
      weight: 58.0,
      updateDate: '15 Jun',
    ),
  ];

  // Dynamic filter state (Indices of selected range)
  late int _startMonthIndex;
  late int _endMonthIndex;
  late List<MonthlyHealthData> _filteredData;

  @override
  void initState() {
    super.initState();
    // Default range is Maret 2026 - Mei 2026
    _startMonthIndex = 2; // Maret
    _endMonthIndex = 4;   // Mei
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _filteredData = _allMonthlyData.sublist(_startMonthIndex, _endMonthIndex + 1);
    });
  }

  String _getPeriodDisplayString() {
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
              border: Border.all(
                color: AppColors.primaryFixed,
                width: 2.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.0),
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(),
                    )
                  : _buildInitialsAvatar(),
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
          color: AppColors.primary,
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
                          color: AppColors.primaryContainer,
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
                          color: AppColors.primaryFixed,
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
            height: 140,
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
                    minY: 60,
                    maxY: 150,
                    animProgress: animValue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10.0),

          // X Axis Month Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: monthLabels.map((lbl) {
              return Expanded(
                child: Center(
                  child: Text(
                    lbl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
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
                      color: AppColors.primaryContainer,
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
            height: 140,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_filteredData),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, animValue, child) {
                return CustomPaint(
                  painter: CurveChartPainter(
                    systolicPoints: uricAcidPoints,
                    minY: 4.0,
                    maxY: 8.0,
                    animProgress: animValue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10.0),

          // X Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: monthLabels.map((lbl) {
              return Expanded(
                child: Center(
                  child: Text(
                    lbl,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
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
                // Weight ranges from 50 - 65, map height percentage
                final percentHeight = ((item.weight - 50.0) / (65.0 - 50.0)).clamp(0.1, 1.0);
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
                              return FractionallySizedBox(
                                heightFactor: scale,
                                child: Container(
                                  width: 24,
                                  decoration: BoxDecoration(
                                    color: isLast ? AppColors.primary : AppColors.primaryFixed,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                                  ),
                                ),
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
class CurveChartPainter extends CustomPaintPainter {
  final List<double> systolicPoints;
  final List<double>? diastolicPoints;
  final double minY;
  final double maxY;
  final double animProgress;

  CurveChartPainter({
    required this.systolicPoints,
    this.diastolicPoints,
    required this.minY,
    required this.maxY,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 12.0;
    final double chartWidth = size.width;
    final double chartHeight = size.height;

    // Draw Grid Lines (3 horizontal lines)
    final gridPaint = Paint()
      ..color = AppColors.onSurface.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      double yGrid = padding + i * (chartHeight - 2 * padding) / 2;
      canvas.drawLine(Offset(0, yGrid), Offset(chartWidth, yGrid), gridPaint);
    }

    if (systolicPoints.isEmpty) return;

    // Calculate dynamic screen coordinates for points
    List<Offset> getScreenCoords(List<double> data) {
      final int n = data.length;
      final coords = <Offset>[];
      for (int i = 0; i < n; i++) {
        final double x = padding + i * (chartWidth - 2 * padding) / (n > 1 ? n - 1 : 1);
        final double normalizedY = (data[i] - minY) / (maxY - minY);
        // Animate the drawing height from middle/bottom to top
        final double y = chartHeight - padding - (normalizedY * (chartHeight - 2 * padding) * animProgress);
        coords.add(Offset(x, y));
      }
      return coords;
    }

    final sysCoords = getScreenCoords(systolicPoints);
    final diaCoords = diastolicPoints != null ? getScreenCoords(diastolicPoints!) : null;

    // Helper to paint line curve and gradient fill
    void paintLineCurve(List<Offset> coords, Color color) {
      if (coords.isEmpty) return;

      final curvePath = Path();
      curvePath.moveTo(coords.first.dx, coords.first.dy);

      if (coords.length == 1) {
        curvePath.lineTo(chartWidth - padding, coords.first.dy);
      } else {
        // Generate beautiful cubic bezier curves
        for (int i = 0; i < coords.length - 1; i++) {
          final p0 = coords[i];
          final p1 = coords[i + 1];
          final controlX = p0.dx + (p1.dx - p0.dx) / 2;
          curvePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }
      }

      // Draw Gradient Fill beneath curve
      final fillPath = Path.from(curvePath);
      fillPath.lineTo(coords.last.dx, chartHeight);
      fillPath.lineTo(coords.first.dx, chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.00),
          ],
        ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Draw Main Stroke Path
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(curvePath, strokePaint);

      // Draw circles at data point vertices
      final dotStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final dotFillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var pt in coords) {
        canvas.drawCircle(pt, 5.0, dotFillPaint);
        canvas.drawCircle(pt, 2.5, dotStrokePaint);
      }
    }

    // Paint Diastolic (drawn below Systolic)
    if (diaCoords != null) {
      paintLineCurve(diaCoords, AppColors.primaryFixedDim);
    }

    // Paint Systolic or single Asam Urat curve
    paintLineCurve(sysCoords, AppColors.primaryContainer);
  }

  @override
  bool shouldRepaint(covariant CurveChartPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.systolicPoints != systolicPoints ||
        oldDelegate.diastolicPoints != diastolicPoints;
  }
}

// Custom CustomPaintPainter base class to avoid deprecated member usage
abstract class CustomPaintPainter extends CustomPainter {}
