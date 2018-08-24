import 'package:dartson/dartson.dart';

class Person {
  String firstName;
  String lastName;

  @Property(name: 'isEmployed')
  bool employed;

  @Property(ignore: true)
  bool changed;
}
