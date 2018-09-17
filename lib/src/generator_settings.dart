import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class GeneratorSettings {
  final Map<ClassElement, ClassElement> entities;
  final Map<ClassElement, ClassElement> replacements;
  final Iterable<ClassElement> transformers;

  GeneratorSettings._(this.entities, this.transformers, this.replacements);

  factory GeneratorSettings.fromConstant(ConstantReader reader) {
    final replacements = _replacerFromReader(reader, 'replacements');

    final entityMap = <ClassElement, ClassElement>{}
      ..addAll(Map<ClassElement, ClassElement>.fromIterable(
          _fromReader(reader, 'entities'),
          key: (v) => v,
          value: (v) => v))
      ..addAll(replacements);

    return new GeneratorSettings._(
      entityMap,
      _fromReader(reader, 'transformers'),
      replacements,
    );
  }
}

Iterable<ClassElement> _fromReader(ConstantReader reader, String key) {
  final field = reader.objectValue.getField(key);
  if (field.isNull) {
    return <ClassElement>[];
  }

  return field
      .toListValue()
      .map((obj) => obj.toTypeValue().element as ClassElement);
}

Map<ClassElement, ClassElement> _replacerFromReader(
    ConstantReader reader, String key) {
  final field = reader.objectValue.getField(key);
  if (field.isNull) {
    return <ClassElement, ClassElement>{};
  }

  return field.toMapValue().map((key, val) =>
      MapEntry<ClassElement, ClassElement>(
          key.toTypeValue().element as ClassElement,
          val.toTypeValue().element as ClassElement));
}
