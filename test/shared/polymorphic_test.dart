library dartson_test.test_polymorphic;

import 'dart:convert' as convert;
import 'package:test/test.dart';
import '../fixture/polymorphic_model.dart';

const json = '{"employees":[{"__identifier__":"employee","name":"Tim","__instance#__":1},{"__identifier__":"employee","name":"Tom","__instance#__":2},{"__identifier__":"mananger","team":[{"__reference#__":1},{"__reference#__":2}],"name":"Bob"}]}';

void main() {}

/// dson: static or mirror-based version of Dartson
void testSerializeAndDeserializePolymorphic(var dsonFactory) {
  test('serialize: inheritance', () {
    var dson = dsonFactory();
    dson.addIdentifier("employee", Employee);
    dson.addIdentifier("mananger", Manager);

    var e1 = new Employee()
      ..name = 'Tim';
    var e2 = new Employee()
      ..name = 'Tom';
    var m1 = new Manager()
      ..name = 'Bob'
      ..team = [e1, e2];

    var company = new Company()
      ..employees = [e1, e2, m1];

    // encoded json might differ in order of field of super classes
    // therefore compare map instead of string
    expect(convert.JSON.decode(dson.encodeReferenceAware(company)),  convert.JSON.decode(json));
  });

  test('parse: inheritance', () {
    var dson = dsonFactory();
    dson.addIdentifier("employee", Employee);
    dson.addIdentifier("mananger", Manager);

    var company = dson.decodeReferenceAware(json, new Company());

    expect(company.employees.length, 3);
    var e1 = company.employees[0];
    var e2 = company.employees[1];
    var e3 = company.employees[2];
    expect(e1 is Employee, true);
    expect(e1 is Manager, false);
    expect(e1.name, "Tim");

    expect(e2 is Employee, true);
    expect(e2 is Manager, false);
    expect(e2.name, "Tom");

    expect(e3 is Employee, true);
    expect(e3 is Manager, true);
    expect(e3.name, "Bob");

    expect(e3.team.length, 2);
    expect(e3.team[0], same(e1));
    expect(e3.team[1], same(e2));
  });

  test('parse: identifier for root', () {
    var json = '{"__identifier__":"cpny"}';

    var dson = dsonFactory();
    dson.addIdentifier("cpny", Company);

    var company = dson.decodeReferenceAware(json, null); // root type not specified
    expect(company is Company, true);
  });

}