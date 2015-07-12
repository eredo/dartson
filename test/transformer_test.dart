library dartson.transformer.test;

import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import '../lib/transformer.dart';

import 'package:analyzer/src/generated/ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

String get _testDirPath => p.dirname(p.fromUri(Platform.script));

void main() {
  var tempDir;

  // test the compiler
  var simplePath = p.join(_testDirPath, 'fixture/simple_class.dart');
  FileCompiler compiler = new FileCompiler(simplePath);
  test('read source code from file', () {
    expect(compiler.compilationUnit.declarations is NodeList, true);
  });

  CompilationUnitMember simpleClass;

  tearDown(() {
    if (tempDir != null) {
      tempDir.deleteSync(recursive: true);
    }
  });

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
    tempDir = Directory.systemTemp.createTempSync('dartson_');

    var compiledFixture = compileFixtureToDirectory('circular_referenced_model.dart', tempDir);
    var fixtureTest = generateFixtureTest(
        compiledFixture,
        tempDir,
        'reference_aware_test.dart',
        'testSerializeAndDeserializeReferenceAware');

    var response = new ReceivePort();
    Isolate.spawnUri(Uri.parse(fixtureTest.path), [], response.sendPort);

    // TODO check failed?
  });

  test('build and compile code for polymorphic model', () {
    tempDir = Directory.systemTemp.createTempSync('dartson_');

    var compiledFixture = compileFixtureToDirectory('polymorphic_model.dart', tempDir);
    var fixtureTest = generateFixtureTest(
        compiledFixture,
        tempDir,
        'polymorphic_test.dart',
        'testSerializeAndDeserializePolymorphic');

    var response = new ReceivePort();
    Isolate.spawnUri(Uri.parse(fixtureTest.path), [], response.sendPort);

    // TODO check failed?
  });
}

File compileFixtureToDirectory(String dartFile, Directory toDir) {
  var newCompiler = new FileCompiler(p.join(_testDirPath, 'fixture/$dartFile'));
  var newCode = newCompiler.build('package:dartson/test/$dartFile');
  var newFile = new File(p.join(toDir.path, 'fixture/$dartFile'))..createSync(recursive: true);
  newFile.writeAsStringSync(newCode);
  return newFile;
}

File generateFixtureTest(File compiledFixture, Directory toDir, String sharedTestHelper, String testMethod) {
  var targetSharedTestHelper = new File(p.join(toDir.path, 'shared/${sharedTestHelper}'))
    ..createSync(recursive: true);
  new File(p.join(_testDirPath, 'shared/${sharedTestHelper}'))
    ..copySync(targetSharedTestHelper.path);

  var testRunnerFile = new File(p.join(toDir.path, 'testrunner.dart'));
  testRunnerFile.writeAsStringSync('''
  library dartson_test.test;

  import 'package:dartson/dartson_static.dart' as ds;
  import 'package:test/test.dart';

  import './shared/${sharedTestHelper}';

  void main() {
    $testMethod(() => new ds.Dartson.JSON());
  }

  ''');
  return testRunnerFile;
}
