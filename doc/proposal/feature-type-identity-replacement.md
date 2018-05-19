# Feature proposal: Type identity replacement

This feature was somewhat supported in dartson by setting up a custom transformer which returned another type base on 
a property provided which identified the type that inherited the actual type of the property.

## Goal

Provide a functionality to use custom implementations of a type based on a property value within the actual object.

## Example

**Note: This code is not a valid dartson implementation and only used to show the actual feature part**

```dart
class Company {
  List<User> employee;
}

class User {
  @typeIdentifier
  String role;
  String fistName;
  String lastName;
}

@TypeIdentity('dev')
class Developer extends User {
  List<String> programmingLanguages;
}

@TypeIdentity('test')
class Tester extends User {
  List<String> components;
}

@Serializer(
  identityReplacement: const {
    User: const [Developer, Tester],
  },
)
final serializer = self.serializer$Serializer;

void main() {
  final obj = serializer.decode('{"employee":[{"role": "test"}, {"role":"dev"}]}', Company);
  print(obj.employee[0].runtimeType); // Tester
  print(obj.employee[1].runtimeType); // Developer
}
```

## Reference

This should also work together with [Type Replacement](./feature-type-replacement.md).

```dart
class DeveloperImpl extends Developer {
  void writeCode(String code) => print('developer says: "This code: $code should work. Because I wrote it."');
}

class TesterImpl extends Tester {
  void test(String code) => print('tester says: "This is broken. It\'s supposed to be \'hello world\' not \'hello world \'".');  
}

@Serializer(
  typeReplacement: const {
    Developer: DeveloperImpl,
    Tester: TesterImpl,    
  },
  identityReplacement: const {
    User: const [Developer, Tester],
  },
)
final serializer = self.serializer$Serializer;
```