part of dartson.default_transformers;

/**
 * A simple DateTime transformer which uses the toString() method.
 */
class DateTimeParser<T> extends TypeTransformer {
  T decode(dynamic value) {
    return DateTime.parse(value);
  }

  dynamic encode(T value) {
    return value.toString();
  }
}