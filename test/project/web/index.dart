library dartson_test.main;

import 'package:dartson/dartson.dart';
import 'package:dartson/transformers/date_time.dart';
import 'package:dartson_test_project/mymodels.dart';
import 'package:dartson_test_project/parts.dart';




void main() {
  var dson = new Dartson.JSON();
  dson.addTransformer(new DateTimeParser(), DateTime);
  var items = dson.decode('[{"name":"test","other":"blub","created":"2015-01-26 23:14:54.401"},{"name":"test2","created":"2015-01-23 00:00:00.000","children":[{"name":"child1"}]}]', new Model(), true);
  
  print(items);
  print(items[0].name);
  print(items[1].name);
  print(items[1].children);
  print(items[1].created);
  
  print(dson.encode(items));
  
  var jsonStr = '{"modelName":"Part Model","object":false}';
  var part = dson.decode(jsonStr, new PartModel());
  print(part.modelName);
  print(part.object);
  print(dson.encode(part));
}