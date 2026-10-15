// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_database.dart';

// ignore_for_file: type=lint
class $DisksTable extends Disks with TableInfo<$DisksTable, DiskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, label, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $DisksTable createAlias(String alias) {
    return $DisksTable(attachedDatabase, alias);
  }
}

class DiskRow extends DataClass implements Insertable<DiskRow> {
  final int id;

  /// Stable identifier (BR-004): fixed for the internal storage, filesystem
  /// UUID for a removable disk.
  final String key;
  final String label;

  /// `DiskKind.index`.
  final int kind;
  const DiskRow({
    required this.id,
    required this.key,
    required this.label,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['label'] = Variable<String>(label);
    map['kind'] = Variable<int>(kind);
    return map;
  }

  DisksCompanion toCompanion(bool nullToAbsent) {
    return DisksCompanion(
      id: Value(id),
      key: Value(key),
      label: Value(label),
      kind: Value(kind),
    );
  }

  factory DiskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiskRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      label: serializer.fromJson<String>(json['label']),
      kind: serializer.fromJson<int>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<int>(kind),
    };
  }

  DiskRow copyWith({int? id, String? key, String? label, int? kind}) => DiskRow(
    id: id ?? this.id,
    key: key ?? this.key,
    label: label ?? this.label,
    kind: kind ?? this.kind,
  );
  DiskRow copyWithCompanion(DisksCompanion data) {
    return DiskRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiskRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, label, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiskRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.label == this.label &&
          other.kind == this.kind);
}

class DisksCompanion extends UpdateCompanion<DiskRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> label;
  final Value<int> kind;
  const DisksCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
  });
  DisksCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String label,
    required int kind,
  }) : key = Value(key),
       label = Value(label),
       kind = Value(kind);
  static Insertable<DiskRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? label,
    Expression<int>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
    });
  }

  DisksCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? label,
    Value<int>? kind,
  }) {
    return DisksCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      label: label ?? this.label,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisksCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('label: $label, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

class $DiskFoldersTable extends DiskFolders
    with TableInfo<$DiskFoldersTable, DiskFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiskFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _diskIdMeta = const VerificationMeta('diskId');
  @override
  late final GeneratedColumn<int> diskId = GeneratedColumn<int>(
    'disk_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disks (id)',
    ),
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [diskId, relativePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disk_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiskFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('disk_id')) {
      context.handle(
        _diskIdMeta,
        diskId.isAcceptableOrUnknown(data['disk_id']!, _diskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diskIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {diskId, relativePath};
  @override
  DiskFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiskFolderRow(
      diskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disk_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
    );
  }

  @override
  $DiskFoldersTable createAlias(String alias) {
    return $DiskFoldersTable(attachedDatabase, alias);
  }
}

class DiskFolderRow extends DataClass implements Insertable<DiskFolderRow> {
  final int diskId;
  final String relativePath;
  const DiskFolderRow({required this.diskId, required this.relativePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['disk_id'] = Variable<int>(diskId);
    map['relative_path'] = Variable<String>(relativePath);
    return map;
  }

  DiskFoldersCompanion toCompanion(bool nullToAbsent) {
    return DiskFoldersCompanion(
      diskId: Value(diskId),
      relativePath: Value(relativePath),
    );
  }

  factory DiskFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiskFolderRow(
      diskId: serializer.fromJson<int>(json['diskId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'diskId': serializer.toJson<int>(diskId),
      'relativePath': serializer.toJson<String>(relativePath),
    };
  }

  DiskFolderRow copyWith({int? diskId, String? relativePath}) => DiskFolderRow(
    diskId: diskId ?? this.diskId,
    relativePath: relativePath ?? this.relativePath,
  );
  DiskFolderRow copyWithCompanion(DiskFoldersCompanion data) {
    return DiskFolderRow(
      diskId: data.diskId.present ? data.diskId.value : this.diskId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiskFolderRow(')
          ..write('diskId: $diskId, ')
          ..write('relativePath: $relativePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(diskId, relativePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiskFolderRow &&
          other.diskId == this.diskId &&
          other.relativePath == this.relativePath);
}

class DiskFoldersCompanion extends UpdateCompanion<DiskFolderRow> {
  final Value<int> diskId;
  final Value<String> relativePath;
  final Value<int> rowid;
  const DiskFoldersCompanion({
    this.diskId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiskFoldersCompanion.insert({
    required int diskId,
    required String relativePath,
    this.rowid = const Value.absent(),
  }) : diskId = Value(diskId),
       relativePath = Value(relativePath);
  static Insertable<DiskFolderRow> custom({
    Expression<int>? diskId,
    Expression<String>? relativePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (diskId != null) 'disk_id': diskId,
      if (relativePath != null) 'relative_path': relativePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiskFoldersCompanion copyWith({
    Value<int>? diskId,
    Value<String>? relativePath,
    Value<int>? rowid,
  }) {
    return DiskFoldersCompanion(
      diskId: diskId ?? this.diskId,
      relativePath: relativePath ?? this.relativePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (diskId.present) {
      map['disk_id'] = Variable<int>(diskId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiskFoldersCompanion(')
          ..write('diskId: $diskId, ')
          ..write('relativePath: $relativePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, TrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _diskIdMeta = const VerificationMeta('diskId');
  @override
  late final GeneratedColumn<int> diskId = GeneratedColumn<int>(
    'disk_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES disks (id)',
    ),
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diskId,
    relativePath,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    discNumber,
    year,
    genre,
    durationMs,
    size,
    modifiedAt,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('disk_id')) {
      context.handle(
        _diskIdMeta,
        diskId.isAcceptableOrUnknown(data['disk_id']!, _diskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diskIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {diskId, relativePath},
  ];
  @override
  TrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      diskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disk_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class TrackRow extends DataClass implements Insertable<TrackRow> {
  final int id;
  final int diskId;
  final String relativePath;
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int? durationMs;
  final int size;
  final DateTime modifiedAt;
  final DateTime indexedAt;
  const TrackRow({
    required this.id,
    required this.diskId,
    required this.relativePath,
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.durationMs,
    required this.size,
    required this.modifiedAt,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['disk_id'] = Variable<int>(diskId);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['size'] = Variable<int>(size);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      diskId: Value(diskId),
      relativePath: Value(relativePath),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      size: Value(size),
      modifiedAt: Value(modifiedAt),
      indexedAt: Value(indexedAt),
    );
  }

  factory TrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackRow(
      id: serializer.fromJson<int>(json['id']),
      diskId: serializer.fromJson<int>(json['diskId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      title: serializer.fromJson<String?>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String?>(json['genre']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      size: serializer.fromJson<int>(json['size']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'diskId': serializer.toJson<int>(diskId),
      'relativePath': serializer.toJson<String>(relativePath),
      'title': serializer.toJson<String?>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String?>(genre),
      'durationMs': serializer.toJson<int?>(durationMs),
      'size': serializer.toJson<int>(size),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  TrackRow copyWith({
    int? id,
    int? diskId,
    String? relativePath,
    Value<String?> title = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    int? size,
    DateTime? modifiedAt,
    DateTime? indexedAt,
  }) => TrackRow(
    id: id ?? this.id,
    diskId: diskId ?? this.diskId,
    relativePath: relativePath ?? this.relativePath,
    title: title.present ? title.value : this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    year: year.present ? year.value : this.year,
    genre: genre.present ? genre.value : this.genre,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    size: size ?? this.size,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  TrackRow copyWithCompanion(TracksCompanion data) {
    return TrackRow(
      id: data.id.present ? data.id.value : this.id,
      diskId: data.diskId.present ? data.diskId.value : this.diskId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      size: data.size.present ? data.size.value : this.size,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackRow(')
          ..write('id: $id, ')
          ..write('diskId: $diskId, ')
          ..write('relativePath: $relativePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diskId,
    relativePath,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    discNumber,
    year,
    genre,
    durationMs,
    size,
    modifiedAt,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackRow &&
          other.id == this.id &&
          other.diskId == this.diskId &&
          other.relativePath == this.relativePath &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.albumArtist == this.albumArtist &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.durationMs == this.durationMs &&
          other.size == this.size &&
          other.modifiedAt == this.modifiedAt &&
          other.indexedAt == this.indexedAt);
}

class TracksCompanion extends UpdateCompanion<TrackRow> {
  final Value<int> id;
  final Value<int> diskId;
  final Value<String> relativePath;
  final Value<String?> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<String?> albumArtist;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> year;
  final Value<String?> genre;
  final Value<int?> durationMs;
  final Value<int> size;
  final Value<DateTime> modifiedAt;
  final Value<DateTime> indexedAt;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.diskId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.size = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required int diskId,
    required String relativePath,
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.durationMs = const Value.absent(),
    required int size,
    required DateTime modifiedAt,
    required DateTime indexedAt,
  }) : diskId = Value(diskId),
       relativePath = Value(relativePath),
       size = Value(size),
       modifiedAt = Value(modifiedAt),
       indexedAt = Value(indexedAt);
  static Insertable<TrackRow> custom({
    Expression<int>? id,
    Expression<int>? diskId,
    Expression<String>? relativePath,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? albumArtist,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<int>? durationMs,
    Expression<int>? size,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diskId != null) 'disk_id': diskId,
      if (relativePath != null) 'relative_path': relativePath,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (durationMs != null) 'duration_ms': durationMs,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<int>? diskId,
    Value<String>? relativePath,
    Value<String?>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<String?>? albumArtist,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? year,
    Value<String?>? genre,
    Value<int?>? durationMs,
    Value<int>? size,
    Value<DateTime>? modifiedAt,
    Value<DateTime>? indexedAt,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      diskId: diskId ?? this.diskId,
      relativePath: relativePath ?? this.relativePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (diskId.present) {
      map['disk_id'] = Variable<int>(diskId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('diskId: $diskId, ')
          ..write('relativePath: $relativePath, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('durationMs: $durationMs, ')
          ..write('size: $size, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $DisksTable disks = $DisksTable(this);
  late final $DiskFoldersTable diskFolders = $DiskFoldersTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    disks,
    diskFolders,
    tracks,
  ];
}

typedef $$DisksTableCreateCompanionBuilder = DisksCompanion Function({
  Value<int> id,
  required String key,
  required String label,
  required int kind,
});
typedef $$DisksTableUpdateCompanionBuilder = DisksCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> label,
  Value<int> kind,
});

final class $$DisksTableReferences
    extends BaseReferences<_$LibraryDatabase, $DisksTable, DiskRow> {
  $$DisksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DiskFoldersTable, List<DiskFolderRow>>
  _diskFoldersRefsTable(_$LibraryDatabase db) => MultiTypedResultKey.fromTable(
    db.diskFolders,
    aliasName: 'disks__id__disk_folders__disk_id',
  );

  $$DiskFoldersTableProcessedTableManager get diskFoldersRefs {
    final manager = $$DiskFoldersTableTableManager(
      $_db,
      $_db.diskFolders,
    ).filter((f) => f.diskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_diskFoldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TracksTable, List<TrackRow>> _tracksRefsTable(
    _$LibraryDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: 'disks__id__tracks__disk_id',
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.diskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DisksTableFilterComposer
    extends Composer<_$LibraryDatabase, $DisksTable> {
  $$DisksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> diskFoldersRefs(
    Expression<bool> Function($$DiskFoldersTableFilterComposer f) f,
  ) {
    final $$DiskFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diskFolders,
      getReferencedColumn: (t) => t.diskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiskFoldersTableFilterComposer(
            $db: $db,
            $table: $db.diskFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.diskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DisksTableOrderingComposer
    extends Composer<_$LibraryDatabase, $DisksTable> {
  $$DisksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DisksTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $DisksTable> {
  $$DisksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  Expression<T> diskFoldersRefs<T extends Object>(
    Expression<T> Function($$DiskFoldersTableAnnotationComposer a) f,
  ) {
    final $$DiskFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.diskFolders,
      getReferencedColumn: (t) => t.diskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiskFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.diskFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.diskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DisksTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $DisksTable,
          DiskRow,
          $$DisksTableFilterComposer,
          $$DisksTableOrderingComposer,
          $$DisksTableAnnotationComposer,
          $$DisksTableCreateCompanionBuilder,
          $$DisksTableUpdateCompanionBuilder,
          (DiskRow, $$DisksTableReferences),
          DiskRow,
          PrefetchHooks Function({bool diskFoldersRefs, bool tracksRefs})
        > {
  $$DisksTableTableManager(_$LibraryDatabase db, $DisksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> kind = const Value.absent(),
          }) => DisksCompanion(id: id, key: key, label: label, kind: kind),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String label,
                required int kind,
              }) => DisksCompanion.insert(
                id: id,
                key: key,
                label: label,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DisksTable, DiskRow>(table),
                  $$DisksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({diskFoldersRefs = false, tracksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (diskFoldersRefs) db.diskFolders,
                    if (tracksRefs) db.tracks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (diskFoldersRefs)
                        await $_getPrefetchedData<
                          DiskRow,
                          $DisksTable,
                          DiskFolderRow
                        >(
                          currentTable: table,
                          referencedTable: $$DisksTableReferences
                              ._diskFoldersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisksTableReferences(
                                db,
                                table,
                                p0,
                              ).diskFoldersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tracksRefs)
                        await $_getPrefetchedData<
                          DiskRow,
                          $DisksTable,
                          TrackRow
                        >(
                          currentTable: table,
                          referencedTable: $$DisksTableReferences
                              ._tracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DisksTableReferences(db, table, p0).tracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DisksTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $DisksTable,
      DiskRow,
      $$DisksTableFilterComposer,
      $$DisksTableOrderingComposer,
      $$DisksTableAnnotationComposer,
      $$DisksTableCreateCompanionBuilder,
      $$DisksTableUpdateCompanionBuilder,
      (DiskRow, $$DisksTableReferences),
      DiskRow,
      PrefetchHooks Function({bool diskFoldersRefs, bool tracksRefs})
    >;
typedef $$DiskFoldersTableCreateCompanionBuilder =
    DiskFoldersCompanion Function({
      required int diskId,
      required String relativePath,
      Value<int> rowid,
    });
typedef $$DiskFoldersTableUpdateCompanionBuilder =
    DiskFoldersCompanion Function({
      Value<int> diskId,
      Value<String> relativePath,
      Value<int> rowid,
    });

final class $$DiskFoldersTableReferences
    extends
        BaseReferences<_$LibraryDatabase, $DiskFoldersTable, DiskFolderRow> {
  $$DiskFoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DisksTable _diskIdTable(_$LibraryDatabase db) =>
      db.disks.createAlias('disk_folders__disk_id__disks__id');

  $$DisksTableProcessedTableManager get diskId {
    final $_column = $_itemColumn<int>('disk_id')!;

    final manager = $$DisksTableTableManager(
      $_db,
      $_db.disks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DiskFoldersTableFilterComposer
    extends Composer<_$LibraryDatabase, $DiskFoldersTable> {
  $$DiskFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  $$DisksTableFilterComposer get diskId {
    final $$DisksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableFilterComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiskFoldersTableOrderingComposer
    extends Composer<_$LibraryDatabase, $DiskFoldersTable> {
  $$DiskFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisksTableOrderingComposer get diskId {
    final $$DisksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableOrderingComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiskFoldersTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $DiskFoldersTable> {
  $$DiskFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  $$DisksTableAnnotationComposer get diskId {
    final $$DisksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableAnnotationComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DiskFoldersTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $DiskFoldersTable,
          DiskFolderRow,
          $$DiskFoldersTableFilterComposer,
          $$DiskFoldersTableOrderingComposer,
          $$DiskFoldersTableAnnotationComposer,
          $$DiskFoldersTableCreateCompanionBuilder,
          $$DiskFoldersTableUpdateCompanionBuilder,
          (DiskFolderRow, $$DiskFoldersTableReferences),
          DiskFolderRow,
          PrefetchHooks Function({bool diskId})
        > {
  $$DiskFoldersTableTableManager(_$LibraryDatabase db, $DiskFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiskFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiskFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiskFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> diskId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiskFoldersCompanion(
                diskId: diskId,
                relativePath: relativePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int diskId,
                required String relativePath,
                Value<int> rowid = const Value.absent(),
              }) => DiskFoldersCompanion.insert(
                diskId: diskId,
                relativePath: relativePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiskFoldersTable, DiskFolderRow>(table),
                  $$DiskFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diskId = false}) {
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
                    if (diskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diskId,
                        referencedTable: $$DiskFoldersTableReferences
                            ._diskIdTable(db),
                        referencedColumn: $$DiskFoldersTableReferences
                            ._diskIdTable(db)
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

typedef $$DiskFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $DiskFoldersTable,
      DiskFolderRow,
      $$DiskFoldersTableFilterComposer,
      $$DiskFoldersTableOrderingComposer,
      $$DiskFoldersTableAnnotationComposer,
      $$DiskFoldersTableCreateCompanionBuilder,
      $$DiskFoldersTableUpdateCompanionBuilder,
      (DiskFolderRow, $$DiskFoldersTableReferences),
      DiskFolderRow,
      PrefetchHooks Function({bool diskId})
    >;
typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required int diskId,
  required String relativePath,
  Value<String?> title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  Value<String?> genre,
  Value<int?> durationMs,
  required int size,
  required DateTime modifiedAt,
  required DateTime indexedAt,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<int> diskId,
  Value<String> relativePath,
  Value<String?> title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int?> year,
  Value<String?> genre,
  Value<int?> durationMs,
  Value<int> size,
  Value<DateTime> modifiedAt,
  Value<DateTime> indexedAt,
});

final class $$TracksTableReferences
    extends BaseReferences<_$LibraryDatabase, $TracksTable, TrackRow> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DisksTable _diskIdTable(_$LibraryDatabase db) =>
      db.disks.createAlias('tracks__disk_id__disks__id');

  $$DisksTableProcessedTableManager get diskId {
    final $_column = $_itemColumn<int>('disk_id')!;

    final manager = $$DisksTableTableManager(
      $_db,
      $_db.disks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$LibraryDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DisksTableFilterComposer get diskId {
    final $$DisksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableFilterComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$LibraryDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DisksTableOrderingComposer get diskId {
    final $$DisksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableOrderingComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  $$DisksTableAnnotationComposer get diskId {
    final $$DisksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diskId,
      referencedTable: $db.disks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DisksTableAnnotationComposer(
            $db: $db,
            $table: $db.disks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $TracksTable,
          TrackRow,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (TrackRow, $$TracksTableReferences),
          TrackRow,
          PrefetchHooks Function({bool diskId})
        > {
  $$TracksTableTableManager(_$LibraryDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> diskId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                diskId: diskId,
                relativePath: relativePath,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                durationMs: durationMs,
                size: size,
                modifiedAt: modifiedAt,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int diskId,
                required String relativePath,
                Value<String?> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                required int size,
                required DateTime modifiedAt,
                required DateTime indexedAt,
              }) => TracksCompanion.insert(
                id: id,
                diskId: diskId,
                relativePath: relativePath,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                durationMs: durationMs,
                size: size,
                modifiedAt: modifiedAt,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, TrackRow>(table),
                  $$TracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diskId = false}) {
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
                    if (diskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.diskId,
                        referencedTable: $$TracksTableReferences._diskIdTable(
                          db,
                        ),
                        referencedColumn: $$TracksTableReferences
                            ._diskIdTable(db)
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

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $TracksTable,
      TrackRow,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (TrackRow, $$TracksTableReferences),
      TrackRow,
      PrefetchHooks Function({bool diskId})
    >;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$DisksTableTableManager get disks =>
      $$DisksTableTableManager(_db, _db.disks);
  $$DiskFoldersTableTableManager get diskFolders =>
      $$DiskFoldersTableTableManager(_db, _db.diskFolders);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
}
