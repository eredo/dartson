part of dartson.default_transformers;

class DateTimeParser<T> extends TypeTransformer {
  T decode(dynamic value) {
    return DateTime.parse(value);
  }

  dynamic encode(T value) {
    return value.toString();
  }
}