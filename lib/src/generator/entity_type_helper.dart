import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_serializable/type_helper.dart';

import 'identifier.dart';

/// Helper which looks up if a [DartType] exists within a list of [_entities]
/// and returns the code for the proper calls to encode/decode method. The list
/// of entities is provided by the generator based on entities, transformers
/// and replacements.
class EntityTypeHelper implements TypeHelper {
  final Map<ClassElement, ClassElement> _entities;
  EntityTypeHelper(this._entities);

  @override
  String deserialize(
      DartType targetType, String expression, DeserializeContext context) {
    final target = targetType.element as ClassElement;
    if (!_entities.containsKey(target)) {
      return null;
    }

    return '${decodeMethod(_entities[target])}($expression, inst)';
  }

  @override
  String serialize(
      DartType targetType, String expression, SerializeContext context) {
    final target = targetType.element as ClassElement;
    if (!_entities.containsKey(target)) {
      return null;
    }

    return '${encodeMethod(_entities[target])}($expression, inst)';
  }
}
