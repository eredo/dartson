@TestOn('vm')
import 'dart:convert';

import 'package:test/test.dart';
import 'package:dartson/dartson.dart';

import 'src/serializer.dart';
import 'src/my_class.dart';
import 'src/sub_class.dart';
import 'src/my_impl.dart';

void main() {
  final jsonSerializer = serializer.useCodec(json);

  group('$Dartson', () {
    test('should throw when encoding an unknown entity', () {
      expect(() => serializer.encode(UnknownEntity()),
          throwsA(TypeMatcher<UnknownEntityException>()));
      expect(() => serializer.encodeList([UnknownEntity()]),
          throwsA(TypeMatcher<UnknownEntityException>()));
    });

    test('should throw when decoding an unknown entity', () {
      expect(() => serializer.decode<UnknownEntity>({}),
          throwsA(TypeMatcher<UnknownEntityException>()));
      expect(() => jsonSerializer.decode<UnknownEntity>('{}'),
          throwsA(TypeMatcher<UnknownEntityException>()));
      expect(() => serializer.decodeList<UnknownEntity>([{}]),
          throwsA(TypeMatcher<UnknownEntityException>()));
      expect(() => jsonSerializer.decodeList<UnknownEntity>('[{}]'),
          throwsA(TypeMatcher<UnknownEntityException>()));
    });

    test('should encode the object', () {
      final result = serializer.encode(MyClass('test')
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
      final result = serializer.encode(MyClass('test')
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
      final result = serializer.encode(MyClass('test')
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

    test('should encode replacements', () {
      final result = serializer
          .encode(MyClass('test')..replacement = (MyImpl()..name = 'test'));
      expect(result['replacement']['name'], 'test');
    });

    test('should decode replacements', () {
      final result = serializer.decode<MyClass>({
        'replacement': {'name': 'test'}
      });

      expect(result.replacement, TypeMatcher<MyImpl>());
      expect(result.replacement.name, 'test');
    });

    test('should decode lists', () {
      final result = serializer.decodeList<MyClass>([
        {'name': 'test1'},
        {'name': 'test2'},
      ]);

      expect(result, allOf(isList, hasLength(2)));
      expect(result[0].name, 'test1');
      expect(result[1].name, 'test2');
    });

    test('should decode serialized lists', () {
      final result = jsonSerializer.decodeList<MyClass>('''[
        {"name": "test1"},
        {"name": "test2"}
      ]''');

      expect(result, allOf(isList, hasLength(2)));
      expect(result[0].name, 'test1');
      expect(result[1].name, 'test2');
    });

    test('should throw error if decoding list is not of type list', () {
      expect(() => serializer.decodeList<MyClass>(''),
          throwsA(TypeMatcher<TypeError>()));
      expect(() => jsonSerializer.decodeList<MyClass>('{}'),
          throwsA(TypeMatcher<TypeError>()));
    });

    test('should encode lists', () {
      final result = serializer.encodeList([
        MyClass('test')..name = 'test1',
        MyClass('test')..name = 'test2',
      ]) as List<Map<String, dynamic>>;

      expect(result, allOf(isList, hasLength(2)));
      expect(result[0]['name'], 'test1');
      expect(result[1]['name'], 'test2');
    });
  });
}

class UnknownEntity {}
