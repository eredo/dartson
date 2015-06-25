library dartson_test.test_referenceaware;

import 'package:test/test.dart';
import './fixture/circular_referenced_model.dart';

const json = '{"persons":[{"id":1,"name":"Yin","__instance#__":1,"parent":{"id":2,"name":"Yang","parent":{"__reference#__":1},"__instance#__":2}},{"__reference#__":2}],"tags":[{"id":1,"name":"Test","persons":[{"__reference#__":1},{"__reference#__":2}]}]}';

void main() {}

/// dson: static or mirror-based version of Dartson
void testSerializeAndDeserializeReferenceAware(var dson) {
  test('serialize static: circular references', () {
    var p1 = new Person()
      ..id = 1
      ..name = 'Yin';
    var p2 = new Person()
      ..id = 2
      ..name = 'Yang'
      ..parent = p1;
    p1.parent = p2;

    var t1 = new Tag()
      ..id = 1
      ..name = 'Test'
      ..persons = [p1, p2];

    var store = new PersonStore()
      ..persons = [p1, p2]
      ..tags = [t1];

    expect(dson.encodeReferenceAware(store), json);
  });

  test('parse static: circular references', () {
    var store = dson.decodeReferenceAware(json, new PersonStore());

    expect(store.persons.length, 2);
    expect(store.tags.length, 1);
    var p1 = store.persons[0];
    var p2 = store.persons[1];
    var t1 = store.tags[0];
    expect(p1.id, 1);
    expect(p1.name, 'Yin');
    expect(p2.id, 2);
    expect(p2.name, 'Yang');
    expect(p1.parent, same(p2));
    expect(p2.parent, same(p1));

    expect(t1.persons.length, 2);
    expect(t1.persons[0], same(p1));
    expect(t1.persons[1], same(p2));
  });
}