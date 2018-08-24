import 'serializer.dart';
import 'my_class.dart';

void usage() {
  final myClass = MyClass()
    ..name = 'test name'
    ..number = 29
    ..hasBoolean = true;

  final myObj = serializer.encode(myClass);
  print(myObj);

  final backToObj = serializer.decode(myObj, MyClass);
  print(backToObj);
}
