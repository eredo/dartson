library dartson.test.simple;

import 'package:dartson/dartson.dart' as ddd;
import 'package:dartson/transformers/date_time.dart';

@TestAnnotation()
@ddd.Entity()
class SimpleClass implements ImplementationTest {
  String name;

  num id;

  @ddd.Property(name: 'last_name')
  String lastName;

  @ddd.Property(ignore: true)
  String ignored;

  ChildClass child;

  List<ChildClass> listOfChildren;

  Map<String, ChildClass> mapOfChildren;

  ChildClass parseSomething(String jsonStr) {
    ddd.Dartson dson = new ddd.Dartson.JSON();
    dson.addTransformer(new DateTimeParser(), DateTime);
    var data = dson.decode(jsonStr, new ChildClass());
    return data;
  }
}

@ddd.Entity()
class ChildClass {
  bool isAwesome;
  int integer;
  String awesomeName;
  DateTime dateTime;
}

class TestAnnotation {
  const TestAnnotation();
}

abstract class ImplementationTest {
  ChildClass parseSomething(String jsonStr);
}
