import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

import 'identifier.dart';

class DartsonGenerator {
  final Set<ClassElement> objects;

  DartsonGenerator(this.objects);

  String build(DartEmitter emitter) =>
      _buildDartson().accept(emitter).toString();

  Spec _buildDartson() {
    final mapValues = <Object, Object>{};

    objects.forEach((t) => mapValues[refer(t.displayName)] =
            refer('DartsonEntity', dartsonPackage).constInstance([
          refer(encodeMethod(t)),
          refer(decodeMethod(t)),
        ], {}, [
          refer(t.displayName)
        ]));

    final lookupMap = literalMap(mapValues, refer('Type', 'dart:core'),
        refer('DartsonEntity', dartsonPackage));

    String dartsonTypeArguments = 'Map<String, dynamic>';

    final constr = Constructor(
        (mb) => mb..initializers.add(refer('super').call([lookupMap]).code));

    return Class((cb) => cb
      ..name = implementationIdentifier
      ..extend = refer('Dartson<$dartsonTypeArguments>', dartsonPackage)
      ..constructors.add(constr));
  }
}
