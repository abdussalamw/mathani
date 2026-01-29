// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSurahCollection on Isar {
  IsarCollection<Surah> get surahs => this.collection();
}

const SurahSchema = CollectionSchema(
  name: r'Surah',
  id: -5819800798527960797,
  properties: {
    r'isFavorite': PropertySchema(
      id: 0,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'juzEnd': PropertySchema(
      id: 1,
      name: r'juzEnd',
      type: IsarType.long,
    ),
    r'juzStart': PropertySchema(
      id: 2,
      name: r'juzStart',
      type: IsarType.long,
    ),
    r'lastReadAyah': PropertySchema(
      id: 3,
      name: r'lastReadAyah',
      type: IsarType.long,
    ),
    r'lastReadTime': PropertySchema(
      id: 4,
      name: r'lastReadTime',
      type: IsarType.dateTime,
    ),
    r'nameArabic': PropertySchema(
      id: 5,
      name: r'nameArabic',
      type: IsarType.string,
    ),
    r'nameEnglish': PropertySchema(
      id: 6,
      name: r'nameEnglish',
      type: IsarType.string,
    ),
    r'nameEnglishTranslation': PropertySchema(
      id: 7,
      name: r'nameEnglishTranslation',
      type: IsarType.string,
    ),
    r'number': PropertySchema(
      id: 8,
      name: r'number',
      type: IsarType.long,
    ),
    r'numberOfAyahs': PropertySchema(
      id: 9,
      name: r'numberOfAyahs',
      type: IsarType.long,
    ),
    r'page': PropertySchema(
      id: 10,
      name: r'page',
      type: IsarType.long,
    ),
    r'revelationType': PropertySchema(
      id: 11,
      name: r'revelationType',
      type: IsarType.string,
    )
  },
  estimateSize: _surahEstimateSize,
  serialize: _surahSerialize,
  deserialize: _surahDeserialize,
  deserializeProp: _surahDeserializeProp,
  idName: r'id',
  indexes: {
    r'number': IndexSchema(
      id: 5012388430481709372,
      name: r'number',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'number',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _surahGetId,
  getLinks: _surahGetLinks,
  attach: _surahAttach,
  version: '3.1.0+1',
);

int _surahEstimateSize(
  Surah object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nameArabic.length * 3;
  bytesCount += 3 + object.nameEnglish.length * 3;
  bytesCount += 3 + object.nameEnglishTranslation.length * 3;
  bytesCount += 3 + object.revelationType.length * 3;
  return bytesCount;
}

void _surahSerialize(
  Surah object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isFavorite);
  writer.writeLong(offsets[1], object.juzEnd);
  writer.writeLong(offsets[2], object.juzStart);
  writer.writeLong(offsets[3], object.lastReadAyah);
  writer.writeDateTime(offsets[4], object.lastReadTime);
  writer.writeString(offsets[5], object.nameArabic);
  writer.writeString(offsets[6], object.nameEnglish);
  writer.writeString(offsets[7], object.nameEnglishTranslation);
  writer.writeLong(offsets[8], object.number);
  writer.writeLong(offsets[9], object.numberOfAyahs);
  writer.writeLong(offsets[10], object.page);
  writer.writeString(offsets[11], object.revelationType);
}

Surah _surahDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Surah();
  object.id = id;
  object.isFavorite = reader.readBool(offsets[0]);
  object.juzEnd = reader.readLongOrNull(offsets[1]);
  object.juzStart = reader.readLongOrNull(offsets[2]);
  object.lastReadAyah = reader.readLong(offsets[3]);
  object.lastReadTime = reader.readDateTimeOrNull(offsets[4]);
  object.nameArabic = reader.readString(offsets[5]);
  object.nameEnglish = reader.readString(offsets[6]);
  object.nameEnglishTranslation = reader.readString(offsets[7]);
  object.number = reader.readLong(offsets[8]);
  object.numberOfAyahs = reader.readLong(offsets[9]);
  object.page = reader.readLongOrNull(offsets[10]);
  object.revelationType = reader.readString(offsets[11]);
  return object;
}

P _surahDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _surahGetId(Surah object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _surahGetLinks(Surah object) {
  return [];
}

void _surahAttach(IsarCollection<dynamic> col, Id id, Surah object) {
  object.id = id;
}

extension SurahByIndex on IsarCollection<Surah> {
  Future<Surah?> getByNumber(int number) {
    return getByIndex(r'number', [number]);
  }

  Surah? getByNumberSync(int number) {
    return getByIndexSync(r'number', [number]);
  }

  Future<bool> deleteByNumber(int number) {
    return deleteByIndex(r'number', [number]);
  }

  bool deleteByNumberSync(int number) {
    return deleteByIndexSync(r'number', [number]);
  }

  Future<List<Surah?>> getAllByNumber(List<int> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return getAllByIndex(r'number', values);
  }

  List<Surah?> getAllByNumberSync(List<int> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'number', values);
  }

  Future<int> deleteAllByNumber(List<int> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'number', values);
  }

  int deleteAllByNumberSync(List<int> numberValues) {
    final values = numberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'number', values);
  }

  Future<Id> putByNumber(Surah object) {
    return putByIndex(r'number', object);
  }

  Id putByNumberSync(Surah object, {bool saveLinks = true}) {
    return putByIndexSync(r'number', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNumber(List<Surah> objects) {
    return putAllByIndex(r'number', objects);
  }

  List<Id> putAllByNumberSync(List<Surah> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'number', objects, saveLinks: saveLinks);
  }
}

extension SurahQueryWhereSort on QueryBuilder<Surah, Surah, QWhere> {
  QueryBuilder<Surah, Surah, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhere> anyNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'number'),
      );
    });
  }
}

extension SurahQueryWhere on QueryBuilder<Surah, Surah, QWhereClause> {
  QueryBuilder<Surah, Surah, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> numberEqualTo(int number) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'number',
        value: [number],
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> numberNotEqualTo(int number) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [],
              upper: [number],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [number],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [number],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'number',
              lower: [],
              upper: [number],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> numberGreaterThan(
    int number, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'number',
        lower: [number],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> numberLessThan(
    int number, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'number',
        lower: [],
        upper: [number],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> numberBetween(
    int lowerNumber,
    int upperNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'number',
        lower: [lowerNumber],
        includeLower: includeLower,
        upper: [upperNumber],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SurahQueryFilter on QueryBuilder<Surah, Surah, QFilterCondition> {
  QueryBuilder<Surah, Surah, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> isFavoriteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'juzEnd',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'juzEnd',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'juzEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'juzEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'juzEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzEndBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'juzEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'juzStart',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'juzStart',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'juzStart',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'juzStart',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'juzStart',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> juzStartBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'juzStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadAyahEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReadAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadAyahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReadAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadAyahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReadAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReadAyah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastReadTime',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastReadTime',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReadTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> lastReadTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReadTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameArabic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameArabic',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameEnglish',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEnglish',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameEnglishTranslation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEnglishTranslation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEnglishTranslation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglishTranslation',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition>
      nameEnglishTranslationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEnglishTranslation',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'number',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'number',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'number',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfAyahsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberOfAyahs',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfAyahsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numberOfAyahs',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfAyahsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numberOfAyahs',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfAyahsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numberOfAyahs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'page',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> pageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'page',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'revelationType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'revelationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'revelationType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'revelationType',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> revelationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'revelationType',
        value: '',
      ));
    });
  }
}

extension SurahQueryObject on QueryBuilder<Surah, Surah, QFilterCondition> {}

extension SurahQueryLinks on QueryBuilder<Surah, Surah, QFilterCondition> {}

extension SurahQuerySortBy on QueryBuilder<Surah, Surah, QSortBy> {
  QueryBuilder<Surah, Surah, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByJuzEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzEnd', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByJuzEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzEnd', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByJuzStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzStart', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByJuzStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzStart', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByLastReadAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAyah', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByLastReadAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAyah', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByLastReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadTime', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByLastReadTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadTime', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglishTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglishTranslation', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglishTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglishTranslation', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumberOfAyahs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfAyahs', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumberOfAyahsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfAyahs', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByRevelationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revelationType', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByRevelationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revelationType', Sort.desc);
    });
  }
}

extension SurahQuerySortThenBy on QueryBuilder<Surah, Surah, QSortThenBy> {
  QueryBuilder<Surah, Surah, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByJuzEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzEnd', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByJuzEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzEnd', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByJuzStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzStart', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByJuzStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juzStart', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByLastReadAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAyah', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByLastReadAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAyah', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByLastReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadTime', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByLastReadTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadTime', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglishTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglishTranslation', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglishTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglishTranslation', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumberOfAyahs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfAyahs', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumberOfAyahsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfAyahs', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByRevelationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revelationType', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByRevelationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revelationType', Sort.desc);
    });
  }
}

extension SurahQueryWhereDistinct on QueryBuilder<Surah, Surah, QDistinct> {
  QueryBuilder<Surah, Surah, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByJuzEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'juzEnd');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByJuzStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'juzStart');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByLastReadAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReadAyah');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByLastReadTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReadTime');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNameArabic(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameArabic', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNameEnglish(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEnglish', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNameEnglishTranslation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEnglishTranslation',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'number');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNumberOfAyahs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberOfAyahs');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'page');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByRevelationType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'revelationType',
          caseSensitive: caseSensitive);
    });
  }
}

extension SurahQueryProperty on QueryBuilder<Surah, Surah, QQueryProperty> {
  QueryBuilder<Surah, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Surah, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<Surah, int?, QQueryOperations> juzEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'juzEnd');
    });
  }

  QueryBuilder<Surah, int?, QQueryOperations> juzStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'juzStart');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> lastReadAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReadAyah');
    });
  }

  QueryBuilder<Surah, DateTime?, QQueryOperations> lastReadTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReadTime');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations> nameArabicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameArabic');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations> nameEnglishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEnglish');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations>
      nameEnglishTranslationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEnglishTranslation');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> numberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'number');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> numberOfAyahsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberOfAyahs');
    });
  }

  QueryBuilder<Surah, int?, QQueryOperations> pageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'page');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations> revelationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'revelationType');
    });
  }
}
