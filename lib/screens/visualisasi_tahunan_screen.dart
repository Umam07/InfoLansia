import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class CommunityMonthlyData {
  final String monthName;
  final double sys;
  final double dia;
  final double sugar;
  final double cholesterol;
  final double uricAcid;

  CommunityMonthlyData({
    required this.monthName,
    required this.sys,
    required this.dia,
    required this.sugar,
    required this.cholesterol,
    required this.uricAcid,
  });
}

class VisualisasiTahunanScreen extends StatefulWidget {
  const VisualisasiTahunanScreen({super.key});

  @override
  State<VisualisasiTahunanScreen> createState() => _VisualisasiTahunanScreenState();
}

class _VisualisasiTahunanScreenState extends State<VisualisasiTahunanScreen> {
  String _activeTab = 'Tensi'; // Tabs: Tensi, Gula Darah, Kolesterol, Asam Urat

  // Community-wide averages over Jan - Jun 2026 (compiled across all patients)
  final List<CommunityMonthlyData> _monthlyDataList = [
    CommunityMonthlyData(monthName: 'Jan', sys: 126, dia: 82, sugar: 118, cholesterol: 198, uricAcid: 6.2),
    CommunityMonthlyData(monthName: 'Feb', sys: 128, dia: 83, sugar: 122, cholesterol: 204, uricAcid: 6.5),
    CommunityMonthlyData(monthName: 'Mar', sys: 124, dia: 81, sugar: 115, cholesterol: 195, uricAcid: 6.1),
    CommunityMonthlyData(monthName: 'Apr', sys: 122, dia: 80, sugar: 110, cholesterol: 190, uricAcid: 5.8),
    CommunityMonthlyData(monthName: 'Mei', sys: 123, dia: 80, sugar: 112, cholesterol: 192, uricAcid: 5.9),
    CommunityMonthlyData(monthName: 'Jun', sys: 121, dia: 79, sugar: 108, cholesterol: 188, uricAcid: 5.7),
  ];

  // Helper getters for currently selected tab
  List<double> get _primaryPoints {
    switch (_activeTab) {
      case 'Tensi':
        return _monthlyDataList.map((e) => e.sys).toList();
      case 'Gula Darah':
        return _monthlyDataList.map((e) => e.sugar).toList();
      case 'Kolesterol':
        return _monthlyDataList.map((e) => e.cholesterol).toList();
      case 'Asam Urat':
        return _monthlyDataList.map((e) => e.uricAcid).toList();
      default:
        return [];
    }
  }

  List<double>? get _secondaryPoints {
    if (_activeTab == 'Tensi') {
      return _monthlyDataList.map((e) => e.dia).toList();
    }
    return null;
  }

  double get _minY {
    switch (_activeTab) {
      case 'Tensi':
        return 60.0;
      case 'Gula Darah':
        return 80.0;
      case 'Kolesterol':
        return 150.0;
      case 'Asam Urat':
        return 4.0;
      default:
        return 0.0;
    }
  }

  double get _maxY {
    switch (_activeTab) {
      case 'Tensi':
        return 150.0;
      case 'Gula Darah':
        return 150.0;
      case 'Kolesterol':
        return 230.0;
      case 'Asam Urat':
        return 8.0;
      default:
        return 100.0;
    }
  }

  String get _unit {
    switch (_activeTab) {
      case 'Tensi':
        return 'mmHg';
      case 'Gula Darah':
        return 'mg/dL';
      case 'Kolesterol':
        return 'mg/dL';
      case 'Asam Urat':
        return 'mg/dL';
      default:
        return '';
    }
  }

  // Averages calculations
  double _calculateAverage() {
    final points = _primaryPoints;
    if (points.isEmpty) return 0;
    return points.reduce((a, b) => a + b) / points.length;
  }

  double _calculateSecondaryAverage() {
    final points = _secondaryPoints;
    if (points == null || points.isEmpty) return 0;
    return points.reduce((a, b) => a + b) / points.length;
  }

  double _calculateMax() {
    final points = _primaryPoints;
    if (points.isEmpty) return 0;
    return points.reduce((a, b) => a > b ? a : b);
  }

  double _calculateMin() {
    final points = _primaryPoints;
    if (points.isEmpty) return 0;
    return points.reduce((a, b) => a < b ? a : b);
  }

  // Clinical Advice text block
  String get _clinicalAdvice {
    switch (_activeTab) {
      case 'Tensi':
        return 'Tren tekanan darah komunitas rata-rata stabil normal di kisaran 122/80 mmHg. Terjadi tren penurunan positif pada bulan April - Juni karena pelaksanaan program Senam Lansia Rutin berjalan efektif seminggu dua kali di posyandu.';
      case 'Gula Darah':
        return 'Kadar gula darah rata-rata lansia terkontrol sangat baik (<120 mg/dL). Bidan menyarankan untuk terus memperbanyak penyuluhan gizi seimbang, terutama menjaga pola konsumsi makanan manis menjelang festival desa.';
      case 'Kolesterol':
        return 'Tingkat kolesterol rata-rata komunitas berada di ambang batas aman 192 mg/dL. Sebaiknya pertahankan edukasi mengenai pembatasan makanan bersantan, gorengan, dan dorong warga meningkatkan konsumsi buah/sayur tinggi serat.';
      case 'Asam Urat':
        return 'Kadar asam urat rata-rata warga relatif stabil normal di batas 5.9 mg/dL. Tetap pantau dan ingatkan lansia mengenai pembatasan jeroan, kacang-kacangan berlebih, serta dorong hidrasi air putih minimum 2 liter per hari.';
      default:
        return '';
    }
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
            // Period Badge header
            _buildPeriodBadge(),
            const SizedBox(height: 20.0),

            // Navigation tabs
            _buildSlidingTabs(),
            const SizedBox(height: 24.0),

            // Main Interactive Chart Card
            _buildChartCard(),
            const SizedBox(height: 24.0),

            // Bento Summary Stats
            _buildBentoStatsGrid(),
            const SizedBox(height: 24.0),

            // Clinical Insights Analysis
            _buildClinicalInsightsCard(),
          ],
        ),
      ),
    );
  }

  // App Bar
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
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
                  'Tren Analitik Tahunan',
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
              const SizedBox(width: 40.0), // Spacer
            ],
          ),
        ),
      ),
    );
  }

  // Period Header
  Widget _buildPeriodBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    'Laporan Komunitas RW 06',
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
        const SizedBox(width: 12.0),
        Text(
          'Jan - Jun 2026',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Sliding tab bar selector
  Widget _buildSlidingTabs() {
    final tabs = ['Tensi', 'Gula Darah', 'Kolesterol', 'Asam Urat'];
    return Container(
      height: 52.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          return Expanded(
            child: _SpringButton(
              onTap: () => setState(() => _activeTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.outline,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Primary Line Chart Card
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of chart with legends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Perkembangan Rata-rata',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Satuan Ukur: $_unit',
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
              const SizedBox(width: 8.0),
              _buildLegendsWidget(),
            ],
          ),
          const SizedBox(height: 24.0),

          // Custom lines drawer
          SizedBox(
            height: 180,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_activeTab),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              builder: (context, val, child) {
                return CustomPaint(
                  painter: _CommunityLinePainter(
                    primaryPoints: _primaryPoints,
                    secondaryPoints: _secondaryPoints,
                    minY: _minY,
                    maxY: _maxY,
                    animVal: val,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10.0),

          // X Axis Month Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _monthlyDataList.map((e) {
              return Expanded(
                child: Center(
                  child: Text(
                    e.monthName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendsWidget() {
    if (_activeTab == 'Tensi') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
              const SizedBox(width: 6.0),
              Text('Sistolik', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryFixedDim, shape: BoxShape.circle)),
              const SizedBox(width: 6.0),
              Text('Diastolik', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _activeTab == 'Gula Darah'
                ? AppColors.primary
                : _activeTab == 'Kolesterol'
                    ? AppColors.tertiary
                    : Colors.indigo,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          _activeTab,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Bento Stats Overview
  Widget _buildBentoStatsGrid() {
    final avg = _calculateAverage();
    final maxVal = _calculateMax();
    final minVal = _calculateMin();

    return Row(
      children: [
        // Rerata Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rerata Tren',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _activeTab == 'Tensi'
                      ? '${avg.toStringAsFixed(0)}/${_calculateSecondaryAverage().toStringAsFixed(0)}'
                      : _activeTab == 'Asam Urat'
                          ? avg.toStringAsFixed(1)
                          : avg.toStringAsFixed(0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Peak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puncak Tertinggi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _activeTab == 'Asam Urat' ? maxVal.toStringAsFixed(1) : maxVal.toStringAsFixed(0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Low Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Titik Terendah',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _activeTab == 'Asam Urat' ? minVal.toStringAsFixed(1) : minVal.toStringAsFixed(0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Clinical insights block
  Widget _buildClinicalInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Catatan Klinis Bidan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            _clinicalAdvice,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// CommunityLinePainter handles drawing double or single trend lines with fills
class _CommunityLinePainter extends CustomPainter {
  final List<double> primaryPoints;
  final List<double>? secondaryPoints;
  final double minY;
  final double maxY;
  final double animVal;

  _CommunityLinePainter({
    required this.primaryPoints,
    this.secondaryPoints,
    required this.minY,
    required this.maxY,
    required this.animVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double padding = 12.0;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = AppColors.onSurface.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      double yGrid = padding + i * (height - 2 * padding) / 2;
      canvas.drawLine(Offset(0, yGrid), Offset(width, yGrid), gridPaint);
    }

    if (primaryPoints.isEmpty) return;

    // Convert values to screen coordinates
    List<Offset> getScreenCoords(List<double> data) {
      final int n = data.length;
      final coords = <Offset>[];
      for (int i = 0; i < n; i++) {
        final double x = padding + i * (width - 2 * padding) / (n - 1);
        final double normY = (data[i] - minY) / (maxY - minY);
        final double y = height - padding - (normY * (height - 2 * padding) * animVal);
        coords.add(Offset(x, y));
      }
      return coords;
    }

    final primaryCoords = getScreenCoords(primaryPoints);
    final secondaryCoords = secondaryPoints != null ? getScreenCoords(secondaryPoints!) : null;

    // Curves and fills drawer
    void drawCurve(List<Offset> coords, Color color) {
      final path = Path();
      path.moveTo(coords.first.dx, coords.first.dy);

      for (int i = 0; i < coords.length - 1; i++) {
        final p0 = coords[i];
        final p1 = coords[i + 1];
        final ctrlX = p0.dx + (p1.dx - p0.dx) / 2;
        path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
      }

      // Draw Gradient fill
      final fillPath = Path.from(path);
      fillPath.lineTo(coords.last.dx, height);
      fillPath.lineTo(coords.first.dx, height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Draw Stroke
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);

      // Draw glowing points
      final dotStroke = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final dotFill = Paint()..color = color..style = PaintingStyle.fill;

      for (var pt in coords) {
        canvas.drawCircle(pt, 5.0, dotFill);
        canvas.drawCircle(pt, 2.5, dotStroke);
      }
    }

    // Draw lines
    if (secondaryCoords != null) {
      drawCurve(secondaryCoords, AppColors.primaryFixedDim);
    }
    drawCurve(primaryCoords, AppColors.primaryContainer);
  }

  @override
  bool shouldRepaint(covariant _CommunityLinePainter oldDelegate) {
    return oldDelegate.animVal != animVal ||
        oldDelegate.primaryPoints != primaryPoints ||
        oldDelegate.secondaryPoints != secondaryPoints;
  }
}

// tactile private button
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
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.95,
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
