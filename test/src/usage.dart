import 'serializer.dart';
import 'my_class.dart';

void usage() {
  final myClass = MyClass('test')
    ..name = 'test name'
    ..number = 29
    ..hasBoolean = true;

  final myObj = serializer.encode(myClass);
  print(myObj);

  final backToObj = serializer.decode<MyClass>(myObj);
  print(backToObj);
}
