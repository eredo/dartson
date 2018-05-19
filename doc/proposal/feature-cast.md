# Feature proposal: `dartson.cast`

This is a new feature which provides an easier way to work with dynamic data. 

## Goal

Cast entities which contain deserialized values to another entity type and back without loosing properties. Also provide
a strict way of casting objects by comparing their properties with or without any exceptions. 

## Example

**Note: This code is not a valid dartson implementation and only used to show the actual feature part**

```dart
class Account {
  String name;
  double money;
}

class Customer {
  double money;
  bool firstTime;
  
  bool pay(double cost) {
    if (money < cost) {
      return false;
    }
    
    money -= cost;
    return true;
  }
}


void main() {
  Account acc = serializer.decode('{"name":"Test account","money":10.5}', Account);
  final CastResult<Customer> cast = serializer.cast(acc, Customer);
  print(cast.result.runtimeType); // Customer
  print(cast.unknownProperties); // {"name":"Test account"}
  print(cast.origin.runtimeType); // Account
  
  cast.result.pay(5.0);
  acc = cast.revert();
  print(acc.name); // "Test account"
  print(acc.money); // 5.5
  
  // strict implementation
  serializer.cast(acc, Customer, strict: true); // throws Exception: Property "firstTime" not found
  
  // strict with exception
  serializer.cast(acc, Customer, strict: true, exclude: ['firstTime']);
  
  // With transformation
  serializer.cast(acc, Customer, transform: {'firstTime': (Account acc) => acc.name != 'test'});
  
  // With defaults
  serializer.cast(acc, Customer, defaults: {'firstTime': true});
}
```

## Questions

Should cast work with immutable objects as such not modify the origin? Or should cast be able to modify the origin
object when `revert` is called?