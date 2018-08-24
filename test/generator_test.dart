@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:dartson/src/generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as p;

import 'test_lib_utils.dart';
import 'test_file_utils.dart';

LibraryReader elLibrary;

void main() async {
  group('SerializerGenerator', () {
    final generator = new SerializerGenerator();

    test('should detect the property', () async {
      final libPath = testFilePath('lib');
      final testPath = testFilePath('test', 'src');
      final assets = await resolveTestProject(testPath, libPath, [
        p.join(libPath, 'dartson.dart'),
        p.join(libPath, 'transformers', 'date_time.dart'),
        p.join(libPath, 'src', 'annotations.dart')
      ]);

      final expected = <String, String>{
        'test_lib|lib/serializer.g.dart':
            File(p.join(testPath, 'serializer.g.dart')).readAsStringSync(),
      };

      await testBuilder(PartBuilder([generator], '.g.dart'), assets,
          rootPackage: 'test_lib', outputs: expected);
    });
  });
}
