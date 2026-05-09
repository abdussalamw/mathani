// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'juz.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJuzCollection on Isar {
  IsarCollection<Juz> get juzs => this.collection();
}

const JuzSchema = CollectionSchema(
  name: r'Juz',
  id: -4102876579624723299,
  properties: {
    r'endAyah': PropertySchema(
      id: 0,
      name: r'endAyah',
      type: IsarType.long,
    ),
    r'endSurah': PropertySchema(
      id: 1,
      name: r'endSurah',
      type: IsarType.long,
    ),
    r'number': PropertySchema(
      id: 2,
      name: r'number',
      type: IsarType.long,
    ),
    r'startAyah': PropertySchema(
      id: 3,
      name: r'startAyah',
      type: IsarType.long,
    ),
    r'startSurah': PropertySchema(
      id: 4,
      name: r'startSurah',
      type: IsarType.long,
    )
  },
  estimateSize: _juzEstimateSize,
  serialize: _juzSerialize,
  deserialize: _juzDeserialize,
  deserializeProp: _juzDeserializeProp,
  idName: r'id',
  indexes: {
    r'number': IndexSchema(
      id: 5012388430481709372,
      name: r'number',
      unique: false,
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
  getId: _juzGetId,
  getLinks: _juzGetLinks,
  attach: _juzAttach,
  version: '3.1.0+1',
);

int _juzEstimateSize(
  Juz object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _juzSerialize(
  Juz object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endAyah);
  writer.writeLong(offsets[1], object.endSurah);
  writer.writeLong(offsets[2], object.number);
  writer.writeLong(offsets[3], object.startAyah);
  writer.writeLong(offsets[4], object.startSurah);
}

Juz _juzDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Juz();
  object.endAyah = reader.readLong(offsets[0]);
  object.endSurah = reader.readLong(offsets[1]);
  object.id = id;
  object.number = reader.readLong(offsets[2]);
  object.startAyah = reader.readLong(offsets[3]);
  object.startSurah = reader.readLong(offsets[4]);
  return object;
}

P _juzDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _juzGetId(Juz object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _juzGetLinks(Juz object) {
  return [];
}

void _juzAttach(IsarCollection<dynamic> col, Id id, Juz object) {
  object.id = id;
}

extension JuzQueryWhereSort on QueryBuilder<Juz, Juz, QWhere> {
  QueryBuilder<Juz, Juz, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Juz, Juz, QAfterWhere> anyNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'number'),
      );
    });
  }
}

extension JuzQueryWhere on QueryBuilder<Juz, Juz, QWhereClause> {
  QueryBuilder<Juz, Juz, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Juz, Juz, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Juz, Juz, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Juz, Juz, QAfterWhereClause> idBetween(
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

  QueryBuilder<Juz, Juz, QAfterWhereClause> numberEqualTo(int number) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'number',
        value: [number],
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterWhereClause> numberNotEqualTo(int number) {
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

  QueryBuilder<Juz, Juz, QAfterWhereClause> numberGreaterThan(
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

  QueryBuilder<Juz, Juz, QAfterWhereClause> numberLessThan(
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

  QueryBuilder<Juz, Juz, QAfterWhereClause> numberBetween(
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

extension JuzQueryFilter on QueryBuilder<Juz, Juz, QFilterCondition> {
  QueryBuilder<Juz, Juz, QAfterFilterCondition> endAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endAyahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endAyahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endAyah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endSurahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endSurahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endSurahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> endSurahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endSurah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> numberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> numberGreaterThan(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> numberLessThan(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> numberBetween(
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

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startAyahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startAyahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startAyah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startAyah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startSurahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startSurahGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startSurahLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startSurah',
        value: value,
      ));
    });
  }

  QueryBuilder<Juz, Juz, QAfterFilterCondition> startSurahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startSurah',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JuzQueryObject on QueryBuilder<Juz, Juz, QFilterCondition> {}

extension JuzQueryLinks on QueryBuilder<Juz, Juz, QFilterCondition> {}

extension JuzQuerySortBy on QueryBuilder<Juz, Juz, QSortBy> {
  QueryBuilder<Juz, Juz, QAfterSortBy> sortByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByEndSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSurah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByEndSurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSurah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByStartSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSurah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> sortByStartSurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSurah', Sort.desc);
    });
  }
}

extension JuzQuerySortThenBy on QueryBuilder<Juz, Juz, QSortThenBy> {
  QueryBuilder<Juz, Juz, QAfterSortBy> thenByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByEndSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSurah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByEndSurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endSurah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByStartSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSurah', Sort.asc);
    });
  }

  QueryBuilder<Juz, Juz, QAfterSortBy> thenByStartSurahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startSurah', Sort.desc);
    });
  }
}

extension JuzQueryWhereDistinct on QueryBuilder<Juz, Juz, QDistinct> {
  QueryBuilder<Juz, Juz, QDistinct> distinctByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAyah');
    });
  }

  QueryBuilder<Juz, Juz, QDistinct> distinctByEndSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endSurah');
    });
  }

  QueryBuilder<Juz, Juz, QDistinct> distinctByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'number');
    });
  }

  QueryBuilder<Juz, Juz, QDistinct> distinctByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAyah');
    });
  }

  QueryBuilder<Juz, Juz, QDistinct> distinctByStartSurah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startSurah');
    });
  }
}

extension JuzQueryProperty on QueryBuilder<Juz, Juz, QQueryProperty> {
  QueryBuilder<Juz, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Juz, int, QQueryOperations> endAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAyah');
    });
  }

  QueryBuilder<Juz, int, QQueryOperations> endSurahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endSurah');
    });
  }

  QueryBuilder<Juz, int, QQueryOperations> numberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'number');
    });
  }

  QueryBuilder<Juz, int, QQueryOperations> startAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAyah');
    });
  }

  QueryBuilder<Juz, int, QQueryOperations> startSurahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startSurah');
    });
  }
}
