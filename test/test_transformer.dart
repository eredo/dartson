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

  Annotation dartsonEntity;
  test('should show the metadata', () {
    simpleClass = compiler.compilationUnit.declarations.firstWhere((m)
      => m is ClassDeclaration && m.name.name == 'SimpleClass');

    expect(simpleClass.metadata.any((Annotation n) {
      return n.name.name == 'DartsonEntity';
    }), true);
  });

  test('the compiler should contain the SimpleClass', () {
    expect(compiler.entities.any((m) => m.name.name == 'SimpleClass'), true);
  });

  test('inject the toJson method', () {
    compiler.editor.editor.edit(simpleClass.endToken.end - 1, simpleClass.endToken.end - 1, "Map toJson() => {};");
    var builder = compiler.editor.editor.commit();
    builder.build("./fixture/simple_class.dart");
    expect(builder.text is String, true);
  });

  test('fetch entity map from simpleClass', () {
    var map = compiler.buildEntityMap(simpleClass);
    expect(map is Map, true);
    expect(map['name'], 'name');
    expect(map['id'], 'id');
    expect(map['last_name'], 'lastName');
  });
}
