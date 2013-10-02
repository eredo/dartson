part of dartson;

const _getName = mirrors.MirrorSystem.getName;

final Symbol _QN_STRING = mirrors.reflectClass(String).qualifiedName;
final Symbol _QN_NUM = mirrors.reflectClass(num).qualifiedName;
final Symbol _QN_BOOL = mirrors.reflectClass(bool).qualifiedName;
final Symbol _QN_LIST = mirrors.reflectClass(List).qualifiedName;
final Symbol _QN_MAP = mirrors.reflectClass(Map).qualifiedName;

/**
 * Creates a new instance of [clazz], parses the json in [jsonStr] and puts
 * the data into the new instance.
 *  Returns new instance of [clazz]
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 *  Throws [EntityDescriptionMissing] if [ENTITY_MAP] is not null and doesn't contain
 *    the class. 
 */
dynamic parse(String jsonStr, Type clazz) {
  mirrors.InstanceMirror obj = _initiateClass(mirrors.reflectClass(clazz));
  Map filler = JSON.parse(jsonStr);

  _fillObject(obj, filler);

  return obj.reflectee;
}

/**
 * Puts the data of the [filler] into the object in [objMirror]
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 */
void _fillObject(mirrors.InstanceMirror objMirror, Map filler) {
  mirrors.ClassMirror classMirror = objMirror.type;

  classMirror.variables.forEach((sym, variable) {
    if (!variable.isPrivate && !variable.isStatic) {
      String varName = _getName(sym);
      String fieldName = varName;
      DartsonProperty prop = _getProperty(variable);
      
      if (prop != null && prop.name != null) {
        fieldName = prop.name;
      }
      
      if (filler[fieldName] != null) {
        if (ENTITY_MAP != null) {
          objMirror.setField(sym, _convertValue(_getTypeByEntityMap(classMirror, varName),
            filler[fieldName], varName));
        } else {
          objMirror.setField(sym, _convertValue(variable.type, filler[fieldName], varName));
        }
      }
    }
  });
  
  classMirror.setters.forEach((sym, method) {
    if (!method.isPrivate && !method.isStatic) {
      // however names of setter functions contain a "=" at the end of the name
      String varName = _getName(sym).replaceFirst("=", "");
      String fieldName = varName;
      DartsonProperty prop = _getProperty(method);
      
      if (prop != null && prop.name != null) {
        fieldName = prop.name;
      }
      
      if (filler[fieldName] != null) {
        if (ENTITY_MAP != null) {
          objMirror.setField(new Symbol(varName), _convertValue(_getTypeByEntityMap(classMirror, varName), filler[fieldName], varName));
        } else {
          _log("Invoke setter: ${varName} with ${fieldName}");
          objMirror.setField(new Symbol(varName), _convertValue(method.parameters[0].type, filler[fieldName], varName));
        }
      }
    }
  });
}

/**
 *  Throws [EntityDescriptionMissing] if the entity is not descriped in ENTITY_MAP.
 */
mirrors.TypeMirror _getTypeByEntityMap(mirrors.ClassMirror classMirror, String varName) {
  EntityDescription descr = ENTITY_MAP[classMirror];
  
  if (descr == null) {
    throw new EntityDescriptionMissing(classMirror);
  } else {
    return mirrors.reflectClass(descr.properties[varName].type);
  }
}

/**
 * Transforms the value of a field [key] to the correct value.
 *  returns Deserialized value
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [NoConstructorError] 
 */
Object _convertValue(mirrors.TypeMirror valueType, Object value, String key) {
  _log("Convert \"${key}\": $value to ${_getName(valueType.qualifiedName)}");
  
  if (valueType.qualifiedName == _QN_STRING) {
    if (value is String) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "String", key);
    }
  } else if (valueType.qualifiedName == _QN_NUM) {
    if (value is num) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "num", key);
    }
  } else if (valueType.qualifiedName == _QN_BOOL) {
    if (value is bool) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "bool", key);
    }
  } else if (valueType.qualifiedName == _QN_LIST) {
    if (value is List) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "List", key);
    }
  } else if (valueType.qualifiedName == _QN_MAP) {
    if (value is Map) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "Map", key);
    }
  } else if (_getName(valueType.qualifiedName) == "dynamic") {
    // dynamic is used in JavaScript runtime
    // if this appears something went wrong
    // TODO: Think of a correct way to handle this problem / exception?!
  } else {
    _log("Found individuell type is classmirror: ${valueType is mirrors.ClassMirror} ");
    var obj = _initiateClass(valueType);
    
    if (value is Object && !(value is String) && !(value is num)  && !(value is bool)) {
      _fillObject(obj, value);
    } else {
      throw new IncorrectTypeTransform(value, _getName(valueType.qualifiedName), key);
    }
    
    return obj.reflectee;
  }

  return value;
}

/**
 * Initiates an instance of [classMirror] by using an empty constructor name.
 * Therefore the class needs to contain a simple constructor. For example:
 * <code>
 *  class TestClass {
 *    String name;
 *
 *    TestClass(); // or TestClass([this.name])
 *  }
 * </code>
 *  Throws [NoConstructorError] if the class doesn't have a constructor without or
 *    only with optional arguments.
 */
mirrors.InstanceMirror _initiateClass(mirrors.ClassMirror classMirror) {
  _log("Parsing to class: ${_getName(classMirror.qualifiedName)}");
  Symbol constrMethod = null;
  
  if (classMirror.constructors != null) {
  classMirror.constructors.forEach((sym, method) {
    _log("Checking constructor: \"${_getName(method.constructorName)}\"");
    if (method.parameters.length == 0) {
      constrMethod = method.constructorName;
    } else {
      bool onlyOptional = true;
      
      method.parameters.forEach((param) {
        if (!param.isOptional) {
          onlyOptional = false;
        }
      });
      
      if (onlyOptional) {
        constrMethod = method.constructorName;
      }
    }
  });
  }
  
  mirrors.InstanceMirror obj;
  if (constrMethod != null) {
    _log("Found constructor: \"${_getName(constrMethod)}\"");
    obj = classMirror.newInstance(constrMethod, []);
    
    _log("Created instance of type: ${_getName(obj.type.qualifiedName)}");
  } else {
    _log("No constructor found.");
    throw new NoConstructorError(classMirror);     
  }    

  return obj;
}
