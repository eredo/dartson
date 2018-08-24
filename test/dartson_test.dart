@TestOn('vm && browser')
import 'package:test/test.dart';
import 'package:dartson/dartson.dart';

void main() {
  group('$Dartson', () {
    final dartson = Dartson({
      MyClass: DartsonEntity<MyClass>(_myClassEncoder, _myClassDecoder),
    });

    test('should encode the object', () {
      expect(
          dartson.encode(MyClass()..test = 'hello'), equals({'test': 'hello'}));
    });

    test('should decode the object', () {
      expect(dartson.decode({'test': 'hello'}, MyClass),
          equals(MyClass()..test = 'hello'));
    });
  });
}

class MyClass {
  String test;

  @override
  bool operator ==(other) {
    return other is MyClass && other.test == test;
  }
}

Map<String, dynamic> _myClassEncoder(MyClass obj, Dartson inst) => {
      'test': obj.test,
    };

MyClass _myClassDecoder(Map<String, dynamic> data, Dartson inst) =>
    MyClass()..test = data['test'];
