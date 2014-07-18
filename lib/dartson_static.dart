library dartson.static;

import 'dart:convert' show JSON, JsonCodec;

// for unittesting will be removed on compilation
import 'dart:mirrors' as mirror;

Map<Type,Function> _initClass = {};
DartsonClassInitiator _initiator;

abstract class CompiledDartsonEntity {
  void dFromObject(Map dataObject);
  Map dToObject();
}

abstract class DartsonClassInitiator {}

void registerType(Type clazz, Function constr) {
  _initClass[clazz] = constr;
}

dynamic parse(String jsonStr, Type clazz) {
  
}

List parseList(String jsonStr, Type clazz) {
  
}

dynamic map(Map dataObject, Type clazz) {
  
}

List mapList(List<Map> dataMap, Type clazz) {
    
}

dynamic fill(Map dataObject, Object object) {
  if (object is CompiledDartsonEntity) {
    object.dFromObject(dataObject);
  }
  
  return object;
}

/**
 * Serializes the [object] to a JSON string.
 */
String serialize(Object object) {
  return JSON.encode(object);
}

setInitiator(DartsonClassInitiator init) {
  _initiator = init;
}

CompiledDartsonEntity initEntity(Type type, Object data) {
  // this function gets rewritten on compilation
  var clazz = mirror.reflectClass(type).newInstance(#dConstr, []);
  return fill(data, clazz.reflectee);
}