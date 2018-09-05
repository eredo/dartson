library dartson.annotations;

import 'dart:convert';

/// Annotation class to mark a class as serializable. This is required
/// if the dartson builder has to build an entity map for dart2js.
@Deprecated('No longer necessary, as all entities need to be passed to the'
    ' serializer.')
class Entity {
  const Entity();
}

/// Annotation class to describe properties of a class member.
class Property {
  final bool ignore;
  final String name;

  const Property({this.ignore = false, this.name});

  String toString() => "DartsonProperty: Name: $name , Ignore: $ignore";
}

class Serializer {
  final List<Type> entities;
  final List<Type> transformers;
  final Codec codec;

  const Serializer({this.entities, this.codec, this.transformers});
}
