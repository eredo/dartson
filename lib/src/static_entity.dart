library dartson.static_entity;

import 'package:dartson/type_transformer.dart';

abstract class TypeTransformerProvider {
  TypeTransformer getTransformer(Type type);
  bool hasTransformer(Type type);
}

/// Classes that have the [Entity] annotation will be transformed by
/// dartson when using dart2js compiler and then implement this interface.
abstract class StaticEntity {
  /// Converts the object into a serializable Map.
  Map dartsonEntityEncode(TypeTransformerProvider dson);
  
  /// Maps the [object] properties on this object.
  void dartsonEntityDecode(Map object, TypeTransformerProvider dson);
  
  /// Initiates a new instance of the same Type. This method is used to
  /// prevent usage of mirrors.
  StaticEntity newEntity();
}