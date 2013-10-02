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
 * Creates a list with instances of [clazz] and puts the data of the parsed json
 * of [jsonStr] into the instances.
 *   Returns A list of objects of [clazz].
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 *  Throws [EntityDescriptionMissing] if [ENTITY_MAP] is not null and doesn't contain
 *    the class. 
 */
List parseList(String jsonStr, Type clazz) {
  List returnList = [];
  List filler = JSON.parse(jsonStr);
  filler.forEach((item) {
    mirrors.InstanceMirror obj = _initiateClass(mirrors.reflectClass(clazz));
    _fillObject(obj, item);
    returnList.add(obj.reflectee);    
  });
  
  return returnList;
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
//          if (DARTSON_DEBUG) {
//            _log("${_getName(sym)}: original: ${variable.type.isOriginalDeclaration} " + 
//                "reflected: ${variable.type.hasReflectedType} symbol: ${_getName(variable.type.qualifiedName)} " +
//                "original: ${variable.type.reflectedType} is simple ${_isSimpleType(variable.type.reflectedType)}");
//          }
//          
          _log("Set default field: ${_getName(sym)}");
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

bool _isSimpleType(Type type) {
  return type == List || type == bool || type == String || type == num || type == Map || type == dynamic;
}

bool _hasOnlySimpleTypeArguments(mirrors.ClassMirror mirr) {
  bool hasOnly = true;
  
  mirr.typeArguments.forEach((ta) {
    if (ta is mirrors.ClassMirror) {
      if (!_isSimpleType(ta.reflectedType)) {
        hasOnly = false;
      }
    }
  });
  
  return hasOnly;
}

/**
 * Converts a list of objects to a list with a Class.
 */
List _convertGenericList(mirrors.ClassMirror listMirror, List fillerList) {
  mirrors.ClassMirror itemMirror = listMirror.typeArguments[0];
  mirrors.InstanceMirror resultList = _initiateClass(listMirror);
  
  fillerList.forEach((item) {
    (resultList.reflectee as List).add(_convertValue(itemMirror, item, "@LIST_ITEM"));
  });
  
  _log("Created generic list: ${resultList.reflectee}");
  return resultList.reflectee;
}

Map _convertGenericMap(mirrors.ClassMirror mapMirror, Map fillerMap) {
 mirrors.ClassMirror itemMirror = mapMirror.typeArguments[1];
 mirrors.ClassMirror keyMirror = mapMirror.typeArguments[0];
 mirrors.InstanceMirror resultMap = _initiateClass(mapMirror);
 
 fillerMap.forEach((key, value) {
  var keyItem = _convertValue(keyMirror, key, "@MAP_KEY");
  var valueItem = _convertValue(itemMirror, value, "@MAP_VALUE");
  (resultMap.reflectee as Map)[keyItem] = valueItem;
 });
 
 return resultMap.reflectee;
}

/**
 * Transforms the value of a field [key] to the correct value.
 *  returns Deserialized value
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [NoConstructorError] 
 */
Object _convertValue(mirrors.TypeMirror valueType, Object value, String key) {
  _log("Convert \"${key}\": $value to ${_getName(valueType.qualifiedName)}");
  
  if (valueType is mirrors.ClassMirror &&
      !(valueType as mirrors.ClassMirror).isOriginalDeclaration &&
      (valueType as mirrors.ClassMirror).hasReflectedType &&
      !_hasOnlySimpleTypeArguments(valueType)) {
    
    mirrors.ClassMirror varMirror = valueType as mirrors.ClassMirror;
    
    // handle generic lists
    if (varMirror.originalDeclaration.qualifiedName == _QN_LIST) {
      return _convertGenericList(varMirror, value); 
    } else if (varMirror.originalDeclaration.qualifiedName == _QN_MAP) {
    // handle generic maps
      return _convertGenericMap(varMirror, value);      
    }
  } else if (valueType.qualifiedName == _QN_STRING) {
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
