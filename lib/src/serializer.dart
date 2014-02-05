part of dartson;

/**
 * Serializes the [object] to a JSON string.
 */
String serialize(Object object) {
  _log("Start serializing");
  return JSON.encode(objectToSerializable(object));
}

Object objectToSerializable(Object obj) {
  if (obj is String || obj is num || obj is bool || obj == null) {
    _log("Found primetive: $obj");
    return obj;
  } else if (obj is List) {
    _log("Found list");
    return _serializeList(obj);
  } else if (obj is Map) {
    _log("Found map");
    return _serializeMap(obj);
  } else {
    _log("Found object");
    return _serializeObject(obj);
  }
}

List _serializeList(List list) {
  List newList = [];

  list.forEach((item) {
    newList.add(objectToSerializable(item));
  });

  return newList;
}

Map _serializeMap(Map map) {
  Map newMap = new Map<String,Object>();
  map.forEach((key, val) {
    if (val != null) {
      newMap[key] = objectToSerializable(val);
    }
  });

  return newMap;
}

/**
 * Runs through the Object keys by using a ClassMirror.
 */
Object _serializeObject(Object obj) {
  InstanceMirror instMirror = reflect(obj);
  ClassMirror classMirror = instMirror.type;
  _log("Serializing class: ${MirrorSystem.getName(classMirror.qualifiedName)}");
  Map result = new Map<String,Object>();
  
  classMirror.declarations.forEach((sym, decl) {
    if (!decl.isPrivate && 
        (decl is VariableMirror || (decl is MethodMirror && decl.isGetter))) {
      _pushField(sym, decl, instMirror, result);
    }
  });
  
  _log("Serialization completed.");

  return result;
}

/**
 * Checks the DeclarationMirror [variable] for annotations and adds
 * the value to the [result] map. If there's no [DartsonProperty] annotation 
 * with a different name set it will use the name of [symbol].
 */
void _pushField(Symbol symbol, DeclarationMirror variable,
                InstanceMirror instMirror, Map<String,Object> result) {
  InstanceMirror field = instMirror.getField(symbol);
  Object value = field.reflectee;
  String fieldName = MirrorSystem.getName(symbol);
  _log("Start serializing field: ${fieldName}");
  
  // check if there is a DartsonProperty annotation
  DartsonProperty prop = _getProperty(variable);
  _log("Property: ${prop}");
  
  if (prop != null && prop.name != null) {  
    _log("Field renamed to: ${prop.name}");
    fieldName = prop.name;
  }
  
  if (value != null && (prop != null ? !prop.ignore : true)) {
    _log("Serializing field: ${fieldName}");
      result[fieldName] = objectToSerializable(value);
    }
}
