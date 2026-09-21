import 'package:flutter/material.dart';
import '../theme.dart';

/// Pedoman Medis Resmi untuk Skrining Kesehatan Lansia Posyandu Sakura
/// Rujukan:
/// - Tekanan Darah: AHA/ACC Guideline 2025
/// - Kolesterol: Kementerian Kesehatan RI (P2PTM) & AHA
/// - Gula Darah: Kemenkes RI & PERKENI 2024
/// - Asam Urat: World Health Organization (WHO) Reference Range

class MedicalGuidelines {
  static const String disclaimerText =
      'Hasil skrining bersifat indikatif untuk deteksi awal, bukan merupakan diagnosis pasti. Rujuk warga ke dokter atau fasilitas layanan kesehatan (Puskesmas/Klinik) untuk diagnosis dan penanganan lebih lanjut.';

  static const String bpSource = 'American Heart Association (AHA) / ACC Guideline 2025';
  static const String cholesterolSource = 'Kementerian Kesehatan RI (P2PTM) & AHA';
  static const String bloodSugarSource = 'Kementerian Kesehatan RI & PERKENI 2024';
  static const String uricAcidSource = 'World Health Organization (WHO) Reference Range';

  // ==========================================
  // 1. Tekanan Darah (AHA / ACC Guideline 2025)
  // ==========================================
  static HealthStatusResult evaluateBloodPressure(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) {
      return HealthStatusResult(
        label: 'Tidak Ada Data',
        statusType: HealthStatusType.unknown,
        source: bpSource,
      );
    }

    // Rendah (Hipotensi): < 90 sistolik dan/atau < 60 diastolik
    if (systolic < 90 || diastolic < 60) {
      return HealthStatusResult(
        label: 'Hipotensi (Rendah)',
        shortLabel: 'Rendah',
        statusType: HealthStatusType.warning,
        color: AppColors.statusWarning,
        description: 'Tekanan darah di bawah ambang normal (<90/<60 mmHg)',
        source: bpSource,
      );
    }

    // Hipertensi Tahap 2: >= 140 sistolik atau >= 90 diastolik
    if (systolic >= 140 || diastolic >= 90) {
      return HealthStatusResult(
        label: 'Hipertensi Tahap 2',
        shortLabel: 'Hipertensi 2',
        statusType: HealthStatusType.danger,
        color: AppColors.error,
        description: 'Tekanan darah tinggi (≥140/≥90 mmHg), perlu rujukan nakes',
        source: bpSource,
      );
    }

    // Hipertensi Tahap 1: 130-139 sistolik atau 80-89 diastolik
    if ((systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return HealthStatusResult(
        label: 'Hipertensi Tahap 1',
        shortLabel: 'Hipertensi 1',
        statusType: HealthStatusType.warning,
        color: AppColors.statusWarning,
        description: 'Hipertensi derajat 1 (130-139 / 80-89 mmHg)',
        source: bpSource,
      );
    }

    // Waspada (Elevated / Pra-hipertensi): 120-129 sistolik dan < 80 diastolik
    if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return HealthStatusResult(
        label: 'Waspada (Elevated)',
        shortLabel: 'Waspada',
        statusType: HealthStatusType.warning,
        color: AppColors.statusWarning,
        description: 'Pra-hipertensi (120-129 / <80 mmHg), pantau gaya hidup',
        source: bpSource,
      );
    }

    // Normal: < 120 sistolik dan < 80 diastolik
    return HealthStatusResult(
      label: 'Normal',
      shortLabel: 'Normal',
      statusType: HealthStatusType.normal,
      color: AppColors.primary,
      description: 'Tekanan darah dalam batas ideal (<120/<80 mmHg)',
      source: bpSource,
    );
  }

  // ==========================================
  // 2. Kolesterol Total (Kemenkes RI P2PTM & AHA)
  // ==========================================
  static HealthStatusResult evaluateCholesterol(int? cholesterol) {
    if (cholesterol == null) {
      return HealthStatusResult(
        label: 'Tidak Ada Data',
        statusType: HealthStatusType.unknown,
        source: cholesterolSource,
      );
    }

    if (cholesterol >= 240) {
      return HealthStatusResult(
        label: 'Tinggi',
        shortLabel: 'Tinggi',
        statusType: HealthStatusType.danger,
        color: AppColors.error,
        description: 'Kadar kolesterol tinggi (≥240 mg/dL), risiko kardiovaskular',
        source: cholesterolSource,
      );
    }

    if (cholesterol >= 200) {
      return HealthStatusResult(
        label: 'Waspada (Batas Tinggi)',
        shortLabel: 'Waspada',
        statusType: HealthStatusType.warning,
        color: AppColors.statusWarning,
        description: 'Ambang batas tinggi (200-239 mg/dL), kurangi lemak jenuh',
        source: cholesterolSource,
      );
    }

    return HealthStatusResult(
      label: 'Normal (Desirable)',
      shortLabel: 'Normal',
      statusType: HealthStatusType.normal,
      color: AppColors.primary,
      description: 'Kadar kolesterol ideal (<200 mg/dL)',
      source: cholesterolSource,
    );
  }

  // ==========================================
  // 3. Gula Darah (Kemenkes RI & PERKENI 2024)
  // ==========================================
  static HealthStatusResult evaluateBloodSugar(int? sugar, {bool isFasting = false}) {
    if (sugar == null) {
      return HealthStatusResult(
        label: 'Tidak Ada Data',
        statusType: HealthStatusType.unknown,
        source: bloodSugarSource,
      );
    }

    if (isFasting) {
      // Puasa (GDP)
      if (sugar >= 126) {
        return HealthStatusResult(
          label: 'Tinggi (Diabetes)',
          shortLabel: 'Diabetes',
          statusType: HealthStatusType.danger,
          color: AppColors.error,
          description: 'Glukosa darah puasa tinggi (≥126 mg/dL)',
          source: bloodSugarSource,
        );
      }
      if (sugar >= 100) {
        return HealthStatusResult(
          label: 'Waspada (Prediabetes)',
          shortLabel: 'Prediabetes',
          statusType: HealthStatusType.warning,
          color: AppColors.statusWarning,
          description: 'Ambang prediabetes puasa (100-125 mg/dL)',
          source: bloodSugarSource,
        );
      }
      return HealthStatusResult(
        label: 'Normal',
        shortLabel: 'Normal',
        statusType: HealthStatusType.normal,
        color: AppColors.primary,
        description: 'Glukosa darah puasa normal (70-99 mg/dL)',
        source: bloodSugarSource,
      );
    } else {
      // Sewaktu (GDS) - Skrining Umum Posyandu Lansia
      if (sugar >= 200) {
        return HealthStatusResult(
          label: 'Tinggi (Diabetes)',
          shortLabel: 'Diabetes',
          statusType: HealthStatusType.danger,
          color: AppColors.error,
          description: 'Glukosa darah sewaktu tinggi (≥200 mg/dL)',
          source: bloodSugarSource,
        );
      }
      if (sugar >= 140) {
        return HealthStatusResult(
          label: 'Waspada (Prediabetes)',
          shortLabel: 'Prediabetes',
          statusType: HealthStatusType.warning,
          color: AppColors.statusWarning,
          description: 'Glukosa darah sewaktu waspada (140-199 mg/dL)',
          source: bloodSugarSource,
        );
      }
      return HealthStatusResult(
        label: 'Normal',
        shortLabel: 'Normal',
        statusType: HealthStatusType.normal,
        color: AppColors.primary,
        description: 'Glukosa darah sewaktu normal (<140 mg/dL)',
        source: bloodSugarSource,
      );
    }
  }

  // ==========================================
  // 4. Asam Urat (WHO Reference Range)
  // ==========================================
  static HealthStatusResult evaluateUricAcid(double? uricAcid, {String gender = 'Laki-laki'}) {
    if (uricAcid == null) {
      return HealthStatusResult(
        label: 'Tidak Ada Data',
        statusType: HealthStatusType.unknown,
        source: uricAcidSource,
      );
    }

    final isFemale = gender.toLowerCase() == 'perempuan' || gender.toLowerCase() == 'wanita';

    if (isFemale) {
      // Standar WHO Wanita: 2.4 - 6.0 mg/dL
      // Catatan medis: wanita menopause cenderung mendekati pria (~7.0 mg/dL)
      if (uricAcid > 6.0) {
        return HealthStatusResult(
          label: 'Tinggi (Hiperurisemia)',
          shortLabel: 'Tinggi',
          statusType: HealthStatusType.danger,
          color: AppColors.error,
          description: 'Kadar asam urat di atas ambang wanita (>6.0 mg/dL)',
          source: uricAcidSource,
        );
      }
      if (uricAcid < 2.4) {
        return HealthStatusResult(
          label: 'Rendah',
          shortLabel: 'Rendah',
          statusType: HealthStatusType.warning,
          color: AppColors.statusWarning,
          description: 'Kadar asam urat di bawah ambang wanita (<2.4 mg/dL)',
          source: uricAcidSource,
        );
      }
      return HealthStatusResult(
        label: 'Normal',
        shortLabel: 'Normal',
        statusType: HealthStatusType.normal,
        color: AppColors.primary,
        description: 'Kadar asam urat normal wanita (2.4 - 6.0 mg/dL)',
        source: uricAcidSource,
      );
    } else {
      // Standar WHO Pria: 3.4 - 7.0 mg/dL
      if (uricAcid > 7.0) {
        return HealthStatusResult(
          label: 'Tinggi (Hiperurisemia)',
          shortLabel: 'Tinggi',
          statusType: HealthStatusType.danger,
          color: AppColors.error,
          description: 'Kadar asam urat di atas ambang pria (>7.0 mg/dL)',
          source: uricAcidSource,
        );
      }
      if (uricAcid < 3.4) {
        return HealthStatusResult(
          label: 'Rendah',
          shortLabel: 'Rendah',
          statusType: HealthStatusType.warning,
          color: AppColors.statusWarning,
          description: 'Kadar asam urat di bawah ambang pria (<3.4 mg/dL)',
          source: uricAcidSource,
        );
      }
      return HealthStatusResult(
        label: 'Normal',
        shortLabel: 'Normal',
        statusType: HealthStatusType.normal,
        color: AppColors.primary,
        description: 'Kadar asam urat normal pria (3.4 - 7.0 mg/dL)',
        source: uricAcidSource,
      );
    }
  }

  /// Evaluasi Keseluruhan Status Kesehatan Skrining
  static HealthStatusResult evaluateOverallScreening({
    int? systolic,
    int? diastolic,
    int? cholesterol,
    int? sugar,
    double? uricAcid,
    String gender = 'Laki-laki',
    bool isFasting = false,
  }) {
    final bp = evaluateBloodPressure(systolic, diastolic);
    final chol = evaluateCholesterol(cholesterol);
    final glu = evaluateBloodSugar(sugar, isFasting: isFasting);
    final uric = evaluateUricAcid(uricAcid, gender: gender);

    final results = [bp, chol, glu, uric];

    final hasDanger = results.any((r) => r.statusType == HealthStatusType.danger);
    if (hasDanger) {
      return HealthStatusResult(
        label: 'Risiko Tinggi',
        shortLabel: 'Risiko Tinggi',
        statusType: HealthStatusType.danger,
        color: AppColors.error,
        description: 'Terdapat parameter yang memerlukan penanganan atau rujukan tenaga medis',
        source: 'Kombinasi Pedoman Medis Resmi',
      );
    }

    final hasWarning = results.any((r) => r.statusType == HealthStatusType.warning);
    if (hasWarning) {
      return HealthStatusResult(
        label: 'Waspada (Risiko Sedang)',
        shortLabel: 'Waspada',
        statusType: HealthStatusType.warning,
        color: AppColors.statusWarning,
        description: 'Terdapat parameter ambang batas yang memerlukan evaluasi pola hidup',
        source: 'Kombinasi Pedoman Medis Resmi',
      );
    }

    return HealthStatusResult(
      label: 'Normal / Stabil',
      shortLabel: 'Normal',
      statusType: HealthStatusType.normal,
      color: AppColors.primary,
      description: 'Seluruh parameter skrining berada dalam rentang aman',
      source: 'Kombinasi Pedoman Medis Resmi',
    );
  }
}

enum HealthStatusType {
  normal,
  warning,
  danger,
  unknown,
}

class HealthStatusResult {
  final String label;
  final String shortLabel;
  final HealthStatusType statusType;
  final Color color;
  final String description;
  final String source;

  HealthStatusResult({
    required this.label,
    String? shortLabel,
    required this.statusType,
    Color? color,
    this.description = '',
    required this.source,
  })  : shortLabel = shortLabel ?? label,
        color = color ?? AppColors.primary;
}
