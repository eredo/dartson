library dartson.shared_exceptions;

class NullObjectError extends Error {

  String toString() => "Object must not be null";
}

class UnknownIdentifierError extends Error {
  final String _identifier;

  UnknownIdentifierError(this._identifier);

  String toString() =>
  "Type for identifier '${_identifier}' unknown. Use addIdentifier to register type information.";
}