import 'package:dartson_test/serializer.dart';

void main() {
  print(serializer.encode(MyClass()..name = 'test'));
  print(serializer.decode<MyClass>('{"name":"test"}').name);
}
