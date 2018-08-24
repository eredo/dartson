library dartson.transformers.DateTime;

import 'package:dartson/dartson.dart';

/// A simple DateTime transformer which uses the toString() method.
class DateTimeParser extends TypeTransformer<String, DateTime> {
  DateTime decode(String value) => DateTime.parse(value);
  String encode(DateTime value) => value.toUtc().toIso8601String();
}
