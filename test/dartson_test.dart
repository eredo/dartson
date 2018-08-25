@TestOn('vm')
import 'package:test/test.dart';
import 'package:dartson/dartson.dart';

void main() {
  group('$Dartson', () {
    final dartson = Dartson({
      MyClass: DartsonEntity<MyClass>(_myClassEncoder, _myClassDecoder),
    });

    test('should encode the object', () {
      expect(
          dartson.encode(MyClass()
            ..test = 'hello'
            ..num = 1.0),
          equals({'test': 'hello', 'num': 1.0}));
    });

    test('should decode the object', () {
      expect(
          dartson.decode({'test': 'hello', 'num': 1}, MyClass),
          equals(MyClass()
            ..test = 'hello'
            ..num = 1.0));
    });
  });
}

class MyClass {
  String test;
  double num;

  @override
  bool operator ==(other) {
    return other is MyClass && other.test == test && other.num == num;
  }
}

Map<String, dynamic> _myClassEncoder(MyClass obj, Dartson inst) => {
      'test': obj.test,
      'num': obj.num,
    };

MyClass _myClassDecoder(Map<String, dynamic> data, Dartson inst) => MyClass()
  ..test = data['test']
  ..num = (data['num'] as num)?.toDouble();
