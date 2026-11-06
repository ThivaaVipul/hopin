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
  static const VerificationMeta _shareRidesMeta = const VerificationMeta(
    'shareRides',
  );
  @override
  late final GeneratedColumn<bool> shareRides = GeneratedColumn<bool>(
    'share_rides',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("share_rides" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    shareRides,
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
    if (data.containsKey('share_rides')) {
      context.handle(
        _shareRidesMeta,
        shareRides.isAcceptableOrUnknown(data['share_rides']!, _shareRidesMeta),
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
      shareRides: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}share_rides'],
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

  /// A guide here shares the ride by itself.
  final bool shareRides;

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
    required this.shareRides,
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
    map['share_rides'] = Variable<bool>(shareRides);
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
      shareRides: Value(shareRides),
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
      shareRides: serializer.fromJson<bool>(json['shareRides']),
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
      'shareRides': serializer.toJson<bool>(shareRides),
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
    bool? shareRides,
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
    shareRides: shareRides ?? this.shareRides,
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
      shareRides: data.shareRides.present
          ? data.shareRides.value
          : this.shareRides,
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
          ..write('shareRides: $shareRides, ')
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
    shareRides,
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
          other.shareRides == this.shareRides &&
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
  final Value<bool> shareRides;
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
    this.shareRides = const Value.absent(),
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
    this.shareRides = const Value.absent(),
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
    Expression<bool>? shareRides,
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
      if (shareRides != null) 'share_rides': shareRides,
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
    Value<bool>? shareRides,
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
      shareRides: shareRides ?? this.shareRides,
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
    if (shareRides.present) {
      map['share_rides'] = Variable<bool>(shareRides.value);
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
          ..write('shareRides: $shareRides, ')
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

class $RidesTable extends Rides with TableInfo<$RidesTable, RideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RidesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verdictMeta = const VerificationMeta(
    'verdict',
  );
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
    'verdict',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _haltsMeta = const VerificationMeta('halts');
  @override
  late final GeneratedColumn<String> halts = GeneratedColumn<String>(
    'halts',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featuresMeta = const VerificationMeta(
    'features',
  );
  @override
  late final GeneratedColumn<String> features = GeneratedColumn<String>(
    'features',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guideToMeta = const VerificationMeta(
    'guideTo',
  );
  @override
  late final GeneratedColumn<String> guideTo = GeneratedColumn<String>(
    'guide_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromNameMeta = const VerificationMeta(
    'fromName',
  );
  @override
  late final GeneratedColumn<String> fromName = GeneratedColumn<String>(
    'from_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toNameMeta = const VerificationMeta('toName');
  @override
  late final GeneratedColumn<String> toName = GeneratedColumn<String>(
    'to_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    startedAt,
    endedAt,
    verdict,
    distanceM,
    path,
    halts,
    features,
    guideTo,
    fromName,
    toName,
    route,
    updatedAt,
    deletedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rides';
  @override
  VerificationContext validateIntegrity(
    Insertable<RideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('verdict')) {
      context.handle(
        _verdictMeta,
        verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta),
      );
    } else if (isInserting) {
      context.missing(_verdictMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('halts')) {
      context.handle(
        _haltsMeta,
        halts.isAcceptableOrUnknown(data['halts']!, _haltsMeta),
      );
    }
    if (data.containsKey('features')) {
      context.handle(
        _featuresMeta,
        features.isAcceptableOrUnknown(data['features']!, _featuresMeta),
      );
    } else if (isInserting) {
      context.missing(_featuresMeta);
    }
    if (data.containsKey('guide_to')) {
      context.handle(
        _guideToMeta,
        guideTo.isAcceptableOrUnknown(data['guide_to']!, _guideToMeta),
      );
    }
    if (data.containsKey('from_name')) {
      context.handle(
        _fromNameMeta,
        fromName.isAcceptableOrUnknown(data['from_name']!, _fromNameMeta),
      );
    }
    if (data.containsKey('to_name')) {
      context.handle(
        _toNameMeta,
        toName.isAcceptableOrUnknown(data['to_name']!, _toNameMeta),
      );
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
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
  RideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      )!,
      verdict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verdict'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      ),
      halts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}halts'],
      ),
      features: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}features'],
      )!,
      guideTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guide_to'],
      ),
      fromName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_name'],
      ),
      toName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_name'],
      ),
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      ),
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
  $RidesTable createAlias(String alias) {
    return $RidesTable(attachedDatabase, alias);
  }
}

class RideRow extends DataClass implements Insertable<RideRow> {
  final String id;

  /// Microseconds since the epoch.
  final int startedAt;
  final int endedAt;

  /// `bus`, `not_bus` or `unknown`.
  final String verdict;
  final int distanceM;

  /// Encoded polylines; none for a ride that was not a bus.
  final String? path;
  final String? halts;

  /// The bus logic's numbers, as JSON.
  final String features;
  final String? guideTo;
  final String? fromName;
  final String? toName;

  /// The bus it was, as tagged: RouteTag as JSON.
  final String? route;
  final int updatedAt;
  final int? deletedAt;
  final int? pendingSince;
  const RideRow({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.verdict,
    required this.distanceM,
    this.path,
    this.halts,
    required this.features,
    this.guideTo,
    this.fromName,
    this.toName,
    this.route,
    required this.updatedAt,
    this.deletedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<int>(startedAt);
    map['ended_at'] = Variable<int>(endedAt);
    map['verdict'] = Variable<String>(verdict);
    map['distance_m'] = Variable<int>(distanceM);
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String>(path);
    }
    if (!nullToAbsent || halts != null) {
      map['halts'] = Variable<String>(halts);
    }
    map['features'] = Variable<String>(features);
    if (!nullToAbsent || guideTo != null) {
      map['guide_to'] = Variable<String>(guideTo);
    }
    if (!nullToAbsent || fromName != null) {
      map['from_name'] = Variable<String>(fromName);
    }
    if (!nullToAbsent || toName != null) {
      map['to_name'] = Variable<String>(toName);
    }
    if (!nullToAbsent || route != null) {
      map['route'] = Variable<String>(route);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  RidesCompanion toCompanion(bool nullToAbsent) {
    return RidesCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      verdict: Value(verdict),
      distanceM: Value(distanceM),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      halts: halts == null && nullToAbsent
          ? const Value.absent()
          : Value(halts),
      features: Value(features),
      guideTo: guideTo == null && nullToAbsent
          ? const Value.absent()
          : Value(guideTo),
      fromName: fromName == null && nullToAbsent
          ? const Value.absent()
          : Value(fromName),
      toName: toName == null && nullToAbsent
          ? const Value.absent()
          : Value(toName),
      route: route == null && nullToAbsent
          ? const Value.absent()
          : Value(route),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory RideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int>(json['endedAt']),
      verdict: serializer.fromJson<String>(json['verdict']),
      distanceM: serializer.fromJson<int>(json['distanceM']),
      path: serializer.fromJson<String?>(json['path']),
      halts: serializer.fromJson<String?>(json['halts']),
      features: serializer.fromJson<String>(json['features']),
      guideTo: serializer.fromJson<String?>(json['guideTo']),
      fromName: serializer.fromJson<String?>(json['fromName']),
      toName: serializer.fromJson<String?>(json['toName']),
      route: serializer.fromJson<String?>(json['route']),
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
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int>(endedAt),
      'verdict': serializer.toJson<String>(verdict),
      'distanceM': serializer.toJson<int>(distanceM),
      'path': serializer.toJson<String?>(path),
      'halts': serializer.toJson<String?>(halts),
      'features': serializer.toJson<String>(features),
      'guideTo': serializer.toJson<String?>(guideTo),
      'fromName': serializer.toJson<String?>(fromName),
      'toName': serializer.toJson<String?>(toName),
      'route': serializer.toJson<String?>(route),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  RideRow copyWith({
    String? id,
    int? startedAt,
    int? endedAt,
    String? verdict,
    int? distanceM,
    Value<String?> path = const Value.absent(),
    Value<String?> halts = const Value.absent(),
    String? features,
    Value<String?> guideTo = const Value.absent(),
    Value<String?> fromName = const Value.absent(),
    Value<String?> toName = const Value.absent(),
    Value<String?> route = const Value.absent(),
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<int?> pendingSince = const Value.absent(),
  }) => RideRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    verdict: verdict ?? this.verdict,
    distanceM: distanceM ?? this.distanceM,
    path: path.present ? path.value : this.path,
    halts: halts.present ? halts.value : this.halts,
    features: features ?? this.features,
    guideTo: guideTo.present ? guideTo.value : this.guideTo,
    fromName: fromName.present ? fromName.value : this.fromName,
    toName: toName.present ? toName.value : this.toName,
    route: route.present ? route.value : this.route,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  RideRow copyWithCompanion(RidesCompanion data) {
    return RideRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      path: data.path.present ? data.path.value : this.path,
      halts: data.halts.present ? data.halts.value : this.halts,
      features: data.features.present ? data.features.value : this.features,
      guideTo: data.guideTo.present ? data.guideTo.value : this.guideTo,
      fromName: data.fromName.present ? data.fromName.value : this.fromName,
      toName: data.toName.present ? data.toName.value : this.toName,
      route: data.route.present ? data.route.value : this.route,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('verdict: $verdict, ')
          ..write('distanceM: $distanceM, ')
          ..write('path: $path, ')
          ..write('halts: $halts, ')
          ..write('features: $features, ')
          ..write('guideTo: $guideTo, ')
          ..write('fromName: $fromName, ')
          ..write('toName: $toName, ')
          ..write('route: $route, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    verdict,
    distanceM,
    path,
    halts,
    features,
    guideTo,
    fromName,
    toName,
    route,
    updatedAt,
    deletedAt,
    pendingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.verdict == this.verdict &&
          other.distanceM == this.distanceM &&
          other.path == this.path &&
          other.halts == this.halts &&
          other.features == this.features &&
          other.guideTo == this.guideTo &&
          other.fromName == this.fromName &&
          other.toName == this.toName &&
          other.route == this.route &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSince == this.pendingSince);
}

class RidesCompanion extends UpdateCompanion<RideRow> {
  final Value<String> id;
  final Value<int> startedAt;
  final Value<int> endedAt;
  final Value<String> verdict;
  final Value<int> distanceM;
  final Value<String?> path;
  final Value<String?> halts;
  final Value<String> features;
  final Value<String?> guideTo;
  final Value<String?> fromName;
  final Value<String?> toName;
  final Value<String?> route;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const RidesCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.verdict = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.path = const Value.absent(),
    this.halts = const Value.absent(),
    this.features = const Value.absent(),
    this.guideTo = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toName = const Value.absent(),
    this.route = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RidesCompanion.insert({
    required String id,
    required int startedAt,
    required int endedAt,
    required String verdict,
    required int distanceM,
    this.path = const Value.absent(),
    this.halts = const Value.absent(),
    required String features,
    this.guideTo = const Value.absent(),
    this.fromName = const Value.absent(),
    this.toName = const Value.absent(),
    this.route = const Value.absent(),
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       verdict = Value(verdict),
       distanceM = Value(distanceM),
       features = Value(features),
       updatedAt = Value(updatedAt);
  static Insertable<RideRow> custom({
    Expression<String>? id,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? verdict,
    Expression<int>? distanceM,
    Expression<String>? path,
    Expression<String>? halts,
    Expression<String>? features,
    Expression<String>? guideTo,
    Expression<String>? fromName,
    Expression<String>? toName,
    Expression<String>? route,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (verdict != null) 'verdict': verdict,
      if (distanceM != null) 'distance_m': distanceM,
      if (path != null) 'path': path,
      if (halts != null) 'halts': halts,
      if (features != null) 'features': features,
      if (guideTo != null) 'guide_to': guideTo,
      if (fromName != null) 'from_name': fromName,
      if (toName != null) 'to_name': toName,
      if (route != null) 'route': route,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RidesCompanion copyWith({
    Value<String>? id,
    Value<int>? startedAt,
    Value<int>? endedAt,
    Value<String>? verdict,
    Value<int>? distanceM,
    Value<String?>? path,
    Value<String?>? halts,
    Value<String>? features,
    Value<String?>? guideTo,
    Value<String?>? fromName,
    Value<String?>? toName,
    Value<String?>? route,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return RidesCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      verdict: verdict ?? this.verdict,
      distanceM: distanceM ?? this.distanceM,
      path: path ?? this.path,
      halts: halts ?? this.halts,
      features: features ?? this.features,
      guideTo: guideTo ?? this.guideTo,
      fromName: fromName ?? this.fromName,
      toName: toName ?? this.toName,
      route: route ?? this.route,
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
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (halts.present) {
      map['halts'] = Variable<String>(halts.value);
    }
    if (features.present) {
      map['features'] = Variable<String>(features.value);
    }
    if (guideTo.present) {
      map['guide_to'] = Variable<String>(guideTo.value);
    }
    if (fromName.present) {
      map['from_name'] = Variable<String>(fromName.value);
    }
    if (toName.present) {
      map['to_name'] = Variable<String>(toName.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
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
    return (StringBuffer('RidesCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('verdict: $verdict, ')
          ..write('distanceM: $distanceM, ')
          ..write('path: $path, ')
          ..write('halts: $halts, ')
          ..write('features: $features, ')
          ..write('guideTo: $guideTo, ')
          ..write('fromName: $fromName, ')
          ..write('toName: $toName, ')
          ..write('route: $route, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PooledHaltsTable extends PooledHalts
    with TableInfo<$PooledHaltsTable, PooledHaltsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PooledHaltsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
    'ride_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    rideId,
    uid,
    points,
    updatedAt,
    deletedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pooled_halts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PooledHaltsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ride_id')) {
      context.handle(
        _rideIdMeta,
        rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
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
  Set<GeneratedColumn> get $primaryKey => {rideId};
  @override
  PooledHaltsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PooledHaltsRow(
      rideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ride_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points'],
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
  $PooledHaltsTable createAlias(String alias) {
    return $PooledHaltsTable(attachedDatabase, alias);
  }
}

class PooledHaltsRow extends DataClass implements Insertable<PooledHaltsRow> {
  final String rideId;
  final String uid;

  /// "lat,lng,seconds;..." (ride_record.dart); empty once taken back.
  final String points;
  final int updatedAt;
  final int? deletedAt;
  final int? pendingSince;
  const PooledHaltsRow({
    required this.rideId,
    required this.uid,
    required this.points,
    required this.updatedAt,
    this.deletedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ride_id'] = Variable<String>(rideId);
    map['uid'] = Variable<String>(uid);
    map['points'] = Variable<String>(points);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  PooledHaltsCompanion toCompanion(bool nullToAbsent) {
    return PooledHaltsCompanion(
      rideId: Value(rideId),
      uid: Value(uid),
      points: Value(points),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory PooledHaltsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PooledHaltsRow(
      rideId: serializer.fromJson<String>(json['rideId']),
      uid: serializer.fromJson<String>(json['uid']),
      points: serializer.fromJson<String>(json['points']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      pendingSince: serializer.fromJson<int?>(json['pendingSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rideId': serializer.toJson<String>(rideId),
      'uid': serializer.toJson<String>(uid),
      'points': serializer.toJson<String>(points),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  PooledHaltsRow copyWith({
    String? rideId,
    String? uid,
    String? points,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<int?> pendingSince = const Value.absent(),
  }) => PooledHaltsRow(
    rideId: rideId ?? this.rideId,
    uid: uid ?? this.uid,
    points: points ?? this.points,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  PooledHaltsRow copyWithCompanion(PooledHaltsCompanion data) {
    return PooledHaltsRow(
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      uid: data.uid.present ? data.uid.value : this.uid,
      points: data.points.present ? data.points.value : this.points,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PooledHaltsRow(')
          ..write('rideId: $rideId, ')
          ..write('uid: $uid, ')
          ..write('points: $points, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(rideId, uid, points, updatedAt, deletedAt, pendingSince);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PooledHaltsRow &&
          other.rideId == this.rideId &&
          other.uid == this.uid &&
          other.points == this.points &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSince == this.pendingSince);
}

class PooledHaltsCompanion extends UpdateCompanion<PooledHaltsRow> {
  final Value<String> rideId;
  final Value<String> uid;
  final Value<String> points;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const PooledHaltsCompanion({
    this.rideId = const Value.absent(),
    this.uid = const Value.absent(),
    this.points = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PooledHaltsCompanion.insert({
    required String rideId,
    required String uid,
    required String points,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rideId = Value(rideId),
       uid = Value(uid),
       points = Value(points),
       updatedAt = Value(updatedAt);
  static Insertable<PooledHaltsRow> custom({
    Expression<String>? rideId,
    Expression<String>? uid,
    Expression<String>? points,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rideId != null) 'ride_id': rideId,
      if (uid != null) 'uid': uid,
      if (points != null) 'points': points,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PooledHaltsCompanion copyWith({
    Value<String>? rideId,
    Value<String>? uid,
    Value<String>? points,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return PooledHaltsCompanion(
      rideId: rideId ?? this.rideId,
      uid: uid ?? this.uid,
      points: points ?? this.points,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendingSince: pendingSince ?? this.pendingSince,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
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
    return (StringBuffer('PooledHaltsCompanion(')
          ..write('rideId: $rideId, ')
          ..write('uid: $uid, ')
          ..write('points: $points, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopNotesTable extends StopNotes
    with TableInfo<$StopNotesTable, StopNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<bool> removed = GeneratedColumn<bool>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _byMeta = const VerificationMeta('by');
  @override
  late final GeneratedColumn<String> by = GeneratedColumn<String>(
    'by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    lat,
    lng,
    name,
    removed,
    by,
    updatedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    if (data.containsKey('by')) {
      context.handle(_byMeta, by.isAcceptableOrUnknown(data['by']!, _byMeta));
    } else if (isInserting) {
      context.missing(_byMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
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
  StopNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed'],
      )!,
      by: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_since'],
      ),
    );
  }

  @override
  $StopNotesTable createAlias(String alias) {
    return $StopNotesTable(attachedDatabase, alias);
  }
}

class StopNoteRow extends DataClass implements Insertable<StopNoteRow> {
  final String id;
  final double lat;
  final double lng;
  final String? name;
  final bool removed;
  final String by;
  final int updatedAt;
  final int? pendingSince;
  const StopNoteRow({
    required this.id,
    required this.lat,
    required this.lng,
    this.name,
    required this.removed,
    required this.by,
    required this.updatedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['removed'] = Variable<bool>(removed);
    map['by'] = Variable<String>(by);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  StopNotesCompanion toCompanion(bool nullToAbsent) {
    return StopNotesCompanion(
      id: Value(id),
      lat: Value(lat),
      lng: Value(lng),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      removed: Value(removed),
      by: Value(by),
      updatedAt: Value(updatedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory StopNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopNoteRow(
      id: serializer.fromJson<String>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      name: serializer.fromJson<String?>(json['name']),
      removed: serializer.fromJson<bool>(json['removed']),
      by: serializer.fromJson<String>(json['by']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      pendingSince: serializer.fromJson<int?>(json['pendingSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'name': serializer.toJson<String?>(name),
      'removed': serializer.toJson<bool>(removed),
      'by': serializer.toJson<String>(by),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  StopNoteRow copyWith({
    String? id,
    double? lat,
    double? lng,
    Value<String?> name = const Value.absent(),
    bool? removed,
    String? by,
    int? updatedAt,
    Value<int?> pendingSince = const Value.absent(),
  }) => StopNoteRow(
    id: id ?? this.id,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    name: name.present ? name.value : this.name,
    removed: removed ?? this.removed,
    by: by ?? this.by,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  StopNoteRow copyWithCompanion(StopNotesCompanion data) {
    return StopNoteRow(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      name: data.name.present ? data.name.value : this.name,
      removed: data.removed.present ? data.removed.value : this.removed,
      by: data.by.present ? data.by.value : this.by,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopNoteRow(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('name: $name, ')
          ..write('removed: $removed, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lat, lng, name, removed, by, updatedAt, pendingSince);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopNoteRow &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.name == this.name &&
          other.removed == this.removed &&
          other.by == this.by &&
          other.updatedAt == this.updatedAt &&
          other.pendingSince == this.pendingSince);
}

class StopNotesCompanion extends UpdateCompanion<StopNoteRow> {
  final Value<String> id;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> name;
  final Value<bool> removed;
  final Value<String> by;
  final Value<int> updatedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const StopNotesCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.name = const Value.absent(),
    this.removed = const Value.absent(),
    this.by = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopNotesCompanion.insert({
    required String id,
    required double lat,
    required double lng,
    this.name = const Value.absent(),
    this.removed = const Value.absent(),
    required String by,
    required int updatedAt,
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lat = Value(lat),
       lng = Value(lng),
       by = Value(by),
       updatedAt = Value(updatedAt);
  static Insertable<StopNoteRow> custom({
    Expression<String>? id,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? name,
    Expression<bool>? removed,
    Expression<String>? by,
    Expression<int>? updatedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (name != null) 'name': name,
      if (removed != null) 'removed': removed,
      if (by != null) 'by': by,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopNotesCompanion copyWith({
    Value<String>? id,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? name,
    Value<bool>? removed,
    Value<String>? by,
    Value<int>? updatedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return StopNotesCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      name: name ?? this.name,
      removed: removed ?? this.removed,
      by: by ?? this.by,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (removed.present) {
      map['removed'] = Variable<bool>(removed.value);
    }
    if (by.present) {
      map['by'] = Variable<String>(by.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
    return (StringBuffer('StopNotesCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('name: $name, ')
          ..write('removed: $removed, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OsmStopsTable extends OsmStops
    with TableInfo<$OsmStopsTable, OsmStopRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OsmStopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enMeta = const VerificationMeta('en');
  @override
  late final GeneratedColumn<String> en = GeneratedColumn<String>(
    'en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taMeta = const VerificationMeta('ta');
  @override
  late final GeneratedColumn<String> ta = GeneratedColumn<String>(
    'ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siMeta = const VerificationMeta('si');
  @override
  late final GeneratedColumn<String> si = GeneratedColumn<String>(
    'si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tileMeta = const VerificationMeta('tile');
  @override
  late final GeneratedColumn<String> tile = GeneratedColumn<String>(
    'tile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lat, lng, en, ta, si, tile];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'osm_stops';
  @override
  VerificationContext validateIntegrity(
    Insertable<OsmStopRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('en')) {
      context.handle(_enMeta, en.isAcceptableOrUnknown(data['en']!, _enMeta));
    }
    if (data.containsKey('ta')) {
      context.handle(_taMeta, ta.isAcceptableOrUnknown(data['ta']!, _taMeta));
    }
    if (data.containsKey('si')) {
      context.handle(_siMeta, si.isAcceptableOrUnknown(data['si']!, _siMeta));
    }
    if (data.containsKey('tile')) {
      context.handle(
        _tileMeta,
        tile.isAcceptableOrUnknown(data['tile']!, _tileMeta),
      );
    } else if (isInserting) {
      context.missing(_tileMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OsmStopRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OsmStopRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      en: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en'],
      ),
      ta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ta'],
      ),
      si: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}si'],
      ),
      tile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tile'],
      )!,
    );
  }

  @override
  $OsmStopsTable createAlias(String alias) {
    return $OsmStopsTable(attachedDatabase, alias);
  }
}

class OsmStopRow extends DataClass implements Insertable<OsmStopRow> {
  final int id;
  final double lat;
  final double lng;
  final String? en;
  final String? ta;
  final String? si;
  final String tile;
  const OsmStopRow({
    required this.id,
    required this.lat,
    required this.lng,
    this.en,
    this.ta,
    this.si,
    required this.tile,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || en != null) {
      map['en'] = Variable<String>(en);
    }
    if (!nullToAbsent || ta != null) {
      map['ta'] = Variable<String>(ta);
    }
    if (!nullToAbsent || si != null) {
      map['si'] = Variable<String>(si);
    }
    map['tile'] = Variable<String>(tile);
    return map;
  }

  OsmStopsCompanion toCompanion(bool nullToAbsent) {
    return OsmStopsCompanion(
      id: Value(id),
      lat: Value(lat),
      lng: Value(lng),
      en: en == null && nullToAbsent ? const Value.absent() : Value(en),
      ta: ta == null && nullToAbsent ? const Value.absent() : Value(ta),
      si: si == null && nullToAbsent ? const Value.absent() : Value(si),
      tile: Value(tile),
    );
  }

  factory OsmStopRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OsmStopRow(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      en: serializer.fromJson<String?>(json['en']),
      ta: serializer.fromJson<String?>(json['ta']),
      si: serializer.fromJson<String?>(json['si']),
      tile: serializer.fromJson<String>(json['tile']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'en': serializer.toJson<String?>(en),
      'ta': serializer.toJson<String?>(ta),
      'si': serializer.toJson<String?>(si),
      'tile': serializer.toJson<String>(tile),
    };
  }

  OsmStopRow copyWith({
    int? id,
    double? lat,
    double? lng,
    Value<String?> en = const Value.absent(),
    Value<String?> ta = const Value.absent(),
    Value<String?> si = const Value.absent(),
    String? tile,
  }) => OsmStopRow(
    id: id ?? this.id,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    en: en.present ? en.value : this.en,
    ta: ta.present ? ta.value : this.ta,
    si: si.present ? si.value : this.si,
    tile: tile ?? this.tile,
  );
  OsmStopRow copyWithCompanion(OsmStopsCompanion data) {
    return OsmStopRow(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      en: data.en.present ? data.en.value : this.en,
      ta: data.ta.present ? data.ta.value : this.ta,
      si: data.si.present ? data.si.value : this.si,
      tile: data.tile.present ? data.tile.value : this.tile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OsmStopRow(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('en: $en, ')
          ..write('ta: $ta, ')
          ..write('si: $si, ')
          ..write('tile: $tile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lat, lng, en, ta, si, tile);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OsmStopRow &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.en == this.en &&
          other.ta == this.ta &&
          other.si == this.si &&
          other.tile == this.tile);
}

class OsmStopsCompanion extends UpdateCompanion<OsmStopRow> {
  final Value<int> id;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> en;
  final Value<String?> ta;
  final Value<String?> si;
  final Value<String> tile;
  const OsmStopsCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.en = const Value.absent(),
    this.ta = const Value.absent(),
    this.si = const Value.absent(),
    this.tile = const Value.absent(),
  });
  OsmStopsCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lng,
    this.en = const Value.absent(),
    this.ta = const Value.absent(),
    this.si = const Value.absent(),
    required String tile,
  }) : lat = Value(lat),
       lng = Value(lng),
       tile = Value(tile);
  static Insertable<OsmStopRow> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? en,
    Expression<String>? ta,
    Expression<String>? si,
    Expression<String>? tile,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (en != null) 'en': en,
      if (ta != null) 'ta': ta,
      if (si != null) 'si': si,
      if (tile != null) 'tile': tile,
    });
  }

  OsmStopsCompanion copyWith({
    Value<int>? id,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? en,
    Value<String?>? ta,
    Value<String?>? si,
    Value<String>? tile,
  }) {
    return OsmStopsCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      en: en ?? this.en,
      ta: ta ?? this.ta,
      si: si ?? this.si,
      tile: tile ?? this.tile,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (en.present) {
      map['en'] = Variable<String>(en.value);
    }
    if (ta.present) {
      map['ta'] = Variable<String>(ta.value);
    }
    if (si.present) {
      map['si'] = Variable<String>(si.value);
    }
    if (tile.present) {
      map['tile'] = Variable<String>(tile.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OsmStopsCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('en: $en, ')
          ..write('ta: $ta, ')
          ..write('si: $si, ')
          ..write('tile: $tile')
          ..write(')'))
        .toString();
  }
}

class $StopTilesTable extends StopTiles
    with TableInfo<$StopTilesTable, StopTileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopTilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_tiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopTileRow> instance, {
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
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StopTileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopTileRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $StopTilesTable createAlias(String alias) {
    return $StopTilesTable(attachedDatabase, alias);
  }
}

class StopTileRow extends DataClass implements Insertable<StopTileRow> {
  final String key;
  final int fetchedAt;
  const StopTileRow({required this.key, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  StopTilesCompanion toCompanion(bool nullToAbsent) {
    return StopTilesCompanion(key: Value(key), fetchedAt: Value(fetchedAt));
  }

  factory StopTileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopTileRow(
      key: serializer.fromJson<String>(json['key']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  StopTileRow copyWith({String? key, int? fetchedAt}) =>
      StopTileRow(key: key ?? this.key, fetchedAt: fetchedAt ?? this.fetchedAt);
  StopTileRow copyWithCompanion(StopTilesCompanion data) {
    return StopTileRow(
      key: data.key.present ? data.key.value : this.key,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopTileRow(')
          ..write('key: $key, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopTileRow &&
          other.key == this.key &&
          other.fetchedAt == this.fetchedAt);
}

class StopTilesCompanion extends UpdateCompanion<StopTileRow> {
  final Value<String> key;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const StopTilesCompanion({
    this.key = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopTilesCompanion.insert({
    required String key,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       fetchedAt = Value(fetchedAt);
  static Insertable<StopTileRow> custom({
    Expression<String>? key,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopTilesCompanion copyWith({
    Value<String>? key,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return StopTilesCompanion(
      key: key ?? this.key,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopTilesCompanion(')
          ..write('key: $key, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopNamesTable extends StopNames
    with TableInfo<$StopNamesTable, StopNameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, lat, lng, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopNameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopNameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopNameRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $StopNamesTable createAlias(String alias) {
    return $StopNamesTable(attachedDatabase, alias);
  }
}

class StopNameRow extends DataClass implements Insertable<StopNameRow> {
  final int id;
  final double lat;
  final double lng;
  final String name;
  const StopNameRow({
    required this.id,
    required this.lat,
    required this.lng,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['name'] = Variable<String>(name);
    return map;
  }

  StopNamesCompanion toCompanion(bool nullToAbsent) {
    return StopNamesCompanion(
      id: Value(id),
      lat: Value(lat),
      lng: Value(lng),
      name: Value(name),
    );
  }

  factory StopNameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopNameRow(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'name': serializer.toJson<String>(name),
    };
  }

  StopNameRow copyWith({int? id, double? lat, double? lng, String? name}) =>
      StopNameRow(
        id: id ?? this.id,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        name: name ?? this.name,
      );
  StopNameRow copyWithCompanion(StopNamesCompanion data) {
    return StopNameRow(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopNameRow(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lat, lng, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopNameRow &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.name == this.name);
}

class StopNamesCompanion extends UpdateCompanion<StopNameRow> {
  final Value<int> id;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String> name;
  const StopNamesCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.name = const Value.absent(),
  });
  StopNamesCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lng,
    required String name,
  }) : lat = Value(lat),
       lng = Value(lng),
       name = Value(name);
  static Insertable<StopNameRow> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (name != null) 'name': name,
    });
  }

  StopNamesCompanion copyWith({
    Value<int>? id,
    Value<double>? lat,
    Value<double>? lng,
    Value<String>? name,
  }) {
    return StopNamesCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopNamesCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $RouteDataTable extends RouteData
    with TableInfo<$RouteDataTable, RouteDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<int> checkedAt = GeneratedColumn<int>(
    'checked_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [source, body, etag, checkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source};
  @override
  RouteDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteDataRow(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}checked_at'],
      )!,
    );
  }

  @override
  $RouteDataTable createAlias(String alias) {
    return $RouteDataTable(attachedDatabase, alias);
  }
}

class RouteDataRow extends DataClass implements Insertable<RouteDataRow> {
  /// `osm`, `ntc` or `lmt`.
  final String source;
  final String body;
  final String? etag;

  /// When the file was last asked for, in microseconds since the epoch.
  final int checkedAt;
  const RouteDataRow({
    required this.source,
    required this.body,
    this.etag,
    required this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['checked_at'] = Variable<int>(checkedAt);
    return map;
  }

  RouteDataCompanion toCompanion(bool nullToAbsent) {
    return RouteDataCompanion(
      source: Value(source),
      body: Value(body),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      checkedAt: Value(checkedAt),
    );
  }

  factory RouteDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteDataRow(
      source: serializer.fromJson<String>(json['source']),
      body: serializer.fromJson<String>(json['body']),
      etag: serializer.fromJson<String?>(json['etag']),
      checkedAt: serializer.fromJson<int>(json['checkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'body': serializer.toJson<String>(body),
      'etag': serializer.toJson<String?>(etag),
      'checkedAt': serializer.toJson<int>(checkedAt),
    };
  }

  RouteDataRow copyWith({
    String? source,
    String? body,
    Value<String?> etag = const Value.absent(),
    int? checkedAt,
  }) => RouteDataRow(
    source: source ?? this.source,
    body: body ?? this.body,
    etag: etag.present ? etag.value : this.etag,
    checkedAt: checkedAt ?? this.checkedAt,
  );
  RouteDataRow copyWithCompanion(RouteDataCompanion data) {
    return RouteDataRow(
      source: data.source.present ? data.source.value : this.source,
      body: data.body.present ? data.body.value : this.body,
      etag: data.etag.present ? data.etag.value : this.etag,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteDataRow(')
          ..write('source: $source, ')
          ..write('body: $body, ')
          ..write('etag: $etag, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, body, etag, checkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteDataRow &&
          other.source == this.source &&
          other.body == this.body &&
          other.etag == this.etag &&
          other.checkedAt == this.checkedAt);
}

class RouteDataCompanion extends UpdateCompanion<RouteDataRow> {
  final Value<String> source;
  final Value<String> body;
  final Value<String?> etag;
  final Value<int> checkedAt;
  final Value<int> rowid;
  const RouteDataCompanion({
    this.source = const Value.absent(),
    this.body = const Value.absent(),
    this.etag = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteDataCompanion.insert({
    required String source,
    required String body,
    this.etag = const Value.absent(),
    required int checkedAt,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       body = Value(body),
       checkedAt = Value(checkedAt);
  static Insertable<RouteDataRow> custom({
    Expression<String>? source,
    Expression<String>? body,
    Expression<String>? etag,
    Expression<int>? checkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (body != null) 'body': body,
      if (etag != null) 'etag': etag,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteDataCompanion copyWith({
    Value<String>? source,
    Value<String>? body,
    Value<String?>? etag,
    Value<int>? checkedAt,
    Value<int>? rowid,
  }) {
    return RouteDataCompanion(
      source: source ?? this.source,
      body: body ?? this.body,
      etag: etag ?? this.etag,
      checkedAt: checkedAt ?? this.checkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<int>(checkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteDataCompanion(')
          ..write('source: $source, ')
          ..write('body: $body, ')
          ..write('etag: $etag, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteNotesTable extends RouteNotes
    with TableInfo<$RouteNotesTable, RouteNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taMeta = const VerificationMeta('ta');
  @override
  late final GeneratedColumn<String> ta = GeneratedColumn<String>(
    'ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siMeta = const VerificationMeta('si');
  @override
  late final GeneratedColumn<String> si = GeneratedColumn<String>(
    'si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enMeta = const VerificationMeta('en');
  @override
  late final GeneratedColumn<String> en = GeneratedColumn<String>(
    'en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<bool> removed = GeneratedColumn<bool>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _byMeta = const VerificationMeta('by');
  @override
  late final GeneratedColumn<String> by = GeneratedColumn<String>(
    'by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    route,
    direction,
    ta,
    si,
    en,
    removed,
    by,
    updatedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('ta')) {
      context.handle(_taMeta, ta.isAcceptableOrUnknown(data['ta']!, _taMeta));
    }
    if (data.containsKey('si')) {
      context.handle(_siMeta, si.isAcceptableOrUnknown(data['si']!, _siMeta));
    }
    if (data.containsKey('en')) {
      context.handle(_enMeta, en.isAcceptableOrUnknown(data['en']!, _enMeta));
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    if (data.containsKey('by')) {
      context.handle(_byMeta, by.isAcceptableOrUnknown(data['by']!, _byMeta));
    } else if (isInserting) {
      context.missing(_byMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
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
  RouteNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      ta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ta'],
      ),
      si: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}si'],
      ),
      en: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}en'],
      ),
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed'],
      )!,
      by: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSince: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_since'],
      ),
    );
  }

  @override
  $RouteNotesTable createAlias(String alias) {
    return $RouteNotesTable(attachedDatabase, alias);
  }
}

class RouteNoteRow extends DataClass implements Insertable<RouteNoteRow> {
  final String id;

  /// The route's id and the direction's key (RouteDirection.noteKey).
  final String route;
  final String direction;

  /// Board lines in place of the file's; null keeps the file's.
  final String? ta;
  final String? si;
  final String? en;
  final bool removed;
  final String by;
  final int updatedAt;
  final int? pendingSince;
  const RouteNoteRow({
    required this.id,
    required this.route,
    required this.direction,
    this.ta,
    this.si,
    this.en,
    required this.removed,
    required this.by,
    required this.updatedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['route'] = Variable<String>(route);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || ta != null) {
      map['ta'] = Variable<String>(ta);
    }
    if (!nullToAbsent || si != null) {
      map['si'] = Variable<String>(si);
    }
    if (!nullToAbsent || en != null) {
      map['en'] = Variable<String>(en);
    }
    map['removed'] = Variable<bool>(removed);
    map['by'] = Variable<String>(by);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  RouteNotesCompanion toCompanion(bool nullToAbsent) {
    return RouteNotesCompanion(
      id: Value(id),
      route: Value(route),
      direction: Value(direction),
      ta: ta == null && nullToAbsent ? const Value.absent() : Value(ta),
      si: si == null && nullToAbsent ? const Value.absent() : Value(si),
      en: en == null && nullToAbsent ? const Value.absent() : Value(en),
      removed: Value(removed),
      by: Value(by),
      updatedAt: Value(updatedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory RouteNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteNoteRow(
      id: serializer.fromJson<String>(json['id']),
      route: serializer.fromJson<String>(json['route']),
      direction: serializer.fromJson<String>(json['direction']),
      ta: serializer.fromJson<String?>(json['ta']),
      si: serializer.fromJson<String?>(json['si']),
      en: serializer.fromJson<String?>(json['en']),
      removed: serializer.fromJson<bool>(json['removed']),
      by: serializer.fromJson<String>(json['by']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      pendingSince: serializer.fromJson<int?>(json['pendingSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'route': serializer.toJson<String>(route),
      'direction': serializer.toJson<String>(direction),
      'ta': serializer.toJson<String?>(ta),
      'si': serializer.toJson<String?>(si),
      'en': serializer.toJson<String?>(en),
      'removed': serializer.toJson<bool>(removed),
      'by': serializer.toJson<String>(by),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  RouteNoteRow copyWith({
    String? id,
    String? route,
    String? direction,
    Value<String?> ta = const Value.absent(),
    Value<String?> si = const Value.absent(),
    Value<String?> en = const Value.absent(),
    bool? removed,
    String? by,
    int? updatedAt,
    Value<int?> pendingSince = const Value.absent(),
  }) => RouteNoteRow(
    id: id ?? this.id,
    route: route ?? this.route,
    direction: direction ?? this.direction,
    ta: ta.present ? ta.value : this.ta,
    si: si.present ? si.value : this.si,
    en: en.present ? en.value : this.en,
    removed: removed ?? this.removed,
    by: by ?? this.by,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  RouteNoteRow copyWithCompanion(RouteNotesCompanion data) {
    return RouteNoteRow(
      id: data.id.present ? data.id.value : this.id,
      route: data.route.present ? data.route.value : this.route,
      direction: data.direction.present ? data.direction.value : this.direction,
      ta: data.ta.present ? data.ta.value : this.ta,
      si: data.si.present ? data.si.value : this.si,
      en: data.en.present ? data.en.value : this.en,
      removed: data.removed.present ? data.removed.value : this.removed,
      by: data.by.present ? data.by.value : this.by,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteNoteRow(')
          ..write('id: $id, ')
          ..write('route: $route, ')
          ..write('direction: $direction, ')
          ..write('ta: $ta, ')
          ..write('si: $si, ')
          ..write('en: $en, ')
          ..write('removed: $removed, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    route,
    direction,
    ta,
    si,
    en,
    removed,
    by,
    updatedAt,
    pendingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteNoteRow &&
          other.id == this.id &&
          other.route == this.route &&
          other.direction == this.direction &&
          other.ta == this.ta &&
          other.si == this.si &&
          other.en == this.en &&
          other.removed == this.removed &&
          other.by == this.by &&
          other.updatedAt == this.updatedAt &&
          other.pendingSince == this.pendingSince);
}

class RouteNotesCompanion extends UpdateCompanion<RouteNoteRow> {
  final Value<String> id;
  final Value<String> route;
  final Value<String> direction;
  final Value<String?> ta;
  final Value<String?> si;
  final Value<String?> en;
  final Value<bool> removed;
  final Value<String> by;
  final Value<int> updatedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const RouteNotesCompanion({
    this.id = const Value.absent(),
    this.route = const Value.absent(),
    this.direction = const Value.absent(),
    this.ta = const Value.absent(),
    this.si = const Value.absent(),
    this.en = const Value.absent(),
    this.removed = const Value.absent(),
    this.by = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteNotesCompanion.insert({
    required String id,
    required String route,
    required String direction,
    this.ta = const Value.absent(),
    this.si = const Value.absent(),
    this.en = const Value.absent(),
    this.removed = const Value.absent(),
    required String by,
    required int updatedAt,
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       route = Value(route),
       direction = Value(direction),
       by = Value(by),
       updatedAt = Value(updatedAt);
  static Insertable<RouteNoteRow> custom({
    Expression<String>? id,
    Expression<String>? route,
    Expression<String>? direction,
    Expression<String>? ta,
    Expression<String>? si,
    Expression<String>? en,
    Expression<bool>? removed,
    Expression<String>? by,
    Expression<int>? updatedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (route != null) 'route': route,
      if (direction != null) 'direction': direction,
      if (ta != null) 'ta': ta,
      if (si != null) 'si': si,
      if (en != null) 'en': en,
      if (removed != null) 'removed': removed,
      if (by != null) 'by': by,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? route,
    Value<String>? direction,
    Value<String?>? ta,
    Value<String?>? si,
    Value<String?>? en,
    Value<bool>? removed,
    Value<String>? by,
    Value<int>? updatedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return RouteNotesCompanion(
      id: id ?? this.id,
      route: route ?? this.route,
      direction: direction ?? this.direction,
      ta: ta ?? this.ta,
      si: si ?? this.si,
      en: en ?? this.en,
      removed: removed ?? this.removed,
      by: by ?? this.by,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (ta.present) {
      map['ta'] = Variable<String>(ta.value);
    }
    if (si.present) {
      map['si'] = Variable<String>(si.value);
    }
    if (en.present) {
      map['en'] = Variable<String>(en.value);
    }
    if (removed.present) {
      map['removed'] = Variable<bool>(removed.value);
    }
    if (by.present) {
      map['by'] = Variable<String>(by.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
    return (StringBuffer('RouteNotesCompanion(')
          ..write('id: $id, ')
          ..write('route: $route, ')
          ..write('direction: $direction, ')
          ..write('ta: $ta, ')
          ..write('si: $si, ')
          ..write('en: $en, ')
          ..write('removed: $removed, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HandRoutesTable extends HandRoutes
    with TableInfo<$HandRoutesTable, HandRouteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HandRoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromLatMeta = const VerificationMeta(
    'fromLat',
  );
  @override
  late final GeneratedColumn<double> fromLat = GeneratedColumn<double>(
    'from_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromLngMeta = const VerificationMeta(
    'fromLng',
  );
  @override
  late final GeneratedColumn<double> fromLng = GeneratedColumn<double>(
    'from_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromEnMeta = const VerificationMeta('fromEn');
  @override
  late final GeneratedColumn<String> fromEn = GeneratedColumn<String>(
    'from_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromTaMeta = const VerificationMeta('fromTa');
  @override
  late final GeneratedColumn<String> fromTa = GeneratedColumn<String>(
    'from_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromSiMeta = const VerificationMeta('fromSi');
  @override
  late final GeneratedColumn<String> fromSi = GeneratedColumn<String>(
    'from_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toLatMeta = const VerificationMeta('toLat');
  @override
  late final GeneratedColumn<double> toLat = GeneratedColumn<double>(
    'to_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toLngMeta = const VerificationMeta('toLng');
  @override
  late final GeneratedColumn<double> toLng = GeneratedColumn<double>(
    'to_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toEnMeta = const VerificationMeta('toEn');
  @override
  late final GeneratedColumn<String> toEn = GeneratedColumn<String>(
    'to_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toTaMeta = const VerificationMeta('toTa');
  @override
  late final GeneratedColumn<String> toTa = GeneratedColumn<String>(
    'to_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toSiMeta = const VerificationMeta('toSi');
  @override
  late final GeneratedColumn<String> toSi = GeneratedColumn<String>(
    'to_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viaMeta = const VerificationMeta('via');
  @override
  late final GeneratedColumn<String> via = GeneratedColumn<String>(
    'via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roadMeta = const VerificationMeta('road');
  @override
  late final GeneratedColumn<String> road = GeneratedColumn<String>(
    'road',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byMeta = const VerificationMeta('by');
  @override
  late final GeneratedColumn<String> by = GeneratedColumn<String>(
    'by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    number,
    fromLat,
    fromLng,
    fromEn,
    fromTa,
    fromSi,
    toLat,
    toLng,
    toEn,
    toTa,
    toSi,
    via,
    road,
    by,
    updatedAt,
    deletedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hand_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<HandRouteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('from_lat')) {
      context.handle(
        _fromLatMeta,
        fromLat.isAcceptableOrUnknown(data['from_lat']!, _fromLatMeta),
      );
    } else if (isInserting) {
      context.missing(_fromLatMeta);
    }
    if (data.containsKey('from_lng')) {
      context.handle(
        _fromLngMeta,
        fromLng.isAcceptableOrUnknown(data['from_lng']!, _fromLngMeta),
      );
    } else if (isInserting) {
      context.missing(_fromLngMeta);
    }
    if (data.containsKey('from_en')) {
      context.handle(
        _fromEnMeta,
        fromEn.isAcceptableOrUnknown(data['from_en']!, _fromEnMeta),
      );
    }
    if (data.containsKey('from_ta')) {
      context.handle(
        _fromTaMeta,
        fromTa.isAcceptableOrUnknown(data['from_ta']!, _fromTaMeta),
      );
    }
    if (data.containsKey('from_si')) {
      context.handle(
        _fromSiMeta,
        fromSi.isAcceptableOrUnknown(data['from_si']!, _fromSiMeta),
      );
    }
    if (data.containsKey('to_lat')) {
      context.handle(
        _toLatMeta,
        toLat.isAcceptableOrUnknown(data['to_lat']!, _toLatMeta),
      );
    } else if (isInserting) {
      context.missing(_toLatMeta);
    }
    if (data.containsKey('to_lng')) {
      context.handle(
        _toLngMeta,
        toLng.isAcceptableOrUnknown(data['to_lng']!, _toLngMeta),
      );
    } else if (isInserting) {
      context.missing(_toLngMeta);
    }
    if (data.containsKey('to_en')) {
      context.handle(
        _toEnMeta,
        toEn.isAcceptableOrUnknown(data['to_en']!, _toEnMeta),
      );
    }
    if (data.containsKey('to_ta')) {
      context.handle(
        _toTaMeta,
        toTa.isAcceptableOrUnknown(data['to_ta']!, _toTaMeta),
      );
    }
    if (data.containsKey('to_si')) {
      context.handle(
        _toSiMeta,
        toSi.isAcceptableOrUnknown(data['to_si']!, _toSiMeta),
      );
    }
    if (data.containsKey('via')) {
      context.handle(
        _viaMeta,
        via.isAcceptableOrUnknown(data['via']!, _viaMeta),
      );
    } else if (isInserting) {
      context.missing(_viaMeta);
    }
    if (data.containsKey('road')) {
      context.handle(
        _roadMeta,
        road.isAcceptableOrUnknown(data['road']!, _roadMeta),
      );
    } else if (isInserting) {
      context.missing(_roadMeta);
    }
    if (data.containsKey('by')) {
      context.handle(_byMeta, by.isAcceptableOrUnknown(data['by']!, _byMeta));
    } else if (isInserting) {
      context.missing(_byMeta);
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
  HandRouteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HandRouteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      fromLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}from_lat'],
      )!,
      fromLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}from_lng'],
      )!,
      fromEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_en'],
      ),
      fromTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_ta'],
      ),
      fromSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_si'],
      ),
      toLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}to_lat'],
      )!,
      toLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}to_lng'],
      )!,
      toEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_en'],
      ),
      toTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_ta'],
      ),
      toSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_si'],
      ),
      via: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}via'],
      )!,
      road: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road'],
      )!,
      by: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by'],
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
  $HandRoutesTable createAlias(String alias) {
    return $HandRoutesTable(attachedDatabase, alias);
  }
}

class HandRouteRow extends DataClass implements Insertable<HandRouteRow> {
  final String id;
  final String number;
  final double fromLat;
  final double fromLng;
  final String? fromEn;
  final String? fromTa;
  final String? fromSi;
  final double toLat;
  final double toLng;
  final String? toEn;
  final String? toTa;
  final String? toSi;

  /// The towns on the way, in order, as JSON: [{"lat", "lng", "en", "ta",
  /// "si"}].
  final String via;

  /// The road OSRM drew, as an encoded polyline.
  final String road;
  final String by;
  final int updatedAt;
  final int? deletedAt;
  final int? pendingSince;
  const HandRouteRow({
    required this.id,
    required this.number,
    required this.fromLat,
    required this.fromLng,
    this.fromEn,
    this.fromTa,
    this.fromSi,
    required this.toLat,
    required this.toLng,
    this.toEn,
    this.toTa,
    this.toSi,
    required this.via,
    required this.road,
    required this.by,
    required this.updatedAt,
    this.deletedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['number'] = Variable<String>(number);
    map['from_lat'] = Variable<double>(fromLat);
    map['from_lng'] = Variable<double>(fromLng);
    if (!nullToAbsent || fromEn != null) {
      map['from_en'] = Variable<String>(fromEn);
    }
    if (!nullToAbsent || fromTa != null) {
      map['from_ta'] = Variable<String>(fromTa);
    }
    if (!nullToAbsent || fromSi != null) {
      map['from_si'] = Variable<String>(fromSi);
    }
    map['to_lat'] = Variable<double>(toLat);
    map['to_lng'] = Variable<double>(toLng);
    if (!nullToAbsent || toEn != null) {
      map['to_en'] = Variable<String>(toEn);
    }
    if (!nullToAbsent || toTa != null) {
      map['to_ta'] = Variable<String>(toTa);
    }
    if (!nullToAbsent || toSi != null) {
      map['to_si'] = Variable<String>(toSi);
    }
    map['via'] = Variable<String>(via);
    map['road'] = Variable<String>(road);
    map['by'] = Variable<String>(by);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  HandRoutesCompanion toCompanion(bool nullToAbsent) {
    return HandRoutesCompanion(
      id: Value(id),
      number: Value(number),
      fromLat: Value(fromLat),
      fromLng: Value(fromLng),
      fromEn: fromEn == null && nullToAbsent
          ? const Value.absent()
          : Value(fromEn),
      fromTa: fromTa == null && nullToAbsent
          ? const Value.absent()
          : Value(fromTa),
      fromSi: fromSi == null && nullToAbsent
          ? const Value.absent()
          : Value(fromSi),
      toLat: Value(toLat),
      toLng: Value(toLng),
      toEn: toEn == null && nullToAbsent ? const Value.absent() : Value(toEn),
      toTa: toTa == null && nullToAbsent ? const Value.absent() : Value(toTa),
      toSi: toSi == null && nullToAbsent ? const Value.absent() : Value(toSi),
      via: Value(via),
      road: Value(road),
      by: Value(by),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory HandRouteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HandRouteRow(
      id: serializer.fromJson<String>(json['id']),
      number: serializer.fromJson<String>(json['number']),
      fromLat: serializer.fromJson<double>(json['fromLat']),
      fromLng: serializer.fromJson<double>(json['fromLng']),
      fromEn: serializer.fromJson<String?>(json['fromEn']),
      fromTa: serializer.fromJson<String?>(json['fromTa']),
      fromSi: serializer.fromJson<String?>(json['fromSi']),
      toLat: serializer.fromJson<double>(json['toLat']),
      toLng: serializer.fromJson<double>(json['toLng']),
      toEn: serializer.fromJson<String?>(json['toEn']),
      toTa: serializer.fromJson<String?>(json['toTa']),
      toSi: serializer.fromJson<String?>(json['toSi']),
      via: serializer.fromJson<String>(json['via']),
      road: serializer.fromJson<String>(json['road']),
      by: serializer.fromJson<String>(json['by']),
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
      'number': serializer.toJson<String>(number),
      'fromLat': serializer.toJson<double>(fromLat),
      'fromLng': serializer.toJson<double>(fromLng),
      'fromEn': serializer.toJson<String?>(fromEn),
      'fromTa': serializer.toJson<String?>(fromTa),
      'fromSi': serializer.toJson<String?>(fromSi),
      'toLat': serializer.toJson<double>(toLat),
      'toLng': serializer.toJson<double>(toLng),
      'toEn': serializer.toJson<String?>(toEn),
      'toTa': serializer.toJson<String?>(toTa),
      'toSi': serializer.toJson<String?>(toSi),
      'via': serializer.toJson<String>(via),
      'road': serializer.toJson<String>(road),
      'by': serializer.toJson<String>(by),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  HandRouteRow copyWith({
    String? id,
    String? number,
    double? fromLat,
    double? fromLng,
    Value<String?> fromEn = const Value.absent(),
    Value<String?> fromTa = const Value.absent(),
    Value<String?> fromSi = const Value.absent(),
    double? toLat,
    double? toLng,
    Value<String?> toEn = const Value.absent(),
    Value<String?> toTa = const Value.absent(),
    Value<String?> toSi = const Value.absent(),
    String? via,
    String? road,
    String? by,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<int?> pendingSince = const Value.absent(),
  }) => HandRouteRow(
    id: id ?? this.id,
    number: number ?? this.number,
    fromLat: fromLat ?? this.fromLat,
    fromLng: fromLng ?? this.fromLng,
    fromEn: fromEn.present ? fromEn.value : this.fromEn,
    fromTa: fromTa.present ? fromTa.value : this.fromTa,
    fromSi: fromSi.present ? fromSi.value : this.fromSi,
    toLat: toLat ?? this.toLat,
    toLng: toLng ?? this.toLng,
    toEn: toEn.present ? toEn.value : this.toEn,
    toTa: toTa.present ? toTa.value : this.toTa,
    toSi: toSi.present ? toSi.value : this.toSi,
    via: via ?? this.via,
    road: road ?? this.road,
    by: by ?? this.by,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  HandRouteRow copyWithCompanion(HandRoutesCompanion data) {
    return HandRouteRow(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      fromLat: data.fromLat.present ? data.fromLat.value : this.fromLat,
      fromLng: data.fromLng.present ? data.fromLng.value : this.fromLng,
      fromEn: data.fromEn.present ? data.fromEn.value : this.fromEn,
      fromTa: data.fromTa.present ? data.fromTa.value : this.fromTa,
      fromSi: data.fromSi.present ? data.fromSi.value : this.fromSi,
      toLat: data.toLat.present ? data.toLat.value : this.toLat,
      toLng: data.toLng.present ? data.toLng.value : this.toLng,
      toEn: data.toEn.present ? data.toEn.value : this.toEn,
      toTa: data.toTa.present ? data.toTa.value : this.toTa,
      toSi: data.toSi.present ? data.toSi.value : this.toSi,
      via: data.via.present ? data.via.value : this.via,
      road: data.road.present ? data.road.value : this.road,
      by: data.by.present ? data.by.value : this.by,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HandRouteRow(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('fromLat: $fromLat, ')
          ..write('fromLng: $fromLng, ')
          ..write('fromEn: $fromEn, ')
          ..write('fromTa: $fromTa, ')
          ..write('fromSi: $fromSi, ')
          ..write('toLat: $toLat, ')
          ..write('toLng: $toLng, ')
          ..write('toEn: $toEn, ')
          ..write('toTa: $toTa, ')
          ..write('toSi: $toSi, ')
          ..write('via: $via, ')
          ..write('road: $road, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    fromLat,
    fromLng,
    fromEn,
    fromTa,
    fromSi,
    toLat,
    toLng,
    toEn,
    toTa,
    toSi,
    via,
    road,
    by,
    updatedAt,
    deletedAt,
    pendingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HandRouteRow &&
          other.id == this.id &&
          other.number == this.number &&
          other.fromLat == this.fromLat &&
          other.fromLng == this.fromLng &&
          other.fromEn == this.fromEn &&
          other.fromTa == this.fromTa &&
          other.fromSi == this.fromSi &&
          other.toLat == this.toLat &&
          other.toLng == this.toLng &&
          other.toEn == this.toEn &&
          other.toTa == this.toTa &&
          other.toSi == this.toSi &&
          other.via == this.via &&
          other.road == this.road &&
          other.by == this.by &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSince == this.pendingSince);
}

class HandRoutesCompanion extends UpdateCompanion<HandRouteRow> {
  final Value<String> id;
  final Value<String> number;
  final Value<double> fromLat;
  final Value<double> fromLng;
  final Value<String?> fromEn;
  final Value<String?> fromTa;
  final Value<String?> fromSi;
  final Value<double> toLat;
  final Value<double> toLng;
  final Value<String?> toEn;
  final Value<String?> toTa;
  final Value<String?> toSi;
  final Value<String> via;
  final Value<String> road;
  final Value<String> by;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const HandRoutesCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.fromLat = const Value.absent(),
    this.fromLng = const Value.absent(),
    this.fromEn = const Value.absent(),
    this.fromTa = const Value.absent(),
    this.fromSi = const Value.absent(),
    this.toLat = const Value.absent(),
    this.toLng = const Value.absent(),
    this.toEn = const Value.absent(),
    this.toTa = const Value.absent(),
    this.toSi = const Value.absent(),
    this.via = const Value.absent(),
    this.road = const Value.absent(),
    this.by = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HandRoutesCompanion.insert({
    required String id,
    required String number,
    required double fromLat,
    required double fromLng,
    this.fromEn = const Value.absent(),
    this.fromTa = const Value.absent(),
    this.fromSi = const Value.absent(),
    required double toLat,
    required double toLng,
    this.toEn = const Value.absent(),
    this.toTa = const Value.absent(),
    this.toSi = const Value.absent(),
    required String via,
    required String road,
    required String by,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       number = Value(number),
       fromLat = Value(fromLat),
       fromLng = Value(fromLng),
       toLat = Value(toLat),
       toLng = Value(toLng),
       via = Value(via),
       road = Value(road),
       by = Value(by),
       updatedAt = Value(updatedAt);
  static Insertable<HandRouteRow> custom({
    Expression<String>? id,
    Expression<String>? number,
    Expression<double>? fromLat,
    Expression<double>? fromLng,
    Expression<String>? fromEn,
    Expression<String>? fromTa,
    Expression<String>? fromSi,
    Expression<double>? toLat,
    Expression<double>? toLng,
    Expression<String>? toEn,
    Expression<String>? toTa,
    Expression<String>? toSi,
    Expression<String>? via,
    Expression<String>? road,
    Expression<String>? by,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (fromLat != null) 'from_lat': fromLat,
      if (fromLng != null) 'from_lng': fromLng,
      if (fromEn != null) 'from_en': fromEn,
      if (fromTa != null) 'from_ta': fromTa,
      if (fromSi != null) 'from_si': fromSi,
      if (toLat != null) 'to_lat': toLat,
      if (toLng != null) 'to_lng': toLng,
      if (toEn != null) 'to_en': toEn,
      if (toTa != null) 'to_ta': toTa,
      if (toSi != null) 'to_si': toSi,
      if (via != null) 'via': via,
      if (road != null) 'road': road,
      if (by != null) 'by': by,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HandRoutesCompanion copyWith({
    Value<String>? id,
    Value<String>? number,
    Value<double>? fromLat,
    Value<double>? fromLng,
    Value<String?>? fromEn,
    Value<String?>? fromTa,
    Value<String?>? fromSi,
    Value<double>? toLat,
    Value<double>? toLng,
    Value<String?>? toEn,
    Value<String?>? toTa,
    Value<String?>? toSi,
    Value<String>? via,
    Value<String>? road,
    Value<String>? by,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return HandRoutesCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      fromEn: fromEn ?? this.fromEn,
      fromTa: fromTa ?? this.fromTa,
      fromSi: fromSi ?? this.fromSi,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      toEn: toEn ?? this.toEn,
      toTa: toTa ?? this.toTa,
      toSi: toSi ?? this.toSi,
      via: via ?? this.via,
      road: road ?? this.road,
      by: by ?? this.by,
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
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (fromLat.present) {
      map['from_lat'] = Variable<double>(fromLat.value);
    }
    if (fromLng.present) {
      map['from_lng'] = Variable<double>(fromLng.value);
    }
    if (fromEn.present) {
      map['from_en'] = Variable<String>(fromEn.value);
    }
    if (fromTa.present) {
      map['from_ta'] = Variable<String>(fromTa.value);
    }
    if (fromSi.present) {
      map['from_si'] = Variable<String>(fromSi.value);
    }
    if (toLat.present) {
      map['to_lat'] = Variable<double>(toLat.value);
    }
    if (toLng.present) {
      map['to_lng'] = Variable<double>(toLng.value);
    }
    if (toEn.present) {
      map['to_en'] = Variable<String>(toEn.value);
    }
    if (toTa.present) {
      map['to_ta'] = Variable<String>(toTa.value);
    }
    if (toSi.present) {
      map['to_si'] = Variable<String>(toSi.value);
    }
    if (via.present) {
      map['via'] = Variable<String>(via.value);
    }
    if (road.present) {
      map['road'] = Variable<String>(road.value);
    }
    if (by.present) {
      map['by'] = Variable<String>(by.value);
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
    return (StringBuffer('HandRoutesCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('fromLat: $fromLat, ')
          ..write('fromLng: $fromLng, ')
          ..write('fromEn: $fromEn, ')
          ..write('fromTa: $fromTa, ')
          ..write('fromSi: $fromSi, ')
          ..write('toLat: $toLat, ')
          ..write('toLng: $toLng, ')
          ..write('toEn: $toEn, ')
          ..write('toTa: $toTa, ')
          ..write('toSi: $toSi, ')
          ..write('via: $via, ')
          ..write('road: $road, ')
          ..write('by: $by, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteRoadsTable extends RouteRoads
    with TableInfo<$RouteRoadsTable, RouteRoadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteRoadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rideIdMeta = const VerificationMeta('rideId');
  @override
  late final GeneratedColumn<String> rideId = GeneratedColumn<String>(
    'ride_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roadMeta = const VerificationMeta('road');
  @override
  late final GeneratedColumn<String> road = GeneratedColumn<String>(
    'road',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    rideId,
    uid,
    route,
    direction,
    number,
    road,
    updatedAt,
    deletedAt,
    pendingSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_roads';
  @override
  VerificationContext validateIntegrity(
    Insertable<RouteRoadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ride_id')) {
      context.handle(
        _rideIdMeta,
        rideId.isAcceptableOrUnknown(data['ride_id']!, _rideIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rideIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('road')) {
      context.handle(
        _roadMeta,
        road.isAcceptableOrUnknown(data['road']!, _roadMeta),
      );
    } else if (isInserting) {
      context.missing(_roadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {rideId};
  @override
  RouteRoadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteRoadRow(
      rideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ride_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      road: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road'],
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
  $RouteRoadsTable createAlias(String alias) {
    return $RouteRoadsTable(attachedDatabase, alias);
  }
}

class RouteRoadRow extends DataClass implements Insertable<RouteRoadRow> {
  final String rideId;
  final String uid;

  /// The route's id and the direction's key (RouteTag).
  final String route;
  final String direction;
  final String number;

  /// The ride's bus part, an encoded polyline; empty once taken back.
  final String road;
  final int updatedAt;
  final int? deletedAt;
  final int? pendingSince;
  const RouteRoadRow({
    required this.rideId,
    required this.uid,
    required this.route,
    required this.direction,
    required this.number,
    required this.road,
    required this.updatedAt,
    this.deletedAt,
    this.pendingSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ride_id'] = Variable<String>(rideId);
    map['uid'] = Variable<String>(uid);
    map['route'] = Variable<String>(route);
    map['direction'] = Variable<String>(direction);
    map['number'] = Variable<String>(number);
    map['road'] = Variable<String>(road);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || pendingSince != null) {
      map['pending_since'] = Variable<int>(pendingSince);
    }
    return map;
  }

  RouteRoadsCompanion toCompanion(bool nullToAbsent) {
    return RouteRoadsCompanion(
      rideId: Value(rideId),
      uid: Value(uid),
      route: Value(route),
      direction: Value(direction),
      number: Value(number),
      road: Value(road),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      pendingSince: pendingSince == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingSince),
    );
  }

  factory RouteRoadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteRoadRow(
      rideId: serializer.fromJson<String>(json['rideId']),
      uid: serializer.fromJson<String>(json['uid']),
      route: serializer.fromJson<String>(json['route']),
      direction: serializer.fromJson<String>(json['direction']),
      number: serializer.fromJson<String>(json['number']),
      road: serializer.fromJson<String>(json['road']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      pendingSince: serializer.fromJson<int?>(json['pendingSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rideId': serializer.toJson<String>(rideId),
      'uid': serializer.toJson<String>(uid),
      'route': serializer.toJson<String>(route),
      'direction': serializer.toJson<String>(direction),
      'number': serializer.toJson<String>(number),
      'road': serializer.toJson<String>(road),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'pendingSince': serializer.toJson<int?>(pendingSince),
    };
  }

  RouteRoadRow copyWith({
    String? rideId,
    String? uid,
    String? route,
    String? direction,
    String? number,
    String? road,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    Value<int?> pendingSince = const Value.absent(),
  }) => RouteRoadRow(
    rideId: rideId ?? this.rideId,
    uid: uid ?? this.uid,
    route: route ?? this.route,
    direction: direction ?? this.direction,
    number: number ?? this.number,
    road: road ?? this.road,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    pendingSince: pendingSince.present ? pendingSince.value : this.pendingSince,
  );
  RouteRoadRow copyWithCompanion(RouteRoadsCompanion data) {
    return RouteRoadRow(
      rideId: data.rideId.present ? data.rideId.value : this.rideId,
      uid: data.uid.present ? data.uid.value : this.uid,
      route: data.route.present ? data.route.value : this.route,
      direction: data.direction.present ? data.direction.value : this.direction,
      number: data.number.present ? data.number.value : this.number,
      road: data.road.present ? data.road.value : this.road,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      pendingSince: data.pendingSince.present
          ? data.pendingSince.value
          : this.pendingSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteRoadRow(')
          ..write('rideId: $rideId, ')
          ..write('uid: $uid, ')
          ..write('route: $route, ')
          ..write('direction: $direction, ')
          ..write('number: $number, ')
          ..write('road: $road, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rideId,
    uid,
    route,
    direction,
    number,
    road,
    updatedAt,
    deletedAt,
    pendingSince,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteRoadRow &&
          other.rideId == this.rideId &&
          other.uid == this.uid &&
          other.route == this.route &&
          other.direction == this.direction &&
          other.number == this.number &&
          other.road == this.road &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.pendingSince == this.pendingSince);
}

class RouteRoadsCompanion extends UpdateCompanion<RouteRoadRow> {
  final Value<String> rideId;
  final Value<String> uid;
  final Value<String> route;
  final Value<String> direction;
  final Value<String> number;
  final Value<String> road;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int?> pendingSince;
  final Value<int> rowid;
  const RouteRoadsCompanion({
    this.rideId = const Value.absent(),
    this.uid = const Value.absent(),
    this.route = const Value.absent(),
    this.direction = const Value.absent(),
    this.number = const Value.absent(),
    this.road = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteRoadsCompanion.insert({
    required String rideId,
    required String uid,
    required String route,
    required String direction,
    required String number,
    required String road,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.pendingSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rideId = Value(rideId),
       uid = Value(uid),
       route = Value(route),
       direction = Value(direction),
       number = Value(number),
       road = Value(road),
       updatedAt = Value(updatedAt);
  static Insertable<RouteRoadRow> custom({
    Expression<String>? rideId,
    Expression<String>? uid,
    Expression<String>? route,
    Expression<String>? direction,
    Expression<String>? number,
    Expression<String>? road,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? pendingSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rideId != null) 'ride_id': rideId,
      if (uid != null) 'uid': uid,
      if (route != null) 'route': route,
      if (direction != null) 'direction': direction,
      if (number != null) 'number': number,
      if (road != null) 'road': road,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (pendingSince != null) 'pending_since': pendingSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteRoadsCompanion copyWith({
    Value<String>? rideId,
    Value<String>? uid,
    Value<String>? route,
    Value<String>? direction,
    Value<String>? number,
    Value<String>? road,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int?>? pendingSince,
    Value<int>? rowid,
  }) {
    return RouteRoadsCompanion(
      rideId: rideId ?? this.rideId,
      uid: uid ?? this.uid,
      route: route ?? this.route,
      direction: direction ?? this.direction,
      number: number ?? this.number,
      road: road ?? this.road,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pendingSince: pendingSince ?? this.pendingSince,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rideId.present) {
      map['ride_id'] = Variable<String>(rideId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (road.present) {
      map['road'] = Variable<String>(road.value);
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
    return (StringBuffer('RouteRoadsCompanion(')
          ..write('rideId: $rideId, ')
          ..write('uid: $uid, ')
          ..write('route: $route, ')
          ..write('direction: $direction, ')
          ..write('number: $number, ')
          ..write('road: $road, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('pendingSince: $pendingSince, ')
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
  late final $RidesTable rides = $RidesTable(this);
  late final $PooledHaltsTable pooledHalts = $PooledHaltsTable(this);
  late final $StopNotesTable stopNotes = $StopNotesTable(this);
  late final $OsmStopsTable osmStops = $OsmStopsTable(this);
  late final $StopTilesTable stopTiles = $StopTilesTable(this);
  late final $StopNamesTable stopNames = $StopNamesTable(this);
  late final $RouteDataTable routeData = $RouteDataTable(this);
  late final $RouteNotesTable routeNotes = $RouteNotesTable(this);
  late final $HandRoutesTable handRoutes = $HandRoutesTable(this);
  late final $RouteRoadsTable routeRoads = $RouteRoadsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    places,
    recents,
    rides,
    pooledHalts,
    stopNotes,
    osmStops,
    stopTiles,
    stopNames,
    routeData,
    routeNotes,
    handRoutes,
    routeRoads,
    settings,
  ];
}
