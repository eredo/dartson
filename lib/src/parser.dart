part of dartson;

const _getName = MirrorSystem.getName;

final Symbol _QN_STRING = reflectClass(String).qualifiedName;
final Symbol _QN_NUM = reflectClass(num).qualifiedName;
final Symbol _QN_INT = reflectClass(int).qualifiedName;
final Symbol _QN_BOOL = reflectClass(bool).qualifiedName;
final Symbol _QN_LIST = reflectClass(List).qualifiedName;
final Symbol _QN_MAP = reflectClass(Map).qualifiedName;
final Symbol _QN_OBJECT = reflectClass(Object).qualifiedName;

// map that contains all type transformer
Map<String,TypeTransformer> _transformers = {};

/**
 * Creates a new instance of [clazz], parses the json in [jsonStr] and puts
 * the data into the new instance.
 *  Returns new instance of [clazz]
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 */
dynamic parse(String jsonStr, Type clazz) {
  InstanceMirror obj = _initiateClass(reflectClass(clazz));
  Map filler = JSON.decode(jsonStr);

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
 */
List parseList(String jsonStr, Type clazz) {
  List returnList = [];
  List filler = JSON.decode(jsonStr);
  filler.forEach((item) {
    InstanceMirror obj = _initiateClass(reflectClass(clazz));
    _fillObject(obj, item);
    returnList.add(obj.reflectee);    
  });
  
  return returnList;
}

/**
 * Creates a new instance of [clazz] and maps the data of [dataObject] into it.
 *  Returns new instance of [clazz]
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 */
dynamic map(Map dataObject, Type clazz) {
  InstanceMirror obj = _initiateClass(reflectClass(clazz));
  _fillObject(obj, dataObject);

  return obj.reflectee;
}

/**
 * Creates a list with instances of [clazz] and maps the data of [dataMap] into
 * each instance.
 *   Returns A list of objects of [clazz].
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 */
List mapList(List<Map> dataMap, Type clazz) {
  List returnList = [];
  dataMap.forEach((item) {
    InstanceMirror obj = _initiateClass(reflectClass(clazz));
    _fillObject(obj, item);
    returnList.add(obj.reflectee);
  });

  return returnList;
}

/**
 * Filles an [object] with the data of [dataObject] and returns the [object].
 *  Throws [NoConstructorError] if [clazz] or Classes used inside [clazz] do not
 *    have a constructor without or only optional arguments.
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [FormatException] if the [jsonStr] is not valid JSON text.
 */
dynamic fill(Map dataObject, Object object) {
  _fillObject(reflect(object), dataObject);
  return object;
}

/**
 * Registers the [transformer] into the map.
 */
void registerTransformer(TypeTransformer transformer) {
  InstanceMirror mirr = reflect(transformer);
  _transformers[_getName(mirr.type.typeArguments[0].qualifiedName)] = transformer;
}

bool hasTransformer(Type type) {
  TypeMirror mirr = reflectType(type);
  return _transformers[_getName(mirr.qualifiedName)] != null;
}

/**
 * Puts the data of the [filler] into the object in [objMirror]
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 */
void _fillObject(InstanceMirror objMirror, Map filler) {
  ClassMirror classMirror = objMirror.type;

  classMirror.declarations.forEach((sym, decl) {
    if (!decl.isPrivate && (decl is VariableMirror || decl is MethodMirror)) {
      String varName = _getName(sym);
      String fieldName = varName;
      TypeMirror valueType;
      
      // if it's a setter function we need to change the name
      if (decl is MethodMirror && decl.isSetter) {
        fieldName = varName = varName.substring(0, varName.length - 1);
        _log('Found setter function varName: ' + varName);
        valueType = decl.parameters[0].type;
      } else if (decl is VariableMirror) {
        valueType = decl.type;
      } else {
        return;
      }
      
      // check if the property is renamed by DartsonProperty
      DartsonProperty prop = _getProperty(decl);
      if (prop != null && prop.name != null) {
        fieldName = prop.name;
      }
      
      _log('Try to fill object with: ${fieldName}: ${filler[fieldName]}');
      if (filler[fieldName] != null) {
        objMirror.setField(new Symbol(varName), _convertValue(valueType,
            filler[fieldName], varName));
      }
    }    
  });
  
  _log("Filled object completly: ${filler}");
}

/**
 *  Throws [EntityDescriptionMissing] if the entity is not descriped in ENTITY_MAP.
 */
TypeMirror _getTypeByEntityMap(ClassMirror classMirror, String varName) {
  EntityDescription descr = ENTITY_MAP[classMirror];
  
  if (descr == null) {
    throw new EntityDescriptionMissing(classMirror);
  } else {
    return reflectClass(descr.properties[varName].type);
  }
}

bool _isSimpleType(Type type) {
  return type == List || type == bool || type == String || type == num || type == Map || type == dynamic;
}

bool _hasOnlySimpleTypeArguments(ClassMirror mirr) {
  bool hasOnly = true;
  
  mirr.typeArguments.forEach((ta) {
    if (ta is ClassMirror) {
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
List _convertGenericList(ClassMirror listMirror, List fillerList) {
  _log('Converting generic list');
  ClassMirror itemMirror = listMirror.typeArguments[0];
  InstanceMirror resultList = _initiateClass(listMirror);
  
  fillerList.forEach((item) {
    (resultList.reflectee as List).add(_convertValue(itemMirror, item, "@LIST_ITEM"));
  });
  
  _log("Created generic list: ${resultList.reflectee}");
  return resultList.reflectee;
}

Map _convertGenericMap(ClassMirror mapMirror, Map fillerMap) {
  _log('Converting generic map');
  ClassMirror itemMirror = mapMirror.typeArguments[1];
  ClassMirror keyMirror = mapMirror.typeArguments[0];
  InstanceMirror resultMap = _initiateClass(mapMirror);
  Map reflectee = {};
 
  fillerMap.forEach((key, value) {
    var keyItem = _convertValue(keyMirror, key, "@MAP_KEY");
    var valueItem = _convertValue(itemMirror, value, "@MAP_VALUE");
    reflectee[keyItem] = valueItem;
    _log("Added item ${valueItem} to map key: ${keyItem}");
  });
 
  _log("Map converted completly");
  return reflectee;
}

/**
 * Transforms the value of a field [key] to the correct value.
 *  returns Deserialized value
 *  Throws [IncorrectTypeTransform] if json data types doesn't match.
 *  Throws [NoConstructorError] 
 */
Object _convertValue(TypeMirror valueType, Object value, String key) {
  _log("Convert \"${key}\": $value to ${_getName(valueType.qualifiedName)}");
  if (DARTSON_DEBUG) {
    if (valueType is ClassMirror) {
      _log("$key: original: ${valueType.isOriginalDeclaration} " + "reflected: ${valueType.hasReflectedType} symbol: ${_getName(valueType.qualifiedName)} " + "original: ${valueType.reflectedType} is " + "simple ${_isSimpleType(valueType.reflectedType)}");
    }
  }

  if (valueType is ClassMirror && !valueType.isOriginalDeclaration && valueType.hasReflectedType && !_hasOnlySimpleTypeArguments(valueType)) {

    ClassMirror varMirror = valueType;

    _log('Handle generic');
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
    if (value is num || value is int) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "num", key);
    }
  } else if (valueType.qualifiedName == _QN_INT) {
    if (value is int || value is num) {
      return value;
    } else {
      throw new IncorrectTypeTransform(value, "int", key);
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
  } else if (valueType.qualifiedName == _QN_OBJECT) {
    return value;
  } else if (_getName(valueType.qualifiedName) == "dynamic") {
    // dynamic is used in JavaScript runtime
    // if this appears something went wrong
    // TODO: Think of a correct way to handle this problem / exception?!
  } else if (_transformers[_getName(valueType.qualifiedName)] != null) {
    return _transformers[_getName(valueType.qualifiedName)].decode(value);
  } else {
    var obj = _initiateClass(valueType);
    
    if (!(value is String) && !(value is num)  && !(value is bool)) {
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
InstanceMirror _initiateClass(ClassMirror classMirror) {
  _log("Parsing to class: ${_getName(classMirror.qualifiedName)}");
  Symbol constrMethod = null;

  classMirror.declarations.forEach((sym, decl) {
    if (decl is MethodMirror && decl.isConstructor) {
      _log('Found constructor function: ${_getName(decl.qualifiedName)}');

      if (decl.parameters.length == 0) {
        constrMethod = decl.constructorName;
      } else {
        bool onlyOptional = true;
        decl.parameters.forEach((p) => !p.isOptional && (onlyOptional = false));

        if (onlyOptional) {
          constrMethod = decl.constructorName;
        }
      }
    }
  });

  InstanceMirror obj;
  if (classMirror.qualifiedName == _QN_LIST) {
    _log('No constructor for list found, try to run empty one');
    obj = reflect([]);
  } else if (classMirror.qualifiedName == _QN_MAP) {
    _log('No constructor for map found');
    obj = reflect({
    });
  } else if (constrMethod != null) {
    _log("Found constructor: \"${_getName(constrMethod)}\"");
    obj = classMirror.newInstance(constrMethod, []);

    _log("Created instance of type: ${_getName(obj.type.qualifiedName)}");
  } else {
    _log("No constructor found.");
    throw new NoConstructorError(classMirror);     
  }    

  return obj;
}
