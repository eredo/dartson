import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';

import '../annotations.dart';
import 'entity_type_helper.dart';
import 'entity_generator.dart';
import 'generator_settings.dart';
import 'transformer_generator.dart';
import 'serializer_generator.dart';

class SerializerGenerator extends GeneratorForAnnotation<Serializer> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final settings = GeneratorSettings.fromConstant(annotation);
    final transformers = TransformerGenerator(settings.transformers);
    final entities = EntityTypeHelper(settings.entities);

    final emitter = DartEmitter();
    final buffer = StringBuffer();

    buffer.write(transformers.build(emitter));
    buffer.writeAll(settings.entities.values
        .map((e) => EntityGenerator(e, transformers, entities).build(emitter)));

    buffer.write(DartsonGenerator(settings.entities.values.toSet(), element)
        .build(emitter));

    return DartFormatter().format(buffer.toString());
  }
}
