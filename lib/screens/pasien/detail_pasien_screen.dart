import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import 'riwayat_pemeriksaan_screen.dart';
import '../../database/app_database.dart';

import '../../services/network_connectivity_service.dart';

class DetailPasienScreen extends StatefulWidget {
  final String? id;
  final String name;
  final String age;
  final String gender;
  final String address;
  final String birthDate;
  final DateTime? birthDateTime;
  final String healthStatus;
  final int? index;
  final Color? avatarBg;
  final Color? avatarColor;
  final DateTime? createdAt;

  const DetailPasienScreen({
    super.key,
    this.id,
    this.name = 'Siti Aminah',
    this.age = '72',
    this.gender = 'Perempuan',
    this.address = 'Jl. Mawar No. 12, RT 04/RW 02, Kec. Sukasari, Kota Bogor',
    this.birthDate = '12 Mei 1951',
    this.birthDateTime,
    this.healthStatus = 'Kesehatan Stabil',
    this.index,
    this.avatarBg,
    this.avatarColor,
    this.createdAt,
  });

  @override
  State<DetailPasienScreen> createState() => _DetailPasienScreenState();
}

class _DetailPasienScreenState extends State<DetailPasienScreen> {
  late String _name;
  late String _age;
  late String _gender;
  late String _address;
  late String _birthDate;
  late String _healthStatus;
  List<Map<String, dynamic>> _latestScreenings = [];
  bool _isLoadingScreenings = false;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _age = widget.age;
    _gender = widget.gender;
    _address = widget.address;
    _birthDate = widget.birthDate;
    _healthStatus = widget.healthStatus;
    _fetchLatestScreenings();
  }

  Future<void> _fetchLatestScreenings() async {
    if (widget.id == null) return;
    setState(() {
      _isLoadingScreenings = _latestScreenings.isEmpty;
    });

    try {
      // 1. Muat dari database lokal terlebih dahulu (Offline-First)
      final localList = await AppDatabase.instance.getScreeningsByPatient(widget.id!);
      if (localList.isNotEmpty) {
        _applyScreeningsList(localList.map((s) => {
          'id': s.id,
          'patient_id': s.patientId,
          'date': s.date,
          'blood_pressure': s.bloodPressure,
          'blood_sugar': s.bloodSugar,
          'cholesterol': s.cholesterol,
          'uric_acid': s.uricAcid,
          'weight': s.weight,
          'height': s.height,
          'status': s.status,
          'is_synced': s.isSynced,
        }).toList());
      }

      // 2. Jika online, ambil data terbaru dari Supabase
      if (NetworkConnectivityService.instance.isOnline.value) {
        final response = await Supabase.instance.client
            .from('screenings')
            .select()
            .eq('patient_id', widget.id!)
            .order('date', ascending: false);

        _applyScreeningsList(List<Map<String, dynamic>>.from(response));
      } else {
        if (mounted) {
          setState(() {
            _isLoadingScreenings = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingScreenings = false;
        });
      }
    }
  }

  void _applyScreeningsList(List<Map<String, dynamic>> list) {
    if (!mounted) return;
    String status = 'Kesehatan Stabil';
    if (list.isNotEmpty) {
      final latestS = list.first;
      final bpStr = latestS['blood_pressure'] as String?;
      final sugarVal = latestS['blood_sugar'] != null
          ? double.tryParse(latestS['blood_sugar'].toString())
          : null;

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
        status = 'Perlu Perhatian';
      } else if (hasPreBP || hasPreSugar) {
        status = 'Pantauan Sedang';
      } else {
        status = 'Kesehatan Stabil';
      }
    } else {
      status = 'Belum Ada Skrining';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeMonthsAgo = DateTime(today.year, today.month - 3, today.day);

    final filteredScreenings = list.where((s) {
      final dateStr = s['date'] as String?;
      if (dateStr == null) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(threeMonthsAgo) ||
            date.isAtSameMomentAs(threeMonthsAgo);
      } catch (_) {
        return false;
      }
    }).toList();

    setState(() {
      _latestScreenings = filteredScreenings;
      _healthStatus = status;
      _isLoadingScreenings = false;
    });
  }


  String _formatShortIndonesianDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isMale = _gender == 'Laki-laki';

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: _buildAppBar(context),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24.0),
            _buildProfileHeader(context, isMale),
            const SizedBox(height: 24.0),
            _buildPersonalInfoCard(context),
            const SizedBox(height: 24.0),
            _buildScreeningHistory(context),
            const SizedBox(height: 48.0),
          ],
        ),
      ),
    );
  }

  // Clean, Minimal App Bar without Dropdown
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
        child: Container(
          height: 64.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Back Button
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
              // Title
              Expanded(
                child: Text(
                  'Detail Pasien',
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

  // Profile Section Header (Clean, Minimal, Zero Glow)
  Widget _buildProfileHeader(BuildContext context, bool isMale) {
    Color statusBgColor;
    Color statusTextColor;
    Color statusBorderColor;
    Color statusDotColor;

    if (_healthStatus == 'Kesehatan Stabil' ||
        _healthStatus.contains('Terkontrol') ||
        _healthStatus == 'Normal') {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
      statusBorderColor = const Color(0xFFA5D6A7);
      statusDotColor = const Color(0xFF2E7D32);
    } else if (_healthStatus == 'Pantauan Sedang' ||
        _healthStatus.contains('Dipantau')) {
      statusBgColor = const Color(0xFFFFF3E0);
      statusTextColor = AppColors.statusWarning;
      statusBorderColor = const Color(0xFFFFCC80);
      statusDotColor = AppColors.statusWarning;
    } else if (_healthStatus == 'Belum Ada Skrining') {
      statusBgColor = AppColors.surfaceContainerLow;
      statusTextColor = AppColors.textSecondary;
      statusBorderColor = AppColors.borderSubtle;
      statusDotColor = AppColors.outline;
    } else {
      statusBgColor = const Color(0xFFFFEBEE);
      statusTextColor = AppColors.error;
      statusBorderColor = const Color(0xFFFFCDD2);
      statusDotColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Initials Avatar
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMale
                    ? AppColors.tertiary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: (isMale ? AppColors.tertiary : AppColors.primary)
                      .withValues(alpha: 0.25),
                  width: 2.5,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(_name),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isMale ? AppColors.tertiary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Name
          Text(
            _name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6.0),

          // Age & Gender Info
          Text(
            '$_age Tahun • $_gender',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // Health Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: statusBorderColor,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7.0),
                Text(
                  _healthStatus,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Personal Info Bento Card
  Widget _buildPersonalInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pasien',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18.0),

            // Info Rows
            _buildInfoRow(
              icon: Icons.wc_rounded,
              title: 'Jenis Kelamin',
              value: _gender,
            ),
            const SizedBox(height: 14.0),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              title: 'Usia & Tanggal Lahir',
              value: _birthDate.isNotEmpty
                  ? '$_age Tahun ($_birthDate)'
                  : '$_age Tahun',
            ),
            const SizedBox(height: 14.0),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              title: 'Alamat Domisili',
              value: _address,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Screening History Card
  Widget _buildScreeningHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Riwayat Pemeriksaan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                _SpringButton(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiwayatPemeriksaanScreen(
                          patientId: widget.id ?? '',
                          name: _name,
                          age: _age,
                          gender: _gender,
                        ),
                      ),
                    );
                    _fetchLatestScreenings();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: _isLoadingScreenings
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _latestScreenings.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 36.0, horizontal: 20.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 40.0,
                                  color: AppColors.outlineVariant,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Belum ada riwayat pemeriksaan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _latestScreenings.length,
                          separatorBuilder: (context, index) =>
                              _buildHistoryDivider(),
                          itemBuilder: (context, index) {
                            final screening = _latestScreenings[index];
                            final dateStr = _formatShortIndonesianDate(
                                screening['date'] as String);
                            final status =
                                screening['status'] as String? ?? 'Normal';
                            final isNormal = status == 'Normal';

                            return _buildHistoryItem(
                              context: context,
                              icon: isNormal
                                  ? Icons.health_and_safety_outlined
                                  : Icons.monitor_heart_outlined,
                              iconBg: isNormal
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.statusWarning
                                      .withValues(alpha: 0.12),
                              iconColor: isNormal
                                  ? AppColors.primary
                                  : AppColors.statusWarning,
                              title: 'Pemeriksaan Kesehatan',
                              date: dateStr,
                              badgeText: status.toUpperCase(),
                              badgeBg: isNormal
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              badgeTextColor: isNormal
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.statusWarning,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDivider() {
    return Divider(
      height: 1.0,
      thickness: 0.5,
      color: AppColors.borderSubtle.withValues(alpha: 0.5),
      indent: 16.0,
      endIndent: 16.0,
    );
  }
}

// Spring Button for smooth tactile interaction
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
