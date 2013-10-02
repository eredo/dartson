library test_builder;

import '../lib/dartson.dart';
import '../lib/builder.dart';
import 'dart:mirrors';
import 'package:unittest/unittest.dart';

part '_test_builded.dart';

@DartsonEntity()
class TestClass {
  String name;
  TestClass child;
  bool boolean;
  num number;
}

void main() {
  DARTSON_BUILDER_DEBUG = true;
  
  BuilderOptions options = new BuilderOptions();
  options.isTest = true;
  build(options);
}