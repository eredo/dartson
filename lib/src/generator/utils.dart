import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartson/dartson.dart';

Property propertyAnnotation(Element element) {
  final annotations = TypeChecker.fromRuntime(Property).annotationsOf(element);
  if (annotations.isEmpty) {
    return Property();
  }

  final ignoreField = annotations.last.getField('ignore');
  final renameField = annotations.last.getField('name');
  return Property(
    ignore: !(ignoreField?.isNull ?? true) ? ignoreField.toBoolValue() : false,
    name: !(renameField?.isNull ?? true) ? renameField.toStringValue() : null,
  );
}

// TODO: This is based on a json_serializable implementation maybe share?
Set<FieldElement> sortedFieldSet(ClassElement element) {
  final fieldsList = element.fields.where((e) => !e.isStatic).toList();
  final manager = InheritanceManager(element.library);

  for (var v in manager.getMembersInheritedFromClasses(element).values) {
    assert(v is! FieldElement);

    if (_dartCoreObjectChecker.isExactly(v.enclosingElement)) {
      continue;
    }

    if (v is PropertyAccessorElement && v.variable is FieldElement) {
      fieldsList.add(v.variable as FieldElement);
    }
  }

  return fieldsList.toSet();
}

final _dartCoreObjectChecker = const TypeChecker.fromRuntime(Object);
