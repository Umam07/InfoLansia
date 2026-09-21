import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:posyandu_sakura/database/app_database.dart';

/// Model untuk merepresentasikan baris data pasien yang diimport dari Excel
class PatientImportRow {
  final int rowNumber;
  final String name;
  final String gender; // 'Laki-laki' | 'Perempuan'
  final String rawBirthDate;
  final DateTime? parsedBirthDate;
  final String address;
  final String category;
  final bool isValid;
  final List<String> errors;
  final bool isDuplicate;
  final String? duplicateReason;

  PatientImportRow({
    required this.rowNumber,
    required this.name,
    required this.gender,
    required this.rawBirthDate,
    required this.parsedBirthDate,
    required this.address,
    required this.category,
    required this.isValid,
    required this.errors,
    this.isDuplicate = false,
    this.duplicateReason,
  });

  /// Hitung usia dari tanggal lahir
  int? get age {
    if (parsedBirthDate == null) return null;
    final now = DateTime.now();
    int calculated = now.year - parsedBirthDate!.year;
    if (now.month < parsedBirthDate!.month ||
        (now.month == parsedBirthDate!.month && now.day < parsedBirthDate!.day)) {
      calculated--;
    }
    return calculated >= 0 ? calculated : null;
  }

  /// Format tanggal lahir Bahasa Indonesia (contoh: 17 Agustus 1954)
  String get formattedBirthDate {
    if (parsedBirthDate == null) return rawBirthDate.isNotEmpty ? rawBirthDate : '-';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${parsedBirthDate!.day} ${months[parsedBirthDate!.month - 1]} ${parsedBirthDate!.year}';
  }

  /// Format string tanggal untuk database lokal & Supabase (YYYY-MM-DD)
  String get isoBirthDate {
    if (parsedBirthDate != null) {
      final y = parsedBirthDate!.year.toString().padLeft(4, '0');
      final m = parsedBirthDate!.month.toString().padLeft(2, '0');
      final d = parsedBirthDate!.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return rawBirthDate;
  }
}

/// Hasil evaluasi impor file Excel
class ExcelImportResult {
  final String fileName;
  final int totalRows;
  final List<PatientImportRow> rows;

  ExcelImportResult({
    required this.fileName,
    required this.totalRows,
    required this.rows,
  });

  List<PatientImportRow> get validRows => rows.where((r) => r.isValid).toList();
  List<PatientImportRow> get invalidRows => rows.where((r) => !r.isValid).toList();
  List<PatientImportRow> get duplicateRows => rows.where((r) => r.isDuplicate).toList();
  List<PatientImportRow> get readyToImportRows => rows.where((r) => r.isValid && !r.isDuplicate).toList();

  int get validCount => validRows.length;
  int get invalidCount => invalidRows.length;
  int get duplicateCount => duplicateRows.length;
  int get readyCount => readyToImportRows.length;
}

class ExcelPatientImportService {
  ExcelPatientImportService._();
  static final ExcelPatientImportService instance = ExcelPatientImportService._();

  /// Parse file Excel dari kumpulan bytes (mendukung Uint8List dan List<int>)
  ExcelImportResult parseBytes(
    List<int> bytes, {
    String fileName = 'data_pasien.xlsx',
    Set<String>? existingPatientKeys,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return ExcelImportResult(fileName: fileName, totalRows: 0, rows: []);
    }

    // Ambil sheet pertama atau sheet dengan nama 'Pasien'/'Data'
    Sheet sheet = excel.tables.values.first;
    for (final key in excel.tables.keys) {
      final lower = key.toLowerCase();
      if (lower.contains('pasien') || lower.contains('lansia') || lower.contains('data')) {
        sheet = excel.tables[key]!;
        break;
      }
    }

    final rows = sheet.rows;
    if (rows.isEmpty) {
      return ExcelImportResult(fileName: fileName, totalRows: 0, rows: []);
    }

    // 1. Cari baris header (Nama, Jenis Kelamin / Gender, Tanggal Lahir, Alamat, dsb.)
    int headerIndex = -1;
    int nameCol = 0;
    int genderCol = 1;
    int birthDateCol = 2;
    int addressCol = 3;
    int categoryCol = -1; // Kategori dihilangkan dari template, default otomatis 'Rutin'

    for (int r = 0; r < rows.length && r < 5; r++) {
      final row = rows[r];
      bool foundName = false;
      bool foundGender = false;

      for (int c = 0; c < row.length; c++) {
        final val = _cellToString(row[c]).toLowerCase().trim();
        if (val.contains('nama')) {
          nameCol = c;
          foundName = true;
        } else if (val.contains('jenis kelamin') || val.contains('gender') || val == 'jk' || val.contains('l/p')) {
          genderCol = c;
          foundGender = true;
        } else if (val.contains('lahir') || val.contains('tgl') || val.contains('birth')) {
          birthDateCol = c;
        } else if (val.contains('alamat') || val.contains('rt') || val.contains('rw')) {
          addressCol = c;
        } else if (val.contains('kategori') || val.contains('status')) {
          categoryCol = c;
        }
      }

      if (foundName || (foundGender && r == 0)) {
        headerIndex = r;
        break;
      }
    }

    // Jika tidak ada header terdeteksi, anggap baris 0 adalah header jika mengandung kata 'nama'
    final startIndex = headerIndex >= 0 ? headerIndex + 1 : 1;
    final List<PatientImportRow> parsedRows = [];
    final Map<String, int> seenInFileKeys = {};

    for (int r = startIndex; r < rows.length; r++) {
      final row = rows[r];

      // Periksa apakah baris kosong secara keseluruhan
      final isRowEmpty = row.every((c) => _cellToString(c).trim().isEmpty);
      if (isRowEmpty) continue;

      // Ambil nilai setiap sel
      final rawName = _getCellValue(row, nameCol);
      final rawGender = _getCellValue(row, genderCol);
      final rawBirthDate = _getCellValue(row, birthDateCol);
      final rawAddress = _getCellValue(row, addressCol);
      final rawCategory = categoryCol >= 0 ? _getCellValue(row, categoryCol) : 'Rutin';

      // Abaikan baris instruksi/catatan atau baris yang hanya berisi 1 sel penjelasan
      final filledCellCount = row.where((c) => _cellToString(c).trim().isNotEmpty).length;
      final lowerName = rawName.toLowerCase();
      if (filledCellCount <= 1 ||
          lowerName.startsWith('catatan') ||
          lowerName.startsWith('petunjuk') ||
          lowerName.startsWith('note') ||
          lowerName.startsWith('*') ||
          RegExp(r'^\d+[\.\)]').hasMatch(rawName.trim())) {
        continue;
      }

      final List<String> errors = [];

      // Validasi Nama
      final cleanName = rawName.trim();
      if (cleanName.isEmpty) {
        errors.add('Nama lengkap wajib diisi');
      }

      // Validasi Jenis Kelamin (Cukup L atau P)
      final normalizedGender = _normalizeGender(rawGender);
      if (normalizedGender == null) {
        errors.add('Jenis kelamin harus L (Laki-laki) atau P (Perempuan)');
      }

      // Validasi Tanggal Lahir (Mendukung DD/MM/YYYY dan YYYY-MM-DD)
      final cellDateObject = _getCellDateObject(row, birthDateCol);
      final parsedDate = cellDateObject ?? _parseDate(rawBirthDate);
      if (parsedDate == null) {
        errors.add('Format tanggal lahir salah. Gunakan DD/MM/YYYY (contoh: 17/08/1954) atau YYYY-MM-DD');
      } else {
        final now = DateTime.now();
        if (parsedDate.isAfter(now)) {
          errors.add('Tanggal lahir tidak boleh di masa depan');
        } else if (parsedDate.year < 1900) {
          errors.add('Tahun lahir minimal 1900');
        }
      }

      // Format alamat & kategori
      final cleanAddress = rawAddress.trim().isEmpty ? 'RW 06' : rawAddress.trim();
      final cleanCategory = rawCategory.trim().isEmpty ? 'Rutin' : rawCategory.trim();

      // Pengecekan Duplikat (Hanya jika baris valid: Nama + Tanggal Lahir + Jenis Kelamin sama persis)
      bool isDuplicate = false;
      String? duplicateReason;

      if (errors.isEmpty && parsedDate != null && normalizedGender != null) {
        final isoDate =
            '${parsedDate.year.toString().padLeft(4, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
        final deduplicationKey = AppDatabase.generatePatientDeduplicationKey(
          name: cleanName,
          birthDate: isoDate,
          gender: normalizedGender,
        );

        if (existingPatientKeys != null && existingPatientKeys.contains(deduplicationKey)) {
          isDuplicate = true;
          duplicateReason = 'Sudah terdaftar di sistem';
        } else if (seenInFileKeys.containsKey(deduplicationKey)) {
          final firstRow = seenInFileKeys[deduplicationKey]!;
          isDuplicate = true;
          duplicateReason = 'Duplikat dengan baris #$firstRow di file ini';
        } else {
          seenInFileKeys[deduplicationKey] = r + 1;
        }
      }

      parsedRows.add(PatientImportRow(
        rowNumber: r + 1,
        name: cleanName,
        gender: normalizedGender ?? (rawGender.trim().isNotEmpty ? rawGender.trim() : '-'),
        rawBirthDate: rawBirthDate.trim(),
        parsedBirthDate: parsedDate,
        address: cleanAddress,
        category: cleanCategory,
        isValid: errors.isEmpty,
        errors: errors,
        isDuplicate: isDuplicate,
        duplicateReason: duplicateReason,
      ));
    }

    return ExcelImportResult(
      fileName: fileName,
      totalRows: parsedRows.length,
      rows: parsedRows,
    );
  }

  /// Membuat Uint8List data file Excel Template resmi Posyandu Sakura
  Uint8List generateTemplateBytes() {
    final excel = Excel.createExcel();
    const String sheetName = 'Data Pasien';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Atur Lebar Kolom agar rapi dan tidak terpotong saat dibuka
    sheet.setColumnWidth(0, 32.0); // Nama Lengkap
    sheet.setColumnWidth(1, 24.0); // Jenis Kelamin (L/P)
    sheet.setColumnWidth(2, 30.0); // Tanggal Lahir (DD/MM/YYYY)
    sheet.setColumnWidth(3, 32.0); // Alamat / RT / RW

    // Style Header: Hijau Posyandu (#006B47), Teks Putih Tebal, Rata Tengah
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#006B47'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Style Baris Contoh Data (Hanya 1 Baris)
    final exampleStyleLeft = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F4FAF6'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final exampleStyleCenter = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F4FAF6'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // 1. Header Kolom (Row 0)
    final headers = [
      'Nama Lengkap *',
      'Jenis Kelamin (L/P) *',
      'Tanggal Lahir (DD/MM/YYYY) *',
      'Alamat / RT / RW',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 2. Baris Contoh Data (Row 1 - Hanya 1 Baris sesuai permintaan)
    final exampleRow = [
      'Hj. Siti Aminah',
      'P',
      '17/08/1954',
      'RT 01 / RW 06',
    ];
    for (int i = 0; i < exampleRow.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(exampleRow[i]);
      cell.cellStyle = (i == 1 || i == 2) ? exampleStyleCenter : exampleStyleLeft;
    }

    // 3. Petunjuk Singkat di Bawah Tabel
    final noteTitleStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#006B47'),
      bold: true,
      fontSize: 10,
    );
    final noteStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#556158'),
      fontSize: 9,
    );

    final notes = [
      '',
      '* PETUNJUK PENGISIAN:',
      '1. Kolom bertanda (*) wajib diisi.',
      '2. Jenis Kelamin: Cukup tulis "L" untuk Laki-laki atau "P" untuk Perempuan.',
      '3. Tanggal Lahir: Gunakan format DD/MM/YYYY (contoh: 17/08/1954) atau YYYY-MM-DD (contoh: 1954-08-17).',
      '4. Alamat: Masukkan keterangan RT/RW atau jalan domisili lansia (opsional).',
      '5. Baris contoh di atas (Hj. Siti Aminah) dapat langsung dihapus atau ditimpa dengan data warga Anda.',
    ];

    for (int i = 0; i < notes.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2 + i));
      cell.value = TextCellValue(notes[i]);
      cell.cellStyle = (i == 1) ? noteTitleStyle : noteStyle;
    }

    // 4. Sheet Kedua: Panduan Lengkap
    final guideSheet = excel['Petunjuk Pengisian'];
    guideSheet.setColumnWidth(0, 8.0);
    guideSheet.setColumnWidth(1, 26.0);
    guideSheet.setColumnWidth(2, 12.0);
    guideSheet.setColumnWidth(3, 56.0);

    final guideHeaders = ['No', 'Nama Kolom', 'Wajib?', 'Keterangan & Format yang Didukung'];
    for (int i = 0; i < guideHeaders.length; i++) {
      final cell = guideSheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(guideHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    final guideRows = [
      ['1', 'Nama Lengkap', 'Ya', 'Tuliskan nama lengkap warga lansia beserta gelar jika ada.'],
      ['2', 'Jenis Kelamin', 'Ya', 'Cukup tulis: "L" (Laki-laki) atau "P" (Perempuan).'],
      ['3', 'Tanggal Lahir', 'Ya', 'Gunakan format DD/MM/YYYY (contoh: 17/08/1954) atau YYYY-MM-DD.'],
      ['4', 'Alamat / RT / RW', 'Tidak', 'Contoh: RT 02 / RW 06. Bila kosong otomatis diisi "RW 06".'],
    ];

    for (int r = 0; r < guideRows.length; r++) {
      final rowData = guideRows[r];
      for (int c = 0; c < rowData.length; c++) {
        final cell = guideSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1 + r));
        cell.value = TextCellValue(rowData[c]);
        cell.cellStyle = (c == 0 || c == 2) ? exampleStyleCenter : exampleStyleLeft;
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Simpan & bagikan file template ke pengguna
  Future<String> shareOrSaveTemplate() async {
    final bytes = generateTemplateBytes();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Template_Import_Warga_Lansia.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Template Excel Import Pasien Posyandu Sakura',
        text: 'Format File Excel untuk Import Massal Data Pasien Warga Lansia Posyandu Sakura RW 06.',
      ),
    );

    return file.path;
  }

  // -------------------------------------------------------------
  // HELPER INTERNAL PARSING & VALIDASI
  // -------------------------------------------------------------

  String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return '';
    return _cellToString(row[colIndex]);
  }

  String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is DateCellValue) {
      final y = val.year.toString().padLeft(4, '0');
      final m = val.month.toString().padLeft(2, '0');
      final d = val.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    if (val is DateTimeCellValue) {
      final y = val.year.toString().padLeft(4, '0');
      final m = val.month.toString().padLeft(2, '0');
      final d = val.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return val.toString().trim();
  }

  DateTime? _getCellDateObject(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return null;
    final cell = row[colIndex];
    if (cell == null || cell.value == null) return null;
    final val = cell.value;
    if (val is DateCellValue) {
      return DateTime(val.year, val.month, val.day);
    }
    if (val is DateTimeCellValue) {
      return DateTime(val.year, val.month, val.day);
    }
    return null;
  }

  /// Normalisasi jenis kelamin menjadi 'Laki-laki' atau 'Perempuan'
  String? _normalizeGender(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;

    if (lower == 'l' ||
        lower == 'laki' ||
        lower == 'laki-laki' ||
        lower == 'lakilaki' ||
        lower == 'pria' ||
        lower == 'm' ||
        lower == 'male') {
      return 'Laki-laki';
    }

    if (lower == 'p' ||
        lower == 'perempuan' ||
        lower == 'wanita' ||
        lower == 'f' ||
        lower == 'female') {
      return 'Perempuan';
    }

    return null;
  }

  /// Parser tanggal fleksibel untuk format umum di Indonesia dan Excel
  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Coba DateTime.tryParse (mendukung format ISO seperti 1955-08-17 atau 1955-08-17T00:00:00)
    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) {
      return DateTime(isoParsed.year, isoParsed.month, isoParsed.day);
    }

    // 2. Format YYYY-MM-DD atau YYYY/MM/DD
    final ymdRegex = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$');
    final ymdMatch = ymdRegex.firstMatch(trimmed);
    if (ymdMatch != null) {
      final y = int.tryParse(ymdMatch.group(1)!);
      final m = int.tryParse(ymdMatch.group(2)!);
      final d = int.tryParse(ymdMatch.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // 3. Format DD-MM-YYYY atau DD/MM/YYYY atau DD.MM.YYYY
    final dmyRegex = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$');
    final dmyMatch = dmyRegex.firstMatch(trimmed);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }

    // 4. Deteksi tahun saja (contoh pengisian: 1955)
    final yearOnly = int.tryParse(trimmed);
    if (yearOnly != null && yearOnly >= 1900 && yearOnly <= DateTime.now().year) {
      return DateTime(yearOnly, 1, 1);
    }

    // 5. Deteksi angka serial Excel (misal 20000 s/d 45000)
    final excelSerial = double.tryParse(trimmed);
    if (excelSerial != null && excelSerial > 1000 && excelSerial < 60000) {
      // Serial date Excel dimulai 1900-01-01 (dengan bug leap year 1900)
      final baseDate = DateTime(1899, 12, 30);
      final days = excelSerial.floor();
      return baseDate.add(Duration(days: days));
    }

    return null;
  }
}
