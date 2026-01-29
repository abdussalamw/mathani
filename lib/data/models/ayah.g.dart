// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAyahCollection on Isar {
  IsarCollection<Ayah> get ayahs => this.collection();
}

const AyahSchema = CollectionSchema(
  name: r'Ayah',
  id: -4601816037318021044,
  properties: {
    r'ayahNumber': PropertySchema(
      id: 0,
      name: r'ayahNumber',
      type: IsarType.long,
    ),
    r'globalNumber': PropertySchema(
      id: 1,
      name: r'globalNumber',
      type: IsarType.long,
    ),
    r'hizbQuarter': PropertySchema(
      id: 2,
      name: r'hizbQuarter',
      type: IsarType.long,
    ),
    r'isBookmarked': PropertySchema(
      id: 3,
      name: r'isBookmarked',
      type: IsarType.bool,
    ),
    r'isFavorite': PropertySchema(
      id: 4,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'juz': PropertySchema(
      id: 5,
      name: r'juz',
      type: IsarType.long,
    ),
    r'manzil': PropertySchema(
      id: 6,
      name: r'manzil',
      type: IsarType.long,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'page': PropertySchema(
      id: 8,
      name: r'page',
      type: IsarType.long,
    ),
    r'surahNumber': PropertySchema(
      id: 9,
      name: r'surahNumber',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 10,
      name: r'text',
      type: IsarType.string,
    ),
    r'textUthmani': PropertySchema(
      id: 11,
      name: r'textUthmani',
      type: IsarType.string,
    )
  },
  estimateSize: _ayahEstimateSize,
  serialize: _ayahSerialize,
  deserialize: _ayahDeserialize,
  deserializeProp: _ayahDeserializeProp,
  idName: r'id',
  indexes: {
    r'surahNumber_ayahNumber': IndexSchema(
      id: 5327427526691098780,
      name: r'surahNumber_ayahNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'surahNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'ayahNumber',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ayahGetId,
  getLinks: _ayahGetLinks,
  attach: _ayahAttach,
  version: '3.1.0+1',
);

int _ayahEstimateSize(
  Ayah object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.text.length * 3;
  {
    final value = object.textUthmani;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _ayahSerialize(
  Ayah object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.ayahNumber);
  writer.writeLong(offsets[1], object.globalNumber);
  writer.writeLong(offsets[2], object.hizbQuarter);
  writer.writeBool(offsets[3], object.isBookmarked);
  writer.writeBool(offsets[4], object.isFavorite);
  writer.writeLong(offsets[5], object.juz);
  writer.writeLong(offsets[6], object.manzil);
  writer.writeString(offsets[7], object.notes);
  writer.writeLong(offsets[8], object.page);
  writer.writeLong(offsets[9], object.surahNumber);
  writer.writeString(offsets[10], object.text);
  writer.writeString(offsets[11], object.textUthmani);
}

Ayah _ayahDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Ayah();
  object.ayahNumber = reader.readLong(offsets[0]);
  object.hizbQuarter = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.isBookmarked = reader.readBool(offsets[3]);
  object.isFavorite = reader.readBool(offsets[4]);
  object.juz = reader.readLong(offsets[5]);
  object.manzil = reader.readLongOrNull(offsets[6]);
  object.notes = reader.readStringOrNull(offsets[7]);
  object.page = reader.readLong(offsets[8]);
  object.surahNumber = reader.readLong(offsets[9]);
  object.text = reader.readString(offsets[10]);
  object.textUthmani = reader.readStringOrNull(offsets[11]);
  return object;
}

P _ayahDeserializeProp<P>(
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
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ayahGetId(Ayah object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ayahGetLinks(Ayah object) {
  return [];
}

void _ayahAttach(IsarCollection<dynamic> col, Id id, Ayah object) {
  object.id = id;
}

extension AyahQueryWhereSort on QueryBuilder<Ayah, Ayah, QWhere> {
  QueryBuilder<Ayah, Ayah, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhere> anySurahNumberAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'surahNumber_ayahNumber'),
      );
    });
  }
}

extension AyahQueryWhere on QueryBuilder<Ayah, Ayah, QWhereClause> {
  QueryBuilder<Ayah, Ayah, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> idBetween(
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

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> surahNumberEqualToAnyAyahNumber(
      int surahNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surahNumber_ayahNumber',
        value: [surahNumber],
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberNotEqualToAnyAyahNumber(int surahNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [],
              upper: [surahNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [],
              upper: [surahNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberGreaterThanAnyAyahNumber(
    int surahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [surahNumber],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> surahNumberLessThanAnyAyahNumber(
    int surahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [],
        upper: [surahNumber],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> surahNumberBetweenAnyAyahNumber(
    int lowerSurahNumber,
    int upperSurahNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [lowerSurahNumber],
        includeLower: includeLower,
        upper: [upperSurahNumber],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause> surahNumberAyahNumberEqualTo(
      int surahNumber, int ayahNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surahNumber_ayahNumber',
        value: [surahNumber, ayahNumber],
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberEqualToAyahNumberNotEqualTo(int surahNumber, int ayahNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber],
              upper: [surahNumber, ayahNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber, ayahNumber],
              includeLower: false,
              upper: [surahNumber],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber, ayahNumber],
              includeLower: false,
              upper: [surahNumber],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber_ayahNumber',
              lower: [surahNumber],
              upper: [surahNumber, ayahNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberEqualToAyahNumberGreaterThan(
    int surahNumber,
    int ayahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [surahNumber, ayahNumber],
        includeLower: include,
        upper: [surahNumber],
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberEqualToAyahNumberLessThan(
    int surahNumber,
    int ayahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [surahNumber],
        upper: [surahNumber, ayahNumber],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterWhereClause>
      surahNumberEqualToAyahNumberBetween(
    int surahNumber,
    int lowerAyahNumber,
    int upperAyahNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber_ayahNumber',
        lower: [surahNumber, lowerAyahNumber],
        includeLower: includeLower,
        upper: [surahNumber, upperAyahNumber],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AyahQueryFilter on QueryBuilder<Ayah, Ayah, QFilterCondition> {
  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> ayahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> ayahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> ayahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ayahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> ayahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ayahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> globalNumberEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'globalNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> globalNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'globalNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> globalNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'globalNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> globalNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'globalNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hizbQuarter',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hizbQuarter',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hizbQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hizbQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hizbQuarter',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> hizbQuarterBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hizbQuarter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> isBookmarkedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBookmarked',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> isFavoriteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFavorite',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> juzEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'juz',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> juzGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'juz',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> juzLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'juz',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> juzBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'juz',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'manzil',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'manzil',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'manzil',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'manzil',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'manzil',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> manzilBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'manzil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> pageEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'page',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> pageGreaterThan(
    int value, {
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> pageLessThan(
    int value, {
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> pageBetween(
    int lower,
    int upper, {
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

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> surahNumberEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> surahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> surahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> surahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'textUthmani',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'textUthmani',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textUthmani',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textUthmani',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textUthmani',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textUthmani',
        value: '',
      ));
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterFilterCondition> textUthmaniIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textUthmani',
        value: '',
      ));
    });
  }
}

extension AyahQueryObject on QueryBuilder<Ayah, Ayah, QFilterCondition> {}

extension AyahQueryLinks on QueryBuilder<Ayah, Ayah, QFilterCondition> {}

extension AyahQuerySortBy on QueryBuilder<Ayah, Ayah, QSortBy> {
  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByGlobalNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByGlobalNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByHizbQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hizbQuarter', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByHizbQuarterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hizbQuarter', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByIsBookmarked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmarked', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByIsBookmarkedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmarked', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByJuz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juz', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByJuzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juz', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByManzil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manzil', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByManzilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manzil', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByTextUthmani() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textUthmani', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> sortByTextUthmaniDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textUthmani', Sort.desc);
    });
  }
}

extension AyahQuerySortThenBy on QueryBuilder<Ayah, Ayah, QSortThenBy> {
  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByAyahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ayahNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByGlobalNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByGlobalNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'globalNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByHizbQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hizbQuarter', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByHizbQuarterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hizbQuarter', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByIsBookmarked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmarked', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByIsBookmarkedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBookmarked', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByJuz() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juz', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByJuzDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'juz', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByManzil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manzil', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByManzilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manzil', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'page', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'text', Sort.desc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByTextUthmani() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textUthmani', Sort.asc);
    });
  }

  QueryBuilder<Ayah, Ayah, QAfterSortBy> thenByTextUthmaniDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textUthmani', Sort.desc);
    });
  }
}

extension AyahQueryWhereDistinct on QueryBuilder<Ayah, Ayah, QDistinct> {
  QueryBuilder<Ayah, Ayah, QDistinct> distinctByAyahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ayahNumber');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByGlobalNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'globalNumber');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByHizbQuarter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hizbQuarter');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByIsBookmarked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBookmarked');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByJuz() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'juz');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByManzil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'manzil');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'page');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahNumber');
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'text', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ayah, Ayah, QDistinct> distinctByTextUthmani(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textUthmani', caseSensitive: caseSensitive);
    });
  }
}

extension AyahQueryProperty on QueryBuilder<Ayah, Ayah, QQueryProperty> {
  QueryBuilder<Ayah, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Ayah, int, QQueryOperations> ayahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ayahNumber');
    });
  }

  QueryBuilder<Ayah, int, QQueryOperations> globalNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'globalNumber');
    });
  }

  QueryBuilder<Ayah, int?, QQueryOperations> hizbQuarterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hizbQuarter');
    });
  }

  QueryBuilder<Ayah, bool, QQueryOperations> isBookmarkedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBookmarked');
    });
  }

  QueryBuilder<Ayah, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<Ayah, int, QQueryOperations> juzProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'juz');
    });
  }

  QueryBuilder<Ayah, int?, QQueryOperations> manzilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manzil');
    });
  }

  QueryBuilder<Ayah, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<Ayah, int, QQueryOperations> pageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'page');
    });
  }

  QueryBuilder<Ayah, int, QQueryOperations> surahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahNumber');
    });
  }

  QueryBuilder<Ayah, String, QQueryOperations> textProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'text');
    });
  }

  QueryBuilder<Ayah, String?, QQueryOperations> textUthmaniProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textUthmani');
    });
  }
}
