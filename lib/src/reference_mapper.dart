library dartson.references;

const INSTANCE_ID = '__instance#__';
const REFERENCE_ID = '__reference#__';

/// Registers instances (serializable maps) and create serializable placeholders for them.
/// An [INSTANCE_ID] will be added to the serializable maps in case a placeholder was created.
/// A placeholder is a serializable map, which contains a [REFERENCE_ID] entry.
class EncodingReferenceMapper {
  int lastId = 0;
  Map<Object, Map> serializableMapsByInstance = new Map.identity();

  void registerSerializableMap(Object value, dynamic serializedObject) {
    if (serializedObject is Map) {
      serializableMapsByInstance.putIfAbsent(value, () => serializedObject);
    }
  }

  bool isSerialized(Object instance) {
    return serializableMapsByInstance.containsKey(instance);
  }

  Map createSerializablePlaceholder(Object instance) {
    var serializableMap = serializableMapsByInstance[instance];
    // if placeholder is needed for object add reference id to serialized object
    serializableMap.putIfAbsent(INSTANCE_ID, () => ++lastId);
    return {REFERENCE_ID: serializableMap[INSTANCE_ID]};
  }
}

/// Registers instances (serializable maps) if they contain an [INSTANCE_ID] entry,
/// and resolve references for placeholders.
/// A placeholder is a serializable map, which contains a [REFERENCE_ID] entry.
class DecodingReferenceMapper {
  Map<int, Object> instancesById = {};

  void registerInstanceIfApplicable(Object instance, Map serializableMap) {
    if (serializableMap.containsKey(INSTANCE_ID)) {
      instancesById.putIfAbsent(serializableMap[INSTANCE_ID], () => instance);
    }
  }

  bool isPlaceholder(Object value) {
    return value is Map && value.length == 1 && value.containsKey(REFERENCE_ID);
  }

  Object resolveReferenceForPlaceholder(Map placeholder) {
    return instancesById[placeholder[REFERENCE_ID]];
  }
}
