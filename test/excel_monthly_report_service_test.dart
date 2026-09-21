import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:posyandu_sakura/services/excel_monthly_report_service.dart';

void main() {
  group('ExcelMonthlyReportService Tests', () {
    test('generateReportExcelBytes generates valid styled report workbook', () {
      final service = ExcelMonthlyReportService.instance;

      final testItems = [
        MonthlyScreeningReportItem(
          screeningDate: '2026-10-14',
          patientName: 'Bpk. Bambang Sutrisno',
          gender: 'L',
          address: 'RT 03 / RW 06',
          age: 72,
          weight: 65.5,
          height: 168.0,
          bloodPressure: '130/85',
          bloodSugar: 110.0,
          cholesterol: 190.0,
          uricAcid: 6.2,
        ),
        MonthlyScreeningReportItem(
          screeningDate: '2026-10-14',
          patientName: 'Ibu Ratna Juwita',
          gender: 'P',
          address: 'RT 01 / RW 06',
          age: 52,
          weight: 54.0,
          height: 152.0,
          bloodPressure: '120/80',
          bloodSugar: 98.0,
          cholesterol: 175.0,
          uricAcid: 4.8,
        ),
      ];

      final bytes = service.generateReportExcelBytes(
        month: 10,
        year: 2026,
        monthName: 'Oktober',
        items: testItems,
        kelurahan: 'Kelurahan Rawamangun',
        posyanduName: 'Posyandu Lansia RW 06',
      );

      expect(bytes, isNotEmpty);

      final decoded = Excel.decodeBytes(bytes);
      expect(decoded.tables.keys, contains('Laporan Oktober 2026'));

      final sheet = decoded.tables['Laporan Oktober 2026']!;
      expect(sheet.maxRows, greaterThanOrEqualTo(7));

      // Baris 1 metadata
      final subTitleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      expect(subTitleCell.value?.toString(), contains('Posyandu Lansia RW 06'));
      expect(subTitleCell.value?.toString(), contains('Kelurahan Rawamangun'));

      // Baris 2 metadata
      final metaCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
      expect(metaCell.value?.toString(), contains('Oktober 2026'));
      expect(metaCell.value?.toString(), contains('14/10/2026'));

      // Baris 4: Headers
      final nameHeader = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4));
      expect(nameHeader.value?.toString(), equals('Nama Pasien'));

      final ageHeader1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 4));
      expect(ageHeader1.value?.toString(), equals('Umur 45-59 Th'));

      final ageHeader2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 4));
      expect(ageHeader2.value?.toString(), equals('Umur ≥ 60 Th'));

      // Baris 5: Data Pasien 1 (Umur 72 -> masuk kolom ≥ 60 Th)
      final p1Age45 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 5));
      final p1Age60 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 5));
      final p1BP = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 5));
      expect(p1Age45.value?.toString(), equals('-'));
      expect(p1Age60.value?.toString(), equals('72 th'));
      expect(p1BP.value?.toString(), equals('130/85'));

      // Baris 6: Data Pasien 2 (Umur 52 -> masuk kolom 45-59 Th)
      final p2Age45 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 6));
      final p2Age60 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 6));
      final p2BP = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 6));
      expect(p2Age45.value?.toString(), equals('52 th'));
      expect(p2Age60.value?.toString(), equals('-'));
      expect(p2BP.value?.toString(), equals('120/80'));
    });
  });
}
