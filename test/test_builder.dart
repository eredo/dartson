library test_builder;

import '../lib/dartson.dart';
import '../lib/builder.dart';

@DartsonEntity()
class TestClass {
  String name;
  TestClass child;
  bool boolean;
  num number;
}

void main() {
  DARTSON_BUILDER_DEBUG = true;
  
  // TODO: Add a test case for the builder
  
  BuilderOptions options = new BuilderOptions();
  options.isTest = true;
  build(options);
}