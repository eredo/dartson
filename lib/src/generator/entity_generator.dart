import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:json_serializable/src/type_helpers/value_helper.dart';
import 'package:json_serializable/src/type_helpers/enum_helper.dart';
import 'package:json_serializable/src/type_helpers/iterable_helper.dart';
import 'package:json_serializable/src/type_helpers/map_helper.dart';

import 'entity_type_helper.dart';
import 'field_context.dart';
import 'identifier.dart';
import 'transformer_generator.dart';
import 'utils.dart';

class EntityGenerator {
  final ClassElement _element;
  final Set<FieldElement> _fields;
  final Iterable<TypeHelper> _helpers;
  final _fieldContexts = <FieldContext>[];

  EntityGenerator(this._element, TransformerGenerator transformers,
      EntityTypeHelper entities)
      : _fields = sortedFieldSet(_element),
        _helpers = <TypeHelper>[
          transformers,
          entities,
        ].followedBy([
          ValueHelper(),
          UriHelper(),
          EnumHelper(),
          IterableHelper(),
          MapHelper(),
          DateTimeHelper(),
        ]);

  String build(DartEmitter emitter) => (StringBuffer()
        ..write(_buildEncoder(_element).accept(emitter))
        ..write(_buildDecoder(_element).accept(emitter))
        ..writeAll(_fieldContexts.expand((f) => f.members).toSet()))
      .toString();

  Method _buildEncoder(ClassElement classElement) {
    final obj = refer('obj');
    final block = BlockBuilder()
      ..statements.add(Code('if (object == null) { return null; }'))
      ..addExpression(refer('Map<String, dynamic>', 'dart:core')
          .newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(field);
      if (fieldProperty.ignore) {
        continue;
      }

      final fieldContext = FieldContext(true, field.metadata, _helpers);
      _fieldContexts.add(fieldContext);

      block.addExpression(obj
          .index(literalString(fieldProperty.name ?? field.name))
          .assign(CodeExpression(Code(
              fieldContext.serialize(field.type, 'object.${field.name}')))));
    }

    block.addExpression(obj.returned);

    return Method((b) => b
      ..name = encodeMethod(classElement)
      ..returns = refer('Map<String, dynamic>')
      ..requiredParameters.addAll([
        Parameter((pb) => pb
          ..name = 'object'
          ..type = refer(classElement.displayName)),
        Parameter((pb) => pb
          ..name = 'inst'
          ..type = refer('Dartson', dartsonPackage))
      ])
      ..body = block.build());
  }

  Method _buildDecoder(ClassElement classElement) {
    final block = BlockBuilder()
      ..statements.add(Code('if (data == null) { return null; }'))
      ..addExpression(
          refer(classElement.displayName).newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(field);
      if (fieldProperty.ignore) {
        continue;
      }
      final fieldContext = FieldContext(true, field.metadata, _helpers);
      _fieldContexts.add(fieldContext);

      block.addExpression(refer('obj').property(field.displayName).assign(
          CodeExpression(Code(fieldContext.deserialize(field.type,
              'data[\'${fieldProperty.name ?? field.displayName}\']')))));
    }

    block.addExpression(refer('obj').returned);

    return Method((b) => b
      ..name = decodeMethod(classElement)
      ..returns = refer(classElement.displayName)
      ..requiredParameters.addAll([
        Parameter((pb) => pb
          ..name = 'data'
          ..type = refer('Map<String, dynamic>')),
        Parameter((pb) => pb
          ..name = 'inst'
          ..type = refer('Dartson', dartsonPackage))
      ])
      ..body = block.build());
  }
}
