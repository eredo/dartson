import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_serializable/type_helper.dart';

import 'identifier.dart';

class EntityTypeHelper implements TypeHelper {
  final Map<ClassElement, ClassElement> entities;
  EntityTypeHelper(this.entities);

  @override
  String deserialize(
      DartType targetType, String expression, DeserializeContext context) {
    final target = targetType.element as ClassElement;
    if (!entities.containsKey(target)) {
      return null;
    }

    return '${decodeMethod(entities[target])}($expression, inst)';
  }

  @override
  String serialize(
      DartType targetType, String expression, SerializeContext context) {
    final target = targetType.element as ClassElement;
    if (!entities.containsKey(target)) {
      return null;
    }

    return '${encodeMethod(entities[target])}($expression, inst)';
  }
}
