library dartson.annotations;

/**
 * Annotation class to mark a class as serializable. This is required
 * if the dartson builder has to build an entity map for dart2js. 
 * @deprecated Currently not required.
 */
class Entity {
  const Entity();
}

/**
 * Annotation class to describe properties of a class member.
 */
class Property {
  final bool _ignore;
  final String name;
  
  const Property({bool ignore, String name}) :
    this._ignore = ignore,
    this.name = name;
  
  bool get ignore => _ignore == null ? false : _ignore;
  String toString() => "DartsonProperty: Name: ${name} , Ignore: ${ignore}";
}
