// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DiversTable extends Divers with TableInfo<$DiversTable, DiverRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiversTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstDiveNumberMeta = const VerificationMeta(
    'firstDiveNumber',
  );
  @override
  late final GeneratedColumn<int> firstDiveNumber = GeneratedColumn<int>(
    'first_dive_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    firstDiveNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'divers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiverRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('first_dive_number')) {
      context.handle(
        _firstDiveNumberMeta,
        firstDiveNumber.isAcceptableOrUnknown(
          data['first_dive_number']!,
          _firstDiveNumberMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiverRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiverRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      firstDiveNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_dive_number'],
      )!,
    );
  }

  @override
  $DiversTable createAlias(String alias) {
    return $DiversTable(attachedDatabase, alias);
  }
}

class DiverRow extends DataClass implements Insertable<DiverRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final int firstDiveNumber;
  const DiverRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.firstDiveNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['first_dive_number'] = Variable<int>(firstDiveNumber);
    return map;
  }

  DiversCompanion toCompanion(bool nullToAbsent) {
    return DiversCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      firstDiveNumber: Value(firstDiveNumber),
    );
  }

  factory DiverRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiverRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      firstDiveNumber: serializer.fromJson<int>(json['firstDiveNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'firstDiveNumber': serializer.toJson<int>(firstDiveNumber),
    };
  }

  DiverRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    int? firstDiveNumber,
  }) => DiverRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    firstDiveNumber: firstDiveNumber ?? this.firstDiveNumber,
  );
  DiverRow copyWithCompanion(DiversCompanion data) {
    return DiverRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      firstDiveNumber: data.firstDiveNumber.present
          ? data.firstDiveNumber.value
          : this.firstDiveNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiverRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('firstDiveNumber: $firstDiveNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, deletedAt, name, firstDiveNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiverRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.firstDiveNumber == this.firstDiveNumber);
}

class DiversCompanion extends UpdateCompanion<DiverRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> firstDiveNumber;
  final Value<int> rowid;
  const DiversCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.firstDiveNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiversCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    this.firstDiveNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<DiverRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? firstDiveNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (firstDiveNumber != null) 'first_dive_number': firstDiveNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiversCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? firstDiveNumber,
    Value<int>? rowid,
  }) {
    return DiversCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      firstDiveNumber: firstDiveNumber ?? this.firstDiveNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (firstDiveNumber.present) {
      map['first_dive_number'] = Variable<int>(firstDiveNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiversCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('firstDiveNumber: $firstDiveNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiveComputersTable extends DiveComputers
    with TableInfo<$DiveComputersTable, DiveComputerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiveComputersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorMeta = const VerificationMeta('vendor');
  @override
  late final GeneratedColumn<String> vendor = GeneratedColumn<String>(
    'vendor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productMeta = const VerificationMeta(
    'product',
  );
  @override
  late final GeneratedColumn<String> product = GeneratedColumn<String>(
    'product',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelNumberMeta = const VerificationMeta(
    'modelNumber',
  );
  @override
  late final GeneratedColumn<int> modelNumber = GeneratedColumn<int>(
    'model_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
    'serial',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firmwareMeta = const VerificationMeta(
    'firmware',
  );
  @override
  late final GeneratedColumn<String> firmware = GeneratedColumn<String>(
    'firmware',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFingerprintMeta = const VerificationMeta(
    'lastFingerprint',
  );
  @override
  late final GeneratedColumn<Uint8List> lastFingerprint =
      GeneratedColumn<Uint8List>(
        'last_fingerprint',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    vendor,
    product,
    modelNumber,
    serial,
    firmware,
    address,
    lastFingerprint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dive_computers';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveComputerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('vendor')) {
      context.handle(
        _vendorMeta,
        vendor.isAcceptableOrUnknown(data['vendor']!, _vendorMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorMeta);
    }
    if (data.containsKey('product')) {
      context.handle(
        _productMeta,
        product.isAcceptableOrUnknown(data['product']!, _productMeta),
      );
    } else if (isInserting) {
      context.missing(_productMeta);
    }
    if (data.containsKey('model_number')) {
      context.handle(
        _modelNumberMeta,
        modelNumber.isAcceptableOrUnknown(
          data['model_number']!,
          _modelNumberMeta,
        ),
      );
    }
    if (data.containsKey('serial')) {
      context.handle(
        _serialMeta,
        serial.isAcceptableOrUnknown(data['serial']!, _serialMeta),
      );
    }
    if (data.containsKey('firmware')) {
      context.handle(
        _firmwareMeta,
        firmware.isAcceptableOrUnknown(data['firmware']!, _firmwareMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('last_fingerprint')) {
      context.handle(
        _lastFingerprintMeta,
        lastFingerprint.isAcceptableOrUnknown(
          data['last_fingerprint']!,
          _lastFingerprintMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiveComputerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveComputerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      vendor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor'],
      )!,
      product: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product'],
      )!,
      modelNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}model_number'],
      ),
      serial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial'],
      ),
      firmware: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      lastFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}last_fingerprint'],
      ),
    );
  }

  @override
  $DiveComputersTable createAlias(String alias) {
    return $DiveComputersTable(attachedDatabase, alias);
  }
}

class DiveComputerRow extends DataClass implements Insertable<DiveComputerRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String vendor;
  final String product;
  final int? modelNumber;
  final String? serial;
  final String? firmware;
  final String? address;
  final Uint8List? lastFingerprint;
  const DiveComputerRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.vendor,
    required this.product,
    this.modelNumber,
    this.serial,
    this.firmware,
    this.address,
    this.lastFingerprint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['vendor'] = Variable<String>(vendor);
    map['product'] = Variable<String>(product);
    if (!nullToAbsent || modelNumber != null) {
      map['model_number'] = Variable<int>(modelNumber);
    }
    if (!nullToAbsent || serial != null) {
      map['serial'] = Variable<String>(serial);
    }
    if (!nullToAbsent || firmware != null) {
      map['firmware'] = Variable<String>(firmware);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || lastFingerprint != null) {
      map['last_fingerprint'] = Variable<Uint8List>(lastFingerprint);
    }
    return map;
  }

  DiveComputersCompanion toCompanion(bool nullToAbsent) {
    return DiveComputersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      vendor: Value(vendor),
      product: Value(product),
      modelNumber: modelNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(modelNumber),
      serial: serial == null && nullToAbsent
          ? const Value.absent()
          : Value(serial),
      firmware: firmware == null && nullToAbsent
          ? const Value.absent()
          : Value(firmware),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      lastFingerprint: lastFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFingerprint),
    );
  }

  factory DiveComputerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveComputerRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      vendor: serializer.fromJson<String>(json['vendor']),
      product: serializer.fromJson<String>(json['product']),
      modelNumber: serializer.fromJson<int?>(json['modelNumber']),
      serial: serializer.fromJson<String?>(json['serial']),
      firmware: serializer.fromJson<String?>(json['firmware']),
      address: serializer.fromJson<String?>(json['address']),
      lastFingerprint: serializer.fromJson<Uint8List?>(json['lastFingerprint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'vendor': serializer.toJson<String>(vendor),
      'product': serializer.toJson<String>(product),
      'modelNumber': serializer.toJson<int?>(modelNumber),
      'serial': serializer.toJson<String?>(serial),
      'firmware': serializer.toJson<String?>(firmware),
      'address': serializer.toJson<String?>(address),
      'lastFingerprint': serializer.toJson<Uint8List?>(lastFingerprint),
    };
  }

  DiveComputerRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? vendor,
    String? product,
    Value<int?> modelNumber = const Value.absent(),
    Value<String?> serial = const Value.absent(),
    Value<String?> firmware = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<Uint8List?> lastFingerprint = const Value.absent(),
  }) => DiveComputerRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    vendor: vendor ?? this.vendor,
    product: product ?? this.product,
    modelNumber: modelNumber.present ? modelNumber.value : this.modelNumber,
    serial: serial.present ? serial.value : this.serial,
    firmware: firmware.present ? firmware.value : this.firmware,
    address: address.present ? address.value : this.address,
    lastFingerprint: lastFingerprint.present
        ? lastFingerprint.value
        : this.lastFingerprint,
  );
  DiveComputerRow copyWithCompanion(DiveComputersCompanion data) {
    return DiveComputerRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      product: data.product.present ? data.product.value : this.product,
      modelNumber: data.modelNumber.present
          ? data.modelNumber.value
          : this.modelNumber,
      serial: data.serial.present ? data.serial.value : this.serial,
      firmware: data.firmware.present ? data.firmware.value : this.firmware,
      address: data.address.present ? data.address.value : this.address,
      lastFingerprint: data.lastFingerprint.present
          ? data.lastFingerprint.value
          : this.lastFingerprint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveComputerRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('vendor: $vendor, ')
          ..write('product: $product, ')
          ..write('modelNumber: $modelNumber, ')
          ..write('serial: $serial, ')
          ..write('firmware: $firmware, ')
          ..write('address: $address, ')
          ..write('lastFingerprint: $lastFingerprint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deletedAt,
    vendor,
    product,
    modelNumber,
    serial,
    firmware,
    address,
    $driftBlobEquality.hash(lastFingerprint),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveComputerRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.vendor == this.vendor &&
          other.product == this.product &&
          other.modelNumber == this.modelNumber &&
          other.serial == this.serial &&
          other.firmware == this.firmware &&
          other.address == this.address &&
          $driftBlobEquality.equals(
            other.lastFingerprint,
            this.lastFingerprint,
          ));
}

class DiveComputersCompanion extends UpdateCompanion<DiveComputerRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> vendor;
  final Value<String> product;
  final Value<int?> modelNumber;
  final Value<String?> serial;
  final Value<String?> firmware;
  final Value<String?> address;
  final Value<Uint8List?> lastFingerprint;
  final Value<int> rowid;
  const DiveComputersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.vendor = const Value.absent(),
    this.product = const Value.absent(),
    this.modelNumber = const Value.absent(),
    this.serial = const Value.absent(),
    this.firmware = const Value.absent(),
    this.address = const Value.absent(),
    this.lastFingerprint = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiveComputersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String vendor,
    required String product,
    this.modelNumber = const Value.absent(),
    this.serial = const Value.absent(),
    this.firmware = const Value.absent(),
    this.address = const Value.absent(),
    this.lastFingerprint = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       vendor = Value(vendor),
       product = Value(product);
  static Insertable<DiveComputerRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? vendor,
    Expression<String>? product,
    Expression<int>? modelNumber,
    Expression<String>? serial,
    Expression<String>? firmware,
    Expression<String>? address,
    Expression<Uint8List>? lastFingerprint,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (vendor != null) 'vendor': vendor,
      if (product != null) 'product': product,
      if (modelNumber != null) 'model_number': modelNumber,
      if (serial != null) 'serial': serial,
      if (firmware != null) 'firmware': firmware,
      if (address != null) 'address': address,
      if (lastFingerprint != null) 'last_fingerprint': lastFingerprint,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiveComputersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? vendor,
    Value<String>? product,
    Value<int?>? modelNumber,
    Value<String?>? serial,
    Value<String?>? firmware,
    Value<String?>? address,
    Value<Uint8List?>? lastFingerprint,
    Value<int>? rowid,
  }) {
    return DiveComputersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      vendor: vendor ?? this.vendor,
      product: product ?? this.product,
      modelNumber: modelNumber ?? this.modelNumber,
      serial: serial ?? this.serial,
      firmware: firmware ?? this.firmware,
      address: address ?? this.address,
      lastFingerprint: lastFingerprint ?? this.lastFingerprint,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(vendor.value);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value);
    }
    if (modelNumber.present) {
      map['model_number'] = Variable<int>(modelNumber.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (firmware.present) {
      map['firmware'] = Variable<String>(firmware.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (lastFingerprint.present) {
      map['last_fingerprint'] = Variable<Uint8List>(lastFingerprint.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiveComputersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('vendor: $vendor, ')
          ..write('product: $product, ')
          ..write('modelNumber: $modelNumber, ')
          ..write('serial: $serial, ')
          ..write('firmware: $firmware, ')
          ..write('address: $address, ')
          ..write('lastFingerprint: $lastFingerprint, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DivesTable extends Dives with TableInfo<$DivesTable, DiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diverIdMeta = const VerificationMeta(
    'diverId',
  );
  @override
  late final GeneratedColumn<String> diverId = GeneratedColumn<String>(
    'diver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES divers (id)',
    ),
  );
  static const VerificationMeta _diveNumberMeta = const VerificationMeta(
    'diveNumber',
  );
  @override
  late final GeneratedColumn<int> diveNumber = GeneratedColumn<int>(
    'dive_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteNameMeta = const VerificationMeta(
    'siteName',
  );
  @override
  late final GeneratedColumn<String> siteName = GeneratedColumn<String>(
    'site_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteCatalogueIdMeta = const VerificationMeta(
    'siteCatalogueId',
  );
  @override
  late final GeneratedColumn<String> siteCatalogueId = GeneratedColumn<String>(
    'site_catalogue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteLatMeta = const VerificationMeta(
    'siteLat',
  );
  @override
  late final GeneratedColumn<double> siteLat = GeneratedColumn<double>(
    'site_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteLonMeta = const VerificationMeta(
    'siteLon',
  );
  @override
  late final GeneratedColumn<double> siteLon = GeneratedColumn<double>(
    'site_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diveComputerIdMeta = const VerificationMeta(
    'diveComputerId',
  );
  @override
  late final GeneratedColumn<String> diveComputerId = GeneratedColumn<String>(
    'dive_computer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dive_computers (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startLocalMeta = const VerificationMeta(
    'startLocal',
  );
  @override
  late final GeneratedColumn<DateTime> startLocal = GeneratedColumn<DateTime>(
    'start_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utcOffsetSMeta = const VerificationMeta(
    'utcOffsetS',
  );
  @override
  late final GeneratedColumn<int> utcOffsetS = GeneratedColumn<int>(
    'utc_offset_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxDepthMMeta = const VerificationMeta(
    'maxDepthM',
  );
  @override
  late final GeneratedColumn<double> maxDepthM = GeneratedColumn<double>(
    'max_depth_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgDepthMMeta = const VerificationMeta(
    'avgDepthM',
  );
  @override
  late final GeneratedColumn<double> avgDepthM = GeneratedColumn<double>(
    'avg_depth_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minTemperatureCMeta = const VerificationMeta(
    'minTemperatureC',
  );
  @override
  late final GeneratedColumn<double> minTemperatureC = GeneratedColumn<double>(
    'min_temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxTemperatureCMeta = const VerificationMeta(
    'maxTemperatureC',
  );
  @override
  late final GeneratedColumn<double> maxTemperatureC = GeneratedColumn<double>(
    'max_temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterTypeMeta = const VerificationMeta(
    'waterType',
  );
  @override
  late final GeneratedColumn<String> waterType = GeneratedColumn<String>(
    'water_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deletedAt,
    diverId,
    diveNumber,
    siteName,
    siteCatalogueId,
    siteLat,
    siteLon,
    diveComputerId,
    source,
    sourceId,
    startLocal,
    utcOffsetS,
    durationS,
    maxDepthM,
    avgDepthM,
    minTemperatureC,
    maxTemperatureC,
    waterType,
    notes,
    rating,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dives';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('diver_id')) {
      context.handle(
        _diverIdMeta,
        diverId.isAcceptableOrUnknown(data['diver_id']!, _diverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diverIdMeta);
    }
    if (data.containsKey('dive_number')) {
      context.handle(
        _diveNumberMeta,
        diveNumber.isAcceptableOrUnknown(data['dive_number']!, _diveNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_diveNumberMeta);
    }
    if (data.containsKey('site_name')) {
      context.handle(
        _siteNameMeta,
        siteName.isAcceptableOrUnknown(data['site_name']!, _siteNameMeta),
      );
    }
    if (data.containsKey('site_catalogue_id')) {
      context.handle(
        _siteCatalogueIdMeta,
        siteCatalogueId.isAcceptableOrUnknown(
          data['site_catalogue_id']!,
          _siteCatalogueIdMeta,
        ),
      );
    }
    if (data.containsKey('site_lat')) {
      context.handle(
        _siteLatMeta,
        siteLat.isAcceptableOrUnknown(data['site_lat']!, _siteLatMeta),
      );
    }
    if (data.containsKey('site_lon')) {
      context.handle(
        _siteLonMeta,
        siteLon.isAcceptableOrUnknown(data['site_lon']!, _siteLonMeta),
      );
    }
    if (data.containsKey('dive_computer_id')) {
      context.handle(
        _diveComputerIdMeta,
        diveComputerId.isAcceptableOrUnknown(
          data['dive_computer_id']!,
          _diveComputerIdMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('start_local')) {
      context.handle(
        _startLocalMeta,
        startLocal.isAcceptableOrUnknown(data['start_local']!, _startLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_startLocalMeta);
    }
    if (data.containsKey('utc_offset_s')) {
      context.handle(
        _utcOffsetSMeta,
        utcOffsetS.isAcceptableOrUnknown(
          data['utc_offset_s']!,
          _utcOffsetSMeta,
        ),
      );
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    } else if (isInserting) {
      context.missing(_durationSMeta);
    }
    if (data.containsKey('max_depth_m')) {
      context.handle(
        _maxDepthMMeta,
        maxDepthM.isAcceptableOrUnknown(data['max_depth_m']!, _maxDepthMMeta),
      );
    } else if (isInserting) {
      context.missing(_maxDepthMMeta);
    }
    if (data.containsKey('avg_depth_m')) {
      context.handle(
        _avgDepthMMeta,
        avgDepthM.isAcceptableOrUnknown(data['avg_depth_m']!, _avgDepthMMeta),
      );
    }
    if (data.containsKey('min_temperature_c')) {
      context.handle(
        _minTemperatureCMeta,
        minTemperatureC.isAcceptableOrUnknown(
          data['min_temperature_c']!,
          _minTemperatureCMeta,
        ),
      );
    }
    if (data.containsKey('max_temperature_c')) {
      context.handle(
        _maxTemperatureCMeta,
        maxTemperatureC.isAcceptableOrUnknown(
          data['max_temperature_c']!,
          _maxTemperatureCMeta,
        ),
      );
    }
    if (data.containsKey('water_type')) {
      context.handle(
        _waterTypeMeta,
        waterType.isAcceptableOrUnknown(data['water_type']!, _waterTypeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      diverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diver_id'],
      )!,
      diveNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dive_number'],
      )!,
      siteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_name'],
      ),
      siteCatalogueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_catalogue_id'],
      ),
      siteLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}site_lat'],
      ),
      siteLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}site_lon'],
      ),
      diveComputerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dive_computer_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      startLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_local'],
      )!,
      utcOffsetS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_s'],
      ),
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      )!,
      maxDepthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_depth_m'],
      )!,
      avgDepthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_depth_m'],
      ),
      minTemperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_temperature_c'],
      ),
      maxTemperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_temperature_c'],
      ),
      waterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}water_type'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
    );
  }

  @override
  $DivesTable createAlias(String alias) {
    return $DivesTable(attachedDatabase, alias);
  }
}

class DiveRow extends DataClass implements Insertable<DiveRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String diverId;
  final int diveNumber;
  final String? siteName;
  final String? siteCatalogueId;
  final double? siteLat;
  final double? siteLon;
  final String? diveComputerId;
  final String source;
  final String? sourceId;

  /// Wall-clock start, stored as if it were UTC so it never shifts.
  final DateTime startLocal;
  final int? utcOffsetS;
  final int durationS;
  final double maxDepthM;
  final double? avgDepthM;
  final double? minTemperatureC;
  final double? maxTemperatureC;
  final String? waterType;
  final String? notes;
  final int? rating;
  const DiveRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.diverId,
    required this.diveNumber,
    this.siteName,
    this.siteCatalogueId,
    this.siteLat,
    this.siteLon,
    this.diveComputerId,
    required this.source,
    this.sourceId,
    required this.startLocal,
    this.utcOffsetS,
    required this.durationS,
    required this.maxDepthM,
    this.avgDepthM,
    this.minTemperatureC,
    this.maxTemperatureC,
    this.waterType,
    this.notes,
    this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['diver_id'] = Variable<String>(diverId);
    map['dive_number'] = Variable<int>(diveNumber);
    if (!nullToAbsent || siteName != null) {
      map['site_name'] = Variable<String>(siteName);
    }
    if (!nullToAbsent || siteCatalogueId != null) {
      map['site_catalogue_id'] = Variable<String>(siteCatalogueId);
    }
    if (!nullToAbsent || siteLat != null) {
      map['site_lat'] = Variable<double>(siteLat);
    }
    if (!nullToAbsent || siteLon != null) {
      map['site_lon'] = Variable<double>(siteLon);
    }
    if (!nullToAbsent || diveComputerId != null) {
      map['dive_computer_id'] = Variable<String>(diveComputerId);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['start_local'] = Variable<DateTime>(startLocal);
    if (!nullToAbsent || utcOffsetS != null) {
      map['utc_offset_s'] = Variable<int>(utcOffsetS);
    }
    map['duration_s'] = Variable<int>(durationS);
    map['max_depth_m'] = Variable<double>(maxDepthM);
    if (!nullToAbsent || avgDepthM != null) {
      map['avg_depth_m'] = Variable<double>(avgDepthM);
    }
    if (!nullToAbsent || minTemperatureC != null) {
      map['min_temperature_c'] = Variable<double>(minTemperatureC);
    }
    if (!nullToAbsent || maxTemperatureC != null) {
      map['max_temperature_c'] = Variable<double>(maxTemperatureC);
    }
    if (!nullToAbsent || waterType != null) {
      map['water_type'] = Variable<String>(waterType);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    return map;
  }

  DivesCompanion toCompanion(bool nullToAbsent) {
    return DivesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      diverId: Value(diverId),
      diveNumber: Value(diveNumber),
      siteName: siteName == null && nullToAbsent
          ? const Value.absent()
          : Value(siteName),
      siteCatalogueId: siteCatalogueId == null && nullToAbsent
          ? const Value.absent()
          : Value(siteCatalogueId),
      siteLat: siteLat == null && nullToAbsent
          ? const Value.absent()
          : Value(siteLat),
      siteLon: siteLon == null && nullToAbsent
          ? const Value.absent()
          : Value(siteLon),
      diveComputerId: diveComputerId == null && nullToAbsent
          ? const Value.absent()
          : Value(diveComputerId),
      source: Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      startLocal: Value(startLocal),
      utcOffsetS: utcOffsetS == null && nullToAbsent
          ? const Value.absent()
          : Value(utcOffsetS),
      durationS: Value(durationS),
      maxDepthM: Value(maxDepthM),
      avgDepthM: avgDepthM == null && nullToAbsent
          ? const Value.absent()
          : Value(avgDepthM),
      minTemperatureC: minTemperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(minTemperatureC),
      maxTemperatureC: maxTemperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTemperatureC),
      waterType: waterType == null && nullToAbsent
          ? const Value.absent()
          : Value(waterType),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
    );
  }

  factory DiveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      diverId: serializer.fromJson<String>(json['diverId']),
      diveNumber: serializer.fromJson<int>(json['diveNumber']),
      siteName: serializer.fromJson<String?>(json['siteName']),
      siteCatalogueId: serializer.fromJson<String?>(json['siteCatalogueId']),
      siteLat: serializer.fromJson<double?>(json['siteLat']),
      siteLon: serializer.fromJson<double?>(json['siteLon']),
      diveComputerId: serializer.fromJson<String?>(json['diveComputerId']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      startLocal: serializer.fromJson<DateTime>(json['startLocal']),
      utcOffsetS: serializer.fromJson<int?>(json['utcOffsetS']),
      durationS: serializer.fromJson<int>(json['durationS']),
      maxDepthM: serializer.fromJson<double>(json['maxDepthM']),
      avgDepthM: serializer.fromJson<double?>(json['avgDepthM']),
      minTemperatureC: serializer.fromJson<double?>(json['minTemperatureC']),
      maxTemperatureC: serializer.fromJson<double?>(json['maxTemperatureC']),
      waterType: serializer.fromJson<String?>(json['waterType']),
      notes: serializer.fromJson<String?>(json['notes']),
      rating: serializer.fromJson<int?>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'diverId': serializer.toJson<String>(diverId),
      'diveNumber': serializer.toJson<int>(diveNumber),
      'siteName': serializer.toJson<String?>(siteName),
      'siteCatalogueId': serializer.toJson<String?>(siteCatalogueId),
      'siteLat': serializer.toJson<double?>(siteLat),
      'siteLon': serializer.toJson<double?>(siteLon),
      'diveComputerId': serializer.toJson<String?>(diveComputerId),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'startLocal': serializer.toJson<DateTime>(startLocal),
      'utcOffsetS': serializer.toJson<int?>(utcOffsetS),
      'durationS': serializer.toJson<int>(durationS),
      'maxDepthM': serializer.toJson<double>(maxDepthM),
      'avgDepthM': serializer.toJson<double?>(avgDepthM),
      'minTemperatureC': serializer.toJson<double?>(minTemperatureC),
      'maxTemperatureC': serializer.toJson<double?>(maxTemperatureC),
      'waterType': serializer.toJson<String?>(waterType),
      'notes': serializer.toJson<String?>(notes),
      'rating': serializer.toJson<int?>(rating),
    };
  }

  DiveRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? diverId,
    int? diveNumber,
    Value<String?> siteName = const Value.absent(),
    Value<String?> siteCatalogueId = const Value.absent(),
    Value<double?> siteLat = const Value.absent(),
    Value<double?> siteLon = const Value.absent(),
    Value<String?> diveComputerId = const Value.absent(),
    String? source,
    Value<String?> sourceId = const Value.absent(),
    DateTime? startLocal,
    Value<int?> utcOffsetS = const Value.absent(),
    int? durationS,
    double? maxDepthM,
    Value<double?> avgDepthM = const Value.absent(),
    Value<double?> minTemperatureC = const Value.absent(),
    Value<double?> maxTemperatureC = const Value.absent(),
    Value<String?> waterType = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> rating = const Value.absent(),
  }) => DiveRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    diverId: diverId ?? this.diverId,
    diveNumber: diveNumber ?? this.diveNumber,
    siteName: siteName.present ? siteName.value : this.siteName,
    siteCatalogueId: siteCatalogueId.present
        ? siteCatalogueId.value
        : this.siteCatalogueId,
    siteLat: siteLat.present ? siteLat.value : this.siteLat,
    siteLon: siteLon.present ? siteLon.value : this.siteLon,
    diveComputerId: diveComputerId.present
        ? diveComputerId.value
        : this.diveComputerId,
    source: source ?? this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    startLocal: startLocal ?? this.startLocal,
    utcOffsetS: utcOffsetS.present ? utcOffsetS.value : this.utcOffsetS,
    durationS: durationS ?? this.durationS,
    maxDepthM: maxDepthM ?? this.maxDepthM,
    avgDepthM: avgDepthM.present ? avgDepthM.value : this.avgDepthM,
    minTemperatureC: minTemperatureC.present
        ? minTemperatureC.value
        : this.minTemperatureC,
    maxTemperatureC: maxTemperatureC.present
        ? maxTemperatureC.value
        : this.maxTemperatureC,
    waterType: waterType.present ? waterType.value : this.waterType,
    notes: notes.present ? notes.value : this.notes,
    rating: rating.present ? rating.value : this.rating,
  );
  DiveRow copyWithCompanion(DivesCompanion data) {
    return DiveRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      diverId: data.diverId.present ? data.diverId.value : this.diverId,
      diveNumber: data.diveNumber.present
          ? data.diveNumber.value
          : this.diveNumber,
      siteName: data.siteName.present ? data.siteName.value : this.siteName,
      siteCatalogueId: data.siteCatalogueId.present
          ? data.siteCatalogueId.value
          : this.siteCatalogueId,
      siteLat: data.siteLat.present ? data.siteLat.value : this.siteLat,
      siteLon: data.siteLon.present ? data.siteLon.value : this.siteLon,
      diveComputerId: data.diveComputerId.present
          ? data.diveComputerId.value
          : this.diveComputerId,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      startLocal: data.startLocal.present
          ? data.startLocal.value
          : this.startLocal,
      utcOffsetS: data.utcOffsetS.present
          ? data.utcOffsetS.value
          : this.utcOffsetS,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      maxDepthM: data.maxDepthM.present ? data.maxDepthM.value : this.maxDepthM,
      avgDepthM: data.avgDepthM.present ? data.avgDepthM.value : this.avgDepthM,
      minTemperatureC: data.minTemperatureC.present
          ? data.minTemperatureC.value
          : this.minTemperatureC,
      maxTemperatureC: data.maxTemperatureC.present
          ? data.maxTemperatureC.value
          : this.maxTemperatureC,
      waterType: data.waterType.present ? data.waterType.value : this.waterType,
      notes: data.notes.present ? data.notes.value : this.notes,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('diverId: $diverId, ')
          ..write('diveNumber: $diveNumber, ')
          ..write('siteName: $siteName, ')
          ..write('siteCatalogueId: $siteCatalogueId, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('diveComputerId: $diveComputerId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('startLocal: $startLocal, ')
          ..write('utcOffsetS: $utcOffsetS, ')
          ..write('durationS: $durationS, ')
          ..write('maxDepthM: $maxDepthM, ')
          ..write('avgDepthM: $avgDepthM, ')
          ..write('minTemperatureC: $minTemperatureC, ')
          ..write('maxTemperatureC: $maxTemperatureC, ')
          ..write('waterType: $waterType, ')
          ..write('notes: $notes, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deletedAt,
    diverId,
    diveNumber,
    siteName,
    siteCatalogueId,
    siteLat,
    siteLon,
    diveComputerId,
    source,
    sourceId,
    startLocal,
    utcOffsetS,
    durationS,
    maxDepthM,
    avgDepthM,
    minTemperatureC,
    maxTemperatureC,
    waterType,
    notes,
    rating,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.diverId == this.diverId &&
          other.diveNumber == this.diveNumber &&
          other.siteName == this.siteName &&
          other.siteCatalogueId == this.siteCatalogueId &&
          other.siteLat == this.siteLat &&
          other.siteLon == this.siteLon &&
          other.diveComputerId == this.diveComputerId &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.startLocal == this.startLocal &&
          other.utcOffsetS == this.utcOffsetS &&
          other.durationS == this.durationS &&
          other.maxDepthM == this.maxDepthM &&
          other.avgDepthM == this.avgDepthM &&
          other.minTemperatureC == this.minTemperatureC &&
          other.maxTemperatureC == this.maxTemperatureC &&
          other.waterType == this.waterType &&
          other.notes == this.notes &&
          other.rating == this.rating);
}

class DivesCompanion extends UpdateCompanion<DiveRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> diverId;
  final Value<int> diveNumber;
  final Value<String?> siteName;
  final Value<String?> siteCatalogueId;
  final Value<double?> siteLat;
  final Value<double?> siteLon;
  final Value<String?> diveComputerId;
  final Value<String> source;
  final Value<String?> sourceId;
  final Value<DateTime> startLocal;
  final Value<int?> utcOffsetS;
  final Value<int> durationS;
  final Value<double> maxDepthM;
  final Value<double?> avgDepthM;
  final Value<double?> minTemperatureC;
  final Value<double?> maxTemperatureC;
  final Value<String?> waterType;
  final Value<String?> notes;
  final Value<int?> rating;
  final Value<int> rowid;
  const DivesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.diverId = const Value.absent(),
    this.diveNumber = const Value.absent(),
    this.siteName = const Value.absent(),
    this.siteCatalogueId = const Value.absent(),
    this.siteLat = const Value.absent(),
    this.siteLon = const Value.absent(),
    this.diveComputerId = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.startLocal = const Value.absent(),
    this.utcOffsetS = const Value.absent(),
    this.durationS = const Value.absent(),
    this.maxDepthM = const Value.absent(),
    this.avgDepthM = const Value.absent(),
    this.minTemperatureC = const Value.absent(),
    this.maxTemperatureC = const Value.absent(),
    this.waterType = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DivesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String diverId,
    required int diveNumber,
    this.siteName = const Value.absent(),
    this.siteCatalogueId = const Value.absent(),
    this.siteLat = const Value.absent(),
    this.siteLon = const Value.absent(),
    this.diveComputerId = const Value.absent(),
    required String source,
    this.sourceId = const Value.absent(),
    required DateTime startLocal,
    this.utcOffsetS = const Value.absent(),
    required int durationS,
    required double maxDepthM,
    this.avgDepthM = const Value.absent(),
    this.minTemperatureC = const Value.absent(),
    this.maxTemperatureC = const Value.absent(),
    this.waterType = const Value.absent(),
    this.notes = const Value.absent(),
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       diverId = Value(diverId),
       diveNumber = Value(diveNumber),
       source = Value(source),
       startLocal = Value(startLocal),
       durationS = Value(durationS),
       maxDepthM = Value(maxDepthM);
  static Insertable<DiveRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? diverId,
    Expression<int>? diveNumber,
    Expression<String>? siteName,
    Expression<String>? siteCatalogueId,
    Expression<double>? siteLat,
    Expression<double>? siteLon,
    Expression<String>? diveComputerId,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<DateTime>? startLocal,
    Expression<int>? utcOffsetS,
    Expression<int>? durationS,
    Expression<double>? maxDepthM,
    Expression<double>? avgDepthM,
    Expression<double>? minTemperatureC,
    Expression<double>? maxTemperatureC,
    Expression<String>? waterType,
    Expression<String>? notes,
    Expression<int>? rating,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (diverId != null) 'diver_id': diverId,
      if (diveNumber != null) 'dive_number': diveNumber,
      if (siteName != null) 'site_name': siteName,
      if (siteCatalogueId != null) 'site_catalogue_id': siteCatalogueId,
      if (siteLat != null) 'site_lat': siteLat,
      if (siteLon != null) 'site_lon': siteLon,
      if (diveComputerId != null) 'dive_computer_id': diveComputerId,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (startLocal != null) 'start_local': startLocal,
      if (utcOffsetS != null) 'utc_offset_s': utcOffsetS,
      if (durationS != null) 'duration_s': durationS,
      if (maxDepthM != null) 'max_depth_m': maxDepthM,
      if (avgDepthM != null) 'avg_depth_m': avgDepthM,
      if (minTemperatureC != null) 'min_temperature_c': minTemperatureC,
      if (maxTemperatureC != null) 'max_temperature_c': maxTemperatureC,
      if (waterType != null) 'water_type': waterType,
      if (notes != null) 'notes': notes,
      if (rating != null) 'rating': rating,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DivesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? diverId,
    Value<int>? diveNumber,
    Value<String?>? siteName,
    Value<String?>? siteCatalogueId,
    Value<double?>? siteLat,
    Value<double?>? siteLon,
    Value<String?>? diveComputerId,
    Value<String>? source,
    Value<String?>? sourceId,
    Value<DateTime>? startLocal,
    Value<int?>? utcOffsetS,
    Value<int>? durationS,
    Value<double>? maxDepthM,
    Value<double?>? avgDepthM,
    Value<double?>? minTemperatureC,
    Value<double?>? maxTemperatureC,
    Value<String?>? waterType,
    Value<String?>? notes,
    Value<int?>? rating,
    Value<int>? rowid,
  }) {
    return DivesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      diverId: diverId ?? this.diverId,
      diveNumber: diveNumber ?? this.diveNumber,
      siteName: siteName ?? this.siteName,
      siteCatalogueId: siteCatalogueId ?? this.siteCatalogueId,
      siteLat: siteLat ?? this.siteLat,
      siteLon: siteLon ?? this.siteLon,
      diveComputerId: diveComputerId ?? this.diveComputerId,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      startLocal: startLocal ?? this.startLocal,
      utcOffsetS: utcOffsetS ?? this.utcOffsetS,
      durationS: durationS ?? this.durationS,
      maxDepthM: maxDepthM ?? this.maxDepthM,
      avgDepthM: avgDepthM ?? this.avgDepthM,
      minTemperatureC: minTemperatureC ?? this.minTemperatureC,
      maxTemperatureC: maxTemperatureC ?? this.maxTemperatureC,
      waterType: waterType ?? this.waterType,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (diverId.present) {
      map['diver_id'] = Variable<String>(diverId.value);
    }
    if (diveNumber.present) {
      map['dive_number'] = Variable<int>(diveNumber.value);
    }
    if (siteName.present) {
      map['site_name'] = Variable<String>(siteName.value);
    }
    if (siteCatalogueId.present) {
      map['site_catalogue_id'] = Variable<String>(siteCatalogueId.value);
    }
    if (siteLat.present) {
      map['site_lat'] = Variable<double>(siteLat.value);
    }
    if (siteLon.present) {
      map['site_lon'] = Variable<double>(siteLon.value);
    }
    if (diveComputerId.present) {
      map['dive_computer_id'] = Variable<String>(diveComputerId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (startLocal.present) {
      map['start_local'] = Variable<DateTime>(startLocal.value);
    }
    if (utcOffsetS.present) {
      map['utc_offset_s'] = Variable<int>(utcOffsetS.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (maxDepthM.present) {
      map['max_depth_m'] = Variable<double>(maxDepthM.value);
    }
    if (avgDepthM.present) {
      map['avg_depth_m'] = Variable<double>(avgDepthM.value);
    }
    if (minTemperatureC.present) {
      map['min_temperature_c'] = Variable<double>(minTemperatureC.value);
    }
    if (maxTemperatureC.present) {
      map['max_temperature_c'] = Variable<double>(maxTemperatureC.value);
    }
    if (waterType.present) {
      map['water_type'] = Variable<String>(waterType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DivesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('diverId: $diverId, ')
          ..write('diveNumber: $diveNumber, ')
          ..write('siteName: $siteName, ')
          ..write('siteCatalogueId: $siteCatalogueId, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('diveComputerId: $diveComputerId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('startLocal: $startLocal, ')
          ..write('utcOffsetS: $utcOffsetS, ')
          ..write('durationS: $durationS, ')
          ..write('maxDepthM: $maxDepthM, ')
          ..write('avgDepthM: $avgDepthM, ')
          ..write('minTemperatureC: $minTemperatureC, ')
          ..write('maxTemperatureC: $maxTemperatureC, ')
          ..write('waterType: $waterType, ')
          ..write('notes: $notes, ')
          ..write('rating: $rating, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiveSamplesTable extends DiveSamples
    with TableInfo<$DiveSamplesTable, DiveSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiveSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _diveIdMeta = const VerificationMeta('diveId');
  @override
  late final GeneratedColumn<String> diveId = GeneratedColumn<String>(
    'dive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dives (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeSMeta = const VerificationMeta('timeS');
  @override
  late final GeneratedColumn<int> timeS = GeneratedColumn<int>(
    'time_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthMMeta = const VerificationMeta('depthM');
  @override
  late final GeneratedColumn<double> depthM = GeneratedColumn<double>(
    'depth_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureCMeta = const VerificationMeta(
    'temperatureC',
  );
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
    'temperature_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ndlSMeta = const VerificationMeta('ndlS');
  @override
  late final GeneratedColumn<int> ndlS = GeneratedColumn<int>(
    'ndl_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decoCeilingMMeta = const VerificationMeta(
    'decoCeilingM',
  );
  @override
  late final GeneratedColumn<double> decoCeilingM = GeneratedColumn<double>(
    'deco_ceiling_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _decoTimeSMeta = const VerificationMeta(
    'decoTimeS',
  );
  @override
  late final GeneratedColumn<int> decoTimeS = GeneratedColumn<int>(
    'deco_time_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gasIndexMeta = const VerificationMeta(
    'gasIndex',
  );
  @override
  late final GeneratedColumn<int> gasIndex = GeneratedColumn<int>(
    'gas_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    diveId,
    timeS,
    depthM,
    temperatureC,
    heartRate,
    ndlS,
    decoCeilingM,
    decoTimeS,
    gasIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dive_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dive_id')) {
      context.handle(
        _diveIdMeta,
        diveId.isAcceptableOrUnknown(data['dive_id']!, _diveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diveIdMeta);
    }
    if (data.containsKey('time_s')) {
      context.handle(
        _timeSMeta,
        timeS.isAcceptableOrUnknown(data['time_s']!, _timeSMeta),
      );
    } else if (isInserting) {
      context.missing(_timeSMeta);
    }
    if (data.containsKey('depth_m')) {
      context.handle(
        _depthMMeta,
        depthM.isAcceptableOrUnknown(data['depth_m']!, _depthMMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMMeta);
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
        _temperatureCMeta,
        temperatureC.isAcceptableOrUnknown(
          data['temperature_c']!,
          _temperatureCMeta,
        ),
      );
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('ndl_s')) {
      context.handle(
        _ndlSMeta,
        ndlS.isAcceptableOrUnknown(data['ndl_s']!, _ndlSMeta),
      );
    }
    if (data.containsKey('deco_ceiling_m')) {
      context.handle(
        _decoCeilingMMeta,
        decoCeilingM.isAcceptableOrUnknown(
          data['deco_ceiling_m']!,
          _decoCeilingMMeta,
        ),
      );
    }
    if (data.containsKey('deco_time_s')) {
      context.handle(
        _decoTimeSMeta,
        decoTimeS.isAcceptableOrUnknown(data['deco_time_s']!, _decoTimeSMeta),
      );
    }
    if (data.containsKey('gas_index')) {
      context.handle(
        _gasIndexMeta,
        gasIndex.isAcceptableOrUnknown(data['gas_index']!, _gasIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {diveId, timeS};
  @override
  DiveSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveSampleRow(
      diveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dive_id'],
      )!,
      timeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_s'],
      )!,
      depthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_m'],
      )!,
      temperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_c'],
      ),
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate'],
      ),
      ndlS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ndl_s'],
      ),
      decoCeilingM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deco_ceiling_m'],
      ),
      decoTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deco_time_s'],
      ),
      gasIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gas_index'],
      ),
    );
  }

  @override
  $DiveSamplesTable createAlias(String alias) {
    return $DiveSamplesTable(attachedDatabase, alias);
  }
}

class DiveSampleRow extends DataClass implements Insertable<DiveSampleRow> {
  final String diveId;
  final int timeS;
  final double depthM;
  final double? temperatureC;
  final int? heartRate;
  final int? ndlS;
  final double? decoCeilingM;
  final int? decoTimeS;
  final int? gasIndex;
  const DiveSampleRow({
    required this.diveId,
    required this.timeS,
    required this.depthM,
    this.temperatureC,
    this.heartRate,
    this.ndlS,
    this.decoCeilingM,
    this.decoTimeS,
    this.gasIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dive_id'] = Variable<String>(diveId);
    map['time_s'] = Variable<int>(timeS);
    map['depth_m'] = Variable<double>(depthM);
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<double>(temperatureC);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || ndlS != null) {
      map['ndl_s'] = Variable<int>(ndlS);
    }
    if (!nullToAbsent || decoCeilingM != null) {
      map['deco_ceiling_m'] = Variable<double>(decoCeilingM);
    }
    if (!nullToAbsent || decoTimeS != null) {
      map['deco_time_s'] = Variable<int>(decoTimeS);
    }
    if (!nullToAbsent || gasIndex != null) {
      map['gas_index'] = Variable<int>(gasIndex);
    }
    return map;
  }

  DiveSamplesCompanion toCompanion(bool nullToAbsent) {
    return DiveSamplesCompanion(
      diveId: Value(diveId),
      timeS: Value(timeS),
      depthM: Value(depthM),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      ndlS: ndlS == null && nullToAbsent ? const Value.absent() : Value(ndlS),
      decoCeilingM: decoCeilingM == null && nullToAbsent
          ? const Value.absent()
          : Value(decoCeilingM),
      decoTimeS: decoTimeS == null && nullToAbsent
          ? const Value.absent()
          : Value(decoTimeS),
      gasIndex: gasIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(gasIndex),
    );
  }

  factory DiveSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveSampleRow(
      diveId: serializer.fromJson<String>(json['diveId']),
      timeS: serializer.fromJson<int>(json['timeS']),
      depthM: serializer.fromJson<double>(json['depthM']),
      temperatureC: serializer.fromJson<double?>(json['temperatureC']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      ndlS: serializer.fromJson<int?>(json['ndlS']),
      decoCeilingM: serializer.fromJson<double?>(json['decoCeilingM']),
      decoTimeS: serializer.fromJson<int?>(json['decoTimeS']),
      gasIndex: serializer.fromJson<int?>(json['gasIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'diveId': serializer.toJson<String>(diveId),
      'timeS': serializer.toJson<int>(timeS),
      'depthM': serializer.toJson<double>(depthM),
      'temperatureC': serializer.toJson<double?>(temperatureC),
      'heartRate': serializer.toJson<int?>(heartRate),
      'ndlS': serializer.toJson<int?>(ndlS),
      'decoCeilingM': serializer.toJson<double?>(decoCeilingM),
      'decoTimeS': serializer.toJson<int?>(decoTimeS),
      'gasIndex': serializer.toJson<int?>(gasIndex),
    };
  }

  DiveSampleRow copyWith({
    String? diveId,
    int? timeS,
    double? depthM,
    Value<double?> temperatureC = const Value.absent(),
    Value<int?> heartRate = const Value.absent(),
    Value<int?> ndlS = const Value.absent(),
    Value<double?> decoCeilingM = const Value.absent(),
    Value<int?> decoTimeS = const Value.absent(),
    Value<int?> gasIndex = const Value.absent(),
  }) => DiveSampleRow(
    diveId: diveId ?? this.diveId,
    timeS: timeS ?? this.timeS,
    depthM: depthM ?? this.depthM,
    temperatureC: temperatureC.present ? temperatureC.value : this.temperatureC,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    ndlS: ndlS.present ? ndlS.value : this.ndlS,
    decoCeilingM: decoCeilingM.present ? decoCeilingM.value : this.decoCeilingM,
    decoTimeS: decoTimeS.present ? decoTimeS.value : this.decoTimeS,
    gasIndex: gasIndex.present ? gasIndex.value : this.gasIndex,
  );
  DiveSampleRow copyWithCompanion(DiveSamplesCompanion data) {
    return DiveSampleRow(
      diveId: data.diveId.present ? data.diveId.value : this.diveId,
      timeS: data.timeS.present ? data.timeS.value : this.timeS,
      depthM: data.depthM.present ? data.depthM.value : this.depthM,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      ndlS: data.ndlS.present ? data.ndlS.value : this.ndlS,
      decoCeilingM: data.decoCeilingM.present
          ? data.decoCeilingM.value
          : this.decoCeilingM,
      decoTimeS: data.decoTimeS.present ? data.decoTimeS.value : this.decoTimeS,
      gasIndex: data.gasIndex.present ? data.gasIndex.value : this.gasIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveSampleRow(')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('depthM: $depthM, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('heartRate: $heartRate, ')
          ..write('ndlS: $ndlS, ')
          ..write('decoCeilingM: $decoCeilingM, ')
          ..write('decoTimeS: $decoTimeS, ')
          ..write('gasIndex: $gasIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    diveId,
    timeS,
    depthM,
    temperatureC,
    heartRate,
    ndlS,
    decoCeilingM,
    decoTimeS,
    gasIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveSampleRow &&
          other.diveId == this.diveId &&
          other.timeS == this.timeS &&
          other.depthM == this.depthM &&
          other.temperatureC == this.temperatureC &&
          other.heartRate == this.heartRate &&
          other.ndlS == this.ndlS &&
          other.decoCeilingM == this.decoCeilingM &&
          other.decoTimeS == this.decoTimeS &&
          other.gasIndex == this.gasIndex);
}

class DiveSamplesCompanion extends UpdateCompanion<DiveSampleRow> {
  final Value<String> diveId;
  final Value<int> timeS;
  final Value<double> depthM;
  final Value<double?> temperatureC;
  final Value<int?> heartRate;
  final Value<int?> ndlS;
  final Value<double?> decoCeilingM;
  final Value<int?> decoTimeS;
  final Value<int?> gasIndex;
  final Value<int> rowid;
  const DiveSamplesCompanion({
    this.diveId = const Value.absent(),
    this.timeS = const Value.absent(),
    this.depthM = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.ndlS = const Value.absent(),
    this.decoCeilingM = const Value.absent(),
    this.decoTimeS = const Value.absent(),
    this.gasIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiveSamplesCompanion.insert({
    required String diveId,
    required int timeS,
    required double depthM,
    this.temperatureC = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.ndlS = const Value.absent(),
    this.decoCeilingM = const Value.absent(),
    this.decoTimeS = const Value.absent(),
    this.gasIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : diveId = Value(diveId),
       timeS = Value(timeS),
       depthM = Value(depthM);
  static Insertable<DiveSampleRow> custom({
    Expression<String>? diveId,
    Expression<int>? timeS,
    Expression<double>? depthM,
    Expression<double>? temperatureC,
    Expression<int>? heartRate,
    Expression<int>? ndlS,
    Expression<double>? decoCeilingM,
    Expression<int>? decoTimeS,
    Expression<int>? gasIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (diveId != null) 'dive_id': diveId,
      if (timeS != null) 'time_s': timeS,
      if (depthM != null) 'depth_m': depthM,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (heartRate != null) 'heart_rate': heartRate,
      if (ndlS != null) 'ndl_s': ndlS,
      if (decoCeilingM != null) 'deco_ceiling_m': decoCeilingM,
      if (decoTimeS != null) 'deco_time_s': decoTimeS,
      if (gasIndex != null) 'gas_index': gasIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiveSamplesCompanion copyWith({
    Value<String>? diveId,
    Value<int>? timeS,
    Value<double>? depthM,
    Value<double?>? temperatureC,
    Value<int?>? heartRate,
    Value<int?>? ndlS,
    Value<double?>? decoCeilingM,
    Value<int?>? decoTimeS,
    Value<int?>? gasIndex,
    Value<int>? rowid,
  }) {
    return DiveSamplesCompanion(
      diveId: diveId ?? this.diveId,
      timeS: timeS ?? this.timeS,
      depthM: depthM ?? this.depthM,
      temperatureC: temperatureC ?? this.temperatureC,
      heartRate: heartRate ?? this.heartRate,
      ndlS: ndlS ?? this.ndlS,
      decoCeilingM: decoCeilingM ?? this.decoCeilingM,
      decoTimeS: decoTimeS ?? this.decoTimeS,
      gasIndex: gasIndex ?? this.gasIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (diveId.present) {
      map['dive_id'] = Variable<String>(diveId.value);
    }
    if (timeS.present) {
      map['time_s'] = Variable<int>(timeS.value);
    }
    if (depthM.present) {
      map['depth_m'] = Variable<double>(depthM.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (ndlS.present) {
      map['ndl_s'] = Variable<int>(ndlS.value);
    }
    if (decoCeilingM.present) {
      map['deco_ceiling_m'] = Variable<double>(decoCeilingM.value);
    }
    if (decoTimeS.present) {
      map['deco_time_s'] = Variable<int>(decoTimeS.value);
    }
    if (gasIndex.present) {
      map['gas_index'] = Variable<int>(gasIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiveSamplesCompanion(')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('depthM: $depthM, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('heartRate: $heartRate, ')
          ..write('ndlS: $ndlS, ')
          ..write('decoCeilingM: $decoCeilingM, ')
          ..write('decoTimeS: $decoTimeS, ')
          ..write('gasIndex: $gasIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiveTankPressuresTable extends DiveTankPressures
    with TableInfo<$DiveTankPressuresTable, DiveTankPressureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiveTankPressuresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _diveIdMeta = const VerificationMeta('diveId');
  @override
  late final GeneratedColumn<String> diveId = GeneratedColumn<String>(
    'dive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dives (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeSMeta = const VerificationMeta('timeS');
  @override
  late final GeneratedColumn<int> timeS = GeneratedColumn<int>(
    'time_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tankIndexMeta = const VerificationMeta(
    'tankIndex',
  );
  @override
  late final GeneratedColumn<int> tankIndex = GeneratedColumn<int>(
    'tank_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pressureBarMeta = const VerificationMeta(
    'pressureBar',
  );
  @override
  late final GeneratedColumn<double> pressureBar = GeneratedColumn<double>(
    'pressure_bar',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [diveId, timeS, tankIndex, pressureBar];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dive_tank_pressures';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveTankPressureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dive_id')) {
      context.handle(
        _diveIdMeta,
        diveId.isAcceptableOrUnknown(data['dive_id']!, _diveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diveIdMeta);
    }
    if (data.containsKey('time_s')) {
      context.handle(
        _timeSMeta,
        timeS.isAcceptableOrUnknown(data['time_s']!, _timeSMeta),
      );
    } else if (isInserting) {
      context.missing(_timeSMeta);
    }
    if (data.containsKey('tank_index')) {
      context.handle(
        _tankIndexMeta,
        tankIndex.isAcceptableOrUnknown(data['tank_index']!, _tankIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tankIndexMeta);
    }
    if (data.containsKey('pressure_bar')) {
      context.handle(
        _pressureBarMeta,
        pressureBar.isAcceptableOrUnknown(
          data['pressure_bar']!,
          _pressureBarMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pressureBarMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {diveId, timeS, tankIndex};
  @override
  DiveTankPressureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveTankPressureRow(
      diveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dive_id'],
      )!,
      timeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_s'],
      )!,
      tankIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tank_index'],
      )!,
      pressureBar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pressure_bar'],
      )!,
    );
  }

  @override
  $DiveTankPressuresTable createAlias(String alias) {
    return $DiveTankPressuresTable(attachedDatabase, alias);
  }
}

class DiveTankPressureRow extends DataClass
    implements Insertable<DiveTankPressureRow> {
  final String diveId;
  final int timeS;
  final int tankIndex;
  final double pressureBar;
  const DiveTankPressureRow({
    required this.diveId,
    required this.timeS,
    required this.tankIndex,
    required this.pressureBar,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dive_id'] = Variable<String>(diveId);
    map['time_s'] = Variable<int>(timeS);
    map['tank_index'] = Variable<int>(tankIndex);
    map['pressure_bar'] = Variable<double>(pressureBar);
    return map;
  }

  DiveTankPressuresCompanion toCompanion(bool nullToAbsent) {
    return DiveTankPressuresCompanion(
      diveId: Value(diveId),
      timeS: Value(timeS),
      tankIndex: Value(tankIndex),
      pressureBar: Value(pressureBar),
    );
  }

  factory DiveTankPressureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveTankPressureRow(
      diveId: serializer.fromJson<String>(json['diveId']),
      timeS: serializer.fromJson<int>(json['timeS']),
      tankIndex: serializer.fromJson<int>(json['tankIndex']),
      pressureBar: serializer.fromJson<double>(json['pressureBar']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'diveId': serializer.toJson<String>(diveId),
      'timeS': serializer.toJson<int>(timeS),
      'tankIndex': serializer.toJson<int>(tankIndex),
      'pressureBar': serializer.toJson<double>(pressureBar),
    };
  }

  DiveTankPressureRow copyWith({
    String? diveId,
    int? timeS,
    int? tankIndex,
    double? pressureBar,
  }) => DiveTankPressureRow(
    diveId: diveId ?? this.diveId,
    timeS: timeS ?? this.timeS,
    tankIndex: tankIndex ?? this.tankIndex,
    pressureBar: pressureBar ?? this.pressureBar,
  );
  DiveTankPressureRow copyWithCompanion(DiveTankPressuresCompanion data) {
    return DiveTankPressureRow(
      diveId: data.diveId.present ? data.diveId.value : this.diveId,
      timeS: data.timeS.present ? data.timeS.value : this.timeS,
      tankIndex: data.tankIndex.present ? data.tankIndex.value : this.tankIndex,
      pressureBar: data.pressureBar.present
          ? data.pressureBar.value
          : this.pressureBar,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveTankPressureRow(')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('tankIndex: $tankIndex, ')
          ..write('pressureBar: $pressureBar')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(diveId, timeS, tankIndex, pressureBar);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveTankPressureRow &&
          other.diveId == this.diveId &&
          other.timeS == this.timeS &&
          other.tankIndex == this.tankIndex &&
          other.pressureBar == this.pressureBar);
}

class DiveTankPressuresCompanion extends UpdateCompanion<DiveTankPressureRow> {
  final Value<String> diveId;
  final Value<int> timeS;
  final Value<int> tankIndex;
  final Value<double> pressureBar;
  final Value<int> rowid;
  const DiveTankPressuresCompanion({
    this.diveId = const Value.absent(),
    this.timeS = const Value.absent(),
    this.tankIndex = const Value.absent(),
    this.pressureBar = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiveTankPressuresCompanion.insert({
    required String diveId,
    required int timeS,
    required int tankIndex,
    required double pressureBar,
    this.rowid = const Value.absent(),
  }) : diveId = Value(diveId),
       timeS = Value(timeS),
       tankIndex = Value(tankIndex),
       pressureBar = Value(pressureBar);
  static Insertable<DiveTankPressureRow> custom({
    Expression<String>? diveId,
    Expression<int>? timeS,
    Expression<int>? tankIndex,
    Expression<double>? pressureBar,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (diveId != null) 'dive_id': diveId,
      if (timeS != null) 'time_s': timeS,
      if (tankIndex != null) 'tank_index': tankIndex,
      if (pressureBar != null) 'pressure_bar': pressureBar,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiveTankPressuresCompanion copyWith({
    Value<String>? diveId,
    Value<int>? timeS,
    Value<int>? tankIndex,
    Value<double>? pressureBar,
    Value<int>? rowid,
  }) {
    return DiveTankPressuresCompanion(
      diveId: diveId ?? this.diveId,
      timeS: timeS ?? this.timeS,
      tankIndex: tankIndex ?? this.tankIndex,
      pressureBar: pressureBar ?? this.pressureBar,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (diveId.present) {
      map['dive_id'] = Variable<String>(diveId.value);
    }
    if (timeS.present) {
      map['time_s'] = Variable<int>(timeS.value);
    }
    if (tankIndex.present) {
      map['tank_index'] = Variable<int>(tankIndex.value);
    }
    if (pressureBar.present) {
      map['pressure_bar'] = Variable<double>(pressureBar.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiveTankPressuresCompanion(')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('tankIndex: $tankIndex, ')
          ..write('pressureBar: $pressureBar, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiveTanksTable extends DiveTanks
    with TableInfo<$DiveTanksTable, DiveTankRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiveTanksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _diveIdMeta = const VerificationMeta('diveId');
  @override
  late final GeneratedColumn<String> diveId = GeneratedColumn<String>(
    'dive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dives (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tankIndexMeta = const VerificationMeta(
    'tankIndex',
  );
  @override
  late final GeneratedColumn<int> tankIndex = GeneratedColumn<int>(
    'tank_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeLMeta = const VerificationMeta(
    'volumeL',
  );
  @override
  late final GeneratedColumn<double> volumeL = GeneratedColumn<double>(
    'volume_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startPressureBarMeta = const VerificationMeta(
    'startPressureBar',
  );
  @override
  late final GeneratedColumn<double> startPressureBar = GeneratedColumn<double>(
    'start_pressure_bar',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endPressureBarMeta = const VerificationMeta(
    'endPressureBar',
  );
  @override
  late final GeneratedColumn<double> endPressureBar = GeneratedColumn<double>(
    'end_pressure_bar',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _o2Meta = const VerificationMeta('o2');
  @override
  late final GeneratedColumn<double> o2 = GeneratedColumn<double>(
    'o2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heMeta = const VerificationMeta('he');
  @override
  late final GeneratedColumn<double> he = GeneratedColumn<double>(
    'he',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    diveId,
    tankIndex,
    volumeL,
    startPressureBar,
    endPressureBar,
    o2,
    he,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dive_tanks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveTankRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dive_id')) {
      context.handle(
        _diveIdMeta,
        diveId.isAcceptableOrUnknown(data['dive_id']!, _diveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diveIdMeta);
    }
    if (data.containsKey('tank_index')) {
      context.handle(
        _tankIndexMeta,
        tankIndex.isAcceptableOrUnknown(data['tank_index']!, _tankIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tankIndexMeta);
    }
    if (data.containsKey('volume_l')) {
      context.handle(
        _volumeLMeta,
        volumeL.isAcceptableOrUnknown(data['volume_l']!, _volumeLMeta),
      );
    }
    if (data.containsKey('start_pressure_bar')) {
      context.handle(
        _startPressureBarMeta,
        startPressureBar.isAcceptableOrUnknown(
          data['start_pressure_bar']!,
          _startPressureBarMeta,
        ),
      );
    }
    if (data.containsKey('end_pressure_bar')) {
      context.handle(
        _endPressureBarMeta,
        endPressureBar.isAcceptableOrUnknown(
          data['end_pressure_bar']!,
          _endPressureBarMeta,
        ),
      );
    }
    if (data.containsKey('o2')) {
      context.handle(_o2Meta, o2.isAcceptableOrUnknown(data['o2']!, _o2Meta));
    }
    if (data.containsKey('he')) {
      context.handle(_heMeta, he.isAcceptableOrUnknown(data['he']!, _heMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {diveId, tankIndex};
  @override
  DiveTankRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveTankRow(
      diveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dive_id'],
      )!,
      tankIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tank_index'],
      )!,
      volumeL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume_l'],
      ),
      startPressureBar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_pressure_bar'],
      ),
      endPressureBar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_pressure_bar'],
      ),
      o2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}o2'],
      ),
      he: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}he'],
      ),
    );
  }

  @override
  $DiveTanksTable createAlias(String alias) {
    return $DiveTanksTable(attachedDatabase, alias);
  }
}

class DiveTankRow extends DataClass implements Insertable<DiveTankRow> {
  final String diveId;
  final int tankIndex;
  final double? volumeL;
  final double? startPressureBar;
  final double? endPressureBar;
  final double? o2;
  final double? he;
  const DiveTankRow({
    required this.diveId,
    required this.tankIndex,
    this.volumeL,
    this.startPressureBar,
    this.endPressureBar,
    this.o2,
    this.he,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dive_id'] = Variable<String>(diveId);
    map['tank_index'] = Variable<int>(tankIndex);
    if (!nullToAbsent || volumeL != null) {
      map['volume_l'] = Variable<double>(volumeL);
    }
    if (!nullToAbsent || startPressureBar != null) {
      map['start_pressure_bar'] = Variable<double>(startPressureBar);
    }
    if (!nullToAbsent || endPressureBar != null) {
      map['end_pressure_bar'] = Variable<double>(endPressureBar);
    }
    if (!nullToAbsent || o2 != null) {
      map['o2'] = Variable<double>(o2);
    }
    if (!nullToAbsent || he != null) {
      map['he'] = Variable<double>(he);
    }
    return map;
  }

  DiveTanksCompanion toCompanion(bool nullToAbsent) {
    return DiveTanksCompanion(
      diveId: Value(diveId),
      tankIndex: Value(tankIndex),
      volumeL: volumeL == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeL),
      startPressureBar: startPressureBar == null && nullToAbsent
          ? const Value.absent()
          : Value(startPressureBar),
      endPressureBar: endPressureBar == null && nullToAbsent
          ? const Value.absent()
          : Value(endPressureBar),
      o2: o2 == null && nullToAbsent ? const Value.absent() : Value(o2),
      he: he == null && nullToAbsent ? const Value.absent() : Value(he),
    );
  }

  factory DiveTankRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveTankRow(
      diveId: serializer.fromJson<String>(json['diveId']),
      tankIndex: serializer.fromJson<int>(json['tankIndex']),
      volumeL: serializer.fromJson<double?>(json['volumeL']),
      startPressureBar: serializer.fromJson<double?>(json['startPressureBar']),
      endPressureBar: serializer.fromJson<double?>(json['endPressureBar']),
      o2: serializer.fromJson<double?>(json['o2']),
      he: serializer.fromJson<double?>(json['he']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'diveId': serializer.toJson<String>(diveId),
      'tankIndex': serializer.toJson<int>(tankIndex),
      'volumeL': serializer.toJson<double?>(volumeL),
      'startPressureBar': serializer.toJson<double?>(startPressureBar),
      'endPressureBar': serializer.toJson<double?>(endPressureBar),
      'o2': serializer.toJson<double?>(o2),
      'he': serializer.toJson<double?>(he),
    };
  }

  DiveTankRow copyWith({
    String? diveId,
    int? tankIndex,
    Value<double?> volumeL = const Value.absent(),
    Value<double?> startPressureBar = const Value.absent(),
    Value<double?> endPressureBar = const Value.absent(),
    Value<double?> o2 = const Value.absent(),
    Value<double?> he = const Value.absent(),
  }) => DiveTankRow(
    diveId: diveId ?? this.diveId,
    tankIndex: tankIndex ?? this.tankIndex,
    volumeL: volumeL.present ? volumeL.value : this.volumeL,
    startPressureBar: startPressureBar.present
        ? startPressureBar.value
        : this.startPressureBar,
    endPressureBar: endPressureBar.present
        ? endPressureBar.value
        : this.endPressureBar,
    o2: o2.present ? o2.value : this.o2,
    he: he.present ? he.value : this.he,
  );
  DiveTankRow copyWithCompanion(DiveTanksCompanion data) {
    return DiveTankRow(
      diveId: data.diveId.present ? data.diveId.value : this.diveId,
      tankIndex: data.tankIndex.present ? data.tankIndex.value : this.tankIndex,
      volumeL: data.volumeL.present ? data.volumeL.value : this.volumeL,
      startPressureBar: data.startPressureBar.present
          ? data.startPressureBar.value
          : this.startPressureBar,
      endPressureBar: data.endPressureBar.present
          ? data.endPressureBar.value
          : this.endPressureBar,
      o2: data.o2.present ? data.o2.value : this.o2,
      he: data.he.present ? data.he.value : this.he,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveTankRow(')
          ..write('diveId: $diveId, ')
          ..write('tankIndex: $tankIndex, ')
          ..write('volumeL: $volumeL, ')
          ..write('startPressureBar: $startPressureBar, ')
          ..write('endPressureBar: $endPressureBar, ')
          ..write('o2: $o2, ')
          ..write('he: $he')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    diveId,
    tankIndex,
    volumeL,
    startPressureBar,
    endPressureBar,
    o2,
    he,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveTankRow &&
          other.diveId == this.diveId &&
          other.tankIndex == this.tankIndex &&
          other.volumeL == this.volumeL &&
          other.startPressureBar == this.startPressureBar &&
          other.endPressureBar == this.endPressureBar &&
          other.o2 == this.o2 &&
          other.he == this.he);
}

class DiveTanksCompanion extends UpdateCompanion<DiveTankRow> {
  final Value<String> diveId;
  final Value<int> tankIndex;
  final Value<double?> volumeL;
  final Value<double?> startPressureBar;
  final Value<double?> endPressureBar;
  final Value<double?> o2;
  final Value<double?> he;
  final Value<int> rowid;
  const DiveTanksCompanion({
    this.diveId = const Value.absent(),
    this.tankIndex = const Value.absent(),
    this.volumeL = const Value.absent(),
    this.startPressureBar = const Value.absent(),
    this.endPressureBar = const Value.absent(),
    this.o2 = const Value.absent(),
    this.he = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiveTanksCompanion.insert({
    required String diveId,
    required int tankIndex,
    this.volumeL = const Value.absent(),
    this.startPressureBar = const Value.absent(),
    this.endPressureBar = const Value.absent(),
    this.o2 = const Value.absent(),
    this.he = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : diveId = Value(diveId),
       tankIndex = Value(tankIndex);
  static Insertable<DiveTankRow> custom({
    Expression<String>? diveId,
    Expression<int>? tankIndex,
    Expression<double>? volumeL,
    Expression<double>? startPressureBar,
    Expression<double>? endPressureBar,
    Expression<double>? o2,
    Expression<double>? he,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (diveId != null) 'dive_id': diveId,
      if (tankIndex != null) 'tank_index': tankIndex,
      if (volumeL != null) 'volume_l': volumeL,
      if (startPressureBar != null) 'start_pressure_bar': startPressureBar,
      if (endPressureBar != null) 'end_pressure_bar': endPressureBar,
      if (o2 != null) 'o2': o2,
      if (he != null) 'he': he,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiveTanksCompanion copyWith({
    Value<String>? diveId,
    Value<int>? tankIndex,
    Value<double?>? volumeL,
    Value<double?>? startPressureBar,
    Value<double?>? endPressureBar,
    Value<double?>? o2,
    Value<double?>? he,
    Value<int>? rowid,
  }) {
    return DiveTanksCompanion(
      diveId: diveId ?? this.diveId,
      tankIndex: tankIndex ?? this.tankIndex,
      volumeL: volumeL ?? this.volumeL,
      startPressureBar: startPressureBar ?? this.startPressureBar,
      endPressureBar: endPressureBar ?? this.endPressureBar,
      o2: o2 ?? this.o2,
      he: he ?? this.he,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (diveId.present) {
      map['dive_id'] = Variable<String>(diveId.value);
    }
    if (tankIndex.present) {
      map['tank_index'] = Variable<int>(tankIndex.value);
    }
    if (volumeL.present) {
      map['volume_l'] = Variable<double>(volumeL.value);
    }
    if (startPressureBar.present) {
      map['start_pressure_bar'] = Variable<double>(startPressureBar.value);
    }
    if (endPressureBar.present) {
      map['end_pressure_bar'] = Variable<double>(endPressureBar.value);
    }
    if (o2.present) {
      map['o2'] = Variable<double>(o2.value);
    }
    if (he.present) {
      map['he'] = Variable<double>(he.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiveTanksCompanion(')
          ..write('diveId: $diveId, ')
          ..write('tankIndex: $tankIndex, ')
          ..write('volumeL: $volumeL, ')
          ..write('startPressureBar: $startPressureBar, ')
          ..write('endPressureBar: $endPressureBar, ')
          ..write('o2: $o2, ')
          ..write('he: $he, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiveEventsTable extends DiveEvents
    with TableInfo<$DiveEventsTable, DiveEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiveEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diveIdMeta = const VerificationMeta('diveId');
  @override
  late final GeneratedColumn<String> diveId = GeneratedColumn<String>(
    'dive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dives (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeSMeta = const VerificationMeta('timeS');
  @override
  late final GeneratedColumn<int> timeS = GeneratedColumn<int>(
    'time_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, diveId, timeS, type, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dive_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiveEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dive_id')) {
      context.handle(
        _diveIdMeta,
        diveId.isAcceptableOrUnknown(data['dive_id']!, _diveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diveIdMeta);
    }
    if (data.containsKey('time_s')) {
      context.handle(
        _timeSMeta,
        timeS.isAcceptableOrUnknown(data['time_s']!, _timeSMeta),
      );
    } else if (isInserting) {
      context.missing(_timeSMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiveEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiveEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dive_id'],
      )!,
      timeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_s'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $DiveEventsTable createAlias(String alias) {
    return $DiveEventsTable(attachedDatabase, alias);
  }
}

class DiveEventRow extends DataClass implements Insertable<DiveEventRow> {
  final String id;
  final String diveId;
  final int timeS;
  final String type;
  final String? value;
  const DiveEventRow({
    required this.id,
    required this.diveId,
    required this.timeS,
    required this.type,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dive_id'] = Variable<String>(diveId);
    map['time_s'] = Variable<int>(timeS);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  DiveEventsCompanion toCompanion(bool nullToAbsent) {
    return DiveEventsCompanion(
      id: Value(id),
      diveId: Value(diveId),
      timeS: Value(timeS),
      type: Value(type),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory DiveEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiveEventRow(
      id: serializer.fromJson<String>(json['id']),
      diveId: serializer.fromJson<String>(json['diveId']),
      timeS: serializer.fromJson<int>(json['timeS']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diveId': serializer.toJson<String>(diveId),
      'timeS': serializer.toJson<int>(timeS),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String?>(value),
    };
  }

  DiveEventRow copyWith({
    String? id,
    String? diveId,
    int? timeS,
    String? type,
    Value<String?> value = const Value.absent(),
  }) => DiveEventRow(
    id: id ?? this.id,
    diveId: diveId ?? this.diveId,
    timeS: timeS ?? this.timeS,
    type: type ?? this.type,
    value: value.present ? value.value : this.value,
  );
  DiveEventRow copyWithCompanion(DiveEventsCompanion data) {
    return DiveEventRow(
      id: data.id.present ? data.id.value : this.id,
      diveId: data.diveId.present ? data.diveId.value : this.diveId,
      timeS: data.timeS.present ? data.timeS.value : this.timeS,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiveEventRow(')
          ..write('id: $id, ')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('type: $type, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, diveId, timeS, type, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiveEventRow &&
          other.id == this.id &&
          other.diveId == this.diveId &&
          other.timeS == this.timeS &&
          other.type == this.type &&
          other.value == this.value);
}

class DiveEventsCompanion extends UpdateCompanion<DiveEventRow> {
  final Value<String> id;
  final Value<String> diveId;
  final Value<int> timeS;
  final Value<String> type;
  final Value<String?> value;
  final Value<int> rowid;
  const DiveEventsCompanion({
    this.id = const Value.absent(),
    this.diveId = const Value.absent(),
    this.timeS = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiveEventsCompanion.insert({
    required String id,
    required String diveId,
    required int timeS,
    required String type,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diveId = Value(diveId),
       timeS = Value(timeS),
       type = Value(type);
  static Insertable<DiveEventRow> custom({
    Expression<String>? id,
    Expression<String>? diveId,
    Expression<int>? timeS,
    Expression<String>? type,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diveId != null) 'dive_id': diveId,
      if (timeS != null) 'time_s': timeS,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiveEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? diveId,
    Value<int>? timeS,
    Value<String>? type,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return DiveEventsCompanion(
      id: id ?? this.id,
      diveId: diveId ?? this.diveId,
      timeS: timeS ?? this.timeS,
      type: type ?? this.type,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diveId.present) {
      map['dive_id'] = Variable<String>(diveId.value);
    }
    if (timeS.present) {
      map['time_s'] = Variable<int>(timeS.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiveEventsCompanion(')
          ..write('id: $id, ')
          ..write('diveId: $diveId, ')
          ..write('timeS: $timeS, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogueSitesTable extends CatalogueSites
    with TableInfo<$CatalogueSitesTable, CatalogueSiteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogueSitesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxDepthMMeta = const VerificationMeta(
    'maxDepthM',
  );
  @override
  late final GeneratedColumn<double> maxDepthM = GeneratedColumn<double>(
    'max_depth_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typesMeta = const VerificationMeta('types');
  @override
  late final GeneratedColumn<String> types = GeneratedColumn<String>(
    'types',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    region,
    countryCode,
    lat,
    lon,
    maxDepthM,
    types,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalogue_sites';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogueSiteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('max_depth_m')) {
      context.handle(
        _maxDepthMMeta,
        maxDepthM.isAcceptableOrUnknown(data['max_depth_m']!, _maxDepthMMeta),
      );
    }
    if (data.containsKey('types')) {
      context.handle(
        _typesMeta,
        types.isAcceptableOrUnknown(data['types']!, _typesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogueSiteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogueSiteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      ),
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      maxDepthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_depth_m'],
      ),
      types: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}types'],
      )!,
    );
  }

  @override
  $CatalogueSitesTable createAlias(String alias) {
    return $CatalogueSitesTable(attachedDatabase, alias);
  }
}

class CatalogueSiteRow extends DataClass
    implements Insertable<CatalogueSiteRow> {
  final String id;
  final String name;
  final String? region;
  final String? countryCode;
  final double lat;
  final double lon;
  final double? maxDepthM;

  /// Comma-separated, e.g. `reef,wreck`.
  final String types;
  const CatalogueSiteRow({
    required this.id,
    required this.name,
    this.region,
    this.countryCode,
    required this.lat,
    required this.lon,
    this.maxDepthM,
    required this.types,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || maxDepthM != null) {
      map['max_depth_m'] = Variable<double>(maxDepthM);
    }
    map['types'] = Variable<String>(types);
    return map;
  }

  CatalogueSitesCompanion toCompanion(bool nullToAbsent) {
    return CatalogueSitesCompanion(
      id: Value(id),
      name: Value(name),
      region: region == null && nullToAbsent
          ? const Value.absent()
          : Value(region),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      lat: Value(lat),
      lon: Value(lon),
      maxDepthM: maxDepthM == null && nullToAbsent
          ? const Value.absent()
          : Value(maxDepthM),
      types: Value(types),
    );
  }

  factory CatalogueSiteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogueSiteRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      region: serializer.fromJson<String?>(json['region']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      maxDepthM: serializer.fromJson<double?>(json['maxDepthM']),
      types: serializer.fromJson<String>(json['types']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'region': serializer.toJson<String?>(region),
      'countryCode': serializer.toJson<String?>(countryCode),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'maxDepthM': serializer.toJson<double?>(maxDepthM),
      'types': serializer.toJson<String>(types),
    };
  }

  CatalogueSiteRow copyWith({
    String? id,
    String? name,
    Value<String?> region = const Value.absent(),
    Value<String?> countryCode = const Value.absent(),
    double? lat,
    double? lon,
    Value<double?> maxDepthM = const Value.absent(),
    String? types,
  }) => CatalogueSiteRow(
    id: id ?? this.id,
    name: name ?? this.name,
    region: region.present ? region.value : this.region,
    countryCode: countryCode.present ? countryCode.value : this.countryCode,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    maxDepthM: maxDepthM.present ? maxDepthM.value : this.maxDepthM,
    types: types ?? this.types,
  );
  CatalogueSiteRow copyWithCompanion(CatalogueSitesCompanion data) {
    return CatalogueSiteRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      region: data.region.present ? data.region.value : this.region,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      maxDepthM: data.maxDepthM.present ? data.maxDepthM.value : this.maxDepthM,
      types: data.types.present ? data.types.value : this.types,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogueSiteRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('region: $region, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('maxDepthM: $maxDepthM, ')
          ..write('types: $types')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, region, countryCode, lat, lon, maxDepthM, types);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogueSiteRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.region == this.region &&
          other.countryCode == this.countryCode &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.maxDepthM == this.maxDepthM &&
          other.types == this.types);
}

class CatalogueSitesCompanion extends UpdateCompanion<CatalogueSiteRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> region;
  final Value<String?> countryCode;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> maxDepthM;
  final Value<String> types;
  final Value<int> rowid;
  const CatalogueSitesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.region = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.maxDepthM = const Value.absent(),
    this.types = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogueSitesCompanion.insert({
    required String id,
    required String name,
    this.region = const Value.absent(),
    this.countryCode = const Value.absent(),
    required double lat,
    required double lon,
    this.maxDepthM = const Value.absent(),
    this.types = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<CatalogueSiteRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? region,
    Expression<String>? countryCode,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? maxDepthM,
    Expression<String>? types,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (region != null) 'region': region,
      if (countryCode != null) 'country_code': countryCode,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (maxDepthM != null) 'max_depth_m': maxDepthM,
      if (types != null) 'types': types,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogueSitesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? region,
    Value<String?>? countryCode,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? maxDepthM,
    Value<String>? types,
    Value<int>? rowid,
  }) {
    return CatalogueSitesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      countryCode: countryCode ?? this.countryCode,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      maxDepthM: maxDepthM ?? this.maxDepthM,
      types: types ?? this.types,
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
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (maxDepthM.present) {
      map['max_depth_m'] = Variable<double>(maxDepthM.value);
    }
    if (types.present) {
      map['types'] = Variable<String>(types.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogueSitesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('region: $region, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('maxDepthM: $maxDepthM, ')
          ..write('types: $types, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiversTable divers = $DiversTable(this);
  late final $DiveComputersTable diveComputers = $DiveComputersTable(this);
  late final $DivesTable dives = $DivesTable(this);
  late final $DiveSamplesTable diveSamples = $DiveSamplesTable(this);
  late final $DiveTankPressuresTable diveTankPressures =
      $DiveTankPressuresTable(this);
  late final $DiveTanksTable diveTanks = $DiveTanksTable(this);
  late final $DiveEventsTable diveEvents = $DiveEventsTable(this);
  late final $CatalogueSitesTable catalogueSites = $CatalogueSitesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final Index divesByDiver = Index(
    'dives_by_diver',
    'CREATE INDEX dives_by_diver ON dives (diver_id, start_local)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    divers,
    diveComputers,
    dives,
    diveSamples,
    diveTankPressures,
    diveTanks,
    diveEvents,
    catalogueSites,
    appMeta,
    divesByDiver,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dives',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dive_samples', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dives',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dive_tank_pressures', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dives',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dive_tanks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dives',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dive_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DiversTableCreateCompanionBuilder = DiversCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  Value<int> firstDiveNumber,
  Value<int> rowid,
});
typedef $$DiversTableUpdateCompanionBuilder = DiversCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<int> firstDiveNumber,
  Value<int> rowid,
});

final class $$DiversTableReferences
    extends BaseReferences<_$AppDatabase, $DiversTable, DiverRow> {
  $$DiversTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DivesTable, List<DiveRow>> _divesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.dives,
    aliasName: 'divers__id__dives__diver_id',
  );

  $$DivesTableProcessedTableManager get divesRefs {
    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.diverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_divesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiversTableFilterComposer
    extends Composer<_$AppDatabase, $DiversTable> {
  $$DiversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstDiveNumber => $composableBuilder(
    column: $table.firstDiveNumber,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> divesRefs(
    Expression<bool> Function($$DivesTableFilterComposer f) f,
  ) {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.diverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiversTableOrderingComposer
    extends Composer<_$AppDatabase, $DiversTable> {
  $$DiversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstDiveNumber => $composableBuilder(
    column: $table.firstDiveNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiversTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiversTable> {
  $$DiversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get firstDiveNumber => $composableBuilder(
    column: $table.firstDiveNumber,
    builder: (column) => column,
  );

  Expression<T> divesRefs<T extends Object>(
    Expression<T> Function($$DivesTableAnnotationComposer a) f,
  ) {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.diverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiversTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiversTable,
          DiverRow,
          $$DiversTableFilterComposer,
          $$DiversTableOrderingComposer,
          $$DiversTableAnnotationComposer,
          $$DiversTableCreateCompanionBuilder,
          $$DiversTableUpdateCompanionBuilder,
          (DiverRow, $$DiversTableReferences),
          DiverRow,
          PrefetchHooks Function({bool divesRefs})
        > {
  $$DiversTableTableManager(_$AppDatabase db, $DiversTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> firstDiveNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiversCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                firstDiveNumber: firstDiveNumber,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<int> firstDiveNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiversCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                firstDiveNumber: firstDiveNumber,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiversTable, DiverRow>(table),
                  $$DiversTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({divesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (divesRefs) db.dives],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (divesRefs)
                    await $_getPrefetchedDataByColumns<
                      DiverRow,
                      $DiversTable,
                      DiveRow,
                      $DivesTable
                    >(
                      currentTable: table,
                      referencedTable: $$DiversTableReferences._divesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$DiversTableReferences(db, table, p0).divesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'diver_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DiversTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiversTable,
      DiverRow,
      $$DiversTableFilterComposer,
      $$DiversTableOrderingComposer,
      $$DiversTableAnnotationComposer,
      $$DiversTableCreateCompanionBuilder,
      $$DiversTableUpdateCompanionBuilder,
      (DiverRow, $$DiversTableReferences),
      DiverRow,
      PrefetchHooks Function({bool divesRefs})
    >;
typedef $$DiveComputersTableCreateCompanionBuilder =
    DiveComputersCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String vendor,
      required String product,
      Value<int?> modelNumber,
      Value<String?> serial,
      Value<String?> firmware,
      Value<String?> address,
      Value<Uint8List?> lastFingerprint,
      Value<int> rowid,
    });
typedef $$DiveComputersTableUpdateCompanionBuilder =
    DiveComputersCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> vendor,
      Value<String> product,
      Value<int?> modelNumber,
      Value<String?> serial,
      Value<String?> firmware,
      Value<String?> address,
      Value<Uint8List?> lastFingerprint,
      Value<int> rowid,
    });

final class $$DiveComputersTableReferences
    extends
        BaseReferences<_$AppDatabase, $DiveComputersTable, DiveComputerRow> {
  $$DiveComputersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$DivesTable, List<DiveRow>> _divesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.dives,
    aliasName: 'dive_computers__id__dives__dive_computer_id',
  );

  $$DivesTableProcessedTableManager get divesRefs {
    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.diveComputerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_divesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiveComputersTableFilterComposer
    extends Composer<_$AppDatabase, $DiveComputersTable> {
  $$DiveComputersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modelNumber => $composableBuilder(
    column: $table.modelNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmware => $composableBuilder(
    column: $table.firmware,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get lastFingerprint => $composableBuilder(
    column: $table.lastFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> divesRefs(
    Expression<bool> Function($$DivesTableFilterComposer f) f,
  ) {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.diveComputerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiveComputersTableOrderingComposer
    extends Composer<_$AppDatabase, $DiveComputersTable> {
  $$DiveComputersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modelNumber => $composableBuilder(
    column: $table.modelNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serial => $composableBuilder(
    column: $table.serial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmware => $composableBuilder(
    column: $table.firmware,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get lastFingerprint => $composableBuilder(
    column: $table.lastFingerprint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiveComputersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiveComputersTable> {
  $$DiveComputersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get product =>
      $composableBuilder(column: $table.product, builder: (column) => column);

  GeneratedColumn<int> get modelNumber => $composableBuilder(
    column: $table.modelNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get firmware =>
      $composableBuilder(column: $table.firmware, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<Uint8List> get lastFingerprint => $composableBuilder(
    column: $table.lastFingerprint,
    builder: (column) => column,
  );

  Expression<T> divesRefs<T extends Object>(
    Expression<T> Function($$DivesTableAnnotationComposer a) f,
  ) {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.diveComputerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiveComputersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiveComputersTable,
          DiveComputerRow,
          $$DiveComputersTableFilterComposer,
          $$DiveComputersTableOrderingComposer,
          $$DiveComputersTableAnnotationComposer,
          $$DiveComputersTableCreateCompanionBuilder,
          $$DiveComputersTableUpdateCompanionBuilder,
          (DiveComputerRow, $$DiveComputersTableReferences),
          DiveComputerRow,
          PrefetchHooks Function({bool divesRefs})
        > {
  $$DiveComputersTableTableManager(_$AppDatabase db, $DiveComputersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiveComputersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiveComputersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiveComputersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> vendor = const Value.absent(),
                Value<String> product = const Value.absent(),
                Value<int?> modelNumber = const Value.absent(),
                Value<String?> serial = const Value.absent(),
                Value<String?> firmware = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<Uint8List?> lastFingerprint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveComputersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                vendor: vendor,
                product: product,
                modelNumber: modelNumber,
                serial: serial,
                firmware: firmware,
                address: address,
                lastFingerprint: lastFingerprint,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String vendor,
                required String product,
                Value<int?> modelNumber = const Value.absent(),
                Value<String?> serial = const Value.absent(),
                Value<String?> firmware = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<Uint8List?> lastFingerprint = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveComputersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                vendor: vendor,
                product: product,
                modelNumber: modelNumber,
                serial: serial,
                firmware: firmware,
                address: address,
                lastFingerprint: lastFingerprint,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiveComputersTable, DiveComputerRow>(table),
                  $$DiveComputersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({divesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (divesRefs) db.dives],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (divesRefs)
                    await $_getPrefetchedDataByColumns<
                      DiveComputerRow,
                      $DiveComputersTable,
                      DiveRow,
                      $DivesTable
                    >(
                      currentTable: table,
                      referencedTable: $$DiveComputersTableReferences
                          ._divesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DiveComputersTableReferences(
                            db,
                            table,
                            p0,
                          ).divesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'dive_computer_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DiveComputersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiveComputersTable,
      DiveComputerRow,
      $$DiveComputersTableFilterComposer,
      $$DiveComputersTableOrderingComposer,
      $$DiveComputersTableAnnotationComposer,
      $$DiveComputersTableCreateCompanionBuilder,
      $$DiveComputersTableUpdateCompanionBuilder,
      (DiveComputerRow, $$DiveComputersTableReferences),
      DiveComputerRow,
      PrefetchHooks Function({bool divesRefs})
    >;
typedef $$DivesTableCreateCompanionBuilder = DivesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String diverId,
  required int diveNumber,
  Value<String?> siteName,
  Value<String?> siteCatalogueId,
  Value<double?> siteLat,
  Value<double?> siteLon,
  Value<String?> diveComputerId,
  required String source,
  Value<String?> sourceId,
  required DateTime startLocal,
  Value<int?> utcOffsetS,
  required int durationS,
  required double maxDepthM,
  Value<double?> avgDepthM,
  Value<double?> minTemperatureC,
  Value<double?> maxTemperatureC,
  Value<String?> waterType,
  Value<String?> notes,
  Value<int?> rating,
  Value<int> rowid,
});
typedef $$DivesTableUpdateCompanionBuilder = DivesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> diverId,
  Value<int> diveNumber,
  Value<String?> siteName,
  Value<String?> siteCatalogueId,
  Value<double?> siteLat,
  Value<double?> siteLon,
  Value<String?> diveComputerId,
  Value<String> source,
  Value<String?> sourceId,
  Value<DateTime> startLocal,
  Value<int?> utcOffsetS,
  Value<int> durationS,
  Value<double> maxDepthM,
  Value<double?> avgDepthM,
  Value<double?> minTemperatureC,
  Value<double?> maxTemperatureC,
  Value<String?> waterType,
  Value<String?> notes,
  Value<int?> rating,
  Value<int> rowid,
});

final class $$DivesTableReferences
    extends BaseReferences<_$AppDatabase, $DivesTable, DiveRow> {
  $$DivesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DiversTable _diverIdTable(_$AppDatabase db) =>
      db.divers.createAlias('dives__diver_id__divers__id');

  $$DiversTableProcessedTableManager get diverId {
    final $_column = $_itemColumn<String>('diver_id')!;

    final manager = $$DiversTableTableManager(
      $_db,
      $_db.divers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DiveComputersTable _diveComputerIdTable(_$AppDatabase db) => db
      .diveComputers
      .createAlias('dives__dive_computer_id__dive_computers__id');

  $$DiveComputersTableProcessedTableManager? get diveComputerId {
    final $_column = $_itemColumn<String>('dive_computer_id');
    if ($_column == null) return null;
    final manager = $$DiveComputersTableTableManager(
      $_db,
      $_db.diveComputers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diveComputerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DiveSamplesTable, List<DiveSampleRow>>
  _diveSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diveSamples,
    aliasName: 'dives__id__dive_samples__dive_id',
  );

  $$DiveSamplesTableProcessedTableManager get diveSamplesRefs {
    final manager = $$DiveSamplesTableTableManager(
      $_db,
      $_db.diveSamples,
    ).filter((f) => f.diveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diveSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiveTankPressuresTable, List<DiveTankPressureRow>>
  _diveTankPressuresRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.diveTankPressures,
        aliasName: 'dives__id__dive_tank_pressures__dive_id',
      );

  $$DiveTankPressuresTableProcessedTableManager get diveTankPressuresRefs {
    final manager = $$DiveTankPressuresTableTableManager(
      $_db,
      $_db.diveTankPressures,
    ).filter((f) => f.diveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _diveTankPressuresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiveTanksTable, List<DiveTankRow>>
  _diveTanksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diveTanks,
    aliasName: 'dives__id__dive_tanks__dive_id',
  );

  $$DiveTanksTableProcessedTableManager get diveTanksRefs {
    final manager = $$DiveTanksTableTableManager(
      $_db,
      $_db.diveTanks,
    ).filter((f) => f.diveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diveTanksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DiveEventsTable, List<DiveEventRow>>
  _diveEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.diveEvents,
    aliasName: 'dives__id__dive_events__dive_id',
  );

  $$DiveEventsTableProcessedTableManager get diveEventsRefs {
    final manager = $$DiveEventsTableTableManager(
      $_db,
      $_db.diveEvents,
    ).filter((f) => f.diveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_diveEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DivesTableFilterComposer extends Composer<_$AppDatabase, $DivesTable> {
  $$DivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diveNumber => $composableBuilder(
    column: $table.diveNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteCatalogueId => $composableBuilder(
    column: $table.siteCatalogueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get siteLat => $composableBuilder(
    column: $table.siteLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get siteLon => $composableBuilder(
    column: $table.siteLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startLocal => $composableBuilder(
    column: $table.startLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetS => $composableBuilder(
    column: $table.utcOffsetS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDepthM => $composableBuilder(
    column: $table.maxDepthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgDepthM => $composableBuilder(
    column: $table.avgDepthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxTemperatureC => $composableBuilder(
    column: $table.maxTemperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waterType => $composableBuilder(
    column: $table.waterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  $$DiversTableFilterComposer get diverId {
    final $$DiversTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diverId,
      referencedTable: $db.divers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiversTableFilterComposer(
            $db: $db,
            $table: $db.divers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiveComputersTableFilterComposer get diveComputerId {
    final $$DiveComputersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveComputerId,
      referencedTable: $db.diveComputers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveComputersTableFilterComposer(
            $db: $db,
            $table: $db.diveComputers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> diveSamplesRefs(
    Expression<bool> Function($$DiveSamplesTableFilterComposer f) f,
  ) {
    final $$DiveSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveSamples,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveSamplesTableFilterComposer(
            $db: $db,
            $table: $db.diveSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diveTankPressuresRefs(
    Expression<bool> Function($$DiveTankPressuresTableFilterComposer f) f,
  ) {
    final $$DiveTankPressuresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveTankPressures,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveTankPressuresTableFilterComposer(
            $db: $db,
            $table: $db.diveTankPressures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diveTanksRefs(
    Expression<bool> Function($$DiveTanksTableFilterComposer f) f,
  ) {
    final $$DiveTanksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveTanks,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveTanksTableFilterComposer(
            $db: $db,
            $table: $db.diveTanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> diveEventsRefs(
    Expression<bool> Function($$DiveEventsTableFilterComposer f) f,
  ) {
    final $$DiveEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveEvents,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveEventsTableFilterComposer(
            $db: $db,
            $table: $db.diveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DivesTableOrderingComposer
    extends Composer<_$AppDatabase, $DivesTable> {
  $$DivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diveNumber => $composableBuilder(
    column: $table.diveNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteName => $composableBuilder(
    column: $table.siteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteCatalogueId => $composableBuilder(
    column: $table.siteCatalogueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get siteLat => $composableBuilder(
    column: $table.siteLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get siteLon => $composableBuilder(
    column: $table.siteLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startLocal => $composableBuilder(
    column: $table.startLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetS => $composableBuilder(
    column: $table.utcOffsetS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDepthM => $composableBuilder(
    column: $table.maxDepthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgDepthM => $composableBuilder(
    column: $table.avgDepthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxTemperatureC => $composableBuilder(
    column: $table.maxTemperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waterType => $composableBuilder(
    column: $table.waterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiversTableOrderingComposer get diverId {
    final $$DiversTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diverId,
      referencedTable: $db.divers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiversTableOrderingComposer(
            $db: $db,
            $table: $db.divers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiveComputersTableOrderingComposer get diveComputerId {
    final $$DiveComputersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveComputerId,
      referencedTable: $db.diveComputers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveComputersTableOrderingComposer(
            $db: $db,
            $table: $db.diveComputers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DivesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DivesTable> {
  $$DivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get diveNumber => $composableBuilder(
    column: $table.diveNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteName =>
      $composableBuilder(column: $table.siteName, builder: (column) => column);

  GeneratedColumn<String> get siteCatalogueId => $composableBuilder(
    column: $table.siteCatalogueId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get siteLat =>
      $composableBuilder(column: $table.siteLat, builder: (column) => column);

  GeneratedColumn<double> get siteLon =>
      $composableBuilder(column: $table.siteLon, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get startLocal => $composableBuilder(
    column: $table.startLocal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetS => $composableBuilder(
    column: $table.utcOffsetS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get maxDepthM =>
      $composableBuilder(column: $table.maxDepthM, builder: (column) => column);

  GeneratedColumn<double> get avgDepthM =>
      $composableBuilder(column: $table.avgDepthM, builder: (column) => column);

  GeneratedColumn<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxTemperatureC => $composableBuilder(
    column: $table.maxTemperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<String> get waterType =>
      $composableBuilder(column: $table.waterType, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  $$DiversTableAnnotationComposer get diverId {
    final $$DiversTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diverId,
      referencedTable: $db.divers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiversTableAnnotationComposer(
            $db: $db,
            $table: $db.divers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DiveComputersTableAnnotationComposer get diveComputerId {
    final $$DiveComputersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveComputerId,
      referencedTable: $db.diveComputers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveComputersTableAnnotationComposer(
            $db: $db,
            $table: $db.diveComputers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> diveSamplesRefs<T extends Object>(
    Expression<T> Function($$DiveSamplesTableAnnotationComposer a) f,
  ) {
    final $$DiveSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveSamples,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.diveSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diveTankPressuresRefs<T extends Object>(
    Expression<T> Function($$DiveTankPressuresTableAnnotationComposer a) f,
  ) {
    final $$DiveTankPressuresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.diveTankPressures,
          getReferencedColumn: (t) => t.diveId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DiveTankPressuresTableAnnotationComposer(
                $db: $db,
                $table: $db.diveTankPressures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> diveTanksRefs<T extends Object>(
    Expression<T> Function($$DiveTanksTableAnnotationComposer a) f,
  ) {
    final $$DiveTanksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveTanks,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveTanksTableAnnotationComposer(
            $db: $db,
            $table: $db.diveTanks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> diveEventsRefs<T extends Object>(
    Expression<T> Function($$DiveEventsTableAnnotationComposer a) f,
  ) {
    final $$DiveEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diveEvents,
      getReferencedColumn: (t) => t.diveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiveEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.diveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DivesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DivesTable,
          DiveRow,
          $$DivesTableFilterComposer,
          $$DivesTableOrderingComposer,
          $$DivesTableAnnotationComposer,
          $$DivesTableCreateCompanionBuilder,
          $$DivesTableUpdateCompanionBuilder,
          (DiveRow, $$DivesTableReferences),
          DiveRow,
          PrefetchHooks Function({
            bool diverId,
            bool diveComputerId,
            bool diveSamplesRefs,
            bool diveTankPressuresRefs,
            bool diveTanksRefs,
            bool diveEventsRefs,
          })
        > {
  $$DivesTableTableManager(_$AppDatabase db, $DivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> diverId = const Value.absent(),
                Value<int> diveNumber = const Value.absent(),
                Value<String?> siteName = const Value.absent(),
                Value<String?> siteCatalogueId = const Value.absent(),
                Value<double?> siteLat = const Value.absent(),
                Value<double?> siteLon = const Value.absent(),
                Value<String?> diveComputerId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<DateTime> startLocal = const Value.absent(),
                Value<int?> utcOffsetS = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> maxDepthM = const Value.absent(),
                Value<double?> avgDepthM = const Value.absent(),
                Value<double?> minTemperatureC = const Value.absent(),
                Value<double?> maxTemperatureC = const Value.absent(),
                Value<String?> waterType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DivesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                diverId: diverId,
                diveNumber: diveNumber,
                siteName: siteName,
                siteCatalogueId: siteCatalogueId,
                siteLat: siteLat,
                siteLon: siteLon,
                diveComputerId: diveComputerId,
                source: source,
                sourceId: sourceId,
                startLocal: startLocal,
                utcOffsetS: utcOffsetS,
                durationS: durationS,
                maxDepthM: maxDepthM,
                avgDepthM: avgDepthM,
                minTemperatureC: minTemperatureC,
                maxTemperatureC: maxTemperatureC,
                waterType: waterType,
                notes: notes,
                rating: rating,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String diverId,
                required int diveNumber,
                Value<String?> siteName = const Value.absent(),
                Value<String?> siteCatalogueId = const Value.absent(),
                Value<double?> siteLat = const Value.absent(),
                Value<double?> siteLon = const Value.absent(),
                Value<String?> diveComputerId = const Value.absent(),
                required String source,
                Value<String?> sourceId = const Value.absent(),
                required DateTime startLocal,
                Value<int?> utcOffsetS = const Value.absent(),
                required int durationS,
                required double maxDepthM,
                Value<double?> avgDepthM = const Value.absent(),
                Value<double?> minTemperatureC = const Value.absent(),
                Value<double?> maxTemperatureC = const Value.absent(),
                Value<String?> waterType = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DivesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                diverId: diverId,
                diveNumber: diveNumber,
                siteName: siteName,
                siteCatalogueId: siteCatalogueId,
                siteLat: siteLat,
                siteLon: siteLon,
                diveComputerId: diveComputerId,
                source: source,
                sourceId: sourceId,
                startLocal: startLocal,
                utcOffsetS: utcOffsetS,
                durationS: durationS,
                maxDepthM: maxDepthM,
                avgDepthM: avgDepthM,
                minTemperatureC: minTemperatureC,
                maxTemperatureC: maxTemperatureC,
                waterType: waterType,
                notes: notes,
                rating: rating,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DivesTable, DiveRow>(table),
                  $$DivesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                diverId = false,
                diveComputerId = false,
                diveSamplesRefs = false,
                diveTankPressuresRefs = false,
                diveTanksRefs = false,
                diveEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diveSamplesRefs) db.diveSamples,
                    if (diveTankPressuresRefs) db.diveTankPressures,
                    if (diveTanksRefs) db.diveTanks,
                    if (diveEventsRefs) db.diveEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (diverId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.diverId,
                            referencedTable: $$DivesTableReferences
                                ._diverIdTable(db),
                            referencedColumn: $$DivesTableReferences
                                ._diverIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (diveComputerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.diveComputerId,
                            referencedTable: $$DivesTableReferences
                                ._diveComputerIdTable(db),
                            referencedColumn: $$DivesTableReferences
                                ._diveComputerIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diveSamplesRefs)
                        await $_getPrefetchedDataByColumns<
                          DiveRow,
                          $DivesTable,
                          DiveSampleRow,
                          $DiveSamplesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DivesTableReferences
                              ._diveSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DivesTableReferences(
                                db,
                                table,
                                p0,
                              ).diveSamplesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dive_id',
                          typedResults: items,
                        ),
                      if (diveTankPressuresRefs)
                        await $_getPrefetchedDataByColumns<
                          DiveRow,
                          $DivesTable,
                          DiveTankPressureRow,
                          $DiveTankPressuresTable
                        >(
                          currentTable: table,
                          referencedTable: $$DivesTableReferences
                              ._diveTankPressuresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DivesTableReferences(
                                db,
                                table,
                                p0,
                              ).diveTankPressuresRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dive_id',
                          typedResults: items,
                        ),
                      if (diveTanksRefs)
                        await $_getPrefetchedDataByColumns<
                          DiveRow,
                          $DivesTable,
                          DiveTankRow,
                          $DiveTanksTable
                        >(
                          currentTable: table,
                          referencedTable: $$DivesTableReferences
                              ._diveTanksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DivesTableReferences(
                                db,
                                table,
                                p0,
                              ).diveTanksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dive_id',
                          typedResults: items,
                        ),
                      if (diveEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          DiveRow,
                          $DivesTable,
                          DiveEventRow,
                          $DiveEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DivesTableReferences
                              ._diveEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DivesTableReferences(
                                db,
                                table,
                                p0,
                              ).diveEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'dive_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DivesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DivesTable,
      DiveRow,
      $$DivesTableFilterComposer,
      $$DivesTableOrderingComposer,
      $$DivesTableAnnotationComposer,
      $$DivesTableCreateCompanionBuilder,
      $$DivesTableUpdateCompanionBuilder,
      (DiveRow, $$DivesTableReferences),
      DiveRow,
      PrefetchHooks Function({
        bool diverId,
        bool diveComputerId,
        bool diveSamplesRefs,
        bool diveTankPressuresRefs,
        bool diveTanksRefs,
        bool diveEventsRefs,
      })
    >;
typedef $$DiveSamplesTableCreateCompanionBuilder =
    DiveSamplesCompanion Function({
      required String diveId,
      required int timeS,
      required double depthM,
      Value<double?> temperatureC,
      Value<int?> heartRate,
      Value<int?> ndlS,
      Value<double?> decoCeilingM,
      Value<int?> decoTimeS,
      Value<int?> gasIndex,
      Value<int> rowid,
    });
typedef $$DiveSamplesTableUpdateCompanionBuilder =
    DiveSamplesCompanion Function({
      Value<String> diveId,
      Value<int> timeS,
      Value<double> depthM,
      Value<double?> temperatureC,
      Value<int?> heartRate,
      Value<int?> ndlS,
      Value<double?> decoCeilingM,
      Value<int?> decoTimeS,
      Value<int?> gasIndex,
      Value<int> rowid,
    });

final class $$DiveSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $DiveSamplesTable, DiveSampleRow> {
  $$DiveSamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DivesTable _diveIdTable(_$AppDatabase db) =>
      db.dives.createAlias('dive_samples__dive_id__dives__id');

  $$DivesTableProcessedTableManager get diveId {
    final $_column = $_itemColumn<String>('dive_id')!;

    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiveSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $DiveSamplesTable> {
  $$DiveSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthM => $composableBuilder(
    column: $table.depthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ndlS => $composableBuilder(
    column: $table.ndlS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get decoCeilingM => $composableBuilder(
    column: $table.decoCeilingM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get decoTimeS => $composableBuilder(
    column: $table.decoTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gasIndex => $composableBuilder(
    column: $table.gasIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$DivesTableFilterComposer get diveId {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiveSamplesTable> {
  $$DiveSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthM => $composableBuilder(
    column: $table.depthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ndlS => $composableBuilder(
    column: $table.ndlS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get decoCeilingM => $composableBuilder(
    column: $table.decoCeilingM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get decoTimeS => $composableBuilder(
    column: $table.decoTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gasIndex => $composableBuilder(
    column: $table.gasIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$DivesTableOrderingComposer get diveId {
    final $$DivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableOrderingComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiveSamplesTable> {
  $$DiveSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get timeS =>
      $composableBuilder(column: $table.timeS, builder: (column) => column);

  GeneratedColumn<double> get depthM =>
      $composableBuilder(column: $table.depthM, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
    column: $table.temperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<int> get ndlS =>
      $composableBuilder(column: $table.ndlS, builder: (column) => column);

  GeneratedColumn<double> get decoCeilingM => $composableBuilder(
    column: $table.decoCeilingM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get decoTimeS =>
      $composableBuilder(column: $table.decoTimeS, builder: (column) => column);

  GeneratedColumn<int> get gasIndex =>
      $composableBuilder(column: $table.gasIndex, builder: (column) => column);

  $$DivesTableAnnotationComposer get diveId {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiveSamplesTable,
          DiveSampleRow,
          $$DiveSamplesTableFilterComposer,
          $$DiveSamplesTableOrderingComposer,
          $$DiveSamplesTableAnnotationComposer,
          $$DiveSamplesTableCreateCompanionBuilder,
          $$DiveSamplesTableUpdateCompanionBuilder,
          (DiveSampleRow, $$DiveSamplesTableReferences),
          DiveSampleRow,
          PrefetchHooks Function({bool diveId})
        > {
  $$DiveSamplesTableTableManager(_$AppDatabase db, $DiveSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiveSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiveSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiveSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> diveId = const Value.absent(),
                Value<int> timeS = const Value.absent(),
                Value<double> depthM = const Value.absent(),
                Value<double?> temperatureC = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<int?> ndlS = const Value.absent(),
                Value<double?> decoCeilingM = const Value.absent(),
                Value<int?> decoTimeS = const Value.absent(),
                Value<int?> gasIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveSamplesCompanion(
                diveId: diveId,
                timeS: timeS,
                depthM: depthM,
                temperatureC: temperatureC,
                heartRate: heartRate,
                ndlS: ndlS,
                decoCeilingM: decoCeilingM,
                decoTimeS: decoTimeS,
                gasIndex: gasIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String diveId,
                required int timeS,
                required double depthM,
                Value<double?> temperatureC = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<int?> ndlS = const Value.absent(),
                Value<double?> decoCeilingM = const Value.absent(),
                Value<int?> decoTimeS = const Value.absent(),
                Value<int?> gasIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveSamplesCompanion.insert(
                diveId: diveId,
                timeS: timeS,
                depthM: depthM,
                temperatureC: temperatureC,
                heartRate: heartRate,
                ndlS: ndlS,
                decoCeilingM: decoCeilingM,
                decoTimeS: decoTimeS,
                gasIndex: gasIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiveSamplesTable, DiveSampleRow>(table),
                  $$DiveSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diveId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diveId,
                        referencedTable: $$DiveSamplesTableReferences
                            ._diveIdTable(db),
                        referencedColumn: $$DiveSamplesTableReferences
                            ._diveIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiveSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiveSamplesTable,
      DiveSampleRow,
      $$DiveSamplesTableFilterComposer,
      $$DiveSamplesTableOrderingComposer,
      $$DiveSamplesTableAnnotationComposer,
      $$DiveSamplesTableCreateCompanionBuilder,
      $$DiveSamplesTableUpdateCompanionBuilder,
      (DiveSampleRow, $$DiveSamplesTableReferences),
      DiveSampleRow,
      PrefetchHooks Function({bool diveId})
    >;
typedef $$DiveTankPressuresTableCreateCompanionBuilder =
    DiveTankPressuresCompanion Function({
      required String diveId,
      required int timeS,
      required int tankIndex,
      required double pressureBar,
      Value<int> rowid,
    });
typedef $$DiveTankPressuresTableUpdateCompanionBuilder =
    DiveTankPressuresCompanion Function({
      Value<String> diveId,
      Value<int> timeS,
      Value<int> tankIndex,
      Value<double> pressureBar,
      Value<int> rowid,
    });

final class $$DiveTankPressuresTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DiveTankPressuresTable,
          DiveTankPressureRow
        > {
  $$DiveTankPressuresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DivesTable _diveIdTable(_$AppDatabase db) =>
      db.dives.createAlias('dive_tank_pressures__dive_id__dives__id');

  $$DivesTableProcessedTableManager get diveId {
    final $_column = $_itemColumn<String>('dive_id')!;

    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiveTankPressuresTableFilterComposer
    extends Composer<_$AppDatabase, $DiveTankPressuresTable> {
  $$DiveTankPressuresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tankIndex => $composableBuilder(
    column: $table.tankIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressureBar => $composableBuilder(
    column: $table.pressureBar,
    builder: (column) => ColumnFilters(column),
  );

  $$DivesTableFilterComposer get diveId {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTankPressuresTableOrderingComposer
    extends Composer<_$AppDatabase, $DiveTankPressuresTable> {
  $$DiveTankPressuresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tankIndex => $composableBuilder(
    column: $table.tankIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressureBar => $composableBuilder(
    column: $table.pressureBar,
    builder: (column) => ColumnOrderings(column),
  );

  $$DivesTableOrderingComposer get diveId {
    final $$DivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableOrderingComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTankPressuresTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiveTankPressuresTable> {
  $$DiveTankPressuresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get timeS =>
      $composableBuilder(column: $table.timeS, builder: (column) => column);

  GeneratedColumn<int> get tankIndex =>
      $composableBuilder(column: $table.tankIndex, builder: (column) => column);

  GeneratedColumn<double> get pressureBar => $composableBuilder(
    column: $table.pressureBar,
    builder: (column) => column,
  );

  $$DivesTableAnnotationComposer get diveId {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTankPressuresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiveTankPressuresTable,
          DiveTankPressureRow,
          $$DiveTankPressuresTableFilterComposer,
          $$DiveTankPressuresTableOrderingComposer,
          $$DiveTankPressuresTableAnnotationComposer,
          $$DiveTankPressuresTableCreateCompanionBuilder,
          $$DiveTankPressuresTableUpdateCompanionBuilder,
          (DiveTankPressureRow, $$DiveTankPressuresTableReferences),
          DiveTankPressureRow,
          PrefetchHooks Function({bool diveId})
        > {
  $$DiveTankPressuresTableTableManager(
    _$AppDatabase db,
    $DiveTankPressuresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiveTankPressuresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiveTankPressuresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiveTankPressuresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> diveId = const Value.absent(),
                Value<int> timeS = const Value.absent(),
                Value<int> tankIndex = const Value.absent(),
                Value<double> pressureBar = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveTankPressuresCompanion(
                diveId: diveId,
                timeS: timeS,
                tankIndex: tankIndex,
                pressureBar: pressureBar,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String diveId,
                required int timeS,
                required int tankIndex,
                required double pressureBar,
                Value<int> rowid = const Value.absent(),
              }) => DiveTankPressuresCompanion.insert(
                diveId: diveId,
                timeS: timeS,
                tankIndex: tankIndex,
                pressureBar: pressureBar,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiveTankPressuresTable, DiveTankPressureRow>(
                    table,
                  ),
                  $$DiveTankPressuresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diveId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diveId,
                        referencedTable: $$DiveTankPressuresTableReferences
                            ._diveIdTable(db),
                        referencedColumn: $$DiveTankPressuresTableReferences
                            ._diveIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiveTankPressuresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiveTankPressuresTable,
      DiveTankPressureRow,
      $$DiveTankPressuresTableFilterComposer,
      $$DiveTankPressuresTableOrderingComposer,
      $$DiveTankPressuresTableAnnotationComposer,
      $$DiveTankPressuresTableCreateCompanionBuilder,
      $$DiveTankPressuresTableUpdateCompanionBuilder,
      (DiveTankPressureRow, $$DiveTankPressuresTableReferences),
      DiveTankPressureRow,
      PrefetchHooks Function({bool diveId})
    >;
typedef $$DiveTanksTableCreateCompanionBuilder = DiveTanksCompanion Function({
  required String diveId,
  required int tankIndex,
  Value<double?> volumeL,
  Value<double?> startPressureBar,
  Value<double?> endPressureBar,
  Value<double?> o2,
  Value<double?> he,
  Value<int> rowid,
});
typedef $$DiveTanksTableUpdateCompanionBuilder = DiveTanksCompanion Function({
  Value<String> diveId,
  Value<int> tankIndex,
  Value<double?> volumeL,
  Value<double?> startPressureBar,
  Value<double?> endPressureBar,
  Value<double?> o2,
  Value<double?> he,
  Value<int> rowid,
});

final class $$DiveTanksTableReferences
    extends BaseReferences<_$AppDatabase, $DiveTanksTable, DiveTankRow> {
  $$DiveTanksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DivesTable _diveIdTable(_$AppDatabase db) =>
      db.dives.createAlias('dive_tanks__dive_id__dives__id');

  $$DivesTableProcessedTableManager get diveId {
    final $_column = $_itemColumn<String>('dive_id')!;

    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiveTanksTableFilterComposer
    extends Composer<_$AppDatabase, $DiveTanksTable> {
  $$DiveTanksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tankIndex => $composableBuilder(
    column: $table.tankIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volumeL => $composableBuilder(
    column: $table.volumeL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startPressureBar => $composableBuilder(
    column: $table.startPressureBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endPressureBar => $composableBuilder(
    column: $table.endPressureBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get o2 => $composableBuilder(
    column: $table.o2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get he => $composableBuilder(
    column: $table.he,
    builder: (column) => ColumnFilters(column),
  );

  $$DivesTableFilterComposer get diveId {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTanksTableOrderingComposer
    extends Composer<_$AppDatabase, $DiveTanksTable> {
  $$DiveTanksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tankIndex => $composableBuilder(
    column: $table.tankIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volumeL => $composableBuilder(
    column: $table.volumeL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startPressureBar => $composableBuilder(
    column: $table.startPressureBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endPressureBar => $composableBuilder(
    column: $table.endPressureBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get o2 => $composableBuilder(
    column: $table.o2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get he => $composableBuilder(
    column: $table.he,
    builder: (column) => ColumnOrderings(column),
  );

  $$DivesTableOrderingComposer get diveId {
    final $$DivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableOrderingComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiveTanksTable> {
  $$DiveTanksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tankIndex =>
      $composableBuilder(column: $table.tankIndex, builder: (column) => column);

  GeneratedColumn<double> get volumeL =>
      $composableBuilder(column: $table.volumeL, builder: (column) => column);

  GeneratedColumn<double> get startPressureBar => $composableBuilder(
    column: $table.startPressureBar,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endPressureBar => $composableBuilder(
    column: $table.endPressureBar,
    builder: (column) => column,
  );

  GeneratedColumn<double> get o2 =>
      $composableBuilder(column: $table.o2, builder: (column) => column);

  GeneratedColumn<double> get he =>
      $composableBuilder(column: $table.he, builder: (column) => column);

  $$DivesTableAnnotationComposer get diveId {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveTanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiveTanksTable,
          DiveTankRow,
          $$DiveTanksTableFilterComposer,
          $$DiveTanksTableOrderingComposer,
          $$DiveTanksTableAnnotationComposer,
          $$DiveTanksTableCreateCompanionBuilder,
          $$DiveTanksTableUpdateCompanionBuilder,
          (DiveTankRow, $$DiveTanksTableReferences),
          DiveTankRow,
          PrefetchHooks Function({bool diveId})
        > {
  $$DiveTanksTableTableManager(_$AppDatabase db, $DiveTanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiveTanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiveTanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiveTanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> diveId = const Value.absent(),
                Value<int> tankIndex = const Value.absent(),
                Value<double?> volumeL = const Value.absent(),
                Value<double?> startPressureBar = const Value.absent(),
                Value<double?> endPressureBar = const Value.absent(),
                Value<double?> o2 = const Value.absent(),
                Value<double?> he = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveTanksCompanion(
                diveId: diveId,
                tankIndex: tankIndex,
                volumeL: volumeL,
                startPressureBar: startPressureBar,
                endPressureBar: endPressureBar,
                o2: o2,
                he: he,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String diveId,
                required int tankIndex,
                Value<double?> volumeL = const Value.absent(),
                Value<double?> startPressureBar = const Value.absent(),
                Value<double?> endPressureBar = const Value.absent(),
                Value<double?> o2 = const Value.absent(),
                Value<double?> he = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveTanksCompanion.insert(
                diveId: diveId,
                tankIndex: tankIndex,
                volumeL: volumeL,
                startPressureBar: startPressureBar,
                endPressureBar: endPressureBar,
                o2: o2,
                he: he,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiveTanksTable, DiveTankRow>(table),
                  $$DiveTanksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diveId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diveId,
                        referencedTable: $$DiveTanksTableReferences
                            ._diveIdTable(db),
                        referencedColumn: $$DiveTanksTableReferences
                            ._diveIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiveTanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiveTanksTable,
      DiveTankRow,
      $$DiveTanksTableFilterComposer,
      $$DiveTanksTableOrderingComposer,
      $$DiveTanksTableAnnotationComposer,
      $$DiveTanksTableCreateCompanionBuilder,
      $$DiveTanksTableUpdateCompanionBuilder,
      (DiveTankRow, $$DiveTanksTableReferences),
      DiveTankRow,
      PrefetchHooks Function({bool diveId})
    >;
typedef $$DiveEventsTableCreateCompanionBuilder = DiveEventsCompanion Function({
  required String id,
  required String diveId,
  required int timeS,
  required String type,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$DiveEventsTableUpdateCompanionBuilder = DiveEventsCompanion Function({
  Value<String> id,
  Value<String> diveId,
  Value<int> timeS,
  Value<String> type,
  Value<String?> value,
  Value<int> rowid,
});

final class $$DiveEventsTableReferences
    extends BaseReferences<_$AppDatabase, $DiveEventsTable, DiveEventRow> {
  $$DiveEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DivesTable _diveIdTable(_$AppDatabase db) =>
      db.dives.createAlias('dive_events__dive_id__dives__id');

  $$DivesTableProcessedTableManager get diveId {
    final $_column = $_itemColumn<String>('dive_id')!;

    final manager = $$DivesTableTableManager(
      $_db,
      $_db.dives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiveEventsTableFilterComposer
    extends Composer<_$AppDatabase, $DiveEventsTable> {
  $$DiveEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$DivesTableFilterComposer get diveId {
    final $$DivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableFilterComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiveEventsTable> {
  $$DiveEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeS => $composableBuilder(
    column: $table.timeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$DivesTableOrderingComposer get diveId {
    final $$DivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableOrderingComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiveEventsTable> {
  $$DiveEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeS =>
      $composableBuilder(column: $table.timeS, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$DivesTableAnnotationComposer get diveId {
    final $$DivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diveId,
      referencedTable: $db.dives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DivesTableAnnotationComposer(
            $db: $db,
            $table: $db.dives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiveEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiveEventsTable,
          DiveEventRow,
          $$DiveEventsTableFilterComposer,
          $$DiveEventsTableOrderingComposer,
          $$DiveEventsTableAnnotationComposer,
          $$DiveEventsTableCreateCompanionBuilder,
          $$DiveEventsTableUpdateCompanionBuilder,
          (DiveEventRow, $$DiveEventsTableReferences),
          DiveEventRow,
          PrefetchHooks Function({bool diveId})
        > {
  $$DiveEventsTableTableManager(_$AppDatabase db, $DiveEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiveEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiveEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiveEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diveId = const Value.absent(),
                Value<int> timeS = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveEventsCompanion(
                id: id,
                diveId: diveId,
                timeS: timeS,
                type: type,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diveId,
                required int timeS,
                required String type,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiveEventsCompanion.insert(
                id: id,
                diveId: diveId,
                timeS: timeS,
                type: type,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiveEventsTable, DiveEventRow>(table),
                  $$DiveEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diveId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diveId,
                        referencedTable: $$DiveEventsTableReferences
                            ._diveIdTable(db),
                        referencedColumn: $$DiveEventsTableReferences
                            ._diveIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DiveEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiveEventsTable,
      DiveEventRow,
      $$DiveEventsTableFilterComposer,
      $$DiveEventsTableOrderingComposer,
      $$DiveEventsTableAnnotationComposer,
      $$DiveEventsTableCreateCompanionBuilder,
      $$DiveEventsTableUpdateCompanionBuilder,
      (DiveEventRow, $$DiveEventsTableReferences),
      DiveEventRow,
      PrefetchHooks Function({bool diveId})
    >;
typedef $$CatalogueSitesTableCreateCompanionBuilder =
    CatalogueSitesCompanion Function({
      required String id,
      required String name,
      Value<String?> region,
      Value<String?> countryCode,
      required double lat,
      required double lon,
      Value<double?> maxDepthM,
      Value<String> types,
      Value<int> rowid,
    });
typedef $$CatalogueSitesTableUpdateCompanionBuilder =
    CatalogueSitesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> region,
      Value<String?> countryCode,
      Value<double> lat,
      Value<double> lon,
      Value<double?> maxDepthM,
      Value<String> types,
      Value<int> rowid,
    });

class $$CatalogueSitesTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogueSitesTable> {
  $$CatalogueSitesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDepthM => $composableBuilder(
    column: $table.maxDepthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get types => $composableBuilder(
    column: $table.types,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogueSitesTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogueSitesTable> {
  $$CatalogueSitesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDepthM => $composableBuilder(
    column: $table.maxDepthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get types => $composableBuilder(
    column: $table.types,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogueSitesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogueSitesTable> {
  $$CatalogueSitesTableAnnotationComposer({
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

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get maxDepthM =>
      $composableBuilder(column: $table.maxDepthM, builder: (column) => column);

  GeneratedColumn<String> get types =>
      $composableBuilder(column: $table.types, builder: (column) => column);
}

class $$CatalogueSitesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogueSitesTable,
          CatalogueSiteRow,
          $$CatalogueSitesTableFilterComposer,
          $$CatalogueSitesTableOrderingComposer,
          $$CatalogueSitesTableAnnotationComposer,
          $$CatalogueSitesTableCreateCompanionBuilder,
          $$CatalogueSitesTableUpdateCompanionBuilder,
          (
            CatalogueSiteRow,
            BaseReferences<
              _$AppDatabase,
              $CatalogueSitesTable,
              CatalogueSiteRow
            >,
          ),
          CatalogueSiteRow,
          PrefetchHooks Function()
        > {
  $$CatalogueSitesTableTableManager(
    _$AppDatabase db,
    $CatalogueSitesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogueSitesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogueSitesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogueSitesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> region = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> maxDepthM = const Value.absent(),
                Value<String> types = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogueSitesCompanion(
                id: id,
                name: name,
                region: region,
                countryCode: countryCode,
                lat: lat,
                lon: lon,
                maxDepthM: maxDepthM,
                types: types,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> region = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                required double lat,
                required double lon,
                Value<double?> maxDepthM = const Value.absent(),
                Value<String> types = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogueSitesCompanion.insert(
                id: id,
                name: name,
                region: region,
                countryCode: countryCode,
                lat: lat,
                lon: lon,
                maxDepthM: maxDepthM,
                types: types,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogueSitesTable, CatalogueSiteRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CatalogueSitesTable,
                    CatalogueSiteRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogueSitesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogueSitesTable,
      CatalogueSiteRow,
      $$CatalogueSitesTableFilterComposer,
      $$CatalogueSitesTableOrderingComposer,
      $$CatalogueSitesTableAnnotationComposer,
      $$CatalogueSitesTableCreateCompanionBuilder,
      $$CatalogueSitesTableUpdateCompanionBuilder,
      (
        CatalogueSiteRow,
        BaseReferences<_$AppDatabase, $CatalogueSitesTable, CatalogueSiteRow>,
      ),
      CatalogueSiteRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaRow>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiversTableTableManager get divers =>
      $$DiversTableTableManager(_db, _db.divers);
  $$DiveComputersTableTableManager get diveComputers =>
      $$DiveComputersTableTableManager(_db, _db.diveComputers);
  $$DivesTableTableManager get dives =>
      $$DivesTableTableManager(_db, _db.dives);
  $$DiveSamplesTableTableManager get diveSamples =>
      $$DiveSamplesTableTableManager(_db, _db.diveSamples);
  $$DiveTankPressuresTableTableManager get diveTankPressures =>
      $$DiveTankPressuresTableTableManager(_db, _db.diveTankPressures);
  $$DiveTanksTableTableManager get diveTanks =>
      $$DiveTanksTableTableManager(_db, _db.diveTanks);
  $$DiveEventsTableTableManager get diveEvents =>
      $$DiveEventsTableTableManager(_db, _db.diveEvents);
  $$CatalogueSitesTableTableManager get catalogueSites =>
      $$CatalogueSitesTableTableManager(_db, _db.catalogueSites);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
