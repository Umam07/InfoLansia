import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import 'tren_kesehatan_screen.dart';
import '../../database/app_database.dart';
import '../../services/network_connectivity_service.dart';

class CheckupRecord {
  final String day;
  final String date;
  final DateTime dateTime;
  final String status; // 'Normal' or 'Perlu Perhatian'
  final String? bloodPressure;
  final String? bloodSugar;
  final String? cholesterol;
  final String? uricAcid;
  final String? weight;
  final String? height;
  final String? hemoglobin;
  final bool isSynced;

  const CheckupRecord({
    required this.day,
    required this.date,
    required this.dateTime,
    required this.status,
    this.bloodPressure,
    this.bloodSugar,
    this.cholesterol,
    this.uricAcid,
    this.weight,
    this.height,
    this.hemoglobin,
    this.isSynced = true,
  });
}

class RiwayatPemeriksaanScreen extends StatefulWidget {
  final String patientId;
  final String name;
  final String age;
  final String gender;

  const RiwayatPemeriksaanScreen({
    super.key,
    required this.patientId,
    this.name = 'Siti Aminah',
    this.age = '65',
    required this.gender,
  });

  @override
  State<RiwayatPemeriksaanScreen> createState() => _RiwayatPemeriksaanScreenState();
}

class _RiwayatPemeriksaanScreenState extends State<RiwayatPemeriksaanScreen> {
  // All checkup records (populated dynamically)
  final List<CheckupRecord> _allRecords = [];
  bool _isLoading = false;

  // Dynamic state list
  late List<CheckupRecord> _filteredRecords;

  // Filter state
  DateTime? _startDate = DateTime(2026, 1, 1);
  DateTime? _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _filteredRecords = [];
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = _allRecords.isEmpty;
    });
    try {
      // 1. Ambil dari database lokal Drift (Offline-First)
      final localList = await AppDatabase.instance.getScreeningsByPatient(widget.patientId);
      if (localList.isNotEmpty) {
        _populateRecordsFromLocal(localList);
      }

      // 2. Jika online, ambil data terbaru dari Supabase
      if (NetworkConnectivityService.instance.isOnline.value) {
        final response = await Supabase.instance.client
            .from('screenings')
            .select()
            .eq('patient_id', widget.patientId)
            .order('date', ascending: false);

        final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
        final List<CheckupRecord> records = data.map((item) {
          final dateStr = item['date'] as String;
          final date = DateTime.parse(dateStr);

          final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          final dayName = days[date.weekday - 1];

          final months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];
          final formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';

          return CheckupRecord(
            day: dayName,
            date: formattedDate,
            dateTime: date,
            status: item['status'] as String? ?? 'Normal',
            bloodPressure: item['blood_pressure'] as String?,
            bloodSugar: item['blood_sugar']?.toString(),
            cholesterol: item['cholesterol']?.toString(),
            uricAcid: item['uric_acid']?.toString(),
            weight: item['weight']?.toString(),
            height: item['height']?.toString(),
            hemoglobin: item['hemoglobin']?.toString(),
            isSynced: true,
          );
        }).toList();

        setState(() {
          _allRecords.clear();
          _allRecords.addAll(records);
          _isLoading = false;
          _applyFilter();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      final fallbackList = await AppDatabase.instance.getScreeningsByPatient(widget.patientId);
      if (fallbackList.isNotEmpty) {
        _populateRecordsFromLocal(fallbackList);
      } else {
        setState(() {
          _isLoading = false;
          _filteredRecords = [];
        });
      }
    }
  }

  void _populateRecordsFromLocal(List<LocalScreening> list) {
    final List<CheckupRecord> records = list.map((item) {
      DateTime date;
      try {
        date = DateTime.parse(item.date);
      } catch (_) {
        date = DateTime.now();
      }

      final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final dayName = days[date.weekday - 1];

      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';

      return CheckupRecord(
        day: dayName,
        date: formattedDate,
        dateTime: date,
        status: item.status,
        bloodPressure: item.bloodPressure,

        bloodSugar: item.bloodSugar?.toString(),
        cholesterol: item.cholesterol?.toString(),
        uricAcid: item.uricAcid?.toString(),
        weight: item.weight?.toString(),
        height: item.height?.toString(),
        hemoglobin: item.hemoglobin?.toString(),
        isSynced: item.isSynced,
      );
    }).toList();

    setState(() {
      _allRecords.clear();
      _allRecords.addAll(records);
      _isLoading = false;
      _applyFilter();
    });
  }


  void _applyFilter() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        if (_startDate != null && record.dateTime.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && record.dateTime.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filteredRecords = List.from(_allRecords);
    });
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // Action to show full checkup detail in a clean minimalist modal (Zero Glow & Zero Gradient)
  void _showRecordDetails(CheckupRecord record) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header (Icon Badge + Title + Subtitle)
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pemeriksaan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${record.day}, ${record.date}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),
                const Divider(color: AppColors.borderSubtle, height: 1.0),
                const SizedBox(height: 16.0),

                // Health status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Kesehatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: record.status == 'Normal'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        record.status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: record.status == 'Normal'
                              ? const Color(0xFF2E7D32)
                              : AppColors.statusWarning,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),

                // Vital signs section header
                Text(
                  'HASIL PEMERIKSAAN LENGKAP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10.0),

                // Details list
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (record.bloodPressure != null)
                            _buildDetailField('Tekanan Darah', record.bloodPressure!, 'mmHg'),
                          if (record.bloodSugar != null)
                            _buildDetailField('Gula Darah', record.bloodSugar!, 'mg/dL'),
                          if (record.cholesterol != null)
                            _buildDetailField('Kolesterol', record.cholesterol!, 'mg/dL'),
                          if (record.uricAcid != null)
                            _buildDetailField('Asam Urat', record.uricAcid!, 'mg/dL'),
                          if (record.weight != null)
                            _buildDetailField('Berat Badan', record.weight!, 'kg'),
                          if (record.height != null)
                            _buildDetailField('Tinggi Badan', record.height!, 'cm'),
                          if (record.hemoglobin != null)
                            _buildDetailField('Hemoglobin', record.hemoglobin!, 'g/dL'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Confirm Action Button (Squircle standard, zero glow)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Interactive Bottom Sheet for Filtering (Clean, Minimalist, Squircle, Zero Glow)
  void _showFilterBottomSheet() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              padding: EdgeInsets.only(
                top: 12.0,
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
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  
                  // Top Title
                  Text(
                    'Filter Rentang Pemeriksaan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Start Date Selector
                  Text(
                    'TANGGAL MULAI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  _SpringButton(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStartDate ?? DateTime(2026, 1, 1),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempStartDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDisplayDate(tempStartDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: tempStartDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: tempStartDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // End Date Selector
                  Text(
                    'TANGGAL SELESAI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  _SpringButton(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEndDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() {
                          tempEndDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDisplayDate(tempEndDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: tempEndDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: tempEndDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28.0),

                  // Actions: Atur Ulang & Terapkan (Squircle standard)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () {
                            setState(() {
                              _resetFilter();
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Atur Ulang',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                          ),
                          onPressed: () {
                            setState(() {
                              _startDate = tempStartDate;
                              _endDate = tempEndDate;
                              _applyFilter();
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Terapkan',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Stats
    final String lastExamDate = _filteredRecords.isNotEmpty 
        ? _filteredRecords.first.date 
        : '-';
    final int totalVisits = _filteredRecords.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBar(context),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 20.0,
          left: 20.0,
          right: 20.0,
          bottom: 32.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Header Card
            _buildPatientProfileCard(),
            const SizedBox(height: 18.0),

            // Stats Grid Cards
            _buildQuickStatsSection(lastExamDate, totalVisits),
            const SizedBox(height: 24.0),

            // Section Header ("Daftar Pemeriksaan") & Filter/Tren Chip
            _buildDaftarPemeriksaanHeader(),
            const SizedBox(height: 16.0),

            // Timeline list
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (_filteredRecords.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRecords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14.0),
                itemBuilder: (context, index) {
                  final record = _filteredRecords[index];
                  return _buildCheckupCard(record, showDetailButton: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Top App Bar (Clean & Minimalist)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.6),
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
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  'Riwayat Pemeriksaan',
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

  // Patient Profile Header (Bento Style, Zero Glow)
  Widget _buildPatientProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Dynamic Profile Avatar (Squircle)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              color: widget.gender == 'Laki-laki' 
                  ? AppColors.tertiary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: widget.gender == 'Laki-laki' 
                    ? AppColors.tertiary.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: _buildInitialsAvatar(),
          ),
          const SizedBox(width: 14.0),
          // Name and Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  '${widget.age} Tahun • ${widget.gender}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Card Icon badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1.0,
              ),
            ),
            child: Text(
              'Rekam Medis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = widget.name.isNotEmpty
        ? widget.name.split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join('').toUpperCase()
        : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: widget.gender == 'Laki-laki' 
              ? AppColors.tertiary 
              : AppColors.primary,
        ),
      ),
    );
  }

  // Quick Summary Stats Grid (2 Bento Cols, Zero Glow & Zero Gradient, Overflow-safe)
  Widget _buildQuickStatsSection(String lastExamDate, int totalVisits) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Last Exam (Solid Primary, Zero Glow)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terakhir Diperiksa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      lastExamDate,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Card 2: Total Visits (Surface Container, Zero Glow)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            constraints: const BoxConstraints(minHeight: 110),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kunjungan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$totalVisits Kali',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Header and Filter Button Row (Squircle Chips)
  Widget _buildDaftarPemeriksaanHeader() {
    final bool isFilterActive = _startDate != null || _endDate != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Daftar Pemeriksaan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8.0),
        Row(
          children: [
            _SpringButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrenKesehatanScreen(
                      patientId: widget.patientId,
                      name: widget.name,
                      age: widget.age,
                      gender: widget.gender,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'Tren',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            _SpringButton(
              onTap: _showFilterBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: isFilterActive 
                      ? AppColors.primary.withValues(alpha: 0.08) 
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isFilterActive 
                        ? AppColors.primary 
                        : AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 15,
                      color: isFilterActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      isFilterActive ? 'Filter (Aktif)' : 'Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isFilterActive ? AppColors.primary : AppColors.textSecondary,
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

  // Checkup Card widget (Clean, Minimalist, Squircle, Strictly Zero Glow & Zero Gradient)
  Widget _buildCheckupCard(CheckupRecord record, {bool showDetailButton = false}) {
    final isNormal = record.status == 'Normal';

    return _SpringButton(
      onTap: () => _showRecordDetails(record),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Date & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.day.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      record.date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isNormal
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isNormal ? const Color(0xFF2E7D32) : AppColors.statusWarning,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            const Divider(color: AppColors.borderSubtle, height: 1.0),
            const SizedBox(height: 14.0),

            // Row 2: Vitals Grid (3 columns)
            LayoutBuilder(
              builder: (context, constraints) {
                final gridItems = <Widget>[];

                if (record.bloodPressure != null) {
                  gridItems.add(_buildGridItem(
                    'Tekanan Darah',
                    record.bloodPressure!,
                    'mmHg',
                    valueColor: !isNormal && record.bloodPressure == '145/95' 
                        ? AppColors.statusWarning 
                        : null,
                  ));
                }
                if (record.bloodSugar != null) {
                  gridItems.add(_buildGridItem('Gula Darah', record.bloodSugar!, 'mg/dL'));
                }
                if (record.cholesterol != null) {
                  gridItems.add(_buildGridItem('Kolesterol', record.cholesterol!, 'mg/dL'));
                }
                if (record.uricAcid != null) {
                  gridItems.add(_buildGridItem('Asam Urat', record.uricAcid!, 'mg/dL'));
                }
                if (record.weight != null) {
                  gridItems.add(_buildGridItem('Berat Badan', record.weight!, 'kg'));
                }
                if (record.height != null) {
                  gridItems.add(_buildGridItem('Tinggi Badan', record.height!, 'cm'));
                }
                if (record.hemoglobin != null) {
                  gridItems.add(_buildGridItem('Hemoglobin', record.hemoglobin!, 'g/dL'));
                }

                final rows = <Widget>[];
                for (var i = 0; i < gridItems.length; i += 3) {
                  final rowChildren = <Widget>[];
                  for (var j = i; j < i + 3 && j < gridItems.length; j++) {
                    rowChildren.add(Expanded(child: gridItems[j]));
                  }
                  while (rowChildren.length < 3) {
                    rowChildren.add(const Expanded(child: SizedBox()));
                  }
                  rows.add(Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rowChildren,
                  ));
                  if (i + 3 < gridItems.length) {
                    rows.add(const SizedBox(height: 14.0));
                  }
                }

                return Column(children: rows);
              },
            ),

            // Row 3: "Lihat Rincian" Clean Affordance
            if (showDetailButton) ...[
              const SizedBox(height: 14.0),
              const Divider(color: AppColors.borderSubtle, height: 1.0),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat Rincian Lengkap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, String value, String unit, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2.0),
            Text(
              unit,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Empty state when filters return nothing (Clean & Squircle)
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            'Tidak Ada Catatan Riwayat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Tidak ada pemeriksaan ditemukan pada rentang tanggal yang dipilih.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18.0),
          _SpringButton(
            onTap: _resetFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'Atur Ulang Filter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
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
