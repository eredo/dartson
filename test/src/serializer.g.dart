// GENERATED CODE - DO NOT MODIFY BY HAND

part of serializer_test;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const _transformer0 = const DateTimeParser();
Map<String, dynamic> _MyClass$encoder(MyClass object, Dartson inst) {
  final obj = new Map<String, dynamic>();
  obj['name'] = object.name;
  obj['number'] = object.number;
  obj['boolean'] = object.hasBoolean;
  obj['numDouble'] = object.numDouble;
  obj['uri'] = object.uri?.toString();
  obj['dateTime'] = _transformer0.encode(object.dateTime);
  obj['inherited'] = object.inherited;
  obj['inheritName'] = object.inheritedRenamed;
  return obj;
}

MyClass _MyClass$decoder(Map<String, dynamic> data, Dartson inst) {
  final obj = new MyClass();
  obj.name = data['name'] as String;
  obj.number = data['number'] as int;
  obj.hasBoolean = data['boolean'] as bool;
  obj.numDouble = (data['numDouble'] as num)?.toDouble();
  obj.uri = data['uri'] == null ? null : Uri.parse(data['uri'] as String);
  obj.dateTime = _transformer0.decode(data['dateTime'] as String);
  obj.inherited = data['inherited'] as bool;
  obj.inheritedRenamed = data['inheritName'] as String;
  return obj;
}

class _Dartson$impl extends Dartson {
  _Dartson$impl()
      : super(<Type, DartsonEntity>{
          MyClass:
              new DartsonEntity<MyClass>(_MyClass$encoder, _MyClass$decoder)
        });
}

final serializer$dartson = new _Dartson$impl();
