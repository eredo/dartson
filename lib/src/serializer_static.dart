part of dartson.static;

/**
 * Serializes the [object] to a JSON string.
 */
String serialize(Object object) {
  return JSON.encode(objectToSerializable(object));
}

Object objectToSerializable(Object obj) {
  if (obj is String || obj is num || obj is bool || obj == null) {
    return obj;
  } else if (obj is List) {
    return _serializeList(obj);
  } else if (obj is Map) {
    return _serializeMap(obj);
  } else {
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
  if (obj is StaticEntity) {
    return obj.dartsonEntityEncode();
  } else {
    throw 'Unable to serialize none StaticEntity.';
  }
}