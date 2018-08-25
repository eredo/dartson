import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';

import 'annotations.dart';
import 'utils.dart';

const _encodeMethodIdentifier = r'$encoder';
const _decodeMethodIdentifier = r'$decoder';
const _serializerIdentifier = r'$dartson';
const _implementationIdentifier = r'_Dartson$impl';

class SerializerGenerator extends GeneratorForAnnotation<Serializer> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final entities = annotation.objectValue.getField('entities').toListValue();

    final emitter = DartEmitter();
    final str = StringBuffer();

    entities.forEach((e) {
      final el = e.toTypeValue();
      final classElement = el.element as ClassElement;

      str.write(_EntityGenerator(classElement).build(emitter));
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
        (t) => mapValues[refer(t.name)] = refer('DartsonEntity').newInstance([
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

  _EntityGenerator(this._element) : this._fields = sortedFieldSet(_element);

  String build(DartEmitter emitter) {
    final buffer = new StringBuffer();
    buffer.write(_buildEncoder(_element).accept(emitter));
    buffer.write(_buildDecoder(_element).accept(emitter));
    return buffer.toString();
  }

  Method _buildEncoder(ClassElement classElement) {
    final obj = refer('obj');
    final block = BlockBuilder()
      ..addExpression(refer('Map<String, dynamic>', 'dart:core')
          .newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(field);
      if (fieldProperty.ignore) {
        continue;
      }

      block.addExpression(obj
          .index(literalString(fieldProperty.name ?? field.name))
          .assign(refer('object').property(field.name)));
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
    final obj = refer('data');
    final block = BlockBuilder()
      ..addExpression(
          refer(classElement.name).newInstance([]).assignFinal('obj'));

    for (var field in _fields) {
      final fieldProperty = propertyAnnotation(field);
      if (fieldProperty.ignore) {
        continue;
      }

      block.addExpression(refer('obj')
          .property(field.name)
          .assign(obj.index(literalString(fieldProperty.name ?? field.name))));
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
