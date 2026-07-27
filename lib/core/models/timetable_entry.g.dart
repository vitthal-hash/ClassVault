// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimetableEntryCollection on Isar {
  IsarCollection<TimetableEntry> get timetableEntrys => this.collection();
}

const TimetableEntrySchema = CollectionSchema(
  name: r'TimetableEntry',
  id: 2359161738487326219,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'day': PropertySchema(
      id: 1,
      name: r'day',
      type: IsarType.byte,
      enumMap: _TimetableEntrydayEnumValueMap,
    ),
    r'endMinutes': PropertySchema(
      id: 2,
      name: r'endMinutes',
      type: IsarType.long,
    ),
    r'room': PropertySchema(
      id: 3,
      name: r'room',
      type: IsarType.string,
    ),
    r'semesterId': PropertySchema(
      id: 4,
      name: r'semesterId',
      type: IsarType.long,
    ),
    r'sessionType': PropertySchema(
      id: 5,
      name: r'sessionType',
      type: IsarType.byte,
      enumMap: _TimetableEntrysessionTypeEnumValueMap,
    ),
    r'startMinutes': PropertySchema(
      id: 6,
      name: r'startMinutes',
      type: IsarType.long,
    ),
    r'subjectId': PropertySchema(
      id: 7,
      name: r'subjectId',
      type: IsarType.long,
    ),
    r'teacherId': PropertySchema(
      id: 8,
      name: r'teacherId',
      type: IsarType.long,
    )
  },
  estimateSize: _timetableEntryEstimateSize,
  serialize: _timetableEntrySerialize,
  deserialize: _timetableEntryDeserialize,
  deserializeProp: _timetableEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'semesterId': IndexSchema(
      id: -4385212551819087598,
      name: r'semesterId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'semesterId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'subjectId': IndexSchema(
      id: 440306668014799972,
      name: r'subjectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'subjectId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _timetableEntryGetId,
  getLinks: _timetableEntryGetLinks,
  attach: _timetableEntryAttach,
  version: '3.1.0+1',
);

int _timetableEntryEstimateSize(
  TimetableEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.room;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _timetableEntrySerialize(
  TimetableEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeByte(offsets[1], object.day.index);
  writer.writeLong(offsets[2], object.endMinutes);
  writer.writeString(offsets[3], object.room);
  writer.writeLong(offsets[4], object.semesterId);
  writer.writeByte(offsets[5], object.sessionType.index);
  writer.writeLong(offsets[6], object.startMinutes);
  writer.writeLong(offsets[7], object.subjectId);
  writer.writeLong(offsets[8], object.teacherId);
}

TimetableEntry _timetableEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimetableEntry();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.day =
      _TimetableEntrydayValueEnumMap[reader.readByteOrNull(offsets[1])] ??
          Weekday.monday;
  object.endMinutes = reader.readLong(offsets[2]);
  object.id = id;
  object.room = reader.readStringOrNull(offsets[3]);
  object.semesterId = reader.readLong(offsets[4]);
  object.sessionType = _TimetableEntrysessionTypeValueEnumMap[
          reader.readByteOrNull(offsets[5])] ??
      SessionType.theory;
  object.startMinutes = reader.readLong(offsets[6]);
  object.subjectId = reader.readLong(offsets[7]);
  object.teacherId = reader.readLongOrNull(offsets[8]);
  return object;
}

P _timetableEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_TimetableEntrydayValueEnumMap[reader.readByteOrNull(offset)] ??
          Weekday.monday) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_TimetableEntrysessionTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SessionType.theory) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TimetableEntrydayEnumValueMap = {
  'monday': 0,
  'tuesday': 1,
  'wednesday': 2,
  'thursday': 3,
  'friday': 4,
  'saturday': 5,
  'sunday': 6,
};
const _TimetableEntrydayValueEnumMap = {
  0: Weekday.monday,
  1: Weekday.tuesday,
  2: Weekday.wednesday,
  3: Weekday.thursday,
  4: Weekday.friday,
  5: Weekday.saturday,
  6: Weekday.sunday,
};
const _TimetableEntrysessionTypeEnumValueMap = {
  'theory': 0,
  'lab': 1,
  'tutorial': 2,
};
const _TimetableEntrysessionTypeValueEnumMap = {
  0: SessionType.theory,
  1: SessionType.lab,
  2: SessionType.tutorial,
};

Id _timetableEntryGetId(TimetableEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timetableEntryGetLinks(TimetableEntry object) {
  return [];
}

void _timetableEntryAttach(
    IsarCollection<dynamic> col, Id id, TimetableEntry object) {
  object.id = id;
}

extension TimetableEntryQueryWhereSort
    on QueryBuilder<TimetableEntry, TimetableEntry, QWhere> {
  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhere> anySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'semesterId'),
      );
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhere> anySubjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'subjectId'),
      );
    });
  }
}

extension TimetableEntryQueryWhere
    on QueryBuilder<TimetableEntry, TimetableEntry, QWhereClause> {
  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      semesterIdEqualTo(int semesterId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'semesterId',
        value: [semesterId],
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      semesterIdNotEqualTo(int semesterId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [],
              upper: [semesterId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [semesterId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [semesterId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'semesterId',
              lower: [],
              upper: [semesterId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      semesterIdGreaterThan(
    int semesterId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'semesterId',
        lower: [semesterId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      semesterIdLessThan(
    int semesterId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'semesterId',
        lower: [],
        upper: [semesterId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      semesterIdBetween(
    int lowerSemesterId,
    int upperSemesterId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'semesterId',
        lower: [lowerSemesterId],
        includeLower: includeLower,
        upper: [upperSemesterId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      subjectIdEqualTo(int subjectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'subjectId',
        value: [subjectId],
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      subjectIdNotEqualTo(int subjectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectId',
              lower: [],
              upper: [subjectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectId',
              lower: [subjectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectId',
              lower: [subjectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'subjectId',
              lower: [],
              upper: [subjectId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      subjectIdGreaterThan(
    int subjectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'subjectId',
        lower: [subjectId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      subjectIdLessThan(
    int subjectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'subjectId',
        lower: [],
        upper: [subjectId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterWhereClause>
      subjectIdBetween(
    int lowerSubjectId,
    int upperSubjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'subjectId',
        lower: [lowerSubjectId],
        includeLower: includeLower,
        upper: [upperSubjectId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimetableEntryQueryFilter
    on QueryBuilder<TimetableEntry, TimetableEntry, QFilterCondition> {
  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      dayEqualTo(Weekday value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      dayGreaterThan(
    Weekday value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      dayLessThan(
    Weekday value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'day',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      dayBetween(
    Weekday lower,
    Weekday upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'day',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      endMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      endMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      endMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      endMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'room',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'room',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'room',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'room',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'room',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'room',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      roomIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'room',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      semesterIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'semesterId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      semesterIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'semesterId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      semesterIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'semesterId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      semesterIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'semesterId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      sessionTypeEqualTo(SessionType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      sessionTypeGreaterThan(
    SessionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      sessionTypeLessThan(
    SessionType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      sessionTypeBetween(
    SessionType lower,
    SessionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      startMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      startMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      startMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      startMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      subjectIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subjectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      subjectIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subjectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      subjectIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subjectId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      subjectIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subjectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'teacherId',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'teacherId',
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'teacherId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'teacherId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'teacherId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterFilterCondition>
      teacherIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'teacherId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimetableEntryQueryObject
    on QueryBuilder<TimetableEntry, TimetableEntry, QFilterCondition> {}

extension TimetableEntryQueryLinks
    on QueryBuilder<TimetableEntry, TimetableEntry, QFilterCondition> {}

extension TimetableEntryQuerySortBy
    on QueryBuilder<TimetableEntry, TimetableEntry, QSortBy> {
  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByRoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'room', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByRoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'room', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortBySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortBySemesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortBySessionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionType', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortBySessionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionType', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortBySubjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortBySubjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectId', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> sortByTeacherId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      sortByTeacherIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.desc);
    });
  }
}

extension TimetableEntryQuerySortThenBy
    on QueryBuilder<TimetableEntry, TimetableEntry, QSortThenBy> {
  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'day', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByEndMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByRoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'room', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByRoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'room', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenBySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenBySemesterIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'semesterId', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenBySessionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionType', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenBySessionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionType', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByStartMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMinutes', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenBySubjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenBySubjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subjectId', Sort.desc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy> thenByTeacherId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.asc);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QAfterSortBy>
      thenByTeacherIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'teacherId', Sort.desc);
    });
  }
}

extension TimetableEntryQueryWhereDistinct
    on QueryBuilder<TimetableEntry, TimetableEntry, QDistinct> {
  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct> distinctByDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'day');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctByEndMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endMinutes');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct> distinctByRoom(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'room', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctBySemesterId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'semesterId');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctBySessionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionType');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctByStartMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMinutes');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctBySubjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subjectId');
    });
  }

  QueryBuilder<TimetableEntry, TimetableEntry, QDistinct>
      distinctByTeacherId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'teacherId');
    });
  }
}

extension TimetableEntryQueryProperty
    on QueryBuilder<TimetableEntry, TimetableEntry, QQueryProperty> {
  QueryBuilder<TimetableEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimetableEntry, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TimetableEntry, Weekday, QQueryOperations> dayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'day');
    });
  }

  QueryBuilder<TimetableEntry, int, QQueryOperations> endMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endMinutes');
    });
  }

  QueryBuilder<TimetableEntry, String?, QQueryOperations> roomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'room');
    });
  }

  QueryBuilder<TimetableEntry, int, QQueryOperations> semesterIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'semesterId');
    });
  }

  QueryBuilder<TimetableEntry, SessionType, QQueryOperations>
      sessionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionType');
    });
  }

  QueryBuilder<TimetableEntry, int, QQueryOperations> startMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMinutes');
    });
  }

  QueryBuilder<TimetableEntry, int, QQueryOperations> subjectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subjectId');
    });
  }

  QueryBuilder<TimetableEntry, int?, QQueryOperations> teacherIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'teacherId');
    });
  }
}
