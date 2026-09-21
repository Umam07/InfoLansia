import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../constants/medical_guidelines.dart';

class MedicalDisclaimerCard extends StatelessWidget {
  final String? source;
  final EdgeInsetsGeometry? margin;
  final bool showSourcesList;

  const MedicalDisclaimerCard({
    super.key,
    this.source,
    this.margin,
    this.showSourcesList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemberitahuan Medis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      MedicalGuidelines.disclaimerText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (source != null && source!.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            const Divider(height: 1.0, color: AppColors.borderSubtle),
            const SizedBox(height: 10.0),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: AppColors.outline,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    'Pedoman Rujukan: $source',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (showSourcesList) ...[
            const SizedBox(height: 14.0),
            const Divider(height: 1.0, color: AppColors.borderSubtle),
            const SizedBox(height: 12.0),
            Text(
              'Rujukan Resmi Standar Skrining:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildSourceItem('Tekanan Darah', MedicalGuidelines.bpSource),
            const SizedBox(height: 6.0),
            _buildSourceItem('Kolesterol Total', MedicalGuidelines.cholesterolSource),
            const SizedBox(height: 6.0),
            _buildSourceItem('Gula Darah', MedicalGuidelines.bloodSugarSource),
            const SizedBox(height: 6.0),
            _buildSourceItem('Asam Urat', MedicalGuidelines.uricAcidSource),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceItem(String parameter, String source) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 6.0, right: 8.0),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$parameter: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(text: source),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
