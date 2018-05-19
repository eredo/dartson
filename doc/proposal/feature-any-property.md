# Feature proposal: `@anyProperty`

This feature was requested in issue [#41](https://github.com/eredo/dartson/issues/41). 

## Goal

Provide a map of values which were provided in the original map during decoding but didn't have a property defined in
the target object. 

## Example

**Note: This code is not a valid dartson implementation and only used to show the actual feature part**

```dart
class ExampleObject {
  String name;
  
  @anyProperty
  Map<String, dynamic> unknownProperties;
}

void main() {
  final obj = serializer.decode('{"name":"hello","isUnknown":true}', ExampleObject);
  print(obj.unknownProperties); // {"isUnknown":true}
}
```