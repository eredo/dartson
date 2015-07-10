library dartson.test.polymorphic;

import 'package:dartson/dartson.dart' as ds;

@ds.Entity()
class Company {
  List<Employee> employees;
}

@ds.Entity()
class Employee {
  String name;
}

@ds.Entity()
class Manager extends Employee {
  List<Employee> team;
}
