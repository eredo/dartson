import 'package:dartson/dartson.dart';

class MyClass extends BaseClass {
  String name;
  int number;
  @Property(name: 'boolean')
  bool hasBoolean;
  @Property(ignore: true)
  bool ignored;
  double numDouble;
  Uri uri;
  DateTime dateTime;
}

class BaseClass {
  bool inherited;
  @Property(name: 'inheritName')
  String inheritedRenamed;
  @Property(ignore: true)
  String inheritedIgnored;
}
