import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';

import 'src/my_class.dart';
import 'src/sub_class.dart';

part 'serializer.g.dart';

@Serializer(entities: [
  MyClass,
  SubClass,
], transformers: [
  DateTimeParser,
])
final serializer = serializer$dartson;
