# dartson

[![Build Status](https://drone.io/github.com/eredo/dartson/status.png)](https://drone.io/github.com/eredo/dartson/latest)

Dartson is a dart library which converts Dart Objects into their JSON representation. It helps you keep your code clean of `fromJSON` and `toJSON` functions by using dart:mirrors reflection. **It works after dart2js compiling.**

> #### NOTICE: The dart2js functionality works since Dart SDK 1.1.0.

A faster version of parsing the object is currently under development. It will provide fromJson and toJson methods after compilation using transformers.

## Latest changes
- dartson now supports custom transformer for specific type / an example for a basic DateTime converter can be found in:  

## Serializing objects in dart

```dart
library example;

import 'package:dartson/dartson.dart';

@MirrorsUsed(targets:const['example'],override:'*')
import 'dart:mirrors';

class EntityClass {
  String name;
  
  @DartsonProperty(name:"renamed")
  String otherName;
  
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

@MirrorsUsed(targets:const['example'],override:'*')
import 'dart:mirrors';

class EntityClass {
  String name;
  String _setted;
  
  @DartsonProperty(name:"renamed")
  String otherName;
  
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

## Mapping Maps and Lists to dart objects
Frameworks like Angular.dart come with several HTTP services which already transform the HTTP response to a map using JSON.encode. To use those encoded Maps or Lists use `map` and `mapList`.

```dart
library example;

import 'package:dartson/dartson.dart';

@MirrorsUsed(targets:const['example'],override:'*')
import 'dart:mirrors';

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
  EntityClass object = map({"name":"test","renamed":"blub","notVisible":"it is", "setted": "awesome"}, EntityClass);  
  print(object.name); // > test
  print(object.otherName); // > blub
  print(object.notVisible); // > it is
  print(object.setted); // > awesome
  
  // to parse a list of items use [parseList]
  List<EntityClass> list = mapList([{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}], EntityClass);
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
  registerTransformer(new DateTimeParser<DateTime>());
}
```

## Use default transformers

```dart
library test;

import 'package:dartson/dartson.dart';
import 'package:dartson/default_transformers.dart' as dd;

void main() {
  dd.register();
}
```

## Roadmap

#### dart2js
I'm thinking of a transformer which saves the hole mirrors reflection and increases the performance. It also should reduce the JavaScript size.

#### Custom serializing handler (implemented since 0.1.5)
Version 0.2.0 will have the functionality to define the way you want to encode / decode specific types.


## TODO

- Better dart2js solution
- Handle recrusive errors
