# dartson

[![Build Status](https://drone.io/github.com/eredo/dartson/status.png)](https://drone.io/github.com/eredo/dartson/latest)

Dartson is a dart library which converts Dart Objects into their JSON representation. It helps you keep your code clean of `fromJSON` and `toJSON` functions by using dart:mirrors reflection. **It works after dart2js compiling.**

## Transformer implementation
This build contains the first version of a transformer. **IT IS STILL UNDER DEVELOPMENT AND NOT COMPLETELY TESTED YET**
Add the following lines to the pubspec.yaml in order to use the transformer:

```
transformers:
- dartson
```

Remove the @MirrorsUsed annotation and the assigned import if it's no longer used by any other library.
When using the transformer, mirrors are completely removed when pub build is called.

### Features not completed yet
- Support of transformers
- Support of nested generics (example: ```Map<String,List<MyClass>>```)
- Support of methods within entities (example: ```String getAName() => "${whatEver}.Name";```)
- "as" import of dartson within a library separated into parts
- Complete end2end testing


### How the transformer works

1. All dartson imports "package:dartson/dartson.dart" are rewritten to "package:dartson/dartson_static.dart"
2. Classes that are annotated using "@Entity" receive 3 methods "dartsonEntityEncode", "dartsonEntityDecode", "newEntity" and implement "StaticEntity"
3. All dartson method calls "parse", "parseList", "map", "mapList" are rewritten using an instance of the entity

```
var list = parseList('[{"name":"test"},{"name":"x"}]', MyEntity);
```

will be changed to:

```
var list = parseList('[{"name":"test"},{"name":"x"}]', new MyEntity());
```

### Known issues:

- Entities cannot contain one of the following methods: "dartsonEntityEncode", "dartsonEntityDecode", "newEntity"
- The interface StaticEntity will be added to the global namespace, there shouldn't be any other class named the same
- Entities need to have a default constructor without any arguments
- Entities of third party libraries do not work
- Entities can only extend other Entities


## Latest changes
- dartson now supports custom transformer for specific type / an example for a basic DateTime converter can be found in:  
- transformer support


## Serializing objects in dart

```dart
library example;

import 'package:dartson/dartson.dart';

@Entity()
class EntityClass {
  String name;
  
  @Property(name:"renamed")
  bool otherName;
  
  @Property(ignore:true)
  String notVisible;
  
  // private members are never serialized
  String _private = "name";
  
  String get doGetter => _private;
}

void main() {
  var dson = new Dartson.JSON();

  EntityClass object = new EntityClass();
  object.name = "test";
  object.otherName = "blub";
  object.notVisible = "hallo";
  
  String jsonString = dson.encode(object);
  print(jsonString);
  // will return: '{"name":"test","renamed":"blub","doGetter":"name"}'
}
```


## Parsing json to dart object

```dart
library example;

import 'package:dartson/dartson.dart';

@Entity()
class EntityClass {
  String name;
  String _setted;
  
  @Property(name:"renamed")
  bool otherName;
  
  @Property(ignore:true)
  String notVisible;
  
  List<EntityClass> children;
  
  set setted(String s) => _setted = s;
  String get setted => _setted;
}

void main() {
  var dson = new Dartson.JSON();

  EntityClass object = dson.decode('{"name":"test","renamed":"blub","notVisible":"it is", "setted": "awesome"}', new EntityClass());
  
  print(object.name); // > test
  print(object.otherName); // > blub
  print(object.notVisible); // > it is
  print(object.setted); // > awesome
  
  // to parse a list of items use [parseList]
  List<EntityClass> list = dson.decode('[{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}]', new EntityClass(), true);
  print(list.length); // > 2
  print(list[0].name); // > test
  print(list[0].children[0].name); // > child1
}
```

## Mapping Maps and Lists to dart objects

Frameworks like Angular.dart come with several HTTP services which already transform the HTTP response to a map using JSON.encode. To use those encoded Maps or Lists use `map` and `mapList`.

```dart
library example;

import 'package:dartson/dartson.dart';

@Entity()
class EntityClass {
  String name;
  String _setted;
  
  @Property(name:"renamed")
  bool otherName;
  
  @Property(ignore:true)
  String notVisible;
  
  List<EntityClass> children;
  
  set setted(String s) => _setted = s;
  String get setted => _setted;
}

void main() {
  var dson = new Dartson.JSON();

  EntityClass object = dson.map({"name":"test","renamed":"blub","notVisible":"it is", "setted": "awesome"}, new EntityClass());
  print(object.name); // > test
  print(object.otherName); // > blub
  print(object.notVisible); // > it is
  print(object.setted); // > awesome
  
  // to parse a list of items use [parseList]
  List<EntityClass> list = dson.map([{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}], new EntityClass(), true);
  print(list.length); // > 2
  print(list[0].name); // > test
  print(list[0].children[0].name); // > child1
}
```


## Writting custom TypeTransformers

Transformers are used to encode / decode none serializable types that shouldn't be treated  as objects / lists (for example DateTime).

```dart
/**
 * A simple DateTime transformer which uses the toString() method.
 */
class DateTimeParser<T> extends TypeTransformer {
  T decode(dynamic value) {
    return DateTime.parse(value);
  }

  dynamic encode(T value) {
    return value.toString();
  }
}
```

In order to use the TypeTransformer you need to register the transformer in a main function:

```dart
// ...
void main() {
  var dson = new Dartson.JSON();
  dson.addTransformer(new DateTimeParser(), DateTime);
}
```

## Use default transformers

```dart
library test;

import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';

void main() {
  var dson = new Dartson.JSON();
  dson.addTransformer(new DateTimeParser(), DateTime);
}
```
