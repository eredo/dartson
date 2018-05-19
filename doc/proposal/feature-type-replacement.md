# Feature proposal: Type replacement

This feature was somewhat supported in dartson by setting up a custom transformer which returned another type that
inherited the actual type of the property.

## Goal

Make it easy to define a custom type which is used as a replacement for another type defined in the serialization target.
This is especially useful if the original object was automatically generated and the implementation contains user written
code.

## Example

**Note: This code is not a valid dartson implementation and only used to show the actual feature part**

```dart
class ExampleObject {
  BaseObject myObject;
}

class BaseObject {
  String text;
}

class ImplementationBaseObject extends BaseObject {
  void append(String part) => text += part;
}

@Serializer(
  typeReplacement: const {
    BaseObject: ImplementationBaseObject,
  },
)
final serializer = self.serializer$Serializer;

void main() {
  final obj = serializer.decode('{"myObject":{"text": "test"}}', ExampleObject);
  print(obj.myObject.runtimeType); // ImplementationBaseObject
}
```
