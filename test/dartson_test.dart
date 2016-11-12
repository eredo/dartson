library test_dartson;

import '../lib/dartson.dart';
import '../lib/type_transformer.dart';
import 'package:test/test.dart';

void main() {
  var dson = new Dartson.JSON();

  test('serialize: simple array test', () {
    String str = dson.encode(['test1', 'test2']);
    expect(str, '["test1","test2"]');
  });

  test('serialize: mixed nested arrays', () {
    String str = dson.encode([[1, 2, 3], [3, 4, 5]]);
    expect(str, '[[1,2,3],[3,4,5]]');

    str = dson.encode(["test1", ["a", "b"], [1, 2], 3]);
    expect(str, '["test1",["a","b"],[1,2],3]');
  });

  test('serialize: simple map test', () {
    Map map = {"key1": "val1", "key2": 2};

    String str = dson.encode(map);
    expect(str, '{"key1":"val1","key2":2}');
  });

  test('serialize: mixed nested map', () {
    Map map = {
      "itsAmap": {"key1": 1, "key2": "val"},
      "itsAarray": [1, 2, 3],
      "keyk": "valo"
    };

    String str = dson.encode(map);
    expect(str,
        '{"itsAmap":{"key1":1,"key2":"val"},"itsAarray":[1,2,3],"keyk":"valo"}');
  });

  test('serialize: simple object', () {
    var obj = {"test": "test"};
    JustObject test = new JustObject();
    test.object = obj;

    expect(dson.encode(test), '{"object":{"test":"test"}}');
  });

  test('serialize: simple class', () {
    var test = new TestClass1();
    test.name = "test1";
    String str = dson.encode(test);
    expect(str, '{"name":"test1"}');

    test = new ExtendedClass1();
    test.name = "test1";
    test.extendedClassName = "extended test1";
    str = dson.encode(test);
    expect(str, '{"extendedClassName":"extended test1","name":"test1"}');
  });

  test('serialize: ignore in object', () {
    var test = new TestClass1();
    test.name = "test";
    test.ignored = true;
    expect(dson.encode(test), '{"name":"test"}');

    test = new ExtendedClass1();
    test.name = "test";
    test.ignored = true;
    test.extendedClassName = "extended test";
    test.extendedClassIgnored = true;
    expect(dson.encode(test),
        '{"extendedClassName":"extended test","name":"test"}');
  });

  test('serialize: renamed property of object', () {
    var test = new TestClass1();
    test.renamed = "test";
    expect(dson.encode(test), '{"the_renamed":"test"}');

    test = new ExtendedClass1();
    test.renamed = "test";
    test.extendedClassRenamed = "extended test";
    expect(dson.encode(test),
        '{"the_extended_Class_renamed":"extended test","the_renamed":"test"}');
  });

  test('serialize: simple getter class', () {
    expect(dson.encode(new TestGetter("test2")), '{"name":"test2"}');
  });

  test('serialize: nested class', () {
    expect(dson.encode(
            new NestedClass("test", [1, 2, 3], new TestGetter("get it"))),
        '{"name":"test","list":[1,2,3],"getter":{"name":"get it"}}');
  });

  test('parse: parser simple', () {
    TestClass1 test = dson.decode(
        '{"name":"test","matter":true,"intNumber":2,"doubleNumber":2.11,"number":5,"list":[1,2,3],"map":{"k":"o"},"the_renamed":"test"}',
        new TestClass1());
    expect(test.name, 'test');
    expect(test.matter, true);
    expect(test.intNumber, 2);
    expect(test.doubleNumber, 2.11);
    expect(test.number, 5);
    expect(test.list.length, 3);
    expect(test.list[1], 2);
    expect(test.map["k"], "o");
    expect(test.renamed, "test");

    ExtendedClass1 testExtended = dson.decode(
        '{"name":"test","matter":true,"intNumber":2,"doubleNumber":2.11,"number":5,"list":[1,2,3],"map":{"k":"o"},"the_renamed":"test","extendedClassName":"test","extendedClassMatter":true,"extendedClassIntNumber":2,"extendedClassDoubleNumber":2.11,"extendedClassNumber":5,"extendedClassList":[1,2,3],"extendedClassMap":{"k":"o"},"the_extended_Class_renamed":"test"}',
        new ExtendedClass1());
    expect(testExtended.name, 'test');
    expect(testExtended.matter, true);
    expect(testExtended.intNumber, 2);
    expect(testExtended.doubleNumber, 2.11);
    expect(testExtended.number, 5);
    expect(testExtended.list.length, 3);
    expect(testExtended.list[1], 2);
    expect(testExtended.map["k"], "o");
    expect(testExtended.renamed, "test");
    expect(testExtended.extendedClassName, 'test');
    expect(testExtended.extendedClassMatter, true);
    expect(testExtended.extendedClassIntNumber, 2);
    expect(testExtended.extendedClassDoubleNumber, 2.11);
    expect(testExtended.extendedClassNumber, 5);
    expect(testExtended.extendedClassList.length, 3);
    expect(testExtended.extendedClassList[1], 2);
    expect(testExtended.extendedClassMap["k"], "o");
    expect(testExtended.extendedClassRenamed, "test");

  });

  test('parse: no constructor found', () {
    NoConstructorError err;
    try {
      NestedParent test =
          dson.decode('{"child": {"name":"failure"}}', new NestedParent());
    } catch (ex) {
      err = ex;
    }

    expect(err != null, true);
    expect(err is NoConstructorError, true);
  });

  test('parse: nested parsing', () {
    TestClass1 test = dson.decode(
        '{"name":"parent","child":{"name":"child"}}', new TestClass1());
    expect(test.child.name, "child");
  });

  test('parse: using setter', () {
    TestSetter test = dson.decode('{"name":"test"}', new TestSetter());
    expect(test.name, 'test');
  });

  test('parse: generics list', () {
    ListClass test = dson.decode(
        '{"list": [{"name": "test1"}, {"name": "test2"}]}', new ListClass());

    expect(test.list[0].name, 'test1');
    expect(test.list[1].name, 'test2');
  });

  test('parse: simple list', () {
    SimpleList list = dson.decode('{"list":[1,2,3]}', new SimpleList());
    expect(list.list[0], 1);
  });

  test('parse: generic map', () {
    MapClass test = dson.decode(
        '{"map": {"test": {"name": "test"}, "test2": {"name": "test2"}}}',
        new MapClass());

    expect(test.map["test"].name, "test");
    expect(test.map["test2"].name, "test2");
  });

  test('parse: simple map', () {
    SimpleMap test = dson.decode(
        '{"map": {"test": "test", "test2": "test2"}}', new SimpleMap());

    expect(test.map["test"], "test");
    expect(test.map["test2"], "test2");
  });

  test('parse: simple map with type declaration', () {
    SimpleMapString test =
        dson.decode('{"map": {"test": 1, "test2": 2}}', new SimpleMapString());

    expect(test.map["test"], 1);
    expect(test.map["test2"], 2);
  });

  test('parse: list of simple class', () {
    List<SimpleClass> test = dson.decode(
        '[{"name":"test"},{"name":"test2"}]', new SimpleClass(), true);
    expect(test[0].name, "test");
    expect(test[1].name, "test2");
  });

  test('map: parse object', () {
    SimpleMapString test =
        dson.map({"map": {"test": 1, "test2": 2}}, new SimpleMapString());

    expect(test.map["test"], 1);
    expect(test.map["test2"], 2);
  });

  test('mapList: parse list', () {
    List<SimpleMapString> test = dson.map([
      {"map": {"test": 1, "test2": 2}},
      {"map": {"test": 3, "test2": 4}}
    ], new SimpleMapString(), true);
    expect(test[0].map["test"], 1);
    expect(test[0].map["test2"], 2);
    expect(test[1].map["test"], 3);
    expect(test[1].map["test2"], 4);
  });

  test('register simple', () {
    dson.addTransformer(new SimpleTransformer(), DateTime);
    expect(dson.hasTransformer(DateTime), true);
  });

  test('parse: DateTime', () {
    var date = new DateTime.now();
    var ctg = dson.decode(
        '{"testDate":"${date.toString()}"}', new SimpleDateContainer());
    expect(ctg.testDate is DateTime, true);
    expect(ctg.testDate == date, true);
  });

  test('serialize: DateTime', () {
    var obj = new SimpleDateContainer();
    obj.testDate = new DateTime.now();
    var str = dson.encode(obj);
    expect(str, '{"testDate":"${obj.testDate.toString()}"}');
  });

  test('serialize double number in num', () {
    var obj = new TestClass1();
    obj.number = 1;

    var str = dson.encode(obj);
    expect(str, '{"number":1}');

    var extendedObj = new ExtendedClass1();
    extendedObj.number = 1;
    extendedObj.extendedClassNumber = 2;

    str = dson.encode(extendedObj);
    expect(str, '{"extendedClassNumber":2,"number":1}');

  });

}

class SimpleTransformer extends TypeTransformer<DateTime> {
  DateTime decode(dynamic value) {
    return DateTime.parse(value);
  }

  dynamic encode(DateTime value) {
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
  double doubleNumber;

  @Property(ignore: true)
  bool ignored;

  @Property(name: "the_renamed")
  String renamed;

  TestClass1();
}

class ExtendedClass1 extends TestClass1 {
  String extendedClassName;
  bool extendedClassMatter;
  num extendedClassNumber;
  List extendedClassList;
  Map extendedClassMap;
  TestClass1 extendedClassChild;
  int extendedClassIntNumber;
  double extendedClassDoubleNumber;

  @Property(ignore: true)
  bool extendedClassIgnored;

  @Property(name: "the_extended_Class_renamed")
  String extendedClassRenamed;
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

class NestedParent {
  NestedClass child;
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
  Map<String, num> map;
}
