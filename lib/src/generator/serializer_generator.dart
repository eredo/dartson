import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

import 'identifier.dart';

/// Generator which initiates the [Dartson] instance passing the map of
/// entities and assigning it to the serializer value adding `$dartson` suffix.
///
/// **Output:**
///
///     final _serializer$dartson = new Dartson<Map<String, dynamic>>({/*...*/});
///
class DartsonGenerator {
  final Set<ClassElement> _objects;
  final Element _element;

  DartsonGenerator(this._objects, this._element);

  String build(DartEmitter emitter) =>
      _buildDartson().accept(emitter).toString();

  Spec _buildDartson() {
    final mapValues = <Object, Object>{};

    _objects.forEach((t) => mapValues[refer(t.displayName)] =
            refer('DartsonEntity', dartsonPackage).constInstance([
          refer(encodeMethod(t)),
          refer(decodeMethod(t)),
        ], {}, [
          refer(t.displayName)
        ]));

    final lookupMap = literalMap(mapValues, refer('Type', 'dart:core'),
        refer('DartsonEntity', dartsonPackage));

    return refer('Dartson<Map<String, dynamic>>', dartsonPackage)
        .newInstance([lookupMap])
        .assignFinal('_${_element.displayName}$serializerIdentifier')
        .statement;
  }
}
