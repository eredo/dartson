library dartson.test.simple;

import '../../lib/dartson.dart';

@TestAnnotation()
@DartsonEntity()
class SimpleClass {

  String name;

  num id;

  @DartsonProperty(name: 'last_name')
  String lastName;
  
  @DartsonProperty(ignore: true)
  String ignored;
}

class TestAnnotation {
  const TestAnnotation();
}
