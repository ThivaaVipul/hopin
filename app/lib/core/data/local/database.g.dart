// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlacesTable extends Places with TableInfo<$PlacesTable, PlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeEnMeta = const VerificationMeta(
    'placeEn',
  );
  @override
  late final GeneratedColumn<String> placeEn = GeneratedColumn<String>(
    'place_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeTaMeta = const VerificationMeta(
    'placeTa',
  );
  @override
  late final GeneratedColumn<String> placeTa = GeneratedColumn<String>(
    'place_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeSiMeta = const VerificationMeta(
    'placeSi',
  );
  @override
  late final GeneratedColumn<String> placeSi = GeneratedColumn<String>(
    'place_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingSinceMeta = const VerificationMeta(
    'pendingSince',
  );
  @override
  late final GeneratedColumn<int> pendingSince = GeneratedColumn<int>(
    'pending_since',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    lat,
    lng,
    placeEn,
    placeTa,
    placeSi,
    position,
    updatedAt,
    deletedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceRow> instance, {
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('place_en')) {
      context.handle(
        _placeEnMeta,
        placeEn.isAcceptableOrUnknown(data['place_en']!, _placeEnMeta),
      );
    }
    if (data.containsKey('place_ta')) {
      context.handle(
        _placeTaMeta,
        placeTa.isAcceptableOrUnknown(data['place_ta']!, _placeTaMeta),
      );
    }
    if (data.containsKey('place_si')) {
      context.handle(
        _placeSiMeta,
        placeSi.isAcceptableOrUnknown(data['place_si']!, _placeSiMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
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
    if (data.containsKey('pending_since')) {
      context.handle(
        _pendingSinceMeta,
        pendingSince.isAcceptableOrUnknown(
          data['pending_since']!,
          _pendingSinceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      placeEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_en'],
      ),
      placeTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_ta'],
      ),
      placeSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_si'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      pendingSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_since'],
      ),
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class PlaceRow extends DataClass implements Insertable<PlaceRow> {
  final String id;
  final String name;
  final String kind;
  final double lat;
  final double lng;
  final String? placeEn;
  final String? placeTa;
  final String? placeSi;

  /// The rider's own order (Settings, Places); 0 until they reorder.
  final int position;

  /// Microseconds since the epoch; the server's time once synced.
  final int updatedAt;
  final int? deletedAt;
  final int? pendingSince;
  const PlaceRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.lat,
    required this.lng,
    this.placeEn,
    this.placeTa,
    this.placeSi,
    required this.position,
    required this.updatedAt,
    this.deletedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || placeEn != null) {
      map['place_en'] = Variable<String>(placeEn);
    }
    if (!nullToAbsent || placeTa != null) {
      map['place_ta'] = Variable<String>(placeTa);
    }
    if (!nullToAbsent || placeSi != null) {
      map['place_si'] = Variable<String>(placeSi);
    }
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      lat: Value(lat),
      lng: Value(lng),
      placeEn: placeEn == null && nullToAbsent
          ? const Value.absent()
          : Value(placeEn),
      placeTa: placeTa == null && nullToAbsent
          ? const Value.absent()
          : Value(placeTa),
      placeSi: placeSi == null && nullToAbsent
          ? const Value.absent()
          : Value(placeSi),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory PlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      placeEn: serializer.fromJson<String?>(json['placeEn']),
      placeTa: serializer.fromJson<String?>(json['placeTa']),
      placeSi: serializer.fromJson<String?>(json['placeSi']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      pendingSince: serializer.fromJson<int?>(json['pendingSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'placeEn': serializer.toJson<String?>(placeEn),
      'placeTa': serializer.toJson<String?>(placeTa),
      'placeSi': serializer.toJson<String?>(placeSi),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  PlaceRow copyWith({
    String? id,
    String? name,
    String? kind,
    double? lat,
    double? lng,
    Value<String?> placeEn = const Value.absent(),
    Value<String?> placeTa = const Value.absent(),
    Value<String?> placeSi = const Value.absent(),
    int? position,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<int?> pendingSince = const Value.absent(),
  }) => PlaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    placeEn: placeEn.present ? placeEn.value : this.placeEn,
    placeTa: placeTa.present ? placeTa.value : this.placeTa,
    placeSi: placeSi.present ? placeSi.value : this.placeSi,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  PlaceRow copyWithCompanion(PlacesCompanion data) {
    return PlaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      placeEn: data.placeEn.present ? data.placeEn.value : this.placeEn,
      placeTa: data.placeTa.present ? data.placeTa.value : this.placeTa,
      placeSi: data.placeSi.present ? data.placeSi.value : this.placeSi,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeTa: $placeTa, ')
          ..write('placeSi: $placeSi, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    lat,
    lng,
    placeEn,
    placeTa,
    placeSi,
    position,
    updatedAt,
    deletedAt,
    pendingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.placeEn == this.placeEn &&
          other.placeTa == this.placeTa &&
          other.placeSi == this.placeSi &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSince == this.pendingSince);
}

class PlacesCompanion extends UpdateCompanion<PlaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> placeEn;
  final Value<String?> placeTa;
  final Value<String?> placeSi;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const PlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.placeEn = const Value.absent(),
    this.placeTa = const Value.absent(),
    this.placeSi = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required double lat,
    required double lng,
    this.placeEn = const Value.absent(),
    this.placeTa = const Value.absent(),
    this.placeSi = const Value.absent(),
    this.position = const Value.absent(),
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       lat = Value(lat),
       lng = Value(lng),
       updatedAt = Value(updatedAt);
  static Insertable<PlaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? placeEn,
    Expression<String>? placeTa,
    Expression<String>? placeSi,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (placeEn != null) 'place_en': placeEn,
      if (placeTa != null) 'place_ta': placeTa,
      if (placeSi != null) 'place_si': placeSi,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? placeEn,
    Value<String?>? placeTa,
    Value<String?>? placeSi,
    Value<int>? position,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return PlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeEn: placeEn ?? this.placeEn,
      placeTa: placeTa ?? this.placeTa,
      placeSi: placeSi ?? this.placeSi,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendingSince: pendingSince ?? this.pendingSince,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (placeEn.present) {
      map['place_en'] = Variable<String>(placeEn.value);
    }
    if (placeTa.present) {
      map['place_ta'] = Variable<String>(placeTa.value);
    }
    if (placeSi.present) {
      map['place_si'] = Variable<String>(placeSi.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (pendingSince.present) {
      map['pending_since'] = Variable<int>(pendingSince.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeTa: $placeTa, ')
          ..write('placeSi: $placeSi, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentsTable extends Recents with TableInfo<$RecentsTable, RecentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeEnMeta = const VerificationMeta(
    'placeEn',
  );
  @override
  late final GeneratedColumn<String> placeEn = GeneratedColumn<String>(
    'place_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeTaMeta = const VerificationMeta(
    'placeTa',
  );
  @override
  late final GeneratedColumn<String> placeTa = GeneratedColumn<String>(
    'place_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeSiMeta = const VerificationMeta(
    'placeSi',
  );
  @override
  late final GeneratedColumn<String> placeSi = GeneratedColumn<String>(
    'place_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<int> usedAt = GeneratedColumn<int>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    lat,
    lng,
    placeEn,
    placeTa,
    placeSi,
    area,
    usedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recents';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentRow> instance, {
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
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('place_en')) {
      context.handle(
        _placeEnMeta,
        placeEn.isAcceptableOrUnknown(data['place_en']!, _placeEnMeta),
      );
    }
    if (data.containsKey('place_ta')) {
      context.handle(
        _placeTaMeta,
        placeTa.isAcceptableOrUnknown(data['place_ta']!, _placeTaMeta),
      );
    }
    if (data.containsKey('place_si')) {
      context.handle(
        _placeSiMeta,
        placeSi.isAcceptableOrUnknown(data['place_si']!, _placeSiMeta),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_usedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  RecentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      placeEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_en'],
      ),
      placeTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_ta'],
      ),
      placeSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_si'],
      ),
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      ),
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at'],
      )!,
    );
  }

  @override
  $RecentsTable createAlias(String alias) {
    return $RecentsTable(attachedDatabase, alias);
  }
}

class RecentRow extends DataClass implements Insertable<RecentRow> {
  /// The position rounded to about 10 m, so the same place is kept once.
  final String key;
  final double lat;
  final double lng;
  final String? placeEn;
  final String? placeTa;
  final String? placeSi;
  final String? area;
  final int usedAt;
  const RecentRow({
    required this.key,
    required this.lat,
    required this.lng,
    this.placeEn,
    this.placeTa,
    this.placeSi,
    this.area,
    required this.usedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || placeEn != null) {
      map['place_en'] = Variable<String>(placeEn);
    }
    if (!nullToAbsent || placeTa != null) {
      map['place_ta'] = Variable<String>(placeTa);
    }
    if (!nullToAbsent || placeSi != null) {
      map['place_si'] = Variable<String>(placeSi);
    }
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<String>(area);
    }
    map['used_at'] = Variable<int>(usedAt);
    return map;
  }

  RecentsCompanion toCompanion(bool nullToAbsent) {
    return RecentsCompanion(
      key: Value(key),
      lat: Value(lat),
      lng: Value(lng),
      placeEn: placeEn == null && nullToAbsent
          ? const Value.absent()
          : Value(placeEn),
      placeTa: placeTa == null && nullToAbsent
          ? const Value.absent()
          : Value(placeTa),
      placeSi: placeSi == null && nullToAbsent
          ? const Value.absent()
          : Value(placeSi),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      usedAt: Value(usedAt),
    );
  }

  factory RecentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentRow(
      key: serializer.fromJson<String>(json['key']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      placeEn: serializer.fromJson<String?>(json['placeEn']),
      placeTa: serializer.fromJson<String?>(json['placeTa']),
      placeSi: serializer.fromJson<String?>(json['placeSi']),
      area: serializer.fromJson<String?>(json['area']),
      usedAt: serializer.fromJson<int>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'placeEn': serializer.toJson<String?>(placeEn),
      'placeTa': serializer.toJson<String?>(placeTa),
      'placeSi': serializer.toJson<String?>(placeSi),
      'area': serializer.toJson<String?>(area),
      'usedAt': serializer.toJson<int>(usedAt),
    };
  }

  RecentRow copyWith({
    String? key,
    double? lat,
    double? lng,
    Value<String?> placeEn = const Value.absent(),
    Value<String?> placeTa = const Value.absent(),
    Value<String?> placeSi = const Value.absent(),
    Value<String?> area = const Value.absent(),
    int? usedAt,
  }) => RecentRow(
    key: key ?? this.key,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    placeEn: placeEn.present ? placeEn.value : this.placeEn,
    placeTa: placeTa.present ? placeTa.value : this.placeTa,
    placeSi: placeSi.present ? placeSi.value : this.placeSi,
    area: area.present ? area.value : this.area,
    usedAt: usedAt ?? this.usedAt,
  );
  RecentRow copyWithCompanion(RecentsCompanion data) {
    return RecentRow(
      key: data.key.present ? data.key.value : this.key,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      placeEn: data.placeEn.present ? data.placeEn.value : this.placeEn,
      placeTa: data.placeTa.present ? data.placeTa.value : this.placeTa,
      placeSi: data.placeSi.present ? data.placeSi.value : this.placeSi,
      area: data.area.present ? data.area.value : this.area,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentRow(')
          ..write('key: $key, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeTa: $placeTa, ')
          ..write('placeSi: $placeSi, ')
          ..write('area: $area, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, lat, lng, placeEn, placeTa, placeSi, area, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentRow &&
          other.key == this.key &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.placeEn == this.placeEn &&
          other.placeTa == this.placeTa &&
          other.placeSi == this.placeSi &&
          other.area == this.area &&
          other.usedAt == this.usedAt);
}

class RecentsCompanion extends UpdateCompanion<RecentRow> {
  final Value<String> key;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> placeEn;
  final Value<String?> placeTa;
  final Value<String?> placeSi;
  final Value<String?> area;
  final Value<int> usedAt;
  final Value<int> rowid;
  const RecentsCompanion({
    this.key = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.placeEn = const Value.absent(),
    this.placeTa = const Value.absent(),
    this.placeSi = const Value.absent(),
    this.area = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentsCompanion.insert({
    required String key,
    required double lat,
    required double lng,
    this.placeEn = const Value.absent(),
    this.placeTa = const Value.absent(),
    this.placeSi = const Value.absent(),
    this.area = const Value.absent(),
    required int usedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       lat = Value(lat),
       lng = Value(lng),
       usedAt = Value(usedAt);
  static Insertable<RecentRow> custom({
    Expression<String>? key,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? placeEn,
    Expression<String>? placeTa,
    Expression<String>? placeSi,
    Expression<String>? area,
    Expression<int>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (placeEn != null) 'place_en': placeEn,
      if (placeTa != null) 'place_ta': placeTa,
      if (placeSi != null) 'place_si': placeSi,
      if (area != null) 'area': area,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentsCompanion copyWith({
    Value<String>? key,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? placeEn,
    Value<String?>? placeTa,
    Value<String?>? placeSi,
    Value<String?>? area,
    Value<int>? usedAt,
    Value<int>? rowid,
  }) {
    return RecentsCompanion(
      key: key ?? this.key,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeEn: placeEn ?? this.placeEn,
      placeTa: placeTa ?? this.placeTa,
      placeSi: placeSi ?? this.placeSi,
      area: area ?? this.area,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (placeEn.present) {
      map['place_en'] = Variable<String>(placeEn.value);
    }
    if (placeTa.present) {
      map['place_ta'] = Variable<String>(placeTa.value);
    }
    if (placeSi.present) {
      map['place_si'] = Variable<String>(placeSi.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<int>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentsCompanion(')
          ..write('key: $key, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeTa: $placeTa, ')
          ..write('placeSi: $placeSi, ')
          ..write('area: $area, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
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

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
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
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HopinDatabase extends GeneratedDatabase {
  _$HopinDatabase(QueryExecutor e) : super(e);
  late final $PlacesTable places = $PlacesTable(this);
  late final $RecentsTable recents = $RecentsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    places,
    recents,
    settings,
  ];
}
