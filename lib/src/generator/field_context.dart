import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/src/json_serializable.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:json_serializable/src/type_helper.dart';

/// Provides the serialization methods for a field using [TypeHelper]s which are
/// standard [TypeHelper], entities or transformers.
class FieldContext implements TypeHelperContextWithConfig {
  final bool nullable;
  final List<ElementAnnotation> metadata;
  final Iterable<TypeHelper> helpers;
  final List<String> members = [];
  final ClassElement classElement;
  final FieldElement fieldElement;

  FieldContext(this.nullable, this.metadata, this.helpers, this.classElement,
      this.fieldElement);

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

  @override
  JsonSerializable get config => JsonSerializable(
        anyMap: false,
        checked: false,
        createFactory: false,
        createToJson: false,
        disallowUnrecognizedKeys: false,
        explicitToJson: false,
        includeIfNull: true,
        generateToJsonFunction: true,
        nullable: true,
        useWrappers: false,
      );
}

final _notSupportedTypeMessage = 'UnsupportedTypeError: None of the provided '
    '`TypeHelper` or defined `entities` and `transformers` support the defined '
    'type. Please make sure to add the type either to `entities`, define a '
    'TypeTransformer in `transformers` or define a `replacement`.';
