library serializer_test;

import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';

import 'my_class.dart';

// ignore: uri_has_not_been_generated
part 'serializer.g.dart';

@Serializer(
  entities: [MyClass],
  transformers: [DateTimeParser],
)
final Dartson serializer = serializer$dartson;
