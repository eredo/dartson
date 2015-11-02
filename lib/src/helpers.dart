part of dartson;

/// Looks for a [Property] annotation in the metadata of [variable].
Property _getProperty(DeclarationMirror variable) {
  Property prop;

  variable.metadata.forEach((meta) {
    if (meta.reflectee is Property) {
      prop = meta.reflectee;
    }
  });

  return prop;
}

bool _isSimpleType(Type type) {
  return type == List ||
      type == bool ||
      type == String ||
      type == num ||
      type == int ||
      type == double ||
      type == Map ||
      type == dynamic;
}

bool _hasOnlySimpleTypeArguments(ClassMirror mirr) {
  bool hasOnly = true;

  mirr.typeArguments.forEach((ta) {
    if (ta is ClassMirror) {
      if (!_isSimpleType(ta.reflectedType)) {
        hasOnly = false;
      }
    }
  });

  return hasOnly;
}
