library dartson.static;

export 'src/annotations.dart';
export 'src/static_entity.dart';
import 'src/static_entity.dart';
import './type_transformer.dart';
import 'src/reference_mapper.dart';
import 'src/shared_exceptions.dart';

import 'package:logging/logging.dart';
import 'dart:convert' show Codec, JSON;
import 'dart:mirrors';

final _SimpleTypeTransformer _st = new _SimpleTypeTransformer();
final Map<Type, TypeTransformer> _transformers = {
  String: _st,
  num: _st,
  int: _st,
  bool: _st,
  Map: _st,
  List: _st
};

class _SimpleTypeTransformer extends TypeTransformer {
  @override
  decode(value) => value;

  @override
  encode(value) => value;
}

class _StaticEntityEncoderImpl extends StaticEntityEncoder {
  final Map<Type, TypeTransformer> transformers;
  final Map<String, Type> types;
  final EncodingReferenceMapper mapper;

  _StaticEntityEncoderImpl(this.transformers, this.types, this.mapper);

  bool hasTransformer(Type type) => transformers[type] != null;
  TypeTransformer getTransformer(Type type) => transformers[type];

  bool isSerialized(Object instance) {
    return mapper != null && mapper.isSerialized(instance);
  }
   Map createSerializablePlaceholder(Object instance) {
     return mapper.createSerializablePlaceholder(instance);
   }
   void registerSerializableMap(Object instance, dynamic serializedObject) {
     if (mapper != null) {
       mapper.registerSerializableMap(instance, serializedObject);
     }
     var key = types.keys.firstWhere((key) => types[key] == instance.runtimeType, orElse: () => null);
     if (key != null) {
       serializedObject.putIfAbsent(TYPE_KEY, () => key);
     }
   }
}

class _StaticEntityDecoderImpl extends StaticEntityDecoder {
  final Map<Type, TypeTransformer> transformers;
  final Map<String, Type> types;
  final DecodingReferenceMapper mapper;

  _StaticEntityDecoderImpl(this.transformers, this.types, this.mapper);


  Object createInstance(Map serializableMap, Object defaultInstance()) {
    var identifier = serializableMap[TYPE_KEY];
    if (identifier == null) {
      return defaultInstance();
    }
    var type = types[identifier];
    if (type == null) {
      throw new UnknownIdentifierError(identifier);
    }
    var c = reflectClass(type);
    return c.newInstance(new Symbol(''), []).reflectee;
  }

  bool hasTransformer(Type type) => transformers[type] != null;
  TypeTransformer getTransformer(Type type) => transformers[type];

  void registerInstanceIfApplicable(Object instance, Map serializableMap) {
    if (mapper != null) {
      mapper.registerInstanceIfApplicable(instance, serializableMap);
    }
  }
  bool isPlaceholder(Object val) {
    return mapper != null && mapper.isPlaceholder(val);
  }
  Object resolveReferenceForPlaceholder(Map placeholder) {
    return mapper.resolveReferenceForPlaceholder(placeholder);
  }
}

/// Static version of dartson.
class Dartson  {
  final Codec _codec;
  final Logger _log;
  final Map<Type, TypeTransformer> transformers = {};
  final Map<String, Type> _types = {};

  Dartson(this._codec, [String identifier = 'dartson'])
      : _log = new Logger(identifier) {
    _log.fine('Initiate static Dartson class.');
    transformers.addAll(_transformers);
  }

  factory Dartson.JSON([String identifier = 'dartson']) =>
      new Dartson(JSON, identifier);

  void addTransformer(TypeTransformer transformer, Type type) {
    transformers[type] = transformer;
  }

  addIdentifier(String identifier, Type type) {
    _types[identifier] = type;
  }

  Object map(Object data, StaticEntity entity, [bool isList = false, bool beReferenceAware = false]) {
    var clazz = entity;
      if (clazz == null) {
        var identifier = data is Map ? data[TYPE_KEY] : null;
        if (identifier == null) {
          throw new NullObjectError();
        }
        var type = _types[identifier];
        if (type == null) {
          throw new UnknownIdentifierError(identifier);
        }
        var c = reflectClass(type);
        clazz = c.newInstance(new Symbol(''), []).reflectee;
      }

    var staticEntityDecoder = new _StaticEntityDecoderImpl(this.transformers, this._types, beReferenceAware ? new DecodingReferenceMapper() : null);
    if (data is List && isList) {
      List returnList = [];

      var firstItem = true;
      data.forEach((item) {
        var cl;

        if (firstItem) {
          firstItem = false;
          cl = clazz;
        } else {
          cl = clazz.newEntity();
        }

        cl.dartsonEntityDecode(item, staticEntityDecoder);
        returnList.add(cl);
      });

      return returnList;
    } else if (data is List || isList) {
      throw 'Incompatible none list type to list.';
    } else {
      clazz.dartsonEntityDecode(data, staticEntityDecoder);
      return clazz;
    }
  }

  Object serialize(Object data, {Type type, EncodingReferenceMapper mapper}) {
    var transformer;

    if (data is List) {
      return _serializeList(data, mapper);
    } else if (data is Map) {
      return _serializeMap(data, mapper);
    } else if (data is StaticEntity) {
      return data.dartsonEntityEncode(new _StaticEntityEncoderImpl(this.transformers, this._types, mapper));
    } else if (type != null && (transformer = transformers[type]) != null) {
      return transformer.encode(data);
    } else {
      throw 'Unable to serialize none Dartson.Entity';
    }
  }

  dynamic encodeReferenceAware(Object clazz) {
    return encode(clazz, beReferenceAware: true);
  }

  dynamic encode(Object clazz, {bool beReferenceAware: false}) {
    return _codec.encode(serialize(clazz, mapper: beReferenceAware ? new EncodingReferenceMapper() : null));
  }

  dynamic decodeReferenceAware(var encoded, Object object, [ bool isList = false]) {
    return decode(encoded, object, isList, true);
  }

  dynamic decode(var encoded, Object object, [bool isList = false, bool beReferenceAware =  false]) {
    return map(_codec.decode(encoded), object, isList, beReferenceAware);
  }

  List _serializeList(List list, [EncodingReferenceMapper mapper]) {
    return list.map((i) => serialize(i, mapper: mapper)).toList();
  }

  Map _serializeMap(Map map, [EncodingReferenceMapper mapper]) {
    Map newMap = new Map<String, Object>();
    map.forEach((key, val) {
      if (val != null) newMap[key] = serialize(val, mapper: mapper);
    });

    return newMap;
  }
}
