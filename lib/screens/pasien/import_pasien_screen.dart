import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;

import '../../theme.dart';
import '../../widgets/app_toast.dart';
import '../../database/app_database.dart';
import '../../services/sync_service.dart';
import '../../services/excel_patient_import_service.dart';
import '../../utils/uuid_generator.dart';

class ImportPasienScreen extends StatefulWidget {
  const ImportPasienScreen({super.key});

  @override
  State<ImportPasienScreen> createState() => _ImportPasienScreenState();
}

class _ImportPasienScreenState extends State<ImportPasienScreen> {
  bool _isLoadingFile = false;
  bool _isProcessingImport = false;
  bool _isSharingTemplate = false;

  ExcelImportResult? _importResult;
  String? _selectedFileName;
  int? _selectedFileSize;
  String _previewFilter = 'Semua'; // 'Semua' | 'Valid' | 'Bermasalah'

  // Unduh / Bagikan file template Excel resmi
  Future<void> _handleShareTemplate() async {
    if (_isSharingTemplate) return;
    setState(() => _isSharingTemplate = true);
    try {
      await ExcelPatientImportService.instance.shareOrSaveTemplate();
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context: context,
          message: 'Gagal membagikan template: $e',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharingTemplate = false);
      }
    }
  }

  // Pilih file Excel dari penyimpanan HP / Komputer
  Future<void> _handlePickExcelFile() async {
    if (_isLoadingFile || _isProcessingImport) return;

    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (files.isEmpty) {
        return;
      }

      setState(() => _isLoadingFile = true);

      final file = files.first;
      final fileName = file.name;
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;

      if (bytes.isEmpty) {
        if (mounted) {
          AppToast.show(
            context: context,
            message: 'File tidak dapat dibaca atau kosong.',
            type: AppToastType.error,
          );
        }
        return;
      }

      // Ambil daftar pasien yang sudah tersimpan di database lokal untuk deteksi duplikasi
      final existingPatients = await AppDatabase.instance.getAllPatients();
      final existingKeys = existingPatients.map((p) => AppDatabase.generatePatientDeduplicationKey(
        name: p.name,
        birthDate: p.birthDate,
        gender: p.gender,
      )).toSet();

      final parsed = ExcelPatientImportService.instance.parseBytes(
        bytes,
        fileName: fileName,
        existingPatientKeys: existingKeys,
      );

      if (mounted) {
        setState(() {
          _importResult = parsed;
          _selectedFileName = fileName;
          _selectedFileSize = fileSize;
          _previewFilter = 'Semua';
        });

        if (parsed.totalRows == 0) {
          AppToast.show(
            context: context,
            message: 'Tidak ditemukan baris data pasien di file ini.',
            type: AppToastType.warning,
          );
        } else if (parsed.invalidCount > 0 || parsed.duplicateCount > 0) {
          final parts = <String>[];
          if (parsed.readyCount > 0) parts.add('${parsed.readyCount} siap impor');
          if (parsed.duplicateCount > 0) parts.add('${parsed.duplicateCount} duplikat (dilewati)');
          if (parsed.invalidCount > 0) parts.add('${parsed.invalidCount} perlu perbaikan');

          AppToast.show(
            context: context,
            message: parts.join(', '),
            type: AppToastType.warning,
          );
        } else {
          AppToast.show(
            context: context,
            message: 'File berhasil dibaca! Seluruh ${parsed.readyCount} baris baru siap diimpor.',
            type: AppToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context: context,
          message: 'Gagal memproses file Excel: $e',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFile = false);
      }
    }
  }

  // Simpan data pasien valid & belum terdaftar ke database lokal Drift & Sinkronisasi
  Future<void> _handleExecuteImport() async {
    final result = _importResult;
    if (result == null || result.readyToImportRows.isEmpty || _isProcessingImport) return;

    final validList = result.readyToImportRows;
    final totalToImport = validList.length;
    final duplicateCount = result.duplicateCount;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Konfirmasi Impor Pasien',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          duplicateCount > 0
              ? 'Sebanyak $totalToImport data pasien lansia baru akan ditambahkan ke sistem Info Lansia Posyandu Sakura RW 06.\n\nCatatan: $duplicateCount data yang sudah terdaftar di sistem atau berulang di file akan otomatis dilewati agar tidak terjadi data ganda.\n\nLanjutkan proses impor?'
              : 'Sebanyak $totalToImport data pasien lansia valid akan ditambahkan ke sistem Info Lansia Posyandu Sakura RW 06.\n\nLanjutkan proses impor?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, Impor Sekarang',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingImport = true);

    try {
      int successCount = 0;
      final now = DateTime.now();

      for (final row in validList) {
        final newId = UuidGenerator.generate();
        await AppDatabase.instance.upsertPatient(
          LocalPatientsCompanion(
            id: drift.Value(newId),
            name: drift.Value(row.name),
            gender: drift.Value(row.gender),
            birthDate: drift.Value(row.isoBirthDate),
            address: drift.Value(row.address),
            category: drift.Value(row.category),
            isSynced: const drift.Value(false),
            syncAction: const drift.Value('insert'),
            updatedAt: drift.Value(now),
            createdAt: drift.Value(now),
          ),
        );
        successCount++;
      }

      // Memicu sinkronisasi latar belakang jika ada koneksi
      SyncService.instance.syncAll();

      if (mounted) {
        setState(() => _isProcessingImport = false);
        _showSuccessResultDialog(successCount, skippedDuplicates: duplicateCount);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImport = false);
        AppToast.show(
          context: context,
          message: 'Terjadi kendala saat menyimpan data: $e',
          type: AppToastType.error,
        );
      }
    }
  }

  void _showSuccessResultDialog(int count, {int skippedDuplicates = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Impor Berhasil!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                skippedDuplicates > 0
                    ? 'Berhasil menambahkan $count data warga lansia baru.\nSebanyak $skippedDuplicates data duplikat dilewati secara aman.'
                    : 'Berhasil menambahkan $count data warga lansia ke dalam sistem Posyandu Sakura.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Tutup dialog
                    Navigator.pop(context, count); // Kembali ke list pasien dengan result
                  },
                  child: Text(
                    'Selesai & Lihat Data',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _importResult;
    final hasResult = result != null && result.totalRows > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Panduan Singkat
                    _buildGuideCard(),
                    const SizedBox(height: 16.0),

                    // Card 1: Download / Bagikan Template
                    _buildTemplateActionCard(),
                    const SizedBox(height: 16.0),

                    // Card 2: Pilih / Upload File Excel
                    _buildFilePickerCard(),
                    const SizedBox(height: 20.0),

                    // Pratinjau & Validasi Data
                    if (hasResult) ...[
                      _buildSummaryBento(result),
                      const SizedBox(height: 16.0),
                      _buildPreviewFilterChips(result),
                      const SizedBox(height: 12.0),
                      _buildPreviewList(result),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom CTA Button (Squircle 16, Height 52, Zero Glow & Gradient)
            _buildBottomActionBar(result),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Excel Pasien',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Layanan Lansia RW 06',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Petunjuk Kolom',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_chart_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impor Massal Data Warga Lansia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masukkan banyak nama lansia sekaligus menggunakan template spreadsheet (.xlsx). Sistem akan otomatis memeriksa validitas data sebelum disimpan.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khusus Kader & Tenaga Kesehatan Posyandu Sakura RW 06',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateActionCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '1',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Unduh Template Resmi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan template resmi agar format kolom (Nama Lengkap, Jenis Kelamin L/P, Tanggal Lahir, Alamat) langsung sesuai.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSharingTemplate ? null : _handleShareTemplate,
              icon: _isSharingTemplate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _isSharingTemplate ? 'Menyiapkan Template...' : 'Unduh / Bagikan Template (.xlsx)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Pilih File Excel (.xlsx)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area Dropzone / Status File Terpilih
          InkWell(
            onTap: _isLoadingFile ? null : _handlePickExcelFile,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: _selectedFileName != null
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedFileName != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  if (_isLoadingFile) ...[
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Membaca file Excel...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else if (_selectedFileName != null) ...[
                    const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFileSize != null
                          ? '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB • Klik untuk ganti file'
                          : 'Klik untuk ganti file',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.file_upload_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih File Excel dari Perangkat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mendukung format .xlsx dan .xls',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBento(ExcelImportResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasDuplicates = result.duplicateCount > 0;
        final totalCards = hasDuplicates ? 4 : 3;
        final cardWidth = (constraints.maxWidth - ((totalCards - 1) * 8)) / totalCards;
        return Row(
          children: [
            // Total
            _buildBentoItem(
              title: 'Total Baris',
              value: '${result.totalRows}',
              color: AppColors.textPrimary,
              bgColor: AppColors.surfaceContainerLow,
              width: cardWidth,
            ),
            const SizedBox(width: 8),
            // Siap Impor
            _buildBentoItem(
              title: 'Siap Impor',
              value: '${result.readyCount}',
              color: AppColors.primary,
              bgColor: AppColors.primary.withValues(alpha: 0.1),
              width: cardWidth,
            ),
            if (hasDuplicates) ...[
              const SizedBox(width: 8),
              // Duplikat
              _buildBentoItem(
                title: 'Duplikat',
                value: '${result.duplicateCount}',
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                width: cardWidth,
              ),
            ],
            const SizedBox(width: 8),
            // Invalid
            _buildBentoItem(
              title: 'Bermasalah',
              value: '${result.invalidCount}',
              color: result.invalidCount > 0 ? AppColors.error : AppColors.textSecondary,
              bgColor: result.invalidCount > 0
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.surfaceContainerLow,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBentoItem({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewFilterChips(ExcelImportResult result) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            'Pratinjau:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Semua (${result.totalRows})', 'Semua'),
          const SizedBox(width: 6),
          _buildFilterChip('Siap Impor (${result.readyCount})', 'Siap Impor'),
          if (result.duplicateCount > 0) ...[
            const SizedBox(width: 6),
            _buildFilterChip('Duplikat (${result.duplicateCount})', 'Duplikat'),
          ],
          if (result.invalidCount > 0) ...[
            const SizedBox(width: 6),
            _buildFilterChip('Error (${result.invalidCount})', 'Bermasalah'),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _previewFilter == value;
    return InkWell(
      onTap: () => setState(() => _previewFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewList(ExcelImportResult result) {
    List<PatientImportRow> displayedRows = result.rows;
    if (_previewFilter == 'Siap Impor' || _previewFilter == 'Valid') {
      displayedRows = result.readyToImportRows;
    } else if (_previewFilter == 'Duplikat') {
      displayedRows = result.duplicateRows;
    } else if (_previewFilter == 'Bermasalah') {
      displayedRows = result.invalidRows;
    }

    if (displayedRows.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Text(
          'Tidak ada data untuk filter ini.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = displayedRows[index];
        return _buildPatientPreviewCard(row);
      },
    );
  }

  Widget _buildPatientPreviewCard(PatientImportRow row) {
    final isL = row.gender == 'Laki-laki';
    final isP = row.gender == 'Perempuan';

    Color borderColor = AppColors.borderSubtle.withValues(alpha: 0.6);
    double borderWidth = 1.0;
    if (!row.isValid) {
      borderColor = AppColors.error.withValues(alpha: 0.4);
      borderWidth = 1.5;
    } else if (row.isDuplicate) {
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.5);
      borderWidth = 1.5;
    }

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge Baris
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${row.rowNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nama Pasien
              Expanded(
                child: Text(
                  row.name.isNotEmpty ? row.name : '(Nama belum diisi)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: row.name.isNotEmpty ? AppColors.textPrimary : AppColors.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Status Badge
              if (!row.isValid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_rounded, size: 13, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Error',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              else if (row.isDuplicate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_all_rounded, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        'Duplikat',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Siap',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Detail Pasien (JK, Tgl Lahir / Usia, Alamat)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              // Gender
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isL ? Icons.male_rounded : (isP ? Icons.female_rounded : Icons.help_outline),
                    size: 15,
                    color: isL ? AppColors.tertiary : (isP ? AppColors.primary : AppColors.error),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    row.gender,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isL ? AppColors.tertiary : (isP ? AppColors.primary : AppColors.error),
                    ),
                  ),
                ],
              ),

              // Tanggal Lahir / Usia
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cake_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    row.parsedBirthDate != null
                        ? '${row.formattedBirthDate} (${row.age ?? 0} th)'
                        : (row.rawBirthDate.isNotEmpty ? row.rawBirthDate : '-'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: row.parsedBirthDate != null ? AppColors.textSecondary : AppColors.error,
                    ),
                  ),
                ],
              ),

              // Alamat
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    row.address,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Keterangan Duplikat jika baris duplikat
          if (row.isDuplicate) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${row.duplicateReason ?? "Sudah terdaftar di sistem"} (Akan otomatis dilewati)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error Details jika tidak valid
          if (!row.isValid) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row.errors.map((err) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            err,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ExcelImportResult? result) {
    final readyCount = result?.readyCount ?? 0;
    final canImport = readyCount > 0 && !_isProcessingImport && !_isLoadingFile;

    String buttonLabel;
    if (_importResult == null) {
      buttonLabel = 'Pilih File Excel Terlebih Dahulu';
    } else if (readyCount == 0) {
      if ((_importResult?.duplicateCount ?? 0) > 0) {
        buttonLabel = 'Semua Data Duplikat / Sudah Terdaftar';
      } else {
        buttonLabel = 'Tidak Ada Data Valid untuk Diimpor';
      }
    } else {
      buttonLabel = 'Impor $readyCount Lansia Baru ke Sistem';
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52, // Standard height sesuai Button Style Guidelines
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shadowColor: Colors.transparent, // Strictly Zero Glow & Zero Gradient
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Squircle 16px
              ),
            ),
            onPressed: canImport ? _handleExecuteImport : null,
            child: _isProcessingImport
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Menyimpan Data Pasien...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    buttonLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Panduan Kolom Excel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                title: '1. Nama Lengkap (Wajib)',
                desc: 'Nama lengkap warga lansia beserta gelar jika ada.',
              ),
              const SizedBox(height: 10),
              _buildHelpItem(
                title: '2. Jenis Kelamin (Wajib)',
                desc: 'Cukup tulis singkat "L" (Laki-laki) atau "P" (Perempuan).',
              ),
              const SizedBox(height: 10),
              _buildHelpItem(
                title: '3. Tanggal Lahir (Wajib)',
                desc: 'Gunakan format DD/MM/YYYY (contoh: 17/08/1954) atau YYYY-MM-DD. Usia lansia akan otomatis dikalkulasi oleh sistem.',
              ),
              const SizedBox(height: 10),
              _buildHelpItem(
                title: '4. Alamat / RT / RW (Opsional)',
                desc: 'Keterangan RT/RW domisili (contoh: RT 02 / RW 06). Bila dikosongkan otomatis diisi "RW 06".',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Mengerti',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({required String title, required String desc}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
