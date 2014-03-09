part of dartson;

abstract class TypeTransformer<T> {
  dynamic encode(T value);
  T decode(dynamic value);
}
