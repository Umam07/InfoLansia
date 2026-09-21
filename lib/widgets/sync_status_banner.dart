import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/network_connectivity_service.dart';
import '../services/sync_service.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkConnectivityService.instance.isOnline,
      builder: (context, isOnline, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: SyncService.instance.isSyncing,
          builder: (context, isSyncing, _) {
            return ValueListenableBuilder<int>(
              valueListenable: SyncService.instance.unsyncedCount,
              builder: (context, unsyncedCount, _) {
                // 1. Kondisi Offline
                if (!isOnline) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.statusWarning.withValues(alpha: 0.12),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.statusWarning.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 16.0,
                          color: AppColors.statusWarning,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Mode Offline — Data tersimpan aman di perangkat.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (unsyncedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: AppColors.statusWarning,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              '$unsyncedCount lokal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // 2. Kondisi Sedang Sinkronisasi
                if (isSyncing) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14.0,
                          height: 14.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            'Menyinkronkan data dengan server Supabase...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 3. Kondisi Online tapi ada data lokal belum tersinkron
                if (unsyncedCount > 0) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.sync_problem_rounded,
                          size: 16.0,
                          color: AppColors.statusWarning,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '$unsyncedCount catatan belum terunggah ke server.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => SyncService.instance.syncAll(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'Sinkron',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Jika online & semua data telah tersinkron: tidak menampilkan banner (clean UI)
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }
}
