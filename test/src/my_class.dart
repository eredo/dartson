import 'package:dartson/dartson.dart';

import 'sub_class.dart';
import 'my_impl.dart';

enum MyEnum { firstValue, secondValue }
enum SecondEnum { has, nothing }

class MyClass extends BaseClass {
  final String finalProp;
  String name;
  int number;
  @Property(name: 'boolean')
  bool hasBoolean;
  @Property(ignore: true)
  bool ignored;
  double numDouble;
  Uri uri;
  DateTime dateTime;
  MyEnum myEnum;
  SecondEnum secondEnum;
  SubClass subClass;
  List<SubClass> subClasses;
  Map<String, SubClass> complexMap;
  MyAbstr replacement;
  String _private;

  MyClass(this.finalProp,
      {this.ignored, @Property(name: 'private') String renamedPrivate})
      : _private = renamedPrivate;

  @Property(name: 'private')
  String get privateGetter => _private;
}

class BaseClass {
  bool inherited;
  @Property(name: 'inheritName')
  String inheritedRenamed;
  @Property(ignore: true)
  String inheritedIgnored;
}
