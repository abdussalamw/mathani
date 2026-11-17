// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recitation_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetRecitationSessionCollection on Isar {
  IsarCollection<RecitationSession> get recitationSessions => this.collection();
}

const RecitationSessionSchema = CollectionSchema(
  name: r'RecitationSession',
  id: 4721352295713944178,
  properties: {
    r'accuracyPercent': PropertySchema(
      id: 0,
      name: r'accuracyPercent',
      type: IsarType.long,
    ),
    r'correctWords': PropertySchema(
      id: 1,
      name: r'correctWords',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'durationSeconds': PropertySchema(
      id: 3,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'endAyah': PropertySchema(id: 4, name: r'endAyah', type: IsarType.long),
    r'mode': PropertySchema(id: 5, name: r'mode', type: IsarType.string),
    r'overallGrade': PropertySchema(
      id: 6,
      name: r'overallGrade',
      type: IsarType.string,
    ),
    r'rawTranscript': PropertySchema(
      id: 7,
      name: r'rawTranscript',
      type: IsarType.string,
    ),
    r'resultJson': PropertySchema(
      id: 8,
      name: r'resultJson',
      type: IsarType.string,
    ),
    r'startAyah': PropertySchema(
      id: 9,
      name: r'startAyah',
      type: IsarType.long,
    ),
    r'surahName': PropertySchema(
      id: 10,
      name: r'surahName',
      type: IsarType.string,
    ),
    r'surahNumber': PropertySchema(
      id: 11,
      name: r'surahNumber',
      type: IsarType.long,
    ),
    r'totalWords': PropertySchema(
      id: 12,
      name: r'totalWords',
      type: IsarType.long,
    ),
  },

  estimateSize: _recitationSessionEstimateSize,
  serialize: _recitationSessionSerialize,
  deserialize: _recitationSessionDeserialize,
  deserializeProp: _recitationSessionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _recitationSessionGetId,
  getLinks: _recitationSessionGetLinks,
  attach: _recitationSessionAttach,
  version: '3.4.1',
);

int _recitationSessionEstimateSize(
  RecitationSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.overallGrade.length * 3;
  bytesCount += 3 + object.rawTranscript.length * 3;
  {
    final value = object.resultJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.surahName.length * 3;
  return bytesCount;
}

void _recitationSessionSerialize(
  RecitationSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accuracyPercent);
  writer.writeLong(offsets[1], object.correctWords);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.durationSeconds);
  writer.writeLong(offsets[4], object.endAyah);
  writer.writeString(offsets[5], object.mode);
  writer.writeString(offsets[6], object.overallGrade);
  writer.writeString(offsets[7], object.rawTranscript);
  writer.writeString(offsets[8], object.resultJson);
  writer.writeLong(offsets[9], object.startAyah);
  writer.writeString(offsets[10], object.surahName);
  writer.writeLong(offsets[11], object.surahNumber);
  writer.writeLong(offsets[12], object.totalWords);
}

RecitationSession _recitationSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RecitationSession();
  object.accuracyPercent = reader.readLong(offsets[0]);
  object.correctWords = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.durationSeconds = reader.readLong(offsets[3]);
  object.endAyah = reader.readLong(offsets[4]);
  object.id = id;
  object.mode = reader.readString(offsets[5]);
  object.overallGrade = reader.readString(offsets[6]);
  object.rawTranscript = reader.readString(offsets[7]);
  object.resultJson = reader.readStringOrNull(offsets[8]);
  object.startAyah = reader.readLong(offsets[9]);
  object.surahName = reader.readString(offsets[10]);
  object.surahNumber = reader.readLong(offsets[11]);
  object.totalWords = reader.readLong(offsets[12]);
  return object;
}

P _recitationSessionDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _recitationSessionGetId(RecitationSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _recitationSessionGetLinks(
  RecitationSession object,
) {
  return [];
}

void _recitationSessionAttach(
  IsarCollection<dynamic> col,
  Id id,
  RecitationSession object,
) {
  object.id = id;
}

extension RecitationSessionQueryWhereSort
    on QueryBuilder<RecitationSession, RecitationSession, QWhere> {
  QueryBuilder<RecitationSession, RecitationSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RecitationSessionQueryWhere
    on QueryBuilder<RecitationSession, RecitationSession, QWhereClause> {
  QueryBuilder<RecitationSession, RecitationSession, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<RecitationSession, RecitationSession, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecitationSessionQueryFilter
    on QueryBuilder<RecitationSession, RecitationSession, QFilterCondition> {
  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  accuracyPercentEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accuracyPercent', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  accuracyPercentGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accuracyPercent',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  accuracyPercentLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accuracyPercent',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  accuracyPercentBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accuracyPercent',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  correctWordsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'correctWords', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  correctWordsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'correctWords',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  correctWordsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'correctWords',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  correctWordsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'correctWords',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationSeconds', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  durationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  durationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  endAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endAyah', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  endAyahGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  endAyahLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  endAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endAyah',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'overallGrade',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'overallGrade',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'overallGrade',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'overallGrade', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  overallGradeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'overallGrade', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawTranscript',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawTranscript',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawTranscript',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawTranscript', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  rawTranscriptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawTranscript', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resultJson'),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resultJson'),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resultJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resultJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resultJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resultJson', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  resultJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resultJson', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  startAyahEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startAyah', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  startAyahGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  startAyahLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startAyah',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  startAyahBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startAyah',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'surahName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'surahName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'surahName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surahName', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'surahName', value: ''),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surahNumber', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'surahNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'surahNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  surahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'surahNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  totalWordsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalWords', value: value),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  totalWordsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalWords',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  totalWordsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalWords',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterFilterCondition>
  totalWordsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalWords',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RecitationSessionQueryObject
    on QueryBuilder<RecitationSession, RecitationSession, QFilterCondition> {}

extension RecitationSessionQueryLinks
    on QueryBuilder<RecitationSession, RecitationSession, QFilterCondition> {}

extension RecitationSessionQuerySortBy
    on QueryBuilder<RecitationSession, RecitationSession, QSortBy> {
  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByAccuracyPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyPercent', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByAccuracyPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyPercent', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByCorrectWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByOverallGrade() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallGrade', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByOverallGradeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallGrade', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByRawTranscript() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawTranscript', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByRawTranscriptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawTranscript', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByResultJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultJson', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByResultJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultJson', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortBySurahName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahName', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortBySurahNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahName', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByTotalWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWords', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  sortByTotalWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWords', Sort.desc);
    });
  }
}

extension RecitationSessionQuerySortThenBy
    on QueryBuilder<RecitationSession, RecitationSession, QSortThenBy> {
  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByAccuracyPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyPercent', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByAccuracyPercentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracyPercent', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByCorrectWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'correctWords', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByEndAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endAyah', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByOverallGrade() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallGrade', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByOverallGradeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallGrade', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByRawTranscript() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawTranscript', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByRawTranscriptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawTranscript', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByResultJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultJson', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByResultJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultJson', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByStartAyahDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startAyah', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenBySurahName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahName', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenBySurahNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahName', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByTotalWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWords', Sort.asc);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QAfterSortBy>
  thenByTotalWordsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWords', Sort.desc);
    });
  }
}

extension RecitationSessionQueryWhereDistinct
    on QueryBuilder<RecitationSession, RecitationSession, QDistinct> {
  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByAccuracyPercent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracyPercent');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByCorrectWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'correctWords');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByEndAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endAyah');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct> distinctByMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByOverallGrade({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overallGrade', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByRawTranscript({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'rawTranscript',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByResultJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resultJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByStartAyah() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startAyah');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctBySurahName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahNumber');
    });
  }

  QueryBuilder<RecitationSession, RecitationSession, QDistinct>
  distinctByTotalWords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalWords');
    });
  }
}

extension RecitationSessionQueryProperty
    on QueryBuilder<RecitationSession, RecitationSession, QQueryProperty> {
  QueryBuilder<RecitationSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations>
  accuracyPercentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracyPercent');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations>
  correctWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'correctWords');
    });
  }

  QueryBuilder<RecitationSession, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations>
  durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations> endAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endAyah');
    });
  }

  QueryBuilder<RecitationSession, String, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<RecitationSession, String, QQueryOperations>
  overallGradeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overallGrade');
    });
  }

  QueryBuilder<RecitationSession, String, QQueryOperations>
  rawTranscriptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawTranscript');
    });
  }

  QueryBuilder<RecitationSession, String?, QQueryOperations>
  resultJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resultJson');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations> startAyahProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startAyah');
    });
  }

  QueryBuilder<RecitationSession, String, QQueryOperations>
  surahNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahName');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations> surahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahNumber');
    });
  }

  QueryBuilder<RecitationSession, int, QQueryOperations> totalWordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalWords');
    });
  }
}
