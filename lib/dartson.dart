library dartson;

import 'package:logging/logging.dart';

export 'src/annotations.dart';
import 'src/annotations.dart';
import './type_transformer.dart';
import 'src/reference_mapper.dart';

@MirrorsUsed(metaTargets: const [Property], override: '*')
import 'dart:mirrors';
import 'dart:convert';

part 'src/exceptions.dart';
part 'src/core_transformers.dart';
part 'src/simple_type_transformer.dart';
part 'src/helpers.dart';

/// The mirror based version of dartson.
class Dartson<T> {
  final Codec _codec;
  final Logger _log;
  final Map<String, TypeTransformer> _transformers = {};

  Dartson(this._codec, [String identifier = 'dartson'])
      : _log = new Logger(identifier) {
    _log.fine('Initiate mirror based Dartson class.');
    _transformers.addAll(_simpleTransformers);
  }

  /// Constructor which sets JSON as the codec used for encoding and decoding.
  factory Dartson.JSON([String identifier = 'dartson']) =>
      new Dartson(JSON, identifier);

  /// Registers a [transformer] for the specific [type] to this darston instance.
  addTransformer(TypeTransformer transformer, Type type) {
    _transformers[_getName(reflectType(type).qualifiedName)] = transformer;
  }

  /// Checks if a transformer is registered for the [type].
  bool hasTransformer(Type type) =>
      _transformers[_getName(reflectType(type).qualifiedName)] != null;

  /// Maps the values within [data] onto the [object] by reflecting the
  /// the type of object. The Class of [object] should have the [Entity]
  /// annotation to work properly when compiling to JavaScript.
  /// Returns the [object].
  Object map(Object data, Object object, [bool isList = false, bool beReferenceAware = false]) {
    var reflectee = reflect(object);
    var mapper = beReferenceAware ? new DecodingReferenceMapper() : null;

    if (data is List && isList) {
      ClassMirror itemMirror = reflectee.type;

      var list = [];
      data.forEach((item) {
        list.add(_convertValue(itemMirror, item, "@LIST_ITEM", mapper));
      });

      return list;
    } else if (data is List && !isList) {
      throw new IncorrectTypeTransform(object, 'List');
    } else {
      _fillObject(reflectee, data, mapper);
    }

    return object;
  }

  /// Transforms an [object] to a serializable map which can be handled
  /// by any encoder like JSON.
  Object serialize(Object object, [EncodingReferenceMapper mapper]) {
    if (object is List) {
      return _serializeList(object, mapper);
    } else if (object is Map) {
      return _serializeMap(object, mapper);
    } else if (object == null) {
      return null;
    } else {
      return _serializeObject(object, mapper);
    }
  }

  /// Decodes the [encoded] object (for example a JSON encoded string) using
  /// the [_codec] and then uses [map] to map it onto the [object].
  /// Reconstruct references and resolved placeholders added by [encodeReferenceAware].
  Object decodeReferenceAware(T encoded, Object object, [ bool isList = false]) {
    return decode(encoded, object, isList, true);
  }

  /// Decodes the [encoded] object (for example a JSON encoded string) using
  /// the [_codec] and then uses [map] to map it onto the [object].
  Object decode(T encoded, Object object, [ bool isList = false, bool beReferenceAware =  false]) {
    return map(_codec.decode(encoded), object, isList, beReferenceAware);
  }

  /// Serializes the [decoded] object using [serialize] and then calls the encode
  /// method on the [_codec].
  /// References to already mapped objects will be serialized by an placeholder (except Lists and Maps)
  T encodeReferenceAware(Object decoded) {
    return encode(decoded, beReferenceAware: true);
  }
  /// Serializes the [decoded] object using [serialize] and then calls the encode
  /// method on the [_codec].
  T encode(Object decoded, {bool beReferenceAware: false}) {
    return _codec.encode(serialize(decoded, beReferenceAware ? new EncodingReferenceMapper() : null));
  }

  /// Creates a new list containing only serializable objects.
  List _serializeList(List object, EncodingReferenceMapper mapper) {
    return object.map((i) => serialize(i, mapper)).toList();
  }

  /// Creates a new map containing only serializable objects.
  Map _serializeMap(Map object, EncodingReferenceMapper mapper) {
    var map = {};
    object.forEach((k, v) {
      if (v != null) map[k] = serialize(v, mapper);
    });
    return map;
  }

  Object _serializeObject(Object object, EncodingReferenceMapper mapper) {
    if (mapper != null && mapper.isSerialized(object)) {
        return mapper.createSerializablePlaceholder(object);
    }
    var reflectee = reflect(object);
    var symbolName = _getName(reflectee.type.qualifiedName),
        transformer;

    if ((transformer = _transformers[symbolName]) != null) {
      var result = transformer.encode(object);
      if (mapper != null) {
        mapper.registerSerializableMap(object, result);
      }
      return result;
    } else {
      Map result = new Map<String, Object>();
      if (mapper != null) {
        mapper.registerSerializableMap(object, result);
      }
      reflectee.type.declarations.forEach((sym, decl) {
        if (!decl.isPrivate &&
            ((decl is VariableMirror && !decl.isConst && !decl.isStatic) ||
                (decl is MethodMirror && decl.isGetter))) {
          _setField(sym, decl, reflectee, result, mapper);
        }
      });

      _log.finer("Serialization completed.");
      return result;
    }
  }

  /// Checks the DeclarationMirror [variable] for annotations and adds
  /// the value to the [result] map. If there's no [Property] annotation
  /// with a different name set it will use the name of [symbol].
  void _setField(Symbol symbol, DeclarationMirror variable,
      InstanceMirror instMirror, Map<String, Object> result, EncodingReferenceMapper mapper) {
    InstanceMirror field = instMirror.getField(symbol);
    Object value = field.reflectee;
    String fieldName = MirrorSystem.getName(symbol);
    _log.finer("Start serializing field: ${fieldName}");

    // check if there is a DartsonProperty annotation
    Property prop = _getProperty(variable);
    _log.finer("Property: ${prop}");

    if (prop != null && prop.name != null) {
      _log.finer("Field renamed to: ${prop.name}");
      fieldName = prop.name;
    }

    if (value != null && (prop != null ? !prop.ignore : true)) {
      _log.finer("Serializing field: ${fieldName}");
      result[fieldName] = serialize(value, mapper);
    }
  }

  /// Puts the data of the [filler] into the object in [objMirror]
  /// Throws [IncorrectTypeTransform] if json data types doesn't match.
  void _fillObject(InstanceMirror objMirror, Map filler, DecodingReferenceMapper mapper) {
    ClassMirror classMirror = objMirror.type;

    if (mapper != null) {
       mapper.registerInstanceIfApplicable(objMirror.reflectee, filler);
    }

    classMirror.declarations.forEach((sym, decl) {
      if (!decl.isPrivate &&
          ((decl is VariableMirror && !decl.isFinal && !decl.isConst) ||
              decl is MethodMirror)) {
        String varName = _getName(sym);
        String fieldName = varName;
        TypeMirror valueType;

        // if it's a setter function we need to change the name
        if (decl is MethodMirror && decl.isSetter) {
          fieldName = varName = varName.substring(0, varName.length - 1);
          _log.finer('Found setter function varName: ' + varName);
          valueType = decl.parameters[0].type;
        } else if (decl is VariableMirror) {
          valueType = decl.type;
        } else {
          return;
        }

        // check if the property is renamed by DartsonProperty
        Property prop = _getProperty(decl);
        if (prop != null && prop.name != null) {
          fieldName = prop.name;
        }

        _log.finer(
            'Try to fill object with: ${fieldName}: ${filler[fieldName]}');
        if (filler[fieldName] != null) {
          objMirror.setField(new Symbol(varName),
              _convertValue(valueType, filler[fieldName], varName, mapper));
        }
      }
    });



    _log.fine("Filled object completly: ${filler}");
  }

  /// Transforms the value of a field [key] to the correct value.
  /// returns Deserialized value
  ///  Throws [IncorrectTypeTransform] if json data types doesn't match.
  ///  Throws [NoConstructorError]
  Object _convertValue(TypeMirror valueType, Object value, String key, DecodingReferenceMapper mapper) {
    if (mapper != null && mapper.isPlaceholder(value)) {
      var instance = mapper.resolveReferenceForPlaceholder(value);
      if (instance == null) {
        _log.severe("unable to resolve reference for placeholder ${value}");
      }
      return instance;
    }
    var symbolName = _getName(valueType.qualifiedName),
        transformer;

    _log.finer('Convert "${key}": $value to ${symbolName}');

    if (valueType is ClassMirror &&
        !valueType.isOriginalDeclaration &&
        valueType.hasReflectedType &&
        !_hasOnlySimpleTypeArguments(valueType)) {
      ClassMirror varMirror = valueType;
      _log.finer('Handle generic type.');
      // handle generic lists
      if (varMirror.originalDeclaration.qualifiedName == _QN_LIST) {
        return _convertGenericList(varMirror, value, mapper);
      } else if (varMirror.originalDeclaration.qualifiedName == _QN_MAP) {
        // handle generic maps
        return _convertGenericMap(varMirror, value, mapper);
      }
    } else if (symbolName == 'dynamic') {
      // dynamic is used in JavaScript runtime
      // if this appears something went wrong
      // TODO: Think of a correct way to handle this problem / exception?!
    } else if ((transformer = _transformers[symbolName]) != null) {
      return transformer.decode(value);
    } else {
      var obj = _initiateClass(valueType);

      if (!(value is String) && !(value is num) && !(value is bool)) {
        _fillObject(obj, value, mapper);
      } else {
        throw new IncorrectTypeTransform(value, symbolName, key);
      }

      return obj.reflectee;
    }

    return value;
  }

  /// Converts a list of objects to a list with a Class.
  List _convertGenericList(ClassMirror listMirror, List fillerList, DecodingReferenceMapper mapper) {
    _log.finer('Converting generic list');
    ClassMirror itemMirror = listMirror.typeArguments[0];
    InstanceMirror resultList = _initiateClass(listMirror);

    fillerList.forEach((item) {
      (resultList.reflectee as List)
          .add(_convertValue(itemMirror, item, "@LIST_ITEM", mapper));
    });

    _log.finer("Created generic list: ${resultList.reflectee}");
    return resultList.reflectee;
  }

  /// Converts a generic map.
  Map _convertGenericMap(ClassMirror mapMirror, Map fillerMap, DecodingReferenceMapper mapper) {
    _log.finer('Converting generic map');

    ClassMirror itemMirror = mapMirror.typeArguments[1];
    ClassMirror keyMirror = mapMirror.typeArguments[0];
    InstanceMirror resultMap = _initiateClass(mapMirror);
    Map reflectee = {};

    fillerMap.forEach((key, value) {
      var keyItem = _convertValue(keyMirror, key, "@MAP_KEY", mapper);
      var valueItem = _convertValue(itemMirror, value, "@MAP_VALUE", mapper);
      reflectee[keyItem] = valueItem;

      _log.finer("Added item ${valueItem} to map key: ${keyItem}");
    });

    _log.finer("Map converted completly");
    return reflectee;
  }

  /// Initiates an instance of [classMirror] by using an empty constructor name.
  /// Therefore the class needs to contain a simple constructor. For example:
  /// <code>
  /// class TestClass {
  ///    String name;
  ///
  ///   TestClass(); // or TestClass([this.name])
  ///  }
  /// </code>
  ///  Throws [NoConstructorError] if the class doesn't have a constructor without or
  ///    only with optional arguments.
  InstanceMirror _initiateClass(ClassMirror classMirror) {
    _log.finer("Parsing to class: ${_getName(classMirror.qualifiedName)}");
    Symbol constrMethod = null;

    classMirror.declarations.forEach((sym, decl) {
      if (decl is MethodMirror && decl.isConstructor) {
        _log.finer(
            'Found constructor function: ${_getName(decl.qualifiedName)}');

        if (decl.parameters.length == 0) {
          constrMethod = decl.constructorName;
        } else {
          bool onlyOptional = true;
          decl.parameters
              .forEach((p) => !p.isOptional && (onlyOptional = false));

          if (onlyOptional) {
            constrMethod = decl.constructorName;
          }
        }
      }
    });

    InstanceMirror obj;
    if (classMirror.qualifiedName == _QN_LIST) {
      _log.finer('No constructor for list found, try to run empty one');
      obj = reflect([]);
    } else if (classMirror.qualifiedName == _QN_MAP) {
      _log.finer('No constructor for map found');
      obj = reflect({});
    } else if (constrMethod != null) {
      _log.finer("Found constructor: \"${_getName(constrMethod)}\"");
      obj = classMirror.newInstance(constrMethod, []);

      _log.finer(
          "Created instance of type: ${_getName(obj.type.qualifiedName)}");
    } else {
      _log.finer("No constructor found.");
      throw new NoConstructorError(classMirror);
    }

    return obj;
  }
}
