library dartson.static_entity;

import 'package:dartson/type_transformer.dart';

abstract class StaticEntityEncoder {
  TypeTransformer getTransformer(Type type);
  bool hasTransformer(Type type);

  bool isSerialized(Object instance);
  Map createSerializablePlaceholder(Object instance);
  void registerSerializableMap(Object instance, dynamic serializedObject);
}

abstract class StaticEntityDecoder {
  TypeTransformer getTransformer(Type type);
  bool hasTransformer(Type type);

  void registerInstanceIfApplicable(Object instance, Map serializableMap);
  bool isPlaceholder(Object val);
  Object resolveReferenceForPlaceholder(Map placeholder);
}

/// Classes that have the [Entity] annotation will be transformed by
/// dartson when using dart2js compiler and then implement this interface.
abstract class StaticEntity {
  /// Converts the object into a serializable Map.
  Map dartsonEntityEncode(StaticEntityEncoder dson);

  /// Maps the [object] properties on this object.
  void dartsonEntityDecode(Map object, StaticEntityDecoder dson);

  /// Initiates a new instance of the same Type. This method is used to
  /// prevent usage of mirrors.
  StaticEntity newEntity();
}
