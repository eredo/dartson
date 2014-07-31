library test_dartson;

import '../lib/dartson.dart';
import 'package:unittest/unittest.dart';


@MirrorsUsed(targets: const[
  'test_dartson'
  ],
  override: '*')
import 'dart:mirrors';

void main() {
  DARTSON_DEBUG = false;

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
  
  test('serialize: simple object', () {
    var obj = {
      "test": "test"
    };
    JustObject test = new JustObject();
    test.object = obj;
    
    expect(serialize(test), '{"object":{"test":"test"}}');
  });

  test('serialize: simple class', () {
    var test = new TestClass1();
    test.name = "test1";
    String str = serialize(test);
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
    TestClass1 test = parse('{"name":"test","matter":true,"intNumber":2,"number":5,"list":[1,2,3],"map":{"k":"o"},"the_renamed":"test"}', TestClass1);
    expect(test.name, 'test');
    expect(test.matter, true);
    expect(test.intNumber, 2);
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
  
  test('parse: generics list', () {
    ListClass test = parse('{"list": [{"name": "test1"}, {"name": "test2"}]}', ListClass);
    
    expect(test.list[0].name, 'test1');
    expect(test.list[1].name, 'test2');
  });
  
  test('parse: simple list', () {
    SimpleList list = parse('{"list":[1,2,3]}', SimpleList);
    expect(list.list[0], 1);
  });
  
  test('parse: generic map', () {
    MapClass test = parse('{"map": {"test": {"name": "test"}, "test2": {"name": "test2"}}}', MapClass);

    expect(test.map["test"].name, "test");
    expect(test.map["test2"].name, "test2");
  });

  test('parse: simple map', () {
    SimpleMap test = parse('{"map": {"test": "test", "test2": "test2"}}', SimpleMap);

    expect(test.map["test"], "test");    
    expect(test.map["test2"], "test2");
  });
  
  test('parse: simple map with type declaration', () {
    SimpleMapString test = parse('{"map": {"test": 1, "test2": 2}}', SimpleMapString);

    expect(test.map["test"], 1);    
    expect(test.map["test2"], 2);
  });
  
  test('parse: list of simple class', () {
    List<SimpleClass> test = parseList('[{"name":"test"},{"name":"test2"}]', SimpleClass);
    expect(test[0].name, "test");
    expect(test[1].name, "test2");
  });
  
//  test('parse: just object', () {
//    JustObject obj = parse('{"object":"test"}', JustObject);
//    expect(obj.object, 'test');
//  });

  test('map: parse object', () {
    SimpleMapString test = map({
      "map": {"test": 1, "test2": 2}
    }, SimpleMapString);

    expect(test.map["test"], 1);
    expect(test.map["test2"], 2);
  });

  test('mapList: parse list', () {
    List<SimpleMapString> test = mapList([{"map": {"test": 1, "test2": 2}}, {"map": {"test": 3, "test2": 4}}], SimpleMapString);
    expect(test[0].map["test"], 1);
    expect(test[0].map["test2"], 2);
    expect(test[1].map["test"], 3);
    expect(test[1].map["test2"], 4);
  });

    test('register simple', () {
      registerTransformer(new SimpleTransformer<DateTime>());
      expect(hasTransformer(DateTime), true);
    });

    test('parse: DateTime', () {
      var date = new DateTime.now();
      var ctg = parse('{"testDate":"${date.toString()}"}', SimpleDateContainer);
      expect(ctg.testDate is DateTime, true);
      expect(ctg.testDate == date, true);
    });

    test('serialize: DateTime', () {
      var obj = new SimpleDateContainer();
      obj.testDate = new DateTime.now();
      var str = serialize(obj);
      expect(str, '{"testDate":"${obj.testDate.toIso8601String()}"}');
    });


}

class SimpleTransformer<T> extends TypeTransformer {
  T decode(dynamic value) {
    return DateTime.parse(value);
  }

  dynamic encode(T value) {
    return value.toString();
  }
}

class SimpleDateContainer {
  DateTime testDate;
}

class TestClass1 {
  String name;
  bool matter;
  num number;
  List list;
  Map map;
  TestClass1 child;
  int intNumber;
  
  @DartsonProperty(ignore:true)
  bool ignored;
  
  @DartsonProperty(name:"the_renamed")
  String renamed;

  TestClass1();
}

class JustObject {
  Object object;
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

class SimpleClass {
  String name;
  
  String toString() => "SimpleClass: name: ${name}";
}

class ListClass {
  List<SimpleClass> list;
}

class MapClass {
  Map<String, SimpleClass> map;
}

class SimpleList {
  List list;
}

class SimpleMap {
  Map map;
}

class SimpleMapString {
  Map<String,num> map;
}

