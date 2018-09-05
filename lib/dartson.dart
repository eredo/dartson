library dartson;

export 'src/annotations.dart';
export 'src/type_transformer.dart';

class Dartson {
  final Map<Type, DartsonEntity> _entities;

  Dartson(this._entities);

  Map<String, dynamic> encode<T>(T data) {
    if (!_entities.containsKey(data.runtimeType)) {
      throw DartsonEntityNotExistsException();
    }

    final entity = _entities[data.runtimeType] as DartsonEntity<T>;
    return entity.encoder(data, this);
  }

  T decode<T>(Map<String, dynamic> data, Type type) {
    if (!_entities.containsKey(type)) {
      throw DartsonEntityNotExistsException();
    }

    final entity = _entities[type] as DartsonEntity<T>;
    return entity.decoder(data, this);
  }
}

class DartsonEntity<T> {
  final Map<String, dynamic> Function(T obj, Dartson inst) encoder;
  final T Function(Map<String, dynamic> data, Dartson inst) decoder;

  const DartsonEntity(this.encoder, this.decoder);
}

class DartsonEntityNotExistsException implements Exception {}
