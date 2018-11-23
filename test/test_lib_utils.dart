import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

Future<Map<String, dynamic>> resolveTestProject(String sourceDirectory,
    String libDirectory, List<String> libFilePaths) async {
  var files = Directory(sourceDirectory).listSync().whereType<File>().toList();
  var fileMap = Map<String, String>.fromEntries(files.map((f) =>
      MapEntry('test_lib|lib/${p.basename(f.path)}', f.readAsStringSync())));

  final libFiles = libFilePaths.map((f) => File(f));
  fileMap.addAll(Map<String, String>.fromEntries(libFiles.map((f) => MapEntry(
      'dartson|lib/${p.relative(f.path, from: libDirectory)}',
      f.readAsStringSync()))));

  return fileMap;
}
