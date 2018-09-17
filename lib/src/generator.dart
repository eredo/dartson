import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:json_serializable/src/type_helpers/value_helper.dart';
import 'package:json_serializable/src/type_helpers/enum_helper.dart';
import 'package:json_serializable/src/type_helpers/iterable_helper.dart';
import 'package:json_serializable/src/type_helpers/map_helper.dart';

import 'annotations.dart';
import 'transformer_generator.dart';
import 'utils.dart';
import 'generator_settings.dart';
import 'identifier.dart';
import 'entity_type_helper.dart';

// TODO: Properly separate the generators.

class SerializerGenerator extends GeneratorForAnnotation<Serializer> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final settings = GeneratorSettings.fromConstant(annotation);
    final trans = TransformerGenerator(settings.transformers);
    final entityHelper = EntityTypeHelper(settings.entities);

    final emitter = DartEmitter();
    final str = StringBuffer();

    str.write(trans.build(emitter));
    str.writeAll(settings.entities.values
        .map((e) => _EntityGenerator(e, trans, entityHelper).build(emitter)));

    str.write(
        _DartsonGenerator(settings.entities.values.toSet()).build(emitter));
    str.write(refer(implementationIdentifier)
        .newInstance([])
        .assignFinal('_${element.name}$serializerIdentifier')
        .statement
        .accept(emitter));

    final formatter = DartFormatter();
    return formatter.format(str.toString());
  }
}

class _DartsonGenerator {
  final Set<ClassElement> objects;

  _DartsonGenerator(this.objects);

  String build(DartEmitter emitter) =>
      _buildDartson().accept(emitter).toString();

  Spec _buildDartson() {
    final mapValues = <Object, Object>{};

    objects.forEach((t) =>
        mapValues[refer(t.displayName)] = refer('DartsonEntity').constInstance([
          refer('_${t.displayName}$encodeMethodIdentifier'),
          refer('_${t.displayName}$decodeMethodIdentifier'),
        ], {}, [
          refer(t.displayName)
        ]));

    final lookupMap = literalMap(mapValues, refer('Type', 'dart:core'),
        refer('DartsonEntity', 'package:dartson/dartson.dart'));

    String dartsonTypeArguments = 'Map<String, dynamic>';

    final constr = Constructor(
        (mb) => mb..initializers.add(refer('super').call([lookupMap]).code));

    return Class((cb) => cb
      ..name = implementationIdentifier
      ..extend = refer(
          'Dartson<$dartsonTypeArguments>', 'package:dartson/dartson.dart')
      ..constructors.add(constr));
  }
}

class _EntityGenerator {
  final ClassElement _element;
  final Set<FieldElement> _fields;
  final Iterable<TypeHelper> _helpers;
  final _fieldContexts = <FieldContext>[];

  _EntityGenerator(this._element, TransformerGenerator _transformers,
      EntityTypeHelper entities)
      : _fields = sortedFieldSet(_element),
        _helpers = <TypeHelper>[_transformers, entities].followedBy([
          ValueHelper(),
          UriHelper(),
          EnumHelper(),
          IterableHelper(),
          MapHelper(),
        ]);

  String build(DartEmitter emitter) {
    final buffer = StringBuffer();
    buffer.write(_buildEncoder(_element).accept(emitter));
    buffer.write(_buildDecoder(_element).accept(emitter));
    Set<String>()
      ..addAll(_fieldContexts.expand((f) => f.members))
      ..forEach(buffer.write);

    return buffer.toString();
  }

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
      ..name = '_${classElement.name}$encodeMethodIdentifier'
      ..returns = refer('Map<String, dynamic>')
      ..requiredParameters.addAll([
        Parameter((pb) => pb
          ..name = 'object'
          ..type = refer(classElement.name)),
        Parameter((pb) => pb
          ..name = 'inst'
          ..type = refer('Dartson'))
      ])
      ..body = block.build());
  }

  Method _buildDecoder(ClassElement classElement) {
    final block = BlockBuilder()
      ..statements.add(Code('if (data == null) { return null; }'))
      ..addExpression(
          refer(classElement.name).newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(field);
      if (fieldProperty.ignore) {
        continue;
      }
      final fieldContext = FieldContext(true, field.metadata, _helpers);
      _fieldContexts.add(fieldContext);

      block.addExpression(refer('obj').property(field.name).assign(
          CodeExpression(Code(fieldContext.deserialize(
              field.type, 'data[\'${fieldProperty.name ?? field.name}\']')))));
    }

    block.addExpression(refer('obj').returned);

    return Method((b) => b
      ..name = '_${classElement.name}$decodeMethodIdentifier'
      ..returns = refer(classElement.name)
      ..requiredParameters.addAll([
        Parameter((pb) => pb
          ..name = 'data'
          ..type = refer('Map<String, dynamic>')),
        Parameter((pb) => pb
          ..name = 'inst'
          ..type = refer('Dartson'))
      ])
      ..body = block.build());
  }
}

class FieldContext implements DeserializeContext, SerializeContext {
  final bool nullable;
  final List<ElementAnnotation> metadata;
  final Iterable<TypeHelper> helpers;
  final List<String> members = [];

  FieldContext(this.nullable, this.metadata, this.helpers);

  @override
  void addMember(String memberContent) {
    members.add(memberContent);
  }

  // TODO: Proper error message.
  @override
  String deserialize(DartType fieldType, String expression) => helpers
      .map((h) => h.deserialize(fieldType, expression, this))
      .firstWhere((r) => r != null,
          orElse: () => throw UnsupportedTypeError(
              fieldType, expression, 'Unable to detect helper.'));

  @override
  String serialize(DartType fieldType, String expression) => helpers
      .map((h) => h.serialize(fieldType, expression, this))
      .firstWhere((r) => r != null,
          orElse: () => throw UnsupportedTypeError(
              fieldType, expression, 'Unable to detect type.'));

  // TODO: Add proper implementation.
  @override
  bool get useWrappers => false;
}
