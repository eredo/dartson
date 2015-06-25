# dartson
[![Pub Version](https://img.shields.io/pub/v/dartson.svg)](https://pub.dartlang.org/packages/dartson)
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
- Support of nested generics (example: ```Map<String,List<MyClass>>```)
- Support of methods within entities (example: ```String getAName() => "${whatEver}.Name";```)
- "as" import of dartson within a library separated into parts
- Complete end2end testing


### How the transformer works

1. All dartson imports "package:dartson/dartson.dart" are rewritten to "package:dartson/dartson_static.dart"
2. Classes that are annotated using "@Entity" receive 3 methods "dartsonEntityEncode", "dartsonEntityDecode", "newEntity" and implement "StaticEntity"

### Known issues:

- Entities cannot contain one of the following methods: "dartsonEntityEncode", "dartsonEntityDecode", "newEntity"
- The interface StaticEntity will be added to the global namespace, there shouldn't be any other class named the same
- Entities need to have a default constructor without any arguments
- Entities of third party libraries do not work
- Entities can only extend other Entities


## Latest changes
- dartson now supports custom transformer for specific type / an example for a basic DateTime converter can be found in:  
- transformer support
- TypeTransformer support for dart2js transformer

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
  
  // to parse a list of items use [decode] and set the third argument to true
  List<EntityClass> list = dson.decode('[{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}]', new EntityClass(), true);
  print(list.length); // > 2
  print(list[0].name); // > test
  print(list[0].children[0].name); // > child1
}
```

## Mapping Maps and Lists to dart objects

Frameworks like Angular.dart come with several HTTP services which already transform the HTTP response to a map using JSON.encode. To use those encoded Maps or Lists use `map`.

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
  
  // to parse a list of items use [map] and set the third argument to true
  List<EntityClass> list = dson.map([{"name":"test", "children": [{"name":"child1"},{"name":"child2"}]},{"name":"test2"}], new EntityClass(), true);
  print(list.length); // > 2
  print(list[0].name); // > test
  print(list[0].children[0].name); // > child1
}
```


## Writting custom TypeTransformers

Transformers are used to encode / decode none serializable types that shouldn't be treated  as objects / lists (for example DateTime).

```dart

/// A simple DateTime transformer which uses the toString() method.
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

## Serialize (circular) references

Use ```String jsonString = dson.encodeReferenceAware(object);``` instead of ```String jsonString = dson.encode(object);``` to serialize object graphs. The object graph may include circular references. Use ```dson.decodeReferenceAware(json, object)``` to deserialize.

Note: Lists and Maps will not be serialized reference aware!

References to already serialized objects will be represented by an placeholder (map): ```{ "__reference#__": <id> }```. To referenced objects an identifier will be added to the serializable map (json): ```"__instance#__": <id>```. See sample below.


Sample:

```
library example;

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

void main() {
  var dson = new ds.Dartson.JSON();

  var p1 = new Person()
      ..id = 1
      ..name = 'Yin';
  var p2 = new Person()
      ..id = 2
      ..name = 'Yang'
      ..parent = p1;
  p1.parent = p2; // circular reference

  var t1 = new Tag()
      ..id = 1
      ..name = 'Test'
      ..persons = [p1, p2];

  var store = new PersonStore()
      ..persons = [p1, p2]
      ..tags = [t1];

  // serialize:
  var json = dson.encodeReferenceAware(store);
  
/* will return:
{  
  "persons":[  
    {  
      "id":1,
      "name":"Yin",
      "__instance#__":1,
      "parent":{  
        "id":2,
        "name":"Yang",
        "parent":{  
          "__reference#__":1
        },
        "__instance#__":2
      }
    },
    {  
      "__reference#__":2
    }
  ],
  "tags":[  
    {  
      "id":1,
      "name":"Test",
      "persons":[  
        {  
          "__reference#__":1
        },
        {  
          "__reference#__":2
        }
      ]
    }
  ]
}
*/

	// deserialize:
	var deserialized = dson.decodeReferenceAware(json, new PersonStore());
}
```



