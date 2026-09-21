import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Tabel Lokal Pasien / Warga Lansia (Offline-first)
class LocalPatients extends Table {
  TextColumn get id => text()(); // UUID string identik dengan Supabase
  TextColumn get name => text()();
  TextColumn get gender => text()();
  TextColumn get birthDate => text()();
  TextColumn get address => text()();
  TextColumn get category => text().withDefault(const Constant('Rutin'))();

  // Kolom Sinkronisasi
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncAction => text().withDefault(const Constant('insert'))(); // 'insert' | 'update' | 'delete'
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabel Lokal Pemeriksaan / Skrining Medis Lansia (Offline-first)
class LocalScreenings extends Table {
  TextColumn get id => text()(); // UUID string identik dengan Supabase
  TextColumn get patientId => text()();
  TextColumn get date => text()();
  RealColumn get weight => real().nullable()();
  RealColumn get height => real().nullable()();
  TextColumn get bloodPressure => text().nullable()();
  RealColumn get cholesterol => real().nullable()();
  RealColumn get bloodSugar => real().nullable()();
  RealColumn get uricAcid => real().nullable()();
  RealColumn get hemoglobin => real().nullable()();
  TextColumn get status => text()();

  // Kolom Sinkronisasi
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncAction => text().withDefault(const Constant('insert'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalPatients, LocalScreenings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();

  @override
  int get schemaVersion => 1;

  // -------------------------------------------------------------
  // HELPER METODE CRUD LOKAL & SINKRONISASI
  // -------------------------------------------------------------

  /// Ambil semua pasien lokal (diurutkan berdasarkan nama)
  Future<List<LocalPatient>> getAllPatients() {
    return (select(localPatients)
          ..where((tbl) => tbl.syncAction.isNotValue('delete'))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  /// Ambil pasien berdasarkan ID
  Future<LocalPatient?> getPatientById(String id) {
    return (select(localPatients)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Normalisasi teks untuk deteksi duplikasi yang presisi
  static String normalizePatientName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizePatientBirthDate(String date) {
    return date.trim().split('T').first;
  }

  static String normalizePatientGender(String gender) {
    final lower = gender.trim().toLowerCase();
    if (lower == 'l' || lower.startsWith('laki') || lower.startsWith('pria') || lower == 'male') {
      return 'L';
    }
    return 'P';
  }

  static String generatePatientDeduplicationKey({
    required String name,
    required String birthDate,
    required String gender,
  }) {
    return '${normalizePatientName(name)}|${normalizePatientBirthDate(birthDate)}|${normalizePatientGender(gender)}';
  }

  /// Cari pasien dengan Nama + Tanggal Lahir + Jenis Kelamin yang sama persis
  /// (Hanya dianggap duplikat jika ketiga komponen ini sama persis)
  Future<LocalPatient?> findDuplicatePatient({
    required String name,
    required String birthDate,
    required String gender,
    String? excludeId,
  }) async {
    final targetKey = generatePatientDeduplicationKey(
      name: name,
      birthDate: birthDate,
      gender: gender,
    );

    final patients = await (select(localPatients)
          ..where((tbl) => tbl.syncAction.isNotValue('delete')))
        .get();

    for (final p in patients) {
      if (excludeId != null && p.id == excludeId) continue;
      final key = generatePatientDeduplicationKey(
        name: p.name,
        birthDate: p.birthDate,
        gender: p.gender,
      );
      if (key == targetKey) {
        return p;
      }
    }
    return null;
  }

  /// Insert atau Update pasien lokal
  Future<void> upsertPatient(LocalPatientsCompanion patient) {
    return into(localPatients).insertOnConflictUpdate(patient);
  }

  /// Ambil semua data pasien yang belum tersinkron
  Future<List<LocalPatient>> getUnsyncedPatients() {
    return (select(localPatients)..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  /// Tandai pasien sebagai tersinkron
  Future<void> markPatientAsSynced(String id) {
    return (update(localPatients)..where((tbl) => tbl.id.equals(id))).write(
      const LocalPatientsCompanion(
        isSynced: Value(true),
        syncAction: Value('none'),
      ),
    );
  }

  /// Tandai pasien dihapus (Soft Delete untuk sinkronisasi offline)
  Future<void> markPatientDeleted(String id) {
    return (update(localPatients)..where((tbl) => tbl.id.equals(id))).write(
      LocalPatientsCompanion(
        isSynced: const Value(false),
        syncAction: const Value('delete'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Ambil semua skrining untuk pasien tertentu (diurutkan tanggal descending)

  Future<List<LocalScreening>> getScreeningsByPatient(String patientId) {
    return (select(localScreenings)
          ..where((tbl) => tbl.patientId.equals(patientId) & tbl.syncAction.isNotValue('delete'))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  /// Ambil semua skrining lokal
  Future<List<LocalScreening>> getAllScreenings() {
    return (select(localScreenings)
          ..where((tbl) => tbl.syncAction.isNotValue('delete'))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  /// Insert atau Update skrining lokal
  Future<void> upsertScreening(LocalScreeningsCompanion screening) {
    return into(localScreenings).insertOnConflictUpdate(screening);
  }

  /// Ambil semua data skrining yang belum tersinkron
  Future<List<LocalScreening>> getUnsyncedScreenings() {
    return (select(localScreenings)..where((tbl) => tbl.isSynced.equals(false))).get();
  }

  /// Tandai skrining sebagai tersinkron
  Future<void> markScreeningAsSynced(String id) {
    return (update(localScreenings)..where((tbl) => tbl.id.equals(id))).write(
      const LocalScreeningsCompanion(
        isSynced: Value(true),
        syncAction: Value('none'),
      ),
    );
  }

  /// Hapus seluruh data lokal (untuk reset database & testing)
  Future<void> clearAllData() async {
    await delete(localScreenings).go();
    await delete(localPatients).go();
  }
}


LazyDatabase _openConnection() {

  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'posyandu_sakura.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
