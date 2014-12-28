library dartson.test.simple;

import 'package:dartson/dartson.dart' as ddd;

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
  
  Map<String,ChildClass> mapOfChildren;
  
  ChildClass parseSomething(String jsonStr) {
    var data = ddd.parse(jsonStr, ChildClass);
    return data;
  }
}


@ddd.Entity()
class ChildClass {
  bool isAwesome;
  int integer;
  String awesomeName;
}

class TestAnnotation {
  const TestAnnotation();
}

abstract class ImplementationTest {
  ChildClass parseSomething(String jsonStr);
}