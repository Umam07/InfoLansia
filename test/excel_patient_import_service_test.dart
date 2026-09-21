import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:posyandu_sakura/services/excel_patient_import_service.dart';

void main() {
  group('ExcelPatientImportService Tests', () {
    test('generateTemplateBytes generates parseable Excel workbook', () {
      final service = ExcelPatientImportService.instance;
      final bytes = service.generateTemplateBytes();
      expect(bytes, isNotEmpty);

      final result = service.parseBytes(bytes, fileName: 'template.xlsx');
      expect(result.totalRows, equals(1));
      expect(result.validCount, equals(1));
      expect(result.invalidCount, equals(0));

      final firstRow = result.validRows.first;
      expect(firstRow.name, equals('Hj. Siti Aminah'));
      expect(firstRow.gender, equals('Perempuan'));
      expect(firstRow.isoBirthDate, equals('1954-08-17'));
      expect(firstRow.category, equals('Rutin'));
      expect(firstRow.age, isNotNull);
      expect(firstRow.address, contains('RW 06'));
    });

    test('validates errors for invalid rows', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Nama Lengkap'),
        TextCellValue('Jenis Kelamin'),
        TextCellValue('Tanggal Lahir'),
        TextCellValue('Alamat'),
      ]);

      // Invalid row 1: missing name
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('L'),
        TextCellValue('1950-01-01'),
        TextCellValue('RT 01'),
      ]);

      // Invalid row 2: invalid gender
      sheet.appendRow([
        TextCellValue('Budi'),
        TextCellValue('X'),
        TextCellValue('1950-01-01'),
        TextCellValue('RT 01'),
      ]);

      // Invalid row 3: invalid date
      sheet.appendRow([
        TextCellValue('Ani'),
        TextCellValue('P'),
        TextCellValue('bukan-tanggal'),
        TextCellValue('RT 01'),
      ]);

      final bytes = excel.encode()!;
      final result = ExcelPatientImportService.instance.parseBytes(bytes);

      expect(result.totalRows, equals(3));
      expect(result.invalidCount, equals(3));
      expect(result.validCount, equals(0));

      expect(result.rows[0].errors.first, contains('Nama lengkap'));
      expect(result.rows[1].errors.first, contains('Jenis kelamin'));
      expect(result.rows[2].errors.first, contains('Format tanggal'));
    });

    test('deduplication correctly flags duplicate only when name, birth date, and gender match', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Nama Lengkap'),
        TextCellValue('Jenis Kelamin'),
        TextCellValue('Tanggal Lahir'),
        TextCellValue('Alamat'),
      ]);

      // Row 1: Lansia A
      sheet.appendRow([
        TextCellValue('Budi Santoso'),
        TextCellValue('L'),
        TextCellValue('1950-01-01'),
        TextCellValue('RT 01'),
      ]);

      // Row 2: Same name, same gender, but DIFFERENT birth date -> NOT duplicate!
      sheet.appendRow([
        TextCellValue('Budi Santoso'),
        TextCellValue('L'),
        TextCellValue('1955-06-15'),
        TextCellValue('RT 02'),
      ]);

      // Row 3: Same name, same birth date, but DIFFERENT gender -> NOT duplicate!
      sheet.appendRow([
        TextCellValue('Budi Santoso'),
        TextCellValue('P'),
        TextCellValue('1950-01-01'),
        TextCellValue('RT 03'),
      ]);

      // Row 4: EXACT MATCH with Row 1 (name, birth date, gender) -> DUPLICATE!
      sheet.appendRow([
        TextCellValue('  budi   santoso  '),
        TextCellValue('Laki-laki'),
        TextCellValue('01/01/1950'),
        TextCellValue('RT 04'),
      ]);

      // Row 5: Matches existing DB patient key -> DUPLICATE!
      sheet.appendRow([
        TextCellValue('Siti Aminah'),
        TextCellValue('P'),
        TextCellValue('1952-12-10'),
        TextCellValue('RT 05'),
      ]);

      final bytes = excel.encode()!;
      final existingKeys = {'siti aminah|1952-12-10|P'};

      final result = ExcelPatientImportService.instance.parseBytes(
        bytes,
        existingPatientKeys: existingKeys,
      );

      expect(result.totalRows, equals(5));
      expect(result.validCount, equals(5));
      expect(result.duplicateCount, equals(2));
      expect(result.readyCount, equals(3));

      // Row 1: Valid and not duplicate
      expect(result.rows[0].isDuplicate, isFalse);

      // Row 2: Same name different date -> not duplicate
      expect(result.rows[1].isDuplicate, isFalse);

      // Row 3: Same name different gender -> not duplicate
      expect(result.rows[2].isDuplicate, isFalse);

      // Row 4: Duplicate with Row 1
      expect(result.rows[3].isDuplicate, isTrue);
      expect(result.rows[3].duplicateReason, contains('baris #2'));

      // Row 5: Duplicate with existing DB key
      expect(result.rows[4].isDuplicate, isTrue);
      expect(result.rows[4].duplicateReason, contains('Sudah terdaftar'));
    });
  });
}
