// GENERATED CODE - DO NOT MODIFY BY HAND

part of serializer_test;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

Map<String, dynamic> _MyClass$encoder(MyClass object, Dartson inst) {
  final obj = new Map<String, dynamic>();
  obj['name'] = object.name;
  obj['number'] = object.number;
  obj['boolean'] = object.hasBoolean;
  return obj;
}

MyClass _MyClass$decoder(Map<String, dynamic> data, Dartson inst) {
  final obj = new MyClass();
  obj.name = data['name'];
  obj.number = data['number'];
  obj.hasBoolean = data['boolean'];
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
