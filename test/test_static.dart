library dartson.test_static;

import '../lib/dartson_static.dart';
import 'package:unittest/unittest.dart';

class SimpleClass implements CompiledDartsonEntity {
  String name;
  num number;
  
  SimpleClass();
  SimpleClass.dConstr();
  
  void dFromObject(Map obj) {
    name = obj["name"];
    number = obj["number"];
  }
  
  Map dToObject() {
    return {"name": name, "number": number};
  }
}

class ParentClass implements CompiledDartsonEntity {
  String name;
  SimpleClass child;
  
  ParentClass();
  ParentClass.dConstr();
  
  void dFromObject(Map obj) {
    name = obj["name"];
    child = initEntity(SimpleClass, obj["child"]);
  }
  
  Map dToObject() {
    return {"name": name, "child": child.dToObject()};
  }  
}

void main() {
  
  test('fill a SimpleClass with an object', () {
    var obj = new SimpleClass();
    fill({"name": "Test", "number": 11}, obj);
    
    expect(obj.name, "Test");
    expect(obj.number, 11);
  });
  
  test('fill a ParentClass with an object', () {
    var obj = new ParentClass();
    fill({"name": "test1", "child": {"name": "asd", "number":2}}, obj);
    
    expect(obj.name, "test1");
    expect(obj.child is SimpleClass, true);
    expect(obj.child.name, "asd");
    expect(obj.child.number, 2);
  });
}