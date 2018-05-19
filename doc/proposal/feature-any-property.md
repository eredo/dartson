# Feature proposal: `@anyProperty`

This feature was requested in issue #41. 

## Goal

Provide a map of values which where provided in the original map during decoding but didn't have a defined property in
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