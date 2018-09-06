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

    test('should encode lists', () {
      final result = serializer.encode(MyClass()
        ..subClasses = [
          SubClass()
            ..name = '1'
            ..aliases = ['t1', 't12'],
          SubClass()
            ..name = '2'
            ..aliases = ['t2', 't22']
        ]);

      expect(result['subClasses'][0]['name'], '1');
      expect(result['subClasses'][1]['name'], '2');
      expect(result['subClasses'][0]['aliases'], ['t1', 't12']);
      expect(result['subClasses'][1]['aliases'], ['t2', 't22']);
    });

    test('should decode lists', () {
      final result = serializer.decode<MyClass>({
        'subClasses': [
          {
            'name': '1',
            'aliases': ['t1', 't12']
          },
          {
            'name': '2',
            'aliases': ['t2', 't22']
          },
        ],
      });

      expect(result.subClasses, hasLength(2));
      expect(result.subClasses[0].name, '1');
      expect(result.subClasses[1].name, '2');
      expect(result.subClasses[0].aliases, ['t1', 't12']);
      expect(result.subClasses[1].aliases, ['t2', 't22']);
    });

    test('should encode maps', () {
      final result = serializer.encode(MyClass()
        ..complexMap = {
          't1': SubClass()..name = 't1',
          't2': SubClass()..name = 't2',
        });

      expect(result['complexMap'], allOf(isMap, hasLength(2)));
      expect(result['complexMap']['t1']['name'], 't1');
      expect(result['complexMap']['t2']['name'], 't2');
    });

    test('should decode maps', () {
      final result = serializer.decode<MyClass>({
        'complexMap': {
          't1': {'name': 't1'},
          't2': {'name': 't2'},
        }
      });

      expect(result.complexMap, allOf(isMap, hasLength(2)));
      expect(result.complexMap['t1'].name, 't1');
      expect(result.complexMap['t2'].name, 't2');
    });
  });
}
