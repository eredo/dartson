library dartson;

export 'src/annotations.dart';
import 'src/annotations.dart';

@MirrorsUsed(
    metaTargets: const [Property],
    override: '*')
import 'dart:mirrors';
import 'dart:convert';

part 'src/exceptions.dart';
part 'src/serializer.dart';
part 'src/parser.dart';
part 'src/type_transformer.dart';


/// Set this to true to receive log output of dartson.
bool DARTSON_DEBUG = false;

void _log(Object msg) {
  if (DARTSON_DEBUG) {
    print("DARTSON: $msg");
  }
}


/// Looks for a [Property] annotation in the metadata of [variable].
Property _getProperty(DeclarationMirror variable) {
  Property prop;
  
  variable.metadata.forEach((meta) {
    if (meta.reflectee is Property) {
      prop = meta.reflectee;
    }
  });
  
  return prop;
}
