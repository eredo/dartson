import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:json_serializable/src/type_helpers/value_helper.dart';
import 'package:json_serializable/src/type_helpers/enum_helper.dart';
import 'package:json_serializable/src/type_helpers/iterable_helper.dart';
import 'package:json_serializable/src/type_helpers/map_helper.dart';

import '../annotations.dart';
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
        ..write(_buildEncoder().accept(emitter))
        ..write(_buildDecoder().accept(emitter))
        ..writeAll(_fieldContexts.expand((f) => f.members).toSet()))
      .toString();

  Method _buildEncoder() {
    final obj = refer('obj');
    final block = BlockBuilder()
      ..statements.add(Code('if (object == null) { return null; }'))
      ..addExpression(refer('Map<String, dynamic>', 'dart:core')
          .newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(
          field.getter.metadata.isNotEmpty ? field.getter : field);
      if (field.isPrivate || fieldProperty.ignore) {
        continue;
      }

      final fieldContext = FieldContext(true, field.metadata, _helpers);
      _fieldContexts.add(fieldContext);

      block.addExpression(obj
          .index(literalString(fieldProperty.name ?? field.displayName))
          .assign(CodeExpression(Code(fieldContext.serialize(
              field.type, 'object.${field.displayName}')))));
    }

    block.addExpression(obj.returned);

    return Method((b) => b
      ..name = encodeMethod(_element)
      ..returns = refer('Map<String, dynamic>')
      ..requiredParameters.addAll([
        Parameter((pb) => pb
          ..name = 'object'
          ..type = refer(_element.displayName)),
        Parameter((pb) => pb
          ..name = 'inst'
          ..type = refer('Dartson', dartsonPackage))
      ])
      ..body = block.build());
  }

  Method _buildDecoder() {
    final constructorParameters = <Expression>[];
    final constructorNamedParameters = <String, Expression>{};
    final passedConstructorParameters = <String>[];

    // Get constructor arguments.
    final constructorArguments = _element.constructors?.first?.parameters ?? [];
    for (var field in constructorArguments) {
      Property fieldProperty;
      if (field.isInitializingFormal) {
        // Fetch details from matching field.
        fieldProperty = propertyAnnotation(
            _fields.firstWhere((fe) => fe.name == field.name));

        passedConstructorParameters.add(field.displayName);
      } else {
        // Check for annotations.
        fieldProperty = propertyAnnotation(field);
      }

      if (fieldProperty.ignore && field.isNotOptional) {
        // TODO: Throw proper error.
        throw 'NotOptional marked as ignored';
      }

      if (fieldProperty.ignore) {
        continue;
      }

      final fieldContext = FieldContext(true, field.metadata, _helpers);
      _fieldContexts.add(fieldContext);

      final expression = CodeExpression(Code(fieldContext.deserialize(
          field.type, 'data[\'${fieldProperty.name ?? field.displayName}\']')));
      if (field.isPositional) {
        constructorParameters.add(expression);
      } else {
        constructorNamedParameters[field.name] = expression;
      }
    }

    final block = BlockBuilder()
      ..statements.add(Code('if (data == null) { return null; }'))
      ..addExpression(refer(_element.displayName)
          .newInstance(constructorParameters, constructorNamedParameters)
          .assignFinal('obj'));

    for (var field in _fields) {
      if (field.isFinal ||
          passedConstructorParameters.contains(field.name) ||
          field.isPrivate) {
        continue;
      }

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
      ..name = decodeMethod(_element)
      ..returns = refer(_element.displayName)
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
