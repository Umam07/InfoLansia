import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import 'sync_service.dart';

/// Item data baris skrining bulanan untuk laporan
class MonthlyScreeningReportItem {
  final String screeningDate;
  final String patientName;
  final String gender; // 'L' atau 'P'
  final String address;
  final int age;
  final double? weight;
  final double? height;
  final String? bloodPressure;
  final double? bloodSugar;
  final double? cholesterol;
  final double? uricAcid;

  MonthlyScreeningReportItem({
    required this.screeningDate,
    required this.patientName,
    required this.gender,
    required this.address,
    required this.age,
    this.weight,
    this.height,
    this.bloodPressure,
    this.bloodSugar,
    this.cholesterol,
    this.uricAcid,
  });

  /// Format tanggal Indonesia (contoh: 14/10/2026 atau 14-10-2026)
  String get formattedDate {
    try {
      final d = DateTime.parse(screeningDate);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return screeningDate;
    }
  }
}

class ExcelMonthlyReportService {
  ExcelMonthlyReportService._();
  static final ExcelMonthlyReportService instance = ExcelMonthlyReportService._();

  /// Mengambil data skrining bulanan dari SQLite lokal Drift (Offline-First)
  Future<List<MonthlyScreeningReportItem>> fetchMonthlyScreenings({
    required int month,
    required int year,
  }) async {
    // 1. Ambil data pasien dan skrining lokal
    final allPatients = await AppDatabase.instance.getAllPatients();
    final allScreenings = await AppDatabase.instance.getAllScreenings();

    final Map<String, LocalPatient> patientMap = {
      for (final p in allPatients) p.id: p,
    };

    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr';

    final List<MonthlyScreeningReportItem> items = [];

    for (final s in allScreenings) {
      if (s.date.startsWith(prefix)) {
        final patient = patientMap[s.patientId];
        final name = patient?.name ?? 'Warga Lansia';
        final genderStr = patient?.gender.toLowerCase() ?? '';
        final genderShort = (genderStr.startsWith('p') || genderStr.contains('perempuan') || genderStr.contains('wanita'))
            ? 'P'
            : 'L';
        final address = patient?.address ?? 'RW 06';

        // Hitung umur pasien berdasarkan tanggal lahir
        int calculatedAge = 60;
        if (patient != null && patient.birthDate.isNotEmpty) {
          try {
            final birthDate = DateTime.parse(patient.birthDate);
            final screeningDate = DateTime.tryParse(s.date) ?? DateTime.now();
            int age = screeningDate.year - birthDate.year;
            if (screeningDate.month < birthDate.month ||
                (screeningDate.month == birthDate.month && screeningDate.day < birthDate.day)) {
              age--;
            }
            if (age > 0) calculatedAge = age;
          } catch (_) {}
        }

        items.add(MonthlyScreeningReportItem(
          screeningDate: s.date,
          patientName: name,
          gender: genderShort,
          address: address,
          age: calculatedAge,
          weight: s.weight,
          height: s.height,
          bloodPressure: s.bloodPressure,
          bloodSugar: s.bloodSugar,
          cholesterol: s.cholesterol,
          uricAcid: s.uricAcid,
        ));
      }
    }

    // Urutkan berdasarkan tanggal skrining ascending, lalu nama pasien
    items.sort((a, b) {
      final dateComp = a.screeningDate.compareTo(b.screeningDate);
      if (dateComp != 0) return dateComp;
      return a.patientName.compareTo(b.patientName);
    });

    return items;
  }

  /// Membuat Uint8List workbook Excel berformat laporan bulanan resmi
  Uint8List generateReportExcelBytes({
    required int month,
    required int year,
    required String monthName,
    required List<MonthlyScreeningReportItem> items,
    String kelurahan = 'Kelurahan Rawamangun',
    String posyanduName = 'Posyandu Lansia RW 06',
  }) {
    final excel = Excel.createExcel();
    final sheetName = 'Laporan $monthName $year';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 1. Kumpulkan tanggal-tanggal pelaksanaan skrining di bulan tersebut
    final uniqueDates = items.map((e) => e.formattedDate).toSet().toList();
    uniqueDates.sort();
    final datesSummary = uniqueDates.isNotEmpty
        ? uniqueDates.join(', ')
        : '-';

    // Lebar Kolom yang rapi dan tidak terpotong
    sheet.setColumnWidth(0, 7.0);   // No
    sheet.setColumnWidth(1, 16.0);  // Tgl Skrining
    sheet.setColumnWidth(2, 30.0);  // Nama Lansia
    sheet.setColumnWidth(3, 9.0);   // JK (L/P)
    sheet.setColumnWidth(4, 26.0);  // Alamat (RT/RW)
    sheet.setColumnWidth(5, 16.0);  // Umur 45 - 59 Th
    sheet.setColumnWidth(6, 16.0);  // Umur ≥ 60 Th
    sheet.setColumnWidth(7, 13.0);  // BB (kg)
    sheet.setColumnWidth(8, 13.0);  // TB (cm)
    sheet.setColumnWidth(9, 20.0);  // Tekanan Darah (TD)
    sheet.setColumnWidth(10, 18.0); // Gula Darah (GDS)
    sheet.setColumnWidth(11, 18.0); // Kolesterol
    sheet.setColumnWidth(12, 18.0); // Asam Urat

    // Styles
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#006B47'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final subTitleStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#1B1B1D'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final metaStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#556158'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final tableHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#006B47'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeftWhite = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final cellCenterWhite = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeftZebra = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F6F9F7'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final cellCenterZebra = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F6F9F7'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final summaryStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E6F4ED'),
      fontColorHex: ExcelColor.fromHexString('#006B47'),
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    // 2. Tulis Header Dokumen
    _setCellValue(sheet, 0, 0, 'LAPORAN BULANAN PEMERIKSAAN KESEHATAN WARGA LANSIA', titleStyle);
    _setCellValue(sheet, 1, 0, '$posyanduName - $kelurahan', subTitleStyle);
    _setCellValue(sheet, 2, 0, 'Periode: $monthName $year   |   Tanggal Skrining: $datesSummary', metaStyle);

    // 3. Tulis Header Tabel di Baris 4
    const int headerRow = 4;
    final headers = [
      'No',
      'Tgl Skrining',
      'Nama Pasien',
      'JK (L/P)',
      'Alamat (RT/RW)',
      'Umur 45-59 Th',
      'Umur ≥ 60 Th',
      'BB (kg)',
      'TB (cm)',
      'Tekanan Darah',
      'Gula Darah (mg/dL)',
      'Kolesterol (mg/dL)',
      'Asam Urat (mg/dL)',
    ];

    for (int c = 0; c < headers.length; c++) {
      _setCellValue(sheet, headerRow, c, headers[c], tableHeaderStyle);
    }

    // 4. Tulis Baris Data
    int currentRow = headerRow + 1;
    int countL = 0;
    int countP = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isZebra = i % 2 == 1;
      final cLeft = isZebra ? cellLeftZebra : cellLeftWhite;
      final cCenter = isZebra ? cellCenterZebra : cellCenterWhite;

      if (item.gender == 'L') countL++;
      if (item.gender == 'P') countP++;

      // Kategori umur
      final umur45To59Str = (item.age >= 45 && item.age <= 59) ? '${item.age} th' : '-';
      final umur60PlusStr = (item.age >= 60) ? '${item.age} th' : '-';

      // Format nilai medis
      final bbStr = item.weight != null ? item.weight!.toStringAsFixed(1) : '-';
      final tbStr = item.height != null ? item.height!.toStringAsFixed(0) : '-';
      final tdStr = (item.bloodPressure != null && item.bloodPressure!.isNotEmpty)
          ? item.bloodPressure!
          : '-';
      final gdsStr = item.bloodSugar != null ? item.bloodSugar!.toStringAsFixed(0) : '-';
      final kolStr = item.cholesterol != null ? item.cholesterol!.toStringAsFixed(0) : '-';
      final auStr = item.uricAcid != null ? item.uricAcid!.toStringAsFixed(1) : '-';

      _setCellValue(sheet, currentRow, 0, '${i + 1}', cCenter);
      _setCellValue(sheet, currentRow, 1, item.formattedDate, cCenter);
      _setCellValue(sheet, currentRow, 2, item.patientName, cLeft);
      _setCellValue(sheet, currentRow, 3, item.gender, cCenter);
      _setCellValue(sheet, currentRow, 4, item.address, cLeft);
      _setCellValue(sheet, currentRow, 5, umur45To59Str, cCenter);
      _setCellValue(sheet, currentRow, 6, umur60PlusStr, cCenter);
      _setCellValue(sheet, currentRow, 7, bbStr, cCenter);
      _setCellValue(sheet, currentRow, 8, tbStr, cCenter);
      _setCellValue(sheet, currentRow, 9, tdStr, cCenter);
      _setCellValue(sheet, currentRow, 10, gdsStr, cCenter);
      _setCellValue(sheet, currentRow, 11, kolStr, cCenter);
      _setCellValue(sheet, currentRow, 12, auStr, cCenter);

      currentRow++;
    }

    // Jika data kosong
    if (items.isEmpty) {
      _setCellValue(sheet, currentRow, 0, '-', cellCenterWhite);
      _setCellValue(sheet, currentRow, 1, '-', cellCenterWhite);
      _setCellValue(sheet, currentRow, 2, 'Belum ada data skrining pada periode ini', cellLeftWhite);
      for (int c = 3; c < headers.length; c++) {
        _setCellValue(sheet, currentRow, c, '-', cellCenterWhite);
      }
      currentRow++;
    }

    // 5. Baris Rekapitulasi / Total
    currentRow++;
    _setCellValue(
      sheet,
      currentRow,
      0,
      'REKAPITULASI: Total ${items.length} Warga Lansia Diperiksa  (Laki-laki: $countL Orang  |  Perempuan: $countP Orang)',
      summaryStyle,
    );

    return Uint8List.fromList(excel.encode()!);
  }

  /// Ekspor dan bagikan file Excel bulanan langsung ke WhatsApp / Penyimpanan
  Future<String> exportAndShareReport({
    required int month,
    required int year,
    required String monthName,
  }) async {
    // Sinkronisasi data terbaru jika online
    try {
      await SyncService.instance.syncAll();
    } catch (_) {}

    final items = await fetchMonthlyScreenings(month: month, year: year);

    final bytes = generateReportExcelBytes(
      month: month,
      year: year,
      monthName: monthName,
      items: items,
      kelurahan: 'Kelurahan Rawamangun',
      posyanduName: 'Posyandu Lansia RW 06',
    );

    final tempDir = await getTemporaryDirectory();
    final sanitizedMonth = monthName.replaceAll(' ', '_');
    final filePath = '${tempDir.path}/Laporan_Skrining_Lansia_${sanitizedMonth}_$year.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'Laporan_Skrining_Lansia_${sanitizedMonth}_$year.xlsx',
          ),
        ],
        subject: 'Laporan Skrining Posyandu Lansia RW 06 $monthName $year',
        text: 'Laporan Bulanan Pemeriksaan Kesehatan Warga Lansia Posyandu Sakura RW 06, Kelurahan Rawamangun periode $monthName $year (${items.length} data pemeriksaan).',
      ),
    );

    return file.path;
  }

  void _setCellValue(Sheet sheet, int row, int col, String value, CellStyle style) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = style;
  }
}
