// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializer.dart';

// **************************************************************************
// SerializerGenerator
// **************************************************************************

Map<String, dynamic> _Person$encoder(Person object, Dartson inst) {
  final obj = new Map<String, dynamic>();
  obj['firstName'] = object.firstName;
  obj['lastName'] = object.lastName;
  obj['isEmployed'] = object.employed;
  return obj;
}

Person _Person$decoder(Map<String, dynamic> data, Dartson inst) {
  final obj = new Person();
  obj.firstName = data['firstName'];
  obj.lastName = data['lastName'];
  obj.employed = data['isEmployed'];
  return obj;
}

class _Dartson$impl extends Dartson {
  _Dartson$impl()
      : super(<Type, DartsonEntity>{
          Person: new DartsonEntity<Person>(_Person$encoder, _Person$decoder)
        });
}

final serializer$dartson = new _Dartson$impl();
