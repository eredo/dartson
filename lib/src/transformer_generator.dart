import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:json_serializable/type_helper.dart';

import 'exceptions.dart';

class TransformerGenerator implements TypeHelper {
  final List<DartObject> _transformers;
  final Map<DartType, _Transformer> _transformerRef = {};

  TransformerGenerator(this._transformers) {
    _transformers?.forEach((obj) {
      final classElement = obj.toTypeValue().element as ClassElement;
      final serialize = classElement.methods.firstWhere(
          (m) => m.name == 'encode',
          orElse: () => throw MissingEncodeMethodException(classElement.name));
      final deserialize = classElement.methods.firstWhere(
          (m) => m.name == 'decode',
          orElse: () => throw MissingDecodeMethodException(classElement.name));

      final targetType = deserialize.returnType;
      final inputType = serialize.returnType;

      _transformerRef[targetType] = _Transformer(targetType, inputType,
          '_transformer${_transformerRef.length}', classElement.displayName);
    });
  }

  String build(DartEmitter emitter) {
    return _transformerRef.values.fold(
        '',
        (String v, _Transformer t) =>
            v += _buildTransformer(t).accept(emitter).toString());
  }

  Code _buildTransformer(_Transformer trans) =>
      refer(trans.element).constInstance([]).assignConst(trans.name).statement;

  @override
  String deserialize(
      DartType targetType, String expression, DeserializeContext context) {
    final transformer = _transformerRef[targetType];
    if (transformer == null) {
      return null;
    }

    return '${transformer.name}.decode(${expression} as '
        '${transformer.inputType.displayName})';
  }

  @override
  String serialize(
      DartType targetType, String expression, SerializeContext context) {
    final transformer = _transformerRef[targetType];
    if (transformer == null) {
      return null;
    }

    return '${transformer.name}.encode(${expression})';
  }
}

class _Transformer {
  final DartType targetType, inputType;
  final String name, element;

  _Transformer(this.targetType, this.inputType, this.name, this.element);
}
