part of dartson;

/// This exception is thrown if the parser tries to convert
/// a value of a different type.
class IncorrectTypeTransform extends Error {
  final String _field;
  final String _type;
  final String _foundType;

  IncorrectTypeTransform(Object value, String type, [String key = "unknown"])
      : _type = type,
        _field = key,
        _foundType = MirrorSystem.getName(reflect(value).type.qualifiedName);

  String toString() =>
      "IncorrectTypeTransform: Cannot transform field \"${_field}\" incorrect " +
          "type. Requires [${_type}] and found [${_foundType}]";
}

/// This exception is thrown when a Class of [mirr] should be initiated but
/// doesn't have a constructor without or only optional arguments.
class NoConstructorError extends Error {
  final String _clazz;

  NoConstructorError(ClassMirror mirr)
      : _clazz = MirrorSystem.getName(mirr.qualifiedName);

  String toString() =>
      "No constructor found: Class [${_clazz}] doesn't have a constructor " +
          "without arguments.";
}

/// This exception only appears in JavaScript if the [ENTITY_MAP] doesn't contain
/// a description of a Class which dartson tries to parse.
class EntityDescriptionMissing extends Error {
  final String _clazz;

  EntityDescriptionMissing(ClassMirror mirr)
      : _clazz = MirrorSystem.getName(mirr.qualifiedName);

  String toString() =>
      "EntityDescription missing: Entity ${_clazz} is not descriped in ENTITY_MAP.";
}

class NullObjectError extends Error {

  String toString() => "Object must not be null";

}

class UnknownIdentifierError extends Error {
  final String _identifier;

  UnknownIdentifierError(this._identifier);

  String toString() =>
      "Type for identifier '${_identifier}' unknown. Use addIdentifier to register type information.";
}