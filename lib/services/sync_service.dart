import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import 'kader_auth_service.dart';
import 'network_connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static SyncService get instance => _instance;

  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<int> unsyncedCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastSyncMessage = ValueNotifier<String?>(null);

  /// Hitung total data lokal yang belum tersinkron
  Future<void> refreshUnsyncedCount() async {
    try {
      final unsyncedPatients = await AppDatabase.instance.getUnsyncedPatients();
      final unsyncedScreenings = await AppDatabase.instance.getUnsyncedScreenings();
      unsyncedCount.value = unsyncedPatients.length + unsyncedScreenings.length;
    } catch (e) {
      debugPrint('[SyncService] Gagal menghitung data belum sinkron: $e');
    }
  }

  /// Sinkronisasi penuh (Upward & Downward)
  Future<bool> syncAll() async {
    if (isSyncing.value) return false;
    if (!NetworkConnectivityService.instance.isOnline.value) {
      await refreshUnsyncedCount();
      return false;
    }

    isSyncing.value = true;
    lastSyncMessage.value = 'Memvalidasi sesi kader...';

    try {
      // 1. Re-validasi status kader di Supabase (Pastikan akun belum dinonaktifkan admin)
      final isKaderValid = await KaderAuthService.revalidateCurrentKader();
      if (!isKaderValid) {
        debugPrint('[SyncService] Akun kader tidak valid / nonaktif. Batalkan sync.');
        isSyncing.value = false;
        lastSyncMessage.value = 'Akun kader dinonaktifkan oleh administrator.';
        return false;
      }

      // 2. Upward Sync: Kirim data lokal yang belum tersinkron ke Supabase
      lastSyncMessage.value = 'Mengunggah data lokal ke server...';
      await _uploadLocalChanges();

      // 3. Downward Sync: Unduh data terbaru dari Supabase ke lokal
      lastSyncMessage.value = 'Mengunduh data terbaru dari server...';
      await _downloadServerData();

      await refreshUnsyncedCount();
      lastSyncMessage.value = 'Sinkronisasi berhasil.';
      isSyncing.value = false;
      return true;
    } catch (e) {
      debugPrint('[SyncService] Error saat sinkronisasi: $e');
      lastSyncMessage.value = 'Gagal menyinkronkan data: $e';
      await refreshUnsyncedCount();
      isSyncing.value = false;
      return false;
    }
  }

  /// Unggah data lokal (is_synced == false) ke Supabase
  Future<void> _uploadLocalChanges() async {
    final unsyncedPatients = await AppDatabase.instance.getUnsyncedPatients();
    final unsyncedScreenings = await AppDatabase.instance.getUnsyncedScreenings();

    // 1. Upload Pasien Lokal
    for (final p in unsyncedPatients) {
      try {
        if (p.syncAction == 'insert' || p.syncAction == 'update') {
          await Supabase.instance.client.from('patients').upsert({
            'id': p.id,
            'name': p.name,
            'gender': p.gender,
            'birth_date': p.birthDate,
            'address': p.address,
            'category': p.category,
            'created_at': p.createdAt.toIso8601String(),
          });
          await AppDatabase.instance.markPatientAsSynced(p.id);
        } else if (p.syncAction == 'delete') {
          await Supabase.instance.client.from('patients').delete().eq('id', p.id);
          // Hapus permanen dari SQLite setelah sukses terhapus di server
          await (AppDatabase.instance.delete(AppDatabase.instance.localPatients)
                ..where((tbl) => tbl.id.equals(p.id)))
              .go();
        }
      } catch (e) {
        debugPrint('[SyncService] Gagal mengunggah pasien ${p.id}: $e');
      }
    }

    // 2. Upload Skrining Lokal
    for (final s in unsyncedScreenings) {
      try {
        if (s.syncAction == 'insert' || s.syncAction == 'update') {
          await Supabase.instance.client.from('screenings').upsert({
            'id': s.id,
            'patient_id': s.patientId,
            'date': s.date,
            'weight': s.weight,
            'height': s.height,
            'blood_pressure': s.bloodPressure,
            'cholesterol': s.cholesterol,
            'blood_sugar': s.bloodSugar,
            'uric_acid': s.uricAcid,
            'hemoglobin': s.hemoglobin,
            'status': s.status,
            'created_at': s.createdAt.toIso8601String(),
          });
          await AppDatabase.instance.markScreeningAsSynced(s.id);
        } else if (s.syncAction == 'delete') {
          await Supabase.instance.client.from('screenings').delete().eq('id', s.id);
          await (AppDatabase.instance.delete(AppDatabase.instance.localScreenings)
                ..where((tbl) => tbl.id.equals(s.id)))
              .go();
        }
      } catch (e) {
        debugPrint('[SyncService] Gagal mengunggah skrining ${s.id}: $e');
      }
    }
  }

  /// Unduh data dari Supabase ke lokal Drift (Two-way sync & reconciliation)
  Future<void> _downloadServerData() async {
    // 1. Ambil data pasien dari server
    final serverPatients =
        await Supabase.instance.client.from('patients').select();
    final Set<String> serverPatientIds = {};

    for (final raw in serverPatients) {
      final id = raw['id'].toString();
      serverPatientIds.add(id);
      final local = await AppDatabase.instance.getPatientById(id);

      // Jika ada data lokal yang belum tersinkron, lindungi dengan LWW (Last-Write-Wins)
      if (local != null && !local.isSynced) {
        continue;
      }

      final createdAt = DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.now();

      await AppDatabase.instance.upsertPatient(
        LocalPatientsCompanion(
          id: drift.Value(id),
          name: drift.Value(raw['name'] ?? ''),
          gender: drift.Value(raw['gender'] ?? 'Laki-laki'),
          birthDate: drift.Value(raw['birth_date'] ?? '1950-01-01'),
          address: drift.Value(raw['address'] ?? '-'),
          category: drift.Value(raw['category'] ?? 'Rutin'),
          isSynced: const drift.Value(true),
          syncAction: const drift.Value('none'),
          updatedAt: drift.Value(DateTime.now()),
          createdAt: drift.Value(createdAt),
        ),
      );
    }

    // 2. Ambil data skrining dari server
    final serverScreenings =
        await Supabase.instance.client.from('screenings').select();
    final Set<String> serverScreeningIds = {};

    for (final raw in serverScreenings) {
      final id = raw['id'].toString();
      serverScreeningIds.add(id);
      final local = await (AppDatabase.instance.select(AppDatabase.instance.localScreenings)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (local != null && !local.isSynced) {
        continue;
      }

      final createdAt = DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.now();

      await AppDatabase.instance.upsertScreening(
        LocalScreeningsCompanion(
          id: drift.Value(id),
          patientId: drift.Value(raw['patient_id'] ?? ''),
          date: drift.Value(raw['date'] ?? ''),
          weight: drift.Value((raw['weight'] as num?)?.toDouble()),
          height: drift.Value((raw['height'] as num?)?.toDouble()),
          bloodPressure: drift.Value(raw['blood_pressure']?.toString()),
          cholesterol: drift.Value((raw['cholesterol'] as num?)?.toDouble()),
          bloodSugar: drift.Value((raw['blood_sugar'] as num?)?.toDouble()),
          uricAcid: drift.Value((raw['uric_acid'] as num?)?.toDouble()),
          hemoglobin: drift.Value((raw['hemoglobin'] as num?)?.toDouble()),
          status: drift.Value(raw['status']?.toString() ?? 'Normal'),
          isSynced: const drift.Value(true),
          syncAction: const drift.Value('none'),
          updatedAt: drift.Value(DateTime.now()),
          createdAt: drift.Value(createdAt),
        ),
      );
    }

    // 3. Rekonsiliasi data lokal yang sudah dihapus di server (Prune deleted server data)
    final localSyncedPatients = await (AppDatabase.instance.select(AppDatabase.instance.localPatients)
          ..where((tbl) => tbl.isSynced.equals(true) & tbl.syncAction.equals('none')))
        .get();
    for (final lp in localSyncedPatients) {
      if (!serverPatientIds.contains(lp.id)) {
        await (AppDatabase.instance.delete(AppDatabase.instance.localPatients)
              ..where((tbl) => tbl.id.equals(lp.id)))
            .go();
      }
    }

    final localSyncedScreenings = await (AppDatabase.instance.select(AppDatabase.instance.localScreenings)
          ..where((tbl) => tbl.isSynced.equals(true) & tbl.syncAction.equals('none')))
        .get();
    for (final ls in localSyncedScreenings) {
      if (!serverScreeningIds.contains(ls.id)) {
        await (AppDatabase.instance.delete(AppDatabase.instance.localScreenings)
              ..where((tbl) => tbl.id.equals(ls.id)))
            .go();
      }
    }

    // 4. Bersihkan juga data skrining lokal yatim (orphan) yang pasiennya sudah tidak ada
    final currentPatients = await AppDatabase.instance.getAllPatients();
    final currentPatientIds = currentPatients.map((p) => p.id).toSet();
    final allScreenings = await AppDatabase.instance.getAllScreenings();
    for (final s in allScreenings) {
      if (!currentPatientIds.contains(s.patientId)) {
        await (AppDatabase.instance.delete(AppDatabase.instance.localScreenings)
              ..where((tbl) => tbl.id.equals(s.id)))
            .go();
      }
    }
  }
}
