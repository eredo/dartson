# dartson

[![Build Status](https://drone.io/github.com/eredo/dartson/status.png)](https://drone.io/github.com/eredo/dartson/latest)

Dartson is a Dart library that can be used to convert Dart objects into a JSON string. It uses dart:mirrors reflection to rebuild the schema.

> #### NOTICE: Latest tests using dart dev channel 1.2.0-dev.1.0 (31918) passed successful using dart2js without any further adjustments. Feedback is welcomed!

## Serializing objects in dart

```dart
library example;

import 'package:dartson/dartson.dart';

// If the builder should recognize this class add the following annotation
@DartsonEntity()
class EntityClass {
  String name;
  
  @DartsonProperty(name:"renamed")
  bool otherName;
  
  @DartsonProperty(ignore:true)
  String notVisible;
  
  // private members are never serialized
  String _private = "name";
  
  String get doGetter => _private;
}

void main() {
  EntityClass object = new EntityClass();
  object.name = "test";
  object.otherName = "blub";
  object.notVisible = "hallo";
  
  String jsonString = serialize(object);
  print(jsonString);
  // will return: '{"name":"test","renamed":"blub","doGetter":"name"}'
}
```

## Parsing json to dart object

```dart
library example;

import 'package:dartson/dartson.dart';

// If the builder should recognize this class add the following annotation
@DartsonEntity()
class EntityClass {
  String name;
  String _setted;
  
  @DartsonProperty(name:"renamed")
  bool otherName;
  
  @DartsonProperty(ignore:true)
  String notVisible;
  
  List<EntityClass> children;
  
  set setted(String s) => _setted = s;
  String get setted => _setted;
}

void main() {
  EntityClass object = parse('{"name":"test","renamed":"blub","notVisible":"it is", "setted": "awesome"}', EntityClass);
  
  print(object.name); // > test
  print(object.otherName); // > blub
  print(object.notVisible); // > it is
  print(object.setted); // > awesome
  
  // to parse a list of items use [parseList]
  List<EntityClass> list = parseList('[{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}]', EntityClass);
  print(list.length); // > 2
  print(list[0].name); // > test
  print(list[0].children[0].name); // > child1
}
```

## Roadmap
I'm thinking of a transformer which saves the hole mirrors reflection and increases the performance. It also should reduce the JavaScript size.

## TODO

- Better dart2js solution
- Handle recrusive errors
