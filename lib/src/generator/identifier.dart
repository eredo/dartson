import 'package:analyzer/dart/element/element.dart';

const _encodeMethodIdentifier = r'$encoder';
const _decodeMethodIdentifier = r'$decoder';
const serializerIdentifier = r'$dartson';
const implementationIdentifier = r'_Dartson$impl';
const dartsonPackage = 'package:dartson/dartson.dart';

/// Returns the encode method identifier for a specific entity [ClassElement].
String encodeMethod(ClassElement element) =>
    '_${element.displayName}$_encodeMethodIdentifier';

/// Returns the decode method identifier for a specific entity [ClassElement].
String decodeMethod(ClassElement element) =>
    '_${element.displayName}$_decodeMethodIdentifier';
