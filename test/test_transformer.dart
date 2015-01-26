library dartson.transformer.test;

import 'dart:io';

import '../lib/transformer.dart';

import 'package:unittest/unittest.dart';
import 'package:analyzer/src/generated/ast.dart';

void main() {
  DartsonTransformer transformer = new DartsonTransformer();

  // test the compiler
  FileCompiler compiler = new FileCompiler('./fixture/simple_class.dart');
  test('read source code from file', () {
    expect(compiler.compilationUnit.declarations is NodeList, true);
  });

  CompilationUnitMember simpleClass;
  test('should contain the SimpleClass declaration', () {
    expect(compiler.compilationUnit.declarations.any((CompilationUnitMember m) {
      if (m is ClassDeclaration) {
        return m.name.name == 'SimpleClass';
      }
    }), true);
  });
  
  skip_test('should find a SimpleIdentifier prefix for the dartson import', () {
    expect(compiler.findDartsonImportName() != null, true);
    expect(compiler.findDartsonImportName().toString(), 'ddd');
  });

  Annotation dartsonEntity;
  test('should show the metadata', () {
    simpleClass = compiler.compilationUnit.declarations.firstWhere((m)
      => m is ClassDeclaration && m.name.name == 'SimpleClass');
    expect(simpleClass.metadata.any((Annotation n) => n.name.name == 'ddd.Entity' ), true);
  });

  test('the compiler should contain the SimpleClass', () {
    expect(compiler.entities.any((m) => m.name.name == 'SimpleClass'), true);
  });

  List<PropertyDefinition> entityMap;
  test('fetch entity map from simpleClass', () {
    entityMap = compiler.buildEntityMap(simpleClass);
    expect(entityMap.length, 6);
    expect(entityMap[0].type, 'String');
    expect(entityMap[5].type, 'Map');
    expect(entityMap[5].typeArguments.length, 2);
    expect(entityMap[4].typeArguments.length, 1);
    expect(entityMap[4].typeArguments[0], 'ChildClass');
    expect(entityMap[5].typeArguments[0], 'String');
    expect(entityMap[5].typeArguments[1], 'ChildClass');
  });

  test('build code', () {
    var code = compiler.build('package:dartson/test/simple_class.dart');
    var file = new File('./tmp/simple_class.dart');
    file.writeAsStringSync(code);
  });
  
  test('compile parts', () {
    var compiler = new FileCompiler('./fixture/part1_class.dart');
    var code = compiler.build('package:dartson/test/part1_class.dart');
    var file = new File('./tmp/part1_class.dart');
    file.writeAsStringSync(code);
  });
}
