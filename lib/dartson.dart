library dartson;

import 'dart:mirrors' as mirrors;
import 'dart:json' as JSON;

part 'exceptions.dart';
part 'serializer.dart';
part 'parser.dart';

bool DARTSON_DEBUG = false;
Map<mirrors.ClassMirror,EntityDescription> ENTITY_MAP = null;

class DartsonEntity {
  const DartsonEntity();
}

class DartsonProperty {
  final bool _ignore;
  final String name;
  
  const DartsonProperty({bool ignore, String name}) :
    this._ignore = ignore,
    this.name = name;
  
  bool get ignore => _ignore == null ? false : _ignore;
  String toString() => "DartsonProperty: Name: ${name} , Ignore: ${ignore}";
}

class EntityDescription {
  Map<String,EntityPropertyDescription> properties = {};
  
  EntityDescription();
}

class EntityPropertyDescription {
  final String name;
  final bool ignore;
  final Type type;
  
  EntityPropertyDescription(this.name, this.type, [this.ignore = false]);
}

void _log(Object msg) {
  if (DARTSON_DEBUG) {
    print("DARTSON: $msg");
  }
}


/**
 * Looks for a [DartsonProperty] annotation in the metadata of [variable]. 
 */
DartsonProperty _getProperty(mirrors.DeclarationMirror variable) {
  DartsonProperty prop;
  
  variable.metadata.forEach((meta) {
    if (meta.reflectee is DartsonProperty) {
      prop = meta.reflectee;
    }
  });
  
  return prop;
}
