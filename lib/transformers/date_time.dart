part of dartson.default_transformers;

/// A simple DateTime transformer which uses the toString() method.
class DateTimeParser<T> extends TypeTransformer {
  T decode(dynamic value) => DateTime.parse(value) as T;
  dynamic encode(T value) => value.toString();
}
