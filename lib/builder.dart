/**
 * NOTICE: The builder is currenlty not used and just a first prototype.
 */

library dartson.builder;

import 'dart:mirrors';
import 'dartson.dart';

bool DARTSON_BUILDER_DEBUG = false;
num _varNum = 0;

final String _VAR_PREFIX = "dsPp";

void _log(String msg) {
  if (DARTSON_BUILDER_DEBUG) {
    print("DARTSON BUILDER: ${msg}");
  }
}

void build(BuilderOptions options) {
  Map<Symbol, ClassMirror> entities = _searchEntities();
  String code = "library dartson.entities;\n\nimport 'dart:mirrors';\nimport '";
  
  if (options.isTest) {
    code += "../lib/dartson.dart' as dartson;\n";    
  } else { 
    code += "package:dartson/dartson.dart' as dartson;\n";
  }
  code += "\nvoid main() {\n  dartson.ENTITY_MAP = {};\n";
  
  entities.forEach((sym, clazz) {
    String varName = "${_VAR_PREFIX}${_varNum}";
    code += _buildEntityInfo(clazz);
    code += "  dartson.ENTITY_MAP[reflectClass(${MirrorSystem.getName(sym)})] = ${varName};\n"; 
  });  
  
  code += "};";
  print(code);
}

String _buildEntityInfo(ClassMirror entity) {
  String varName = "${_VAR_PREFIX}${_varNum++}";
  String code = "  dartson.EntityDescription $varName = new dartson.EntityDescription();\n";
  Map<String,String> propCodes = {};
  
  entity.variables.forEach((sym, variable) {
    if (!variable.isPrivate && !variable.isStatic) {
      String vName = MirrorSystem.getName(variable.simpleName);
      bool ignore = false;
      String name = vName;
      String type = MirrorSystem.getName(variable.type.simpleName);
      
      variable.metadata.forEach((data) {
        if (data.reflectee is DartsonProperty) {
          DartsonProperty prop = data.reflectee;
          ignore = prop.ignore;
          
          if (prop.name != null) {
            name = prop.name;  
          }
        }
      });

      propCodes[vName] = "new dartson.EntityPropertyDescription(\"${name}\",${type},${ignore})";
    }
  });
  
  code += "  ${varName}.properties = {\n";
  bool first = true;
  propCodes.forEach((varName, pc) {
    if (!first) {
      code += ",";
    }
    first = false;
    
    code += "    \"${varName}\": ${pc}\n";  
  });
  
  code += "  };\n";
  return code;
}

Map<Symbol, ClassMirror> _searchEntities() {
  Map<Uri,LibraryMirror> libs = currentMirrorSystem().libraries;
  Map<Symbol, ClassMirror> classes = {};
  
  _log("Searching for Entities");
  libs.forEach((uri, lib) {
    _log("Scan through library: ${uri}");
    lib.classes.forEach((sym, clazz) {
      clazz.metadata.forEach((meta) {
        if (meta.reflectee is DartsonEntity) {
          _log("Found entity: ${MirrorSystem.getName(sym)}");
          classes[sym] = clazz;
        }
      });
    });
  });
  
  _log("Found: ${classes.length} DartsonEntities.");
  return classes;
}

class BuilderOptions {
  String sourceFile = '_dartson_entities.dart';
  bool isTest = false;
}
