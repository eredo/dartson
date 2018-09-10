# dartson
[![Pub Version](https://img.shields.io/pub/v/dartson.svg)](https://pub.dartlang.org/packages/dartson)
[![Build Status](https://travis-ci.org/eredo/dartson.svg?branch=master)](https://travis-ci.org/eredo/dartson)
[![Coverage Status](https://coveralls.io/repos/github/eredo/dartson/badge.svg)](https://coveralls.io/github/eredo/dartson)

**Dartson 1.0.0 is currently in alpha. The public API might be subject to change.**

Dartson is a dart library which converts Dart Objects into their JSON representation. It helps you keep your code clean
of `fromJSON` and `toJSON` functions by providing a builder which generates the serialization methods.

## Usage

Add the following lines to your `pubspec.yaml` in order to use dartson:

```
dependencies:
  dartson: ^1.0.0
  
dev_dependencies:
  build_runner: ^0.10.0
```

Dartson is using a central serializer instead of serializers for each object, therefore create a 
central file which refers the objects that need to be serialized:

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
final Dartson<Map<String, dynamic>> serializer = _serializer$dartson;
```

Dartson encodes and decodes into a serializable Map (`Map<String, dynamic>`) by default. In order to
encode and decode into a json string (in previous versions done by using `Dartson.JSON`) directly, call the
`useCodec` method on the generated `Dartson` instance, which creates a new instance using the provided codec.

```dart
import 'dart:convert';

import 'package:dartson/dartson.dart';
import 'package:some_dependency/some_class.dart';

import 'my_class.dart';

@Serializer(
  entities: [
    MyClass,
    SomeClass,
  ],
)
final Dartson<String> serializer = _serializer$dartson.useCodec(json);
```

### Extending the serializer

Dartson supports extending serializers to provide a module approach. This is necessary to support functionality
like deferred loading. This also may improve build times, so when changing an entity only a part of the 
serializer is regenerated.

**serializer_init.dart**
```dart
import 'dart:convert';

import 'package:dartson/dartson.dart';
import 'package:some_dependency/some_class.dart';

import 'my_class.dart';

@Serializer(
  entities: [
    MyClass,
    SomeClass,
  ],
)
final Dartson<String> serializer = _serializer$dartson.useCodec(json);
```

**serializer_second.dart**
```dart
import 'package:dartson/dartson.dart';

import 'other_class.dart';
import 'serializer_init.dart' as fs;

@Serializer(
  entities: [
    OtherClass,
  ],
)
final Dartson<String> serializer = fs.serializer.extend(_serializer$dartson);
```

Notice that `extend` provides a completely new instance of `Dartson`. Also the entities provided by the
serializer on which `extend` was called can be overwritten by the entities used in the serializer passed
as the argument (in this case: `_serializer$dartson` entities may overwrite `fs.serializer` entities). 

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