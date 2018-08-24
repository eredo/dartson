# dartson
[![Pub Version](https://img.shields.io/pub/v/dartson.svg)](https://pub.dartlang.org/packages/dartson)
[![Build Status](https://travis-ci.org/eredo/dartson.svg?branch=master)](https://travis-ci.org/eredo/dartson)

Dartson is a dart library which converts Dart Objects into their JSON representation. It helps you keep your code clean
of `fromJSON` and `toJSON` functions by providing a builder which provides the serialization mappings.

## Usage

Add the following lines to your `pubspec.yaml` in order to use dartson:

```
dependencies:
  dartson: ^1.0.0
  
dev_dependencies:
  build_runner: ^0.10.0
```

Dartson is using a central serializer instead of generated serializers for each object, therefore
create a central file which refers the objects that need to be serialized:

```dart
import 'package:dartson/dartson.dart';
import 'package:some_dependency/some_class.dart';

import 'my_class.dart';

@Serializer(
  entities: [
    MyClass,
    SomeClass,
  ],
)
final Dartson serializer = serializer$dartson;
```

## Writting custom TypeTransformers
Transformers are used to encode / decode none serializable types that shouldn't be treated  as objects / lists (for example DateTime).

```dart

/// A simple DateTime transformer which uses the toString() method.
class DateTimeParser extends TypeTransformer<String, DateTime> {
  DateTime decode(String value) => DateTime.parse(value);

  String encode(DateTime value) => value.toString();
}
```

In order to use the TypeTransformer you need to register the transformer for the serializer:

```dart
import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';

import 'my_class.dart';

@Serializer(
  entities: [
    MyClass,
  ],
  transformers: [
    DateTimeParser,
  ],
)
final Dartson serializer = serializer$dartson;
```