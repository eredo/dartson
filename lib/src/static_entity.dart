library dartson.static_entity;

/// Classes that have the [Entity] annotation will be transformed by
/// dartson when using dart2js compiler and then implement this interface.
abstract class StaticEntity {
  /// Converts the object into a serializable Map.
  Map dartsonEntityEncode();
  
  /// Maps the [object] properties on this object.
  void dartsonEntityDecode(Map object);
  
  /// Initiates a new instance of the same Type. This method is used to
  /// prevent usage of mirrors.
  StaticEntity newEntity();
}