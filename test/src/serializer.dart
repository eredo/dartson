library serializer_test;

import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';

import 'my_class.dart';
import 'sub_class.dart';
import 'my_impl.dart';

// ignore: uri_has_not_been_generated
part 'serializer.g.dart';

@Serializer(
  entities: [
    MyClass,
    SubClass,
  ],
  transformers: [DateTimeParser],
  replacements: {
    MyAbstr: MyImpl,
  },
)
final Dartson<Map<String, dynamic>> serializer = _serializer$dartson;
