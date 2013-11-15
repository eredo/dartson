library dartson;

import 'dart:mirrors' as mirrors;
import 'dart:convert';

part 'src/exceptions.dart';
part 'src/serializer.dart';
part 'src/parser.dart';

/**
 * Set this to true to receive log output of dartson.
 */
bool DARTSON_DEBUG = false;

/**
 * Contains the description of each class which is has the annotation
 * [DartsonEntity]. This map should be used in dart2js.
 */
Map<mirrors.ClassMirror,EntityDescription> ENTITY_MAP = null;

/**
 * Annotation class to mark a class as serializable. This is required
 * if the dartson builder has to build an entity map for dart2js. 
 */
class DartsonEntity {
  const DartsonEntity();
}

/**
 * Annotation class to describe properties of a class member.
 */
class DartsonProperty {
  final bool _ignore;
  final String name;
  
  const DartsonProperty({bool ignore, String name}) :
    this._ignore = ignore,
    this.name = name;
  
  bool get ignore => _ignore == null ? false : _ignore;
  String toString() => "DartsonProperty: Name: ${name} , Ignore: ${ignore}";
}

/**
 * Container of the properties for a DartsonEntity in the [ENTITY_MAP].
 */
class EntityDescription {
  Map<String,EntityPropertyDescription> properties = {};
  
  EntityDescription();
}

/**
 * Description of a class member of a DartsonEntity in the [ENTITY_MAP].
 */
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
