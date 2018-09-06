import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
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

const _encodeMethodIdentifier = r'$encoder';
const _decodeMethodIdentifier = r'$decoder';
const _serializerIdentifier = r'$dartson';
const _implementationIdentifier = r'_Dartson$impl';

// TODO: Properly separate the generators.

class SerializerGenerator extends GeneratorForAnnotation<Serializer> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final entities = annotation.objectValue.getField('entities').toListValue();
    final transformers =
        annotation.objectValue.getField('transformers').toListValue();

    final emitter = DartEmitter();
    final str = StringBuffer();
    final trans = TransformerGenerator(transformers);
    final entityHelper =
        ExistingEntityHelper(entities.map((e) => e.toTypeValue()).toList());

    str.write(trans.build(emitter));

    entities.forEach((e) {
      final el = e.toTypeValue();
      final classElement = el.element as ClassElement;

      str.write(
          _EntityGenerator(classElement, trans, entityHelper).build(emitter));
    });

    str.write(_DartsonGenerator(entities.toSet()).build(emitter));
    str.write(refer(_implementationIdentifier)
        .newInstance([])
        .assignFinal('${element.name}$_serializerIdentifier')
        .statement
        .accept(emitter));

    final formatter = new DartFormatter();
    return formatter.format(str.toString());
  }
}

class _DartsonGenerator {
  final Set<DartObject> objects;

  _DartsonGenerator(this.objects);

  String build(DartEmitter emitter) {
    return _buildDartson(objects).accept(emitter).toString();
  }

  Spec _buildDartson(Iterable<DartObject> objects) {
    final mapValues = <Object, Object>{};

    objects.map((obj) => obj.toTypeValue()).forEach(
        (t) => mapValues[refer(t.name)] = refer('DartsonEntity').constInstance([
              refer('_${t.name}$_encodeMethodIdentifier'),
              refer('_${t.name}$_decodeMethodIdentifier'),
            ], {}, [
              refer(t.name)
            ]));

    final lookupMap = literalMap(mapValues, refer('Type', 'dart:core'),
        refer('DartsonEntity', 'package:dartson/dartson.dart'));

    final constr = Constructor(
        (mb) => mb..initializers.add(refer('super').call([lookupMap]).code));

    return Class((cb) => cb
      ..name = _implementationIdentifier
      ..extend = refer('Dartson', 'package:dartson/dartson.dart')
      ..constructors.add(constr));
  }
}

class _EntityGenerator {
  final ClassElement _element;
  final Set<FieldElement> _fields;
  final Iterable<TypeHelper> _helpers;
  final _fieldContexts = <FieldContext>[];

  _EntityGenerator(this._element, TransformerGenerator _transformers,
      ExistingEntityHelper entities)
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
      ..name = '_${classElement.name}$_encodeMethodIdentifier'
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
      ..name = '_${classElement.name}$_decodeMethodIdentifier'
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

class ExistingEntityHelper implements TypeHelper {
  final List<DartType> entities;
  ExistingEntityHelper(this.entities);

  @override
  String deserialize(
      DartType targetType, String expression, DeserializeContext context) {
    if (!entities.contains(targetType)) {
      return null;
    }

    return '_${targetType.displayName}$_decodeMethodIdentifier($expression, inst)';
  }

  @override
  String serialize(
      DartType targetType, String expression, SerializeContext context) {
    if (!entities.contains(targetType)) {
      return null;
    }

    return '_${targetType.displayName}$_encodeMethodIdentifier($expression, inst)';
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
