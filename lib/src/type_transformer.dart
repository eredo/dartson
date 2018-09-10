/// The interface for creating new transformers. For a basic example on how to
/// use this interface take a look at [DateTimeParser].
abstract class TypeTransformer<S, T> {
  /// Receives the [value] of type [T] and returns a serializable result which
  /// will be passed into the JSON representation.
  S encode(T value);

  /// Takes a serialized [value] from the JSON object and transforms it into the
  /// correct type.
  T decode(S value);
}
