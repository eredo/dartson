library dartson.transformer.test;

import 'dart:io';

import '../lib/transformer.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

String get _testDirPath => p.dirname(p.fromUri(Platform.script));

void main() {
  // test the compiler
  var simplePath = p.join(_testDirPath, 'fixture/simple_class.dart');
  FileCompiler compiler = new FileCompiler(simplePath);
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

  test('should find a SimpleIdentifier prefix for the dartson import', () {
    expect(compiler.findDartsonImportName() != null, true);
    expect(compiler.findDartsonImportName().toString(), 'ddd');
  }, skip: true);

  test('should show the metadata', () {
    simpleClass = compiler.compilationUnit.declarations.firstWhere(
        (m) => m is ClassDeclaration && m.name.name == 'SimpleClass');
    expect(
        simpleClass.metadata.any((Annotation n) => n.name.name == 'ddd.Entity'),
        true);
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

  // TODO: validate code output
  // TODO: delete temp directory when complete
  test('build and compile code', () {
    var tempDir = Directory.systemTemp.createTempSync('dartson_');
    print('Generating code into: ${tempDir.path}');

    var code = compiler.build('package:dartson/test/simple_class.dart');
    var file = new File(p.join(tempDir.path, 'simple_class.dart'));
    file.writeAsStringSync(code);

    var newCompiler =
        new FileCompiler(p.join(_testDirPath, 'fixture/part1_class.dart'));
    var newCode = newCompiler.build('package:dartson/test/part1_class.dart');
    var newFile = new File(p.join(tempDir.path, 'part1_class.dart'));
    newFile.writeAsStringSync(newCode);
  });

  test('build and compile code for circular referenced model', () {
    var tempDir = Directory.systemTemp.createTempSync('dartson_');
    print('Generating code into: ${tempDir.path}');

    var newCompiler =
        new FileCompiler(p.join(_testDirPath, 'fixture/circular_referenced_model.dart'));
    var newCode = newCompiler.build('package:dartson/test/circular_referenced_model.dart');
    var newFile = new File(p.join(tempDir.path, 'circular_referenced_model.dart'));
    newFile.writeAsStringSync(newCode);
  });
  test('build and compile code for polymorphic model', () {
    var tempDir = Directory.systemTemp.createTempSync('dartson_');
    print('Generating code into: ${tempDir.path}');

    var newCompiler =
        new FileCompiler(p.join(_testDirPath, 'fixture/polymorphic_model.dart'));
    var newCode = newCompiler.build('package:dartson/test/polymorphic_model.dart');
    var newFile = new File(p.join(tempDir.path, 'polymorphic_model.dart'));
    newFile.writeAsStringSync(newCode);
  });
}
