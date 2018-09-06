library dartson;

import 'dart:convert';

export 'src/annotations.dart';
export 'src/type_transformer.dart';

class Dartson<R> {
  final Map<Type, DartsonEntity> _entities;
  final Codec<Object, R> codec;

  Dartson(this._entities, {this.codec});

  R encode<T>(T data) {
    if (!_entities.containsKey(data.runtimeType)) {
      throw DartsonEntityNotExistsException();
    }

    final entity = _entities[data.runtimeType] as DartsonEntity<T>;
    final preData = entity.encoder(data, this);

    if (codec == null) {
      return preData as R;
    }

    return codec.encode(preData);
  }

  T decode<T>(R data) {
    Map<String, dynamic> prepData;
    if (codec != null) {
      prepData = codec.decode(data);
    } else {
      prepData = data as Map<String, dynamic>;
    }

    if (!_entities.containsKey(T)) {
      throw DartsonEntityNotExistsException();
    }

    final entity = _entities[T] as DartsonEntity<T>;
    return entity.decoder(prepData, this);
  }
}

class DartsonEntity<T> {
  final Map<String, dynamic> Function(T obj, Dartson inst) encoder;
  final T Function(Map<String, dynamic> data, Dartson inst) decoder;

  const DartsonEntity(this.encoder, this.decoder);
}

class DartsonEntityNotExistsException implements Exception {}
