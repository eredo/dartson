// GENERATED CODE - DO NOT MODIFY BY HAND

part of serializer_test;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const _transformer0 = const DateTimeParser();
Map<String, dynamic> _MyClass$encoder(MyClass object, Dartson inst) {
  if (object == null) {
    return null;
  }
  final obj = new Map<String, dynamic>();
  obj['finalProp'] = object.finalProp;
  obj['name'] = object.name;
  obj['number'] = object.number;
  obj['boolean'] = object.hasBoolean;
  obj['numDouble'] = object.numDouble;
  obj['uri'] = object.uri?.toString();
  obj['dateTime'] = _transformer0.encode(object.dateTime);
  obj['myEnum'] = _$MyEnumEnumMap[object.myEnum];
  obj['secondEnum'] = _$SecondEnumEnumMap[object.secondEnum];
  obj['subClass'] = _SubClass$encoder(object.subClass, inst);
  obj['subClasses'] =
      object.subClasses?.map((e) => _SubClass$encoder(e, inst))?.toList();
  obj['complexMap'] =
      object.complexMap?.map((k, e) => MapEntry(k, _SubClass$encoder(e, inst)));
  obj['replacement'] = _MyImpl$encoder(object.replacement, inst);
  obj['private'] = object.privateGetter;
  obj['inherited'] = object.inherited;
  obj['inheritName'] = object.inheritedRenamed;
  return obj;
}

MyClass _MyClass$decoder(Map<String, dynamic> data, Dartson inst) {
  if (data == null) {
    return null;
  }
  final obj = new MyClass(data['finalProp'] as String,
      renamedPrivate: data['private'] as String);
  obj.name = data['name'] as String;
  obj.number = data['number'] as int;
  obj.hasBoolean = data['boolean'] as bool;
  obj.numDouble = (data['numDouble'] as num)?.toDouble();
  obj.uri = data['uri'] == null ? null : Uri.parse(data['uri'] as String);
  obj.dateTime = _transformer0.decode(data['dateTime'] as String);
  obj.myEnum = _$enumDecodeNullable(_$MyEnumEnumMap, data['myEnum']);
  obj.secondEnum =
      _$enumDecodeNullable(_$SecondEnumEnumMap, data['secondEnum']);
  obj.subClass = _SubClass$decoder(data['subClass'], inst);
  obj.subClasses = (data['subClasses'] as List)
      ?.map((e) => _SubClass$decoder(e, inst))
      ?.toList();
  obj.complexMap = (data['complexMap'] as Map<String, dynamic>)
      ?.map((k, e) => MapEntry(k, _SubClass$decoder(e, inst)));
  obj.replacement = _MyImpl$decoder(data['replacement'], inst);
  obj.inherited = data['inherited'] as bool;
  obj.inheritedRenamed = data['inheritName'] as String;
  return obj;
}

const _$MyEnumEnumMap = <MyEnum, dynamic>{
  MyEnum.firstValue: 'firstValue',
  MyEnum.secondValue: 'secondValue'
};
const _$SecondEnumEnumMap = <SecondEnum, dynamic>{
  SecondEnum.has: 'has',
  SecondEnum.nothing: 'nothing'
};
T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

Map<String, dynamic> _SubClass$encoder(SubClass object, Dartson inst) {
  if (object == null) {
    return null;
  }
  final obj = new Map<String, dynamic>();
  obj['name'] = object.name;
  obj['aliases'] = object.aliases;
  obj['simpleMap'] = object.simpleMap;
  return obj;
}

SubClass _SubClass$decoder(Map<String, dynamic> data, Dartson inst) {
  if (data == null) {
    return null;
  }
  final obj = new SubClass();
  obj.name = data['name'] as String;
  obj.aliases = (data['aliases'] as List)?.map((e) => e as String)?.toList();
  obj.simpleMap = (data['simpleMap'] as Map<String, dynamic>)
      ?.map((k, e) => MapEntry(k, (e as num)?.toDouble()));
  return obj;
}

Map<String, dynamic> _MyImpl$encoder(MyImpl object, Dartson inst) {
  if (object == null) {
    return null;
  }
  final obj = new Map<String, dynamic>();
  obj['name'] = object.name;
  return obj;
}

MyImpl _MyImpl$decoder(Map<String, dynamic> data, Dartson inst) {
  if (data == null) {
    return null;
  }
  final obj = new MyImpl();
  obj.name = data['name'] as String;
  return obj;
}

final _serializer$dartson =
    new Dartson<Map<String, dynamic>>(<Type, DartsonEntity>{
  MyClass: const DartsonEntity<MyClass>(_MyClass$encoder, _MyClass$decoder),
  SubClass: const DartsonEntity<SubClass>(_SubClass$encoder, _SubClass$decoder),
  MyImpl: const DartsonEntity<MyImpl>(_MyImpl$encoder, _MyImpl$decoder)
});
