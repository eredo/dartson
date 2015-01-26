library dartson.static;

export 'src/annotations.dart';
export 'src/static_entity.dart';
import 'src/static_entity.dart';
import './type_transformer.dart';

import 'package:logging/logging.dart';
import 'dart:convert' show Codec, JSON;

part 'src/serializer_static.dart';

final Map _transformers = {};

/// Static version of dartson.
class Dartson {
  final Codec _codec;
  final Logger _log;
  final Map<String, TypeTransformer> transformers = {};
  
  Dartson(this._codec, [String identifier = 'dartson']) : _log = new Logger(identifier) {
    _log.fine('Initiate static Dartson class.');
    transformers.addAll(_transformers);
  }
  
  factory Dartson.JSON([String identifier = 'dartson']) => new Dartson(JSON, identifier);
  
  void addTransformer(TypeTransformer transformer, String type) {
    transformers[type] = transformer;
  }
  
  bool hasTransformer(String type) => transformers[type] != null;
  
  Object map(Object data, StaticEntity clazz, [bool isList = false]) {
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
        
        cl.dartsonEntityDecode(item);
        returnList.add(cl);
      });
      
      return returnList;
    } else if (data is List || isList) {
      throw 'Incompatible none list type to list.';
    } else {      
      clazz.dartsonEntityDecode(data);
      return clazz;
    }
  }
  
  Object serialize(Object data, {String type}) {
    var transformer;
    
    if (data is List) {
      return _serializeList(data);
    } else if (data is Map) {
      return _serializeMap(data);
    } else if (data is StaticEntity) {
      return data.dartsonEntityEncode();
    } else if (type != null && (transformer = transformers[type]) != null) {
      return transformer.encode(data);
    } else {
      throw 'Unable to serialize none Dartson.Entity';
    }
  }
  
  dynamic encode(Object clazz) {
    return _codec.encode(serialize(clazz));
  }
  
  dynamic decode(var encoded, Object object, [bool isList = false]) {
    return map(_codec.decode(encoded), object, isList);
  }
  
  List _serializeList(List list) {
    return list.map((i) => serialize(i)).toList();
  }
  

  Map _serializeMap(Map map) {
    Map newMap = new Map<String,Object>();
    map.forEach((key, val) {
      if (val != null) newMap[key] = serialize(val);
    });
  
    return newMap;
  }
   
}
