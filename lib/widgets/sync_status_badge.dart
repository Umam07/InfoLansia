import 'package:flutter/material.dart';

/// Badge indikator status sinkronisasi data (Belum Sinkron / Offline status).

class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool showSyncedState;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    this.showSyncedState = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSynced && !showSyncedState) {
      return const SizedBox.shrink();
    }

    if (!isSynced) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 12,
              color: Color(0xFFE65100),
            ),
            SizedBox(width: 4),
            Text(
              'Belum Sinkron',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ],
        ),
      );
    }

    // Synced state (optional)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 12,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 4),
          Text(
            'Tersinkron',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

