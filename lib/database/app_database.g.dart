// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalPatientsTable extends LocalPatients
    with TableInfo<$LocalPatientsTable, LocalPatient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _birthDateMeta =
      const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
      'birth_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Rutin'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncActionMeta =
      const VerificationMeta('syncAction');
  @override
  late final GeneratedColumn<String> syncAction = GeneratedColumn<String>(
      'sync_action', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('insert'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        gender,
        birthDate,
        address,
        category,
        isSynced,
        syncAction,
        updatedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_patients';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPatient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta,
          birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_action')) {
      context.handle(
          _syncActionMeta,
          syncAction.isAcceptableOrUnknown(
              data['sync_action']!, _syncActionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPatient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPatient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      birthDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birth_date'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_action'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalPatientsTable createAlias(String alias) {
    return $LocalPatientsTable(attachedDatabase, alias);
  }
}

class LocalPatient extends DataClass implements Insertable<LocalPatient> {
  final String id;
  final String name;
  final String gender;
  final String birthDate;
  final String address;
  final String category;
  final bool isSynced;
  final String syncAction;
  final DateTime updatedAt;
  final DateTime createdAt;
  const LocalPatient(
      {required this.id,
      required this.name,
      required this.gender,
      required this.birthDate,
      required this.address,
      required this.category,
      required this.isSynced,
      required this.syncAction,
      required this.updatedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['gender'] = Variable<String>(gender);
    map['birth_date'] = Variable<String>(birthDate);
    map['address'] = Variable<String>(address);
    map['category'] = Variable<String>(category);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_action'] = Variable<String>(syncAction);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPatientsCompanion toCompanion(bool nullToAbsent) {
    return LocalPatientsCompanion(
      id: Value(id),
      name: Value(name),
      gender: Value(gender),
      birthDate: Value(birthDate),
      address: Value(address),
      category: Value(category),
      isSynced: Value(isSynced),
      syncAction: Value(syncAction),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPatient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPatient(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String>(json['gender']),
      birthDate: serializer.fromJson<String>(json['birthDate']),
      address: serializer.fromJson<String>(json['address']),
      category: serializer.fromJson<String>(json['category']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncAction: serializer.fromJson<String>(json['syncAction']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String>(gender),
      'birthDate': serializer.toJson<String>(birthDate),
      'address': serializer.toJson<String>(address),
      'category': serializer.toJson<String>(category),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncAction': serializer.toJson<String>(syncAction),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPatient copyWith(
          {String? id,
          String? name,
          String? gender,
          String? birthDate,
          String? address,
          String? category,
          bool? isSynced,
          String? syncAction,
          DateTime? updatedAt,
          DateTime? createdAt}) =>
      LocalPatient(
        id: id ?? this.id,
        name: name ?? this.name,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        address: address ?? this.address,
        category: category ?? this.category,
        isSynced: isSynced ?? this.isSynced,
        syncAction: syncAction ?? this.syncAction,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalPatient copyWithCompanion(LocalPatientsCompanion data) {
    return LocalPatient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      address: data.address.present ? data.address.value : this.address,
      category: data.category.present ? data.category.value : this.category,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncAction:
          data.syncAction.present ? data.syncAction.value : this.syncAction,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPatient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('address: $address, ')
          ..write('category: $category, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAction: $syncAction, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, gender, birthDate, address,
      category, isSynced, syncAction, updatedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPatient &&
          other.id == this.id &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.birthDate == this.birthDate &&
          other.address == this.address &&
          other.category == this.category &&
          other.isSynced == this.isSynced &&
          other.syncAction == this.syncAction &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class LocalPatientsCompanion extends UpdateCompanion<LocalPatient> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> gender;
  final Value<String> birthDate;
  final Value<String> address;
  final Value<String> category;
  final Value<bool> isSynced;
  final Value<String> syncAction;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalPatientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.address = const Value.absent(),
    this.category = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPatientsCompanion.insert({
    required String id,
    required String name,
    required String gender,
    required String birthDate,
    required String address,
    this.category = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAction = const Value.absent(),
    required DateTime updatedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        gender = Value(gender),
        birthDate = Value(birthDate),
        address = Value(address),
        updatedAt = Value(updatedAt),
        createdAt = Value(createdAt);
  static Insertable<LocalPatient> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<String>? birthDate,
    Expression<String>? address,
    Expression<String>? category,
    Expression<bool>? isSynced,
    Expression<String>? syncAction,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (address != null) 'address': address,
      if (category != null) 'category': category,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncAction != null) 'sync_action': syncAction,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPatientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? gender,
      Value<String>? birthDate,
      Value<String>? address,
      Value<String>? category,
      Value<bool>? isSynced,
      Value<String>? syncAction,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalPatientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      category: category ?? this.category,
      isSynced: isSynced ?? this.isSynced,
      syncAction: syncAction ?? this.syncAction,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncAction.present) {
      map['sync_action'] = Variable<String>(syncAction.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPatientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('address: $address, ')
          ..write('category: $category, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAction: $syncAction, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalScreeningsTable extends LocalScreenings
    with TableInfo<$LocalScreeningsTable, LocalScreening> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalScreeningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
      'height', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bloodPressureMeta =
      const VerificationMeta('bloodPressure');
  @override
  late final GeneratedColumn<String> bloodPressure = GeneratedColumn<String>(
      'blood_pressure', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cholesterolMeta =
      const VerificationMeta('cholesterol');
  @override
  late final GeneratedColumn<double> cholesterol = GeneratedColumn<double>(
      'cholesterol', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bloodSugarMeta =
      const VerificationMeta('bloodSugar');
  @override
  late final GeneratedColumn<double> bloodSugar = GeneratedColumn<double>(
      'blood_sugar', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _uricAcidMeta =
      const VerificationMeta('uricAcid');
  @override
  late final GeneratedColumn<double> uricAcid = GeneratedColumn<double>(
      'uric_acid', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hemoglobinMeta =
      const VerificationMeta('hemoglobin');
  @override
  late final GeneratedColumn<double> hemoglobin = GeneratedColumn<double>(
      'hemoglobin', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncActionMeta =
      const VerificationMeta('syncAction');
  @override
  late final GeneratedColumn<String> syncAction = GeneratedColumn<String>(
      'sync_action', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('insert'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        patientId,
        date,
        weight,
        height,
        bloodPressure,
        cholesterol,
        bloodSugar,
        uricAcid,
        hemoglobin,
        status,
        isSynced,
        syncAction,
        updatedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_screenings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalScreening> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('blood_pressure')) {
      context.handle(
          _bloodPressureMeta,
          bloodPressure.isAcceptableOrUnknown(
              data['blood_pressure']!, _bloodPressureMeta));
    }
    if (data.containsKey('cholesterol')) {
      context.handle(
          _cholesterolMeta,
          cholesterol.isAcceptableOrUnknown(
              data['cholesterol']!, _cholesterolMeta));
    }
    if (data.containsKey('blood_sugar')) {
      context.handle(
          _bloodSugarMeta,
          bloodSugar.isAcceptableOrUnknown(
              data['blood_sugar']!, _bloodSugarMeta));
    }
    if (data.containsKey('uric_acid')) {
      context.handle(_uricAcidMeta,
          uricAcid.isAcceptableOrUnknown(data['uric_acid']!, _uricAcidMeta));
    }
    if (data.containsKey('hemoglobin')) {
      context.handle(
          _hemoglobinMeta,
          hemoglobin.isAcceptableOrUnknown(
              data['hemoglobin']!, _hemoglobinMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('sync_action')) {
      context.handle(
          _syncActionMeta,
          syncAction.isAcceptableOrUnknown(
              data['sync_action']!, _syncActionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalScreening map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalScreening(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height']),
      bloodPressure: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blood_pressure']),
      cholesterol: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cholesterol']),
      bloodSugar: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}blood_sugar']),
      uricAcid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}uric_acid']),
      hemoglobin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hemoglobin']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      syncAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_action'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalScreeningsTable createAlias(String alias) {
    return $LocalScreeningsTable(attachedDatabase, alias);
  }
}

class LocalScreening extends DataClass implements Insertable<LocalScreening> {
  final String id;
  final String patientId;
  final String date;
  final double? weight;
  final double? height;
  final String? bloodPressure;
  final double? cholesterol;
  final double? bloodSugar;
  final double? uricAcid;
  final double? hemoglobin;
  final String status;
  final bool isSynced;
  final String syncAction;
  final DateTime updatedAt;
  final DateTime createdAt;
  const LocalScreening(
      {required this.id,
      required this.patientId,
      required this.date,
      this.weight,
      this.height,
      this.bloodPressure,
      this.cholesterol,
      this.bloodSugar,
      this.uricAcid,
      this.hemoglobin,
      required this.status,
      required this.isSynced,
      required this.syncAction,
      required this.updatedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    if (!nullToAbsent || bloodPressure != null) {
      map['blood_pressure'] = Variable<String>(bloodPressure);
    }
    if (!nullToAbsent || cholesterol != null) {
      map['cholesterol'] = Variable<double>(cholesterol);
    }
    if (!nullToAbsent || bloodSugar != null) {
      map['blood_sugar'] = Variable<double>(bloodSugar);
    }
    if (!nullToAbsent || uricAcid != null) {
      map['uric_acid'] = Variable<double>(uricAcid);
    }
    if (!nullToAbsent || hemoglobin != null) {
      map['hemoglobin'] = Variable<double>(hemoglobin);
    }
    map['status'] = Variable<String>(status);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_action'] = Variable<String>(syncAction);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalScreeningsCompanion toCompanion(bool nullToAbsent) {
    return LocalScreeningsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      date: Value(date),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      bloodPressure: bloodPressure == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodPressure),
      cholesterol: cholesterol == null && nullToAbsent
          ? const Value.absent()
          : Value(cholesterol),
      bloodSugar: bloodSugar == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodSugar),
      uricAcid: uricAcid == null && nullToAbsent
          ? const Value.absent()
          : Value(uricAcid),
      hemoglobin: hemoglobin == null && nullToAbsent
          ? const Value.absent()
          : Value(hemoglobin),
      status: Value(status),
      isSynced: Value(isSynced),
      syncAction: Value(syncAction),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalScreening.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalScreening(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      date: serializer.fromJson<String>(json['date']),
      weight: serializer.fromJson<double?>(json['weight']),
      height: serializer.fromJson<double?>(json['height']),
      bloodPressure: serializer.fromJson<String?>(json['bloodPressure']),
      cholesterol: serializer.fromJson<double?>(json['cholesterol']),
      bloodSugar: serializer.fromJson<double?>(json['bloodSugar']),
      uricAcid: serializer.fromJson<double?>(json['uricAcid']),
      hemoglobin: serializer.fromJson<double?>(json['hemoglobin']),
      status: serializer.fromJson<String>(json['status']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncAction: serializer.fromJson<String>(json['syncAction']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'date': serializer.toJson<String>(date),
      'weight': serializer.toJson<double?>(weight),
      'height': serializer.toJson<double?>(height),
      'bloodPressure': serializer.toJson<String?>(bloodPressure),
      'cholesterol': serializer.toJson<double?>(cholesterol),
      'bloodSugar': serializer.toJson<double?>(bloodSugar),
      'uricAcid': serializer.toJson<double?>(uricAcid),
      'hemoglobin': serializer.toJson<double?>(hemoglobin),
      'status': serializer.toJson<String>(status),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncAction': serializer.toJson<String>(syncAction),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalScreening copyWith(
          {String? id,
          String? patientId,
          String? date,
          Value<double?> weight = const Value.absent(),
          Value<double?> height = const Value.absent(),
          Value<String?> bloodPressure = const Value.absent(),
          Value<double?> cholesterol = const Value.absent(),
          Value<double?> bloodSugar = const Value.absent(),
          Value<double?> uricAcid = const Value.absent(),
          Value<double?> hemoglobin = const Value.absent(),
          String? status,
          bool? isSynced,
          String? syncAction,
          DateTime? updatedAt,
          DateTime? createdAt}) =>
      LocalScreening(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        date: date ?? this.date,
        weight: weight.present ? weight.value : this.weight,
        height: height.present ? height.value : this.height,
        bloodPressure:
            bloodPressure.present ? bloodPressure.value : this.bloodPressure,
        cholesterol: cholesterol.present ? cholesterol.value : this.cholesterol,
        bloodSugar: bloodSugar.present ? bloodSugar.value : this.bloodSugar,
        uricAcid: uricAcid.present ? uricAcid.value : this.uricAcid,
        hemoglobin: hemoglobin.present ? hemoglobin.value : this.hemoglobin,
        status: status ?? this.status,
        isSynced: isSynced ?? this.isSynced,
        syncAction: syncAction ?? this.syncAction,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalScreening copyWithCompanion(LocalScreeningsCompanion data) {
    return LocalScreening(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      date: data.date.present ? data.date.value : this.date,
      weight: data.weight.present ? data.weight.value : this.weight,
      height: data.height.present ? data.height.value : this.height,
      bloodPressure: data.bloodPressure.present
          ? data.bloodPressure.value
          : this.bloodPressure,
      cholesterol:
          data.cholesterol.present ? data.cholesterol.value : this.cholesterol,
      bloodSugar:
          data.bloodSugar.present ? data.bloodSugar.value : this.bloodSugar,
      uricAcid: data.uricAcid.present ? data.uricAcid.value : this.uricAcid,
      hemoglobin:
          data.hemoglobin.present ? data.hemoglobin.value : this.hemoglobin,
      status: data.status.present ? data.status.value : this.status,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncAction:
          data.syncAction.present ? data.syncAction.value : this.syncAction,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalScreening(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('date: $date, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('bloodPressure: $bloodPressure, ')
          ..write('cholesterol: $cholesterol, ')
          ..write('bloodSugar: $bloodSugar, ')
          ..write('uricAcid: $uricAcid, ')
          ..write('hemoglobin: $hemoglobin, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAction: $syncAction, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      patientId,
      date,
      weight,
      height,
      bloodPressure,
      cholesterol,
      bloodSugar,
      uricAcid,
      hemoglobin,
      status,
      isSynced,
      syncAction,
      updatedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalScreening &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.date == this.date &&
          other.weight == this.weight &&
          other.height == this.height &&
          other.bloodPressure == this.bloodPressure &&
          other.cholesterol == this.cholesterol &&
          other.bloodSugar == this.bloodSugar &&
          other.uricAcid == this.uricAcid &&
          other.hemoglobin == this.hemoglobin &&
          other.status == this.status &&
          other.isSynced == this.isSynced &&
          other.syncAction == this.syncAction &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class LocalScreeningsCompanion extends UpdateCompanion<LocalScreening> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> date;
  final Value<double?> weight;
  final Value<double?> height;
  final Value<String?> bloodPressure;
  final Value<double?> cholesterol;
  final Value<double?> bloodSugar;
  final Value<double?> uricAcid;
  final Value<double?> hemoglobin;
  final Value<String> status;
  final Value<bool> isSynced;
  final Value<String> syncAction;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalScreeningsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.date = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.bloodPressure = const Value.absent(),
    this.cholesterol = const Value.absent(),
    this.bloodSugar = const Value.absent(),
    this.uricAcid = const Value.absent(),
    this.hemoglobin = const Value.absent(),
    this.status = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncAction = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalScreeningsCompanion.insert({
    required String id,
    required String patientId,
    required String date,
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.bloodPressure = const Value.absent(),
    this.cholesterol = const Value.absent(),
    this.bloodSugar = const Value.absent(),
    this.uricAcid = const Value.absent(),
    this.hemoglobin = const Value.absent(),
    required String status,
    this.isSynced = const Value.absent(),
    this.syncAction = const Value.absent(),
    required DateTime updatedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        patientId = Value(patientId),
        date = Value(date),
        status = Value(status),
        updatedAt = Value(updatedAt),
        createdAt = Value(createdAt);
  static Insertable<LocalScreening> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? date,
    Expression<double>? weight,
    Expression<double>? height,
    Expression<String>? bloodPressure,
    Expression<double>? cholesterol,
    Expression<double>? bloodSugar,
    Expression<double>? uricAcid,
    Expression<double>? hemoglobin,
    Expression<String>? status,
    Expression<bool>? isSynced,
    Expression<String>? syncAction,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (date != null) 'date': date,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bloodPressure != null) 'blood_pressure': bloodPressure,
      if (cholesterol != null) 'cholesterol': cholesterol,
      if (bloodSugar != null) 'blood_sugar': bloodSugar,
      if (uricAcid != null) 'uric_acid': uricAcid,
      if (hemoglobin != null) 'hemoglobin': hemoglobin,
      if (status != null) 'status': status,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncAction != null) 'sync_action': syncAction,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalScreeningsCompanion copyWith(
      {Value<String>? id,
      Value<String>? patientId,
      Value<String>? date,
      Value<double?>? weight,
      Value<double?>? height,
      Value<String?>? bloodPressure,
      Value<double?>? cholesterol,
      Value<double?>? bloodSugar,
      Value<double?>? uricAcid,
      Value<double?>? hemoglobin,
      Value<String>? status,
      Value<bool>? isSynced,
      Value<String>? syncAction,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalScreeningsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      cholesterol: cholesterol ?? this.cholesterol,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      uricAcid: uricAcid ?? this.uricAcid,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      syncAction: syncAction ?? this.syncAction,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (bloodPressure.present) {
      map['blood_pressure'] = Variable<String>(bloodPressure.value);
    }
    if (cholesterol.present) {
      map['cholesterol'] = Variable<double>(cholesterol.value);
    }
    if (bloodSugar.present) {
      map['blood_sugar'] = Variable<double>(bloodSugar.value);
    }
    if (uricAcid.present) {
      map['uric_acid'] = Variable<double>(uricAcid.value);
    }
    if (hemoglobin.present) {
      map['hemoglobin'] = Variable<double>(hemoglobin.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncAction.present) {
      map['sync_action'] = Variable<String>(syncAction.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalScreeningsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('date: $date, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('bloodPressure: $bloodPressure, ')
          ..write('cholesterol: $cholesterol, ')
          ..write('bloodSugar: $bloodSugar, ')
          ..write('uricAcid: $uricAcid, ')
          ..write('hemoglobin: $hemoglobin, ')
          ..write('status: $status, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncAction: $syncAction, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalPatientsTable localPatients = $LocalPatientsTable(this);
  late final $LocalScreeningsTable localScreenings =
      $LocalScreeningsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localPatients, localScreenings];
}

typedef $$LocalPatientsTableCreateCompanionBuilder = LocalPatientsCompanion
    Function({
  required String id,
  required String name,
  required String gender,
  required String birthDate,
  required String address,
  Value<String> category,
  Value<bool> isSynced,
  Value<String> syncAction,
  required DateTime updatedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalPatientsTableUpdateCompanionBuilder = LocalPatientsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> gender,
  Value<String> birthDate,
  Value<String> address,
  Value<String> category,
  Value<bool> isSynced,
  Value<String> syncAction,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalPatientsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPatientsTable> {
  $$LocalPatientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPatientsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPatientsTable> {
  $$LocalPatientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthDate => $composableBuilder(
      column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPatientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPatientsTable> {
  $$LocalPatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPatientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPatientsTable,
    LocalPatient,
    $$LocalPatientsTableFilterComposer,
    $$LocalPatientsTableOrderingComposer,
    $$LocalPatientsTableAnnotationComposer,
    $$LocalPatientsTableCreateCompanionBuilder,
    $$LocalPatientsTableUpdateCompanionBuilder,
    (
      LocalPatient,
      BaseReferences<_$AppDatabase, $LocalPatientsTable, LocalPatient>
    ),
    LocalPatient,
    PrefetchHooks Function()> {
  $$LocalPatientsTableTableManager(_$AppDatabase db, $LocalPatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<String> birthDate = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> syncAction = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPatientsCompanion(
            id: id,
            name: name,
            gender: gender,
            birthDate: birthDate,
            address: address,
            category: category,
            isSynced: isSynced,
            syncAction: syncAction,
            updatedAt: updatedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String gender,
            required String birthDate,
            required String address,
            Value<String> category = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> syncAction = const Value.absent(),
            required DateTime updatedAt,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPatientsCompanion.insert(
            id: id,
            name: name,
            gender: gender,
            birthDate: birthDate,
            address: address,
            category: category,
            isSynced: isSynced,
            syncAction: syncAction,
            updatedAt: updatedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalPatientsTable, LocalPatient>(table),
                    BaseReferences<_$AppDatabase, $LocalPatientsTable,
                        LocalPatient>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPatientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPatientsTable,
    LocalPatient,
    $$LocalPatientsTableFilterComposer,
    $$LocalPatientsTableOrderingComposer,
    $$LocalPatientsTableAnnotationComposer,
    $$LocalPatientsTableCreateCompanionBuilder,
    $$LocalPatientsTableUpdateCompanionBuilder,
    (
      LocalPatient,
      BaseReferences<_$AppDatabase, $LocalPatientsTable, LocalPatient>
    ),
    LocalPatient,
    PrefetchHooks Function()>;
typedef $$LocalScreeningsTableCreateCompanionBuilder = LocalScreeningsCompanion
    Function({
  required String id,
  required String patientId,
  required String date,
  Value<double?> weight,
  Value<double?> height,
  Value<String?> bloodPressure,
  Value<double?> cholesterol,
  Value<double?> bloodSugar,
  Value<double?> uricAcid,
  Value<double?> hemoglobin,
  required String status,
  Value<bool> isSynced,
  Value<String> syncAction,
  required DateTime updatedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalScreeningsTableUpdateCompanionBuilder = LocalScreeningsCompanion
    Function({
  Value<String> id,
  Value<String> patientId,
  Value<String> date,
  Value<double?> weight,
  Value<double?> height,
  Value<String?> bloodPressure,
  Value<double?> cholesterol,
  Value<double?> bloodSugar,
  Value<double?> uricAcid,
  Value<double?> hemoglobin,
  Value<String> status,
  Value<bool> isSynced,
  Value<String> syncAction,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalScreeningsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalScreeningsTable> {
  $$LocalScreeningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bloodPressure => $composableBuilder(
      column: $table.bloodPressure, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cholesterol => $composableBuilder(
      column: $table.cholesterol, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bloodSugar => $composableBuilder(
      column: $table.bloodSugar, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get uricAcid => $composableBuilder(
      column: $table.uricAcid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hemoglobin => $composableBuilder(
      column: $table.hemoglobin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalScreeningsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalScreeningsTable> {
  $$LocalScreeningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patientId => $composableBuilder(
      column: $table.patientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bloodPressure => $composableBuilder(
      column: $table.bloodPressure,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cholesterol => $composableBuilder(
      column: $table.cholesterol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bloodSugar => $composableBuilder(
      column: $table.bloodSugar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get uricAcid => $composableBuilder(
      column: $table.uricAcid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hemoglobin => $composableBuilder(
      column: $table.hemoglobin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalScreeningsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalScreeningsTable> {
  $$LocalScreeningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get bloodPressure => $composableBuilder(
      column: $table.bloodPressure, builder: (column) => column);

  GeneratedColumn<double> get cholesterol => $composableBuilder(
      column: $table.cholesterol, builder: (column) => column);

  GeneratedColumn<double> get bloodSugar => $composableBuilder(
      column: $table.bloodSugar, builder: (column) => column);

  GeneratedColumn<double> get uricAcid =>
      $composableBuilder(column: $table.uricAcid, builder: (column) => column);

  GeneratedColumn<double> get hemoglobin => $composableBuilder(
      column: $table.hemoglobin, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get syncAction => $composableBuilder(
      column: $table.syncAction, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalScreeningsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalScreeningsTable,
    LocalScreening,
    $$LocalScreeningsTableFilterComposer,
    $$LocalScreeningsTableOrderingComposer,
    $$LocalScreeningsTableAnnotationComposer,
    $$LocalScreeningsTableCreateCompanionBuilder,
    $$LocalScreeningsTableUpdateCompanionBuilder,
    (
      LocalScreening,
      BaseReferences<_$AppDatabase, $LocalScreeningsTable, LocalScreening>
    ),
    LocalScreening,
    PrefetchHooks Function()> {
  $$LocalScreeningsTableTableManager(
      _$AppDatabase db, $LocalScreeningsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalScreeningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalScreeningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalScreeningsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> patientId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<double?> height = const Value.absent(),
            Value<String?> bloodPressure = const Value.absent(),
            Value<double?> cholesterol = const Value.absent(),
            Value<double?> bloodSugar = const Value.absent(),
            Value<double?> uricAcid = const Value.absent(),
            Value<double?> hemoglobin = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<String> syncAction = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalScreeningsCompanion(
            id: id,
            patientId: patientId,
            date: date,
            weight: weight,
            height: height,
            bloodPressure: bloodPressure,
            cholesterol: cholesterol,
            bloodSugar: bloodSugar,
            uricAcid: uricAcid,
            hemoglobin: hemoglobin,
            status: status,
            isSynced: isSynced,
            syncAction: syncAction,
            updatedAt: updatedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String patientId,
            required String date,
            Value<double?> weight = const Value.absent(),
            Value<double?> height = const Value.absent(),
            Value<String?> bloodPressure = const Value.absent(),
            Value<double?> cholesterol = const Value.absent(),
            Value<double?> bloodSugar = const Value.absent(),
            Value<double?> uricAcid = const Value.absent(),
            Value<double?> hemoglobin = const Value.absent(),
            required String status,
            Value<bool> isSynced = const Value.absent(),
            Value<String> syncAction = const Value.absent(),
            required DateTime updatedAt,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalScreeningsCompanion.insert(
            id: id,
            patientId: patientId,
            date: date,
            weight: weight,
            height: height,
            bloodPressure: bloodPressure,
            cholesterol: cholesterol,
            bloodSugar: bloodSugar,
            uricAcid: uricAcid,
            hemoglobin: hemoglobin,
            status: status,
            isSynced: isSynced,
            syncAction: syncAction,
            updatedAt: updatedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalScreeningsTable, LocalScreening>(table),
                    BaseReferences<_$AppDatabase, $LocalScreeningsTable,
                        LocalScreening>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalScreeningsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalScreeningsTable,
    LocalScreening,
    $$LocalScreeningsTableFilterComposer,
    $$LocalScreeningsTableOrderingComposer,
    $$LocalScreeningsTableAnnotationComposer,
    $$LocalScreeningsTableCreateCompanionBuilder,
    $$LocalScreeningsTableUpdateCompanionBuilder,
    (
      LocalScreening,
      BaseReferences<_$AppDatabase, $LocalScreeningsTable, LocalScreening>
    ),
    LocalScreening,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalPatientsTableTableManager get localPatients =>
      $$LocalPatientsTableTableManager(_db, _db.localPatients);
  $$LocalScreeningsTableTableManager get localScreenings =>
      $$LocalScreeningsTableTableManager(_db, _db.localScreenings);
}
