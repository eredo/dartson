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
final Dartson serializer = _serializer$dartson;
```

## Writting custom TypeTransformers
Transformers are used to encode / decode none serializable types that shouldn't be treated  as objects / lists (for example DateTime).

```dart

/// A simple DateTime transformer which uses the toString() method.
class DateTimeParser implements TypeTransformer<String, DateTime> {
  // Make sure to add a constant constructor, because dartson will initiate all tranformers
  // as constant to improve dart2js compilation.
  const DateTimeParser();
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
final Dartson serializer = _serializer$dartson;
```

## Roadmap for 1.0.0 alpha/beta

- First alpha release evaluates and tests the reuse of `json_serializable` 
  (refactorings during the alpha/beta will be necessary)
- Additional functionality from proposals will be ported
- Looking for feedback in regards of usability from users
- Further benchmarking of potential bottlenecks because of single point of  
  the builder

## Further features planned

- See doc/proposal for general features
- Add tool to generate serializer.dart based on `serializer.decode<T>()` and
  `serializer.encode(T)` usage
- Add analyzer plugin to detect potential issues of used entities which are not 
  present in the serializer definition