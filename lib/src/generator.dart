import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';

import 'annotations.dart';

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

      str.write(_buildEncoder(classElement).accept(emitter));
      str.write(_buildDecoder(classElement).accept(emitter));
    });

    str.write(_buildDartson(entities).accept(emitter));
    str.write(refer('_Dartson\$impl')
        .newInstance([])
        .assignFinal('${element.name}\$dartson')
        .statement
        .accept(emitter));

    final formatter = new DartFormatter();
    return formatter.format(str.toString());
  }

  Spec _buildDartson(Iterable<DartObject> objects) {
    final mapValues = <Object, Object>{};

    objects.map((obj) => obj.toTypeValue()).forEach((t) =>
        mapValues[refer(t.name)] = refer('DartsonEntity').newInstance(
            [refer('_${t.name}\$encoder'), refer('_${t.name}\$decoder')],
            {},
            [refer(t.name)]));

    final lookupMap = literalMap(mapValues, refer('Type', 'dart:core'),
        refer('DartsonEntity', 'package:dartson/dartson.dart'));

    final constr = Constructor(
        (mb) => mb..initializers.add(refer('super').call([lookupMap]).code));

    return Class((cb) => cb
      ..name = '_Dartson\$impl'
      ..extend = refer('Dartson', 'package:dartson/dartson.dart')
      ..constructors.add(constr));
  }

  Method _buildEncoder(ClassElement classElement) {
    final obj = refer('obj');
    final block = BlockBuilder()
      ..addExpression(refer('Map<String, dynamic>', 'dart:core')
          .newInstance([]).assignFinal('obj'));

    classElement.fields.where((f) => !_ignoreField(f)).forEach((f) {
      block.addExpression(obj
          .index(literalString(_propertyName(f)))
          .assign(refer('object').property(f.name)));
    });

    block.addExpression(obj.returned);

    return Method((b) => b
      ..name = '_${classElement.name}\$encoder'
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

    classElement.fields.where((f) => !_ignoreField(f)).forEach((f) {
      block.addExpression(refer('obj')
          .property(f.name)
          .assign(obj.index(literalString(_propertyName(f)))));
    });

    block.addExpression(refer('obj').returned);

    return Method((b) => b
      ..name = '_${classElement.name}\$decoder'
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

DartObject _propertyAnnotation(FieldElement f) {
  final annotations = TypeChecker.fromRuntime(Property).annotationsOf(f);

  if (annotations.isNotEmpty) {
    return annotations.last;
  }

  return null;
}

String _propertyName(FieldElement f) {
  final annotation = _propertyAnnotation(f);
  if (!(annotation?.getField('name')?.isNull ?? true)) {
    return annotation.getField('name').toStringValue();
  }

  return f.name;
}

bool _ignoreField(FieldElement f) {
  final annotation = _propertyAnnotation(f);
  if (!(annotation?.getField('ignore')?.isNull ?? true)) {
    return annotation.getField('ignore').toBoolValue();
  }

  return false;
}
