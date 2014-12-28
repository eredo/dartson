library dartson_test.mymodels;

import 'package:dartson/dartson.dart';

@Entity()
class Model {
  String name;
  bool wrong;
  
  @Property(ignore: true)
  int ignored;
  
  @Property(name: "other")
  String renamed;
  
  List<ModelChild> children;
}

@Entity()
class ModelChild {
  String name;
  int timeline;
}