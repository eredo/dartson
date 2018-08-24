import 'package:dartson/dartson.dart';

class MyClass {
  String name;
  int number;
  @Property(name: 'boolean')
  bool hasBoolean;
  @Property(ignore: true)
  bool ignored;
}
