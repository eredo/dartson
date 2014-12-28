library dartson_test.main;

import 'package:dartson_test_project/mymodels.dart';
import 'package:dartson_test_project/parts.dart';
import 'package:dartson/dartson.dart';


void main() {
  var items = parseList('[{"name":"test","other":"blub"},{"name":"test2","children":[{"name":"child1"}]}]', Model);
  print(items);
  print(items[0].name);
  print(items[1].name);
  print(items[1].children);
  
  print(serialize(items));
  
  var jsonStr = '{"modelName":"Part Model","object":false}';
  var part = parse(jsonStr, PartModel);
  print(part.modelName);
  print(part.object);
  print(serialize(part));
}