library dartson.transformers.DateTime;

import 'package:dartson/type_transformer.dart';

/// A simple DateTime transformer which uses the toString() method.
class DateTimeParser extends TypeTransformer<DateTime> {
  DateTime decode(dynamic value) => DateTime.parse(value);
  dynamic encode(DateTime value) => value.toUtc().toIso8601String();
}
