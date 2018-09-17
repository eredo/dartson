import 'package:meta/meta.dart';

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
}

/// Defines the generation of a serializer. Assign the variable name as private
/// with a suffix "$dartson" to the annotated variable.
///
///     @Serializer(
///       entities: [MyClass],
///       replacements: {MyInterface: MyImplementation},
///       transformers: [MyCustomTransformer],
///     )
///     final Dartson<String> serializer = _serializer$dartson.useCodec(json);
///
class Serializer {
  /// A list of entities which will be serialized by the [Serializer].
  ///
  /// Note: All classes used within an entity must be added to this list or
  /// have a transformer added to the [transformers].
  final List<Type> entities;

  /// A list of transformers which will be used to serializer classes or types
  /// that are not present in [entities] or can be serialized by default.
  ///
  /// All types in this list need to implement [TypeTransformer] providing both
  /// of the generic type definitions. Otherwise the builder will fail due to
  /// an unknown type.
  final List<Type> transformers;

  /// A map which defines replacements of classes, the key defines the targets
  /// for replacement and the value the implementations which be used instead.
  final Map<Type, Type> replacements;

  const Serializer(
      {@required this.entities, this.transformers, this.replacements});
}
