import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'layanan/layanan_tensi_screen.dart';
import 'layanan/layanan_kolesterol_screen.dart';
import 'layanan/layanan_gula_darah_screen.dart';
import 'layanan/layanan_asam_urat_screen.dart';
import 'layanan/visualisasi_tahunan_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/medical_disclaimer_card.dart';
import '../constants/medical_guidelines.dart';
import '../services/excel_monthly_report_service.dart';

class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> with TickerProviderStateMixin {
  String _selectedMonth = 'Oktober';
  String _selectedYear = '2026';
  bool _isLoading = false;
  bool _isExporting = false;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<String> _years = ['2025', '2026', '2027'];

  final Map<String, int> _monthMap = {
    'Januari': 1, 'Februari': 2, 'Maret': 3, 'April': 4, 'Mei': 5, 'Juni': 6,
    'Juli': 7, 'Agustus': 8, 'September': 9, 'Oktober': 10, 'November': 11, 'Desember': 12
  };

  int _totalPatientsCount = 0;
  int _totalScreeningsCount = 0;
  int _growthPct = 0;
  int _coveragePct = 0;
  int _normalCount = 0;
  int _warningCount = 0;
  int _dangerCount = 0;
  double _normalPct = 0.0;
  double _warningPct = 0.0;
  double _dangerPct = 0.0;
  int _totalTensi = 0;
  int _tensiRate = 0;
  int _totalKolesterol = 0;
  int _kolesterolRate = 0;
  int _totalGula = 0;
  int _gulaRate = 0;
  int _totalAsamUrat = 0;
  int _asamUratRate = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
    _selectedYear = now.year.toString();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _fetchReportData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final patientsResponse = await Supabase.instance.client
          .from('patients')
          .select('id');
      final totalPatients = patientsResponse.length;

      int monthInt = _monthMap[_selectedMonth] ?? 1;
      int yearInt = int.tryParse(_selectedYear) ?? DateTime.now().year;

      final startOfMonth = DateTime(yearInt, monthInt, 1).toIso8601String().split('T').first;
      final endOfMonth = DateTime(yearInt, monthInt + 1, 1).subtract(const Duration(days: 1)).toIso8601String().split('T').first;

      final screeningsResponse = await Supabase.instance.client
          .from('screenings')
          .select()
          .gte('date', startOfMonth)
          .lte('date', endOfMonth);

      final List<Map<String, dynamic>> screenings = List<Map<String, dynamic>>.from(screeningsResponse);

      final lastMonth = monthInt == 1 ? 12 : monthInt - 1;
      final lastMonthYear = monthInt == 1 ? yearInt - 1 : yearInt;
      final startOfLastMonth = DateTime(lastMonthYear, lastMonth, 1).toIso8601String().split('T').first;
      final endOfLastMonth = DateTime(lastMonthYear, lastMonth + 1, 1).subtract(const Duration(days: 1)).toIso8601String().split('T').first;

      final lastMonthResponse = await Supabase.instance.client
          .from('screenings')
          .select('id')
          .gte('date', startOfLastMonth)
          .lte('date', endOfLastMonth);

      final lastMonthCount = lastMonthResponse.length;
      final thisMonthCount = screenings.length;

      int growthPct = 0;
      if (lastMonthCount > 0) {
        growthPct = (((thisMonthCount - lastMonthCount) / lastMonthCount) * 100).round();
      } else if (thisMonthCount > 0) {
        growthPct = 100;
      }

      int normalCount = 0;
      int warningCount = 0;
      int dangerCount = 0;

      int totalTensi = 0;
      int totalKolesterol = 0;
      int totalGula = 0;
      int totalAsamUrat = 0;

      for (final s in screenings) {
        final bpStr = s['blood_pressure'] as String?;
        int? sys;
        int? dia;
        if (bpStr != null && bpStr.contains('/')) {
          final parts = bpStr.split('/');
          if (parts.length == 2) {
            sys = int.tryParse(parts[0].trim());
            dia = int.tryParse(parts[1].trim());
            if (sys != null && dia != null) {
              totalTensi++;
            }
          }
        }

        final cholVal = s['cholesterol'] != null ? num.tryParse(s['cholesterol'].toString())?.round() : null;
        if (cholVal != null) totalKolesterol++;

        final sugarVal = s['blood_sugar'] != null ? num.tryParse(s['blood_sugar'].toString())?.round() : null;
        if (sugarVal != null) totalGula++;

        final uricVal = s['uric_acid'] != null ? double.tryParse(s['uric_acid'].toString()) : null;
        if (uricVal != null) totalAsamUrat++;

        final overall = MedicalGuidelines.evaluateOverallScreening(
          systolic: sys,
          diastolic: dia,
          cholesterol: cholVal,
          sugar: sugarVal,
          uricAcid: uricVal,
        );

        if (overall.statusType == HealthStatusType.danger) {
          dangerCount++;
        } else if (overall.statusType == HealthStatusType.warning) {
          warningCount++;
        } else {
          normalCount++;
        }
      }

      final totalScreened = screenings.length;
      final normalPct = totalScreened > 0 ? normalCount / totalScreened : 0.0;
      final warningPct = totalScreened > 0 ? warningCount / totalScreened : 0.0;
      final dangerPct = totalScreened > 0 ? dangerCount / totalScreened : 0.0;

      final coveragePct = totalPatients > 0 ? (totalScreened / totalPatients * 100).clamp(0, 100).round() : 0;
      final tensiRate = totalPatients > 0 ? (totalTensi / totalPatients * 100).clamp(0, 100).round() : 0;
      final kolesterolRate = totalPatients > 0 ? (totalKolesterol / totalPatients * 100).clamp(0, 100).round() : 0;
      final gulaRate = totalPatients > 0 ? (totalGula / totalPatients * 100).clamp(0, 100).round() : 0;
      final asamUratRate = totalPatients > 0 ? (totalAsamUrat / totalPatients * 100).clamp(0, 100).round() : 0;

      if (mounted) {
        setState(() {
          _totalPatientsCount = totalPatients;
          _totalScreeningsCount = thisMonthCount;
          _growthPct = growthPct;
          _coveragePct = coveragePct;
          _normalCount = normalCount;
          _warningCount = warningCount;
          _dangerCount = dangerCount;
          _normalPct = normalPct;
          _warningPct = warningPct;
          _dangerPct = dangerPct;
          _totalTensi = totalTensi;
          _tensiRate = tensiRate;
          _totalKolesterol = totalKolesterol;
          _kolesterolRate = kolesterolRate;
          _totalGula = totalGula;
          _gulaRate = gulaRate;
          _totalAsamUrat = totalAsamUrat;
          _asamUratRate = asamUratRate;
          _isLoading = false;
        });

        _progressController.reset();
        _progressController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppToast.show(
          context: context,
          message: 'Gagal memuat data laporan: $e',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _handleExportExcel() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final monthInt = _monthMap[_selectedMonth] ?? 1;
      final yearInt = int.tryParse(_selectedYear) ?? DateTime.now().year;

      await ExcelMonthlyReportService.instance.exportAndShareReport(
        month: monthInt,
        year: yearInt,
        monthName: _selectedMonth,
      );

      if (mounted) {
        AppToast.show(
          context: context,
          message: 'Laporan Excel $_selectedMonth $_selectedYear berhasil disiapkan!',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context: context,
          message: 'Gagal mengekspor laporan: $e',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: AppPullToRefresh(
              onRefresh: _fetchReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: 120.0, // Clearance for floating bottom navbar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(),
                    const SizedBox(height: 20.0),
                    _buildMonthlyOverview(),
                    const SizedBox(height: 20.0),
                    _buildHealthDistributionCard(),
                    const SizedBox(height: 28.0),
                    _buildServicesSection(),
                    const SizedBox(height: 28.0),
                    _buildAnnualAnalyticsCard(),
                    const SizedBox(height: 24.0),
                    const MedicalDisclaimerCard(showSourcesList: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Clean Flat Top Header matching other main tabs
  Widget _buildHeader() {
    return Container(
      color: AppColors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
              Expanded(
                child: Text(
                  'Layanan Kesehatan',
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

  // 2. Filter Section (Month & Year selector)
  Widget _buildFilterSection() {
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
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Periode Pelaporan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // Dropdown Bulan
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bulan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    _buildDropdownSelector(
                      value: _selectedMonth,
                      items: _months,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              // Dropdown Tahun
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahun',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    _buildDropdownSelector(
                      value: _selectedYear,
                      items: _years,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // Tombol Tampilkan / Refresh Laporan
              Expanded(
                child: _SpringButton(
                  onTap: _isLoading ? () {} : _fetchReportData,
                  child: Container(
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.primary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                'Tampilkan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              // Tombol Ekspor Laporan Excel (.xlsx) - Squircle 16, Solid Primary, Height 50
              Expanded(
                flex: 2,
                child: _SpringButton(
                  onTap: (_isLoading || _isExporting) ? () {} : _handleExportExcel,
                  child: Container(
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    alignment: Alignment.center,
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.table_chart_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Ekspor Excel (.xlsx)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.outline,
            size: 20,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          borderRadius: BorderRadius.circular(14.0),
          dropdownColor: AppColors.surfaceContainerLowest,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // 3. Monthly Overview Cards (Executive KPIs)
  Widget _buildMonthlyOverview() {
    return Row(
      children: [
        // Primary Metric: Total Skrining
        Expanded(
          flex: 6,
          child: Container(
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: _growthPct >= 0
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _growthPct >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 11,
                            color: _growthPct >= 0 ? AppColors.primary : AppColors.error,
                          ),
                          const SizedBox(width: 3.0),
                          Text(
                            '${_growthPct.abs()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _growthPct >= 0 ? AppColors.primary : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                Text(
                  '$_totalScreeningsCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Pemeriksaan Bulan Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        // Secondary Metric: Cakupan Warga Terperiksa
        Expanded(
          flex: 5,
          child: Container(
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 14.0),
                Text(
                  '$_coveragePct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _totalPatientsCount > 0
                      ? '$_totalScreeningsCount dari $_totalPatientsCount Lansia'
                      : 'Cakupan Lansia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Sebaran Status Kesehatan (Clean Solid Progress Bars)
  Widget _buildHealthDistributionCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribusi Status Kesehatan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '$_totalScreeningsCount Pasien',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'Rekapitulasi tensi, kolesterol, gula darah, dan asam urat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20.0),

          // Normal Bar
          _buildStatusBarRow(
            label: 'Normal / Sehat',
            countText: '$_normalCount warga',
            pctText: '(${(_normalPct * 100).round()}%)',
            percentage: _normalPct,
            barColor: AppColors.primary,
          ),
          const SizedBox(height: 16.0),

          // Waspada / Risiko Sedang Bar
          _buildStatusBarRow(
            label: 'Risiko Sedang (Waspada)',
            countText: '$_warningCount warga',
            pctText: '(${(_warningPct * 100).round()}%)',
            percentage: _warningPct,
            barColor: AppColors.statusWarning,
          ),
          const SizedBox(height: 16.0),

          // Bahaya / Risiko Tinggi Bar
          _buildStatusBarRow(
            label: 'Risiko Tinggi (Perlu Tindakan)',
            countText: '$_dangerCount warga',
            pctText: '(${(_dangerPct * 100).round()}%)',
            percentage: _dangerPct,
            barColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarRow({
    required String label,
    required String countText,
    required String pctText,
    required double percentage,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  countText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  pctText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_progressAnimation.value * percentage).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. Rincian Per Layanan (Clean Minimalist Service Cards)
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Layanan Kesehatan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Pilih salah satu layanan untuk melihat riwayat dan pencatatan kader',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14.0),

        // Service 1: Pemeriksaan Tekanan Darah
        _buildServiceCard(
          title: 'Tekanan Darah (Tensi)',
          icon: Icons.monitor_heart_outlined,
          iconBg: AppColors.secondaryContainer,
          iconColor: AppColors.primary,
          totalDone: '$_totalTensi',
          rateText: '$_tensiRate% cakupan',
          statusLabel: _tensiRate >= 70 ? 'Aktif' : 'Perlu Didorong',
          statusColor: _tensiRate >= 70 ? AppColors.primary : AppColors.statusWarning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LayananTensiScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),

        // Service 2: Pemeriksaan Kolesterol
        _buildServiceCard(
          title: 'Kolesterol Total',
          icon: Icons.water_drop_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFE65100),
          totalDone: '$_totalKolesterol',
          rateText: '$_kolesterolRate% cakupan',
          statusLabel: _kolesterolRate >= 70 ? 'Aktif' : 'Perlu Didorong',
          statusColor: _kolesterolRate >= 70 ? AppColors.primary : AppColors.statusWarning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LayananKolesterolScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),

        // Service 3: Pemeriksaan Gula Darah
        _buildServiceCard(
          title: 'Gula Darah',
          icon: Icons.bloodtype_outlined,
          iconBg: AppColors.tertiaryFixed,
          iconColor: AppColors.tertiary,
          totalDone: '$_totalGula',
          rateText: '$_gulaRate% cakupan',
          statusLabel: _gulaRate >= 70 ? 'Aktif' : 'Perlu Didorong',
          statusColor: _gulaRate >= 70 ? AppColors.primary : AppColors.statusWarning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LayananGulaDarahScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),

        // Service 4: Pemeriksaan Asam Urat
        _buildServiceCard(
          title: 'Asam Urat',
          icon: Icons.science_outlined,
          iconBg: const Color(0xFFE0F2F1),
          iconColor: const Color(0xFF00695C),
          totalDone: '$_totalAsamUrat',
          rateText: '$_asamUratRate% cakupan',
          statusLabel: _asamUratRate >= 70 ? 'Aktif' : 'Perlu Didorong',
          statusColor: _asamUratRate >= 70 ? AppColors.primary : AppColors.statusWarning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LayananAsamUratScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String totalDone,
    required String rateText,
    required String statusLabel,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return _SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Compact Icon Squircle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14.0),
            // Title & Meta Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    '$totalDone lansia terperiksa • $rateText',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            // Status Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            // Minimal Chevron
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }

  // 6. Visualisasi & Analitik Tahunan (Solid Flat Card)
  Widget _buildAnnualAnalyticsCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
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
                    const Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 13,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'TREN KESEHATAN TAHUNAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Tahun $_selectedYear',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'Visualisasi Data Tahunan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Evaluasi perkembangan tensi, gula darah, dan keaktifan warga lansia sepanjang tahun dalam grafik komprehensif.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16.0),

          // Solid Mini Preview Chart
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            child: const _SolidMiniChartWidget(),
          ),
          const SizedBox(height: 16.0),

          // Primary CTA: Squircle 16, height 48, solid AppColors.primary, Zero Glow & Zero Gradient
          _SpringButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisualisasiTahunanScreen(),
                ),
              );
            },
            child: Container(
              height: 48.0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16.0),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Buka Analisis Visualisasi Tahunan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Solid Mini Trend Chart (Zero Gradient, Zero Glow, Clean Canvas)
class _SolidMiniChartWidget extends StatefulWidget {
  const _SolidMiniChartWidget();

  @override
  State<_SolidMiniChartWidget> createState() => _SolidMiniChartWidgetState();
}

class _SolidMiniChartWidgetState extends State<_SolidMiniChartWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SolidMiniChartPainter(progress: _animation.value),
        );
      },
    );
  }
}

class _SolidMiniChartPainter extends CustomPainter {
  final double progress;

  _SolidMiniChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid Lines
    final paintGrid = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double gridSpacing = size.height / 3;
    for (int i = 1; i < 3; i++) {
      final double y = i * gridSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Chart Line: Clean Solid Primary
    final paintLine = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Normal baseline line (subtle reference)
    final paintBaseline = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Sample normalized year curve points
    final List<Offset> points = [
      Offset(size.width * 0.05, size.height * 0.70),
      Offset(size.width * 0.22, size.height * 0.60),
      Offset(size.width * 0.40, size.height * 0.35),
      Offset(size.width * 0.58, size.height * 0.45),
      Offset(size.width * 0.76, size.height * 0.25),
      Offset(size.width * 0.95, size.height * 0.30),
    ];

    if (points.isEmpty) return;

    // Draw reference line
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paintBaseline,
    );

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final controlX1 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlY1 = p1.dy;
      final controlX2 = p1.dx + (p2.dx - p1.dx) / 2;
      final controlY2 = p2.dy;

      if (progress >= (i + 1) / (points.length - 1)) {
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p2.dx, p2.dy);
      } else {
        final double segmentProgress = (progress - (i / (points.length - 1))) * (points.length - 1);
        if (segmentProgress > 0) {
          final double currentX = p1.dx + (p2.dx - p1.dx) * segmentProgress;
          final double currentY = p1.dy + (p2.dy - p1.dy) * segmentProgress;
          
          final ctrlX1 = p1.dx + (currentX - p1.dx) / 2;
          final ctrlY1 = p1.dy;
          final ctrlX2 = p1.dx + (currentX - p1.dx) / 2;
          final ctrlY2 = currentY;

          path.cubicTo(ctrlX1, ctrlY1, ctrlX2, ctrlY2, currentX, currentY);
        }
        break;
      }
    }

    // Draw the solid line
    canvas.drawPath(path, paintLine);

    // Draw solid dots on key points (strictly no glow)
    final paintDot = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final paintDotCenter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      if (progress >= i / (points.length - 1)) {
        canvas.drawCircle(points[i], 4.0, paintDot);
        canvas.drawCircle(points[i], 2.0, paintDotCenter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SolidMiniChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Tactile Click Button
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
