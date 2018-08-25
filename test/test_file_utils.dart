import 'dart:mirrors';

import 'package:path/path.dart' as p;

// TODO: This is based on a json_serializable implementation maybe share?

String testFilePath(String part1, [String part2, String part3]) =>
    p.join(_packagePath(), part1, part2, part3);

String _packagePathCache;

String _packagePath() {
  if (_packagePathCache == null) {
    // Getting the location of this file – via reflection
    var currentFilePath = (reflect(_packagePath) as ClosureMirror)
        .function
        .location
        .sourceUri
        .path;

    _packagePathCache = p.normalize(p.join(p.dirname(currentFilePath), '..'));
  }
  return _packagePathCache;
}
