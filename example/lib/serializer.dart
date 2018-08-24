import 'package:dartson/dartson.dart';

import 'src/my_class.dart';

part 'serializer.g.dart';

@Serializer(entities: [
  Person,
])
final serializer = serializer$dartson;
