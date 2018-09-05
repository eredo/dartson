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
  obj['name'] = object.name;
  obj['number'] = object.number;
  obj['boolean'] = object.hasBoolean;
  obj['numDouble'] = object.numDouble;
  obj['uri'] = object.uri?.toString();
  obj['dateTime'] = _transformer0.encode(object.dateTime);
  obj['myEnum'] = _$MyEnumEnumMap[object.myEnum];
  obj['secondEnum'] = _$SecondEnumEnumMap[object.secondEnum];
  obj['inherited'] = object.inherited;
  obj['inheritName'] = object.inheritedRenamed;
  return obj;
}

MyClass _MyClass$decoder(Map<String, dynamic> data, Dartson inst) {
  if (data == null) {
    return null;
  }
  final obj = new MyClass();
  obj.name = data['name'] as String;
  obj.number = data['number'] as int;
  obj.hasBoolean = data['boolean'] as bool;
  obj.numDouble = (data['numDouble'] as num)?.toDouble();
  obj.uri = data['uri'] == null ? null : Uri.parse(data['uri'] as String);
  obj.dateTime = _transformer0.decode(data['dateTime'] as String);
  obj.myEnum = _$enumDecodeNullable(_$MyEnumEnumMap, data['myEnum']);
  obj.secondEnum =
      _$enumDecodeNullable(_$SecondEnumEnumMap, data['secondEnum']);
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

class _Dartson$impl extends Dartson {
  _Dartson$impl()
      : super(<Type, DartsonEntity>{
          MyClass:
              new DartsonEntity<MyClass>(_MyClass$encoder, _MyClass$decoder)
        });
}

final serializer$dartson = new _Dartson$impl();
