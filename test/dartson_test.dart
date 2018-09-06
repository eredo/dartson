@TestOn('vm')
import 'package:test/test.dart';
import 'package:dartson/dartson.dart';

import 'src/serializer.dart';
import 'src/my_class.dart';
import 'src/sub_class.dart';

void main() {
  group('$Dartson', () {
    test('should encode the object', () {
      final result = serializer.encode(MyClass()
        ..name = 'hello'
        ..numDouble = 1.0
        ..subClass = (SubClass()..name = 'test'));
      expect(result['name'], 'hello');
      expect(result['numDouble'], 1.0);
      expect(result['subClass']['name'], 'test');
    });

    test('should decode the object', () {
      final result = serializer.decode<MyClass>({
        'name': 'hello',
        'numDouble': 1,
        'subClass': {'name': 'hello2'}
      });
      expect(result.name, 'hello');
      expect(result.numDouble, 1.0);
      expect(result.subClass.name, 'hello2');
    });
  });
}
