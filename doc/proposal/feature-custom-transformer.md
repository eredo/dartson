# Feature proposal: `CustomTransformer`

This feature is already provided by dartson. This proposal contains further additions
and notes when this feature ships with the code generation approach including `json_serializable`
support. 

## Goal

`CustomTransformer` provide the functionality to code the serialization and deserialization
of types outside of core types.

## Example

```dart
part 'example.g.dart';

class Example extends Object with _$ExampleSerializerMixin {
  DateTime myTime;
}
```

```dart
class MyDateTransformer extends _$MyDateTransformerMixin implements CustomTransformer<DateTime, String> {
  String encode(DateTime date) => '${date.hour}:${date.second}';
  DateTime decode(String dateStr) => new DateTime.now()
    ..hour = int.parse(dateStr.split(':')[0])
    ..second = int.parse(dateStr.split(':')[1]);
}
```

```dart
abstract class _$MyDateTransformerMixin {
  String get target => 'dart.core.DateTime';
}
```

```dart
void main() {
  var dson = new Dartson();
  dson.addTransformer(new MyDateTransformer());
  
  var obj = dson.decode('{"myTime": "14:10"}', new Example());
}
```