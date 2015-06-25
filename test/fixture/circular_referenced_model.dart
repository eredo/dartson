library dartson.test.circular;

import 'package:dartson/dartson.dart' as ds;

@ds.Entity()
class PersonStore {
  List<Person> persons;
  List<Tag> tags;
}

@ds.Entity()
class Person {
  int id;
  String name;
  Person parent;
}

@ds.Entity()
class Tag {
  int id;
  String name;
  List<Person> persons;
}
