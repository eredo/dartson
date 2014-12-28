library dartson.static;

export 'src/annotations.dart';
export 'src/static_entity.dart';
import 'src/static_entity.dart';

import 'dart:convert' show JSON;

part 'src/serializer_static.dart';


dynamic parse(String jsonStr, StaticEntity clazz) {
  return map(JSON.decode(jsonStr), clazz);
}

List parseList(String jsonStr, StaticEntity clazz) {
  List fillList = JSON.decode(jsonStr);
  
  if (!(fillList is List)) {
    throw 'Unable to parse none List type as List';
  }
  
  return mapList(fillList, clazz);
}

dynamic map(Map dataObject, StaticEntity clazz) {
  clazz.dartsonEntityDecode(dataObject);
  return clazz;
}

List mapList(List<Map> dataMap, StaticEntity clazz) {
  List returnList = [];
  
  var firstItem = true;
  dataMap.forEach((item) {
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
}

dynamic fill(Map dataObject, StaticEntity object) {
  object.dartsonEntityDecode(dataObject);
  return object;
}
