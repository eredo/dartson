library test_dartson;

import '../lib/dartson.dart';
import 'package:unittest/unittest.dart';

@DartsonEntity()
class TestClass1 {
  String name;
  bool matter;
  num number;
  List list;
  Map map;
  TestClass1 child;
  
  @DartsonProperty(ignore:true)
  bool ignored;
  
  @DartsonProperty(name:"the_renamed")
  String renamed;

  TestClass1();
}

class TestGetter {
  String _name;

  TestGetter([this._name]);

  String get name => _name;
}

class TestSetter {
  String _name;
  
  String get name => _name;
  set name(String n) => _name = n;
}

class NestedClass {
  String name;
  List list;
  TestGetter getter;

  NestedClass(this.name, this.list, this.getter);
}

void main() {
  DARTSON_DEBUG = true;

  test('serialize: simple array test', () {
    String str = serialize(['test1', 'test2']);
    expect(str, '["test1","test2"]');
  });

  test('serialize: mixed nested arrays', () {
    String str = serialize([[1,2,3],[3,4,5]]);
    expect(str, '[[1,2,3],[3,4,5]]');

    str = serialize(["test1", ["a","b"], [1,2], 3]);
    expect(str, '["test1",["a","b"],[1,2],3]');
  });

  test('serialize: simple map test', () {
    Map map = {"key1": "val1", "key2": 2};

    String str = serialize(map);
    expect(str, '{"key1":"val1","key2":2}');
  });

  test('serialize: mixed nested map', () {
    Map map = {
      "itsAmap": {
        "key1": 1,
        "key2": "val"
      },
      "itsAarray": [1,2,3],
      "keyk": "valo"
    };

    String str = serialize(map);
    expect(str, '{"itsAmap":{"key1":1,"key2":"val"},"itsAarray":[1,2,3],"keyk":"valo"}');
  });

  test('serialize: simple class', () {
    var test = new TestClass1();
    test.name = "test1";
    String str = serialize(test);
    print("Serialized: ${str}");
    expect(str,'{"name":"test1"}');
  });
  
  test('serialize: ignore in object', () {
    var test = new TestClass1();
    test.name = "test";
    test.ignored = true;
    expect(serialize(test), '{"name":"test"}');
  });
  
  test('serialize: renamed property of object', () {
    var test = new TestClass1();
    test.renamed = "test";
    expect(serialize(test), '{"the_renamed":"test"}');
  });

  test('serialize: simple getter class', () {
    expect(serialize(new TestGetter("test2")), '{"name":"test2"}');
  });

  test('serialize: nested class', () {
    expect(serialize(new NestedClass("test", [1,2,3], new TestGetter("get it"))),
      '{"name":"test","list":[1,2,3],"getter":{"name":"get it"}}');
  });

  test('parse: parser simple', () {
    print('parsing simple: {"name":"test","matter":true,"number":5,"list":[1,2,3],"map":{"k":"o"}}');
    TestClass1 test = parse('{"name":"test","matter":true,"number":5,"list":[1,2,3],"map":{"k":"o"},"the_renamed":"test"}', TestClass1);
    expect(test.name, 'test');
    expect(test.matter, true);
    expect(test.number, 5);
    expect(test.list.length, 3);
    expect(test.list[1], 2);
    expect(test.map["k"], "o");
    expect(test.renamed, "test");
  });
  
  test('parse: no constructor found', () {
    NoConstructorError err;
    try {
      NestedClass test = parse('{"name":"failure"}', NestedClass);
    } catch(ex) {
      err = ex;
    }
    
    expect(err != null, true);
    expect(err is NoConstructorError, true);
  });
  
  test('parse: nested parsing', () {
    TestClass1 test = parse('{"name":"parent","child":{"name":"child"}}', TestClass1);
    expect(test.child.name, "child");
  });
  
  test('parse: using setter', () {
    TestSetter test = parse('{"name":"test"}', TestSetter);
    expect(test.name, 'test');
  });
}
