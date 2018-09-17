import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_serializable/type_helper.dart';

/// Provides the serialization methods for a field using [TypeHelper]s which are
/// standard [TypeHelper], entities or transformers.
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

  @override
  String deserialize(DartType fieldType, String expression) => helpers
      .map((h) => h.deserialize(fieldType, expression, this))
      .firstWhere((r) => r != null,
          orElse: () => throw UnsupportedTypeError(
              fieldType, expression, _notSupportedTypeMessage));

  @override
  String serialize(DartType fieldType, String expression) => helpers
      .map((h) => h.serialize(fieldType, expression, this))
      .firstWhere((r) => r != null,
          orElse: () => throw UnsupportedTypeError(
              fieldType, expression, _notSupportedTypeMessage));

  // TODO: Add proper implementation.
  @override
  bool get useWrappers => false;
}

final _notSupportedTypeMessage = 'UnsupportedTypeError: None of the provided '
    '`TypeHelper` or defined `entities` and `transformers` support the defined '
    'type. Please make sure to add the type either to `entities`, define a '
    'TypeTransformer in `transformers` or define a `replacement`.';
