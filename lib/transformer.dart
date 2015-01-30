library dartson.transformer;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors' as mirrors;

import './dartson.dart';
import './src/static_entity.dart';
import 'package:barback/barback.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_maps/span.dart' show SourceFile;

const SIMPLE_TYPES = const ['String', 'num', 'bool', 'int', 'List', 'Map'];

// in order to make the code more maintainable we reflect the Entity class to get the simpleName
final _DARTSON_ENTITY_NAME =
    mirrors.MirrorSystem.getName(mirrors.reflectClass(Entity).simpleName);
final _DARTSON_PROPERTY_NAME =
    mirrors.MirrorSystem.getName(mirrors.reflectClass(Property).simpleName);
final _DARTSON_STATIC_ENTITY =
    mirrors.MirrorSystem.getName(mirrors.reflectClass(StaticEntity).simpleName);

// method names of the [StaticEntity] interface
const _DARTSON_ENCODE_METHOD = 'dartsonEntityEncode';
const _DARTSON_DECODE_METHOD = 'dartsonEntityDecode';
const _DARTSON_METHODS = const ['parse', 'parseList', 'map', 'mapList'];

class DartsonTransformer extends Transformer {
  DartsonTransformer();

  DartsonTransformer.asPlugin(BarbackSettings settings) : this();

  Future<bool> isPrimary(AssetId inputId) {
    if (inputId.extension != '.dart') {
      return new Future.value(false);
    }

    // TODO: Create a real check to increase performance
    return new Future.value(true);
  }

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    var url = id.path.startsWith('lib/')
        ? 'package:${id.package}/${id.path.substring(4)}'
        : id.path;

    return transform.primaryInput.readAsString().then((String content) {
      var compiler = new FileCompiler.fromString(id, content);
      var code = compiler.build(url);

      if (compiler.hasEdits) {
        transform.addOutput(new Asset.fromString(id, code));
      } else {
        transform.addOutput(transform.primaryInput);
      }
    });
  }
}

class FileCompiler extends _ErrorCollector {
  final CharSequenceReader reader;
  final Editor editor;
  Parser parser;
  Scanner scanner;
  CompilationUnit compilationUnit;

  SimpleIdentifier _dartsonPrefix;
  bool _hasEdits = false;
  bool get hasEdits => _hasEdits;

  final List<ClassDeclaration> entities = <ClassDeclaration>[];

  static final _simpleTransformer = new _SimpleTransformWriter();
  static final _entityTransformer = new _EntityTransformWriter();
  static final _mapTransformer = new _MapTransformWriter();
  static final _listTransformer = new _ListTransformWriter();

  String get _staticEntityInterface =>
      (_dartsonPrefix != null ? _dartsonPrefix.toString() + '.' : '') +
          _DARTSON_STATIC_ENTITY;

  FileCompiler(String path) : this.fromString(path, new File(path).readAsStringSync());

  FileCompiler.fromString(String path, String code) :
    editor = new Editor(path, code),
    reader = new CharSequenceReader(code) {
    scanner = new Scanner(null, reader, this);
    parser = new Parser(null, this);

    compilationUnit = parser.parseCompilationUnit(scanner.tokenize());

    _dartsonPrefix = findDartsonImportName();
    _findDartsonEntities();
  }

  String build(String url) {
    _prepareEntities();
    _rewriteImports();
//    _rewriteCalls();
    _rewriteClassDeclarations();

    var builder = editor.editor.commit();
    builder.build(url);
    return builder.text;
  }

  /// Checks all class declarations for the [Entity] annotation. Each
  /// declaration will be added to the [_entities] list.
  void _findDartsonEntities() {
    entities.addAll(compilationUnit.declarations.where(
        (m) => m is ClassDeclaration &&
            m.metadata
                .any((n) => _isDartsonAnnotation(n, _DARTSON_ENTITY_NAME))));

    if (entities.length > 0) {
      _hasEdits = true;
    }
  }

  /// Runs through all entities, builds the methods and injects them.
  void _prepareEntities() {
    entities.forEach((entity) {
      var entityMap = buildEntityMap(entity);
      var encodeMethod = buildEncodingMethod(entityMap);
      var decodeMethod = buildDecodingMethod(entityMap);
      var newEntityMethod = _buildNewEntityMethod(entity);

      editor.editor.edit(entity.endToken.end - 1, entity.endToken.end - 1,
          '${encodeMethod}\n${decodeMethod}\n${newEntityMethod}\n');
    });
  }

  /// Each class declaration needs to implement the StaticEntity interface.
  void _rewriteClassDeclarations() {
    entities.forEach((entity) {
      if (entity.implementsClause != null) {
        editor.editor.edit(entity.implementsClause.endToken.end,
            entity.implementsClause.endToken.end,
            ', ${_staticEntityInterface} ');
      } else if (entity.extendsClause != null) {
        editor.editor.edit(entity.extendsClause.endToken.end,
            entity.extendsClause.endToken.end,
            ' implements ${_staticEntityInterface}');
      } else {
        editor.editor.edit(entity.name.endToken.end, entity.name.endToken.end,
            ' implements ${_staticEntityInterface}');
      }
    });
  }

  /// Rewrites the import to dartson_static.dart
  void _rewriteImports() {
    ImportDirective dir = compilationUnit.directives.firstWhere(
        (directive) => directive is ImportDirective &&
            directive.uri.stringValue == 'package:dartson/dartson.dart',
        orElse: () => null);

    if (dir != null) {
      editor.editor.edit(dir.uri.beginToken.offset, dir.uri.endToken.end,
          '\'package:dartson/dartson_static.dart\'');
      _hasEdits = true;
    }
  }

  /// Rewrites calls of dartson methods like parse and fill.
  void _rewriteCalls() {
    var visitor = new DartsonMethodVisitor(
        _dartsonPrefix != null ? _dartsonPrefix.toString() : null);
    compilationUnit.accept(visitor);

    visitor.methodInvocations.forEach((inv) {
      var arg = inv.argumentList.arguments[1];
      editor.editor.edit(
          arg.beginToken.offset, arg.endToken.end, '"${arg.toString()}"');
    });
  }

  /// Checks if the [annotation] matches a dartson annotation with [className]
  bool _isDartsonAnnotation(Annotation annotation, String className) =>
      (_dartsonPrefix != null
          ? (annotation.name is PrefixedIdentifier &&
              (annotation.name as PrefixedIdentifier).prefix.toString() ==
                  _dartsonPrefix.toString() &&
              (annotation.name as PrefixedIdentifier).identifier.name ==
                  className)
          : (annotation.name.name == className));

  /// Checks if dartson is imported using a prefix in order to find the annotations correctly.
  SimpleIdentifier findDartsonImportName() {
    if (compilationUnit.directives == null) return null;

    var directive = compilationUnit.directives.firstWhere(
        (directive) => directive is ImportDirective &&
            directive.uri.stringValue == 'package:dartson/dartson.dart',
        orElse: () => null);

    return directive != null ? directive.prefix : null;
  }

  /// Creates a map of properties of the class declaration which will be exported.
  List<PropertyDefinition> buildEntityMap(ClassDeclaration entity) {
    List<PropertyDefinition> list = [];

    entity.members.forEach((ClassMember member) {
      if (member is FieldDeclaration) {
        Property dartEnt = _findDartsonProperty(member.metadata);

        // parse the type and the assigned arguments for generic types
        var type = member.fields.type.name.name;
        var typeArguments = [];

        if (member.fields.type.typeArguments != null) {
          member.fields.type.typeArguments.arguments
              .forEach((arg) => typeArguments.add(arg.name.name));
        }

        // run through all delegated variables
        member.fields.variables.forEach((VariableDeclaration d) {

          // const and final properties are excluded
          if (d.isFinal || d.isConst) return;
          // skip ignored properties
          if (dartEnt != null && dartEnt.ignore) return;

          var serializedName = d.name.name;
          // fetch the correct name of the entity
          if (dartEnt != null &&
              dartEnt.name != null &&
              dartEnt.name.isNotEmpty) {
            serializedName = dartEnt.name;
          }

          list.add(new PropertyDefinition(
              type, typeArguments, serializedName, d.name.name));
        });
      }
    });

    return list;
  }

  /// Looksup all annotations for the [Property] annotation and then creates an instance with
  /// the same properties.
  Property _findDartsonProperty(NodeList<Annotation> meta) {
    Annotation annotation = meta.firstWhere(
        (m) => _isDartsonAnnotation(m, _DARTSON_PROPERTY_NAME),
        orElse: () => null);

    if (annotation != null) {
      var argsMap = {};
      annotation.arguments.arguments.forEach((arg) {
        if (arg is NamedExpression) {
          argsMap[arg.name.label.name] = arg.expression.value;
        }
      });

      return new Property(
          ignore: argsMap['ignore'] == true, name: argsMap['name']);
    } else {
      return null;
    }
  }

  /// Builds the encoding method for the [Entity] annotated class.
  String buildEncodingMethod(List<PropertyDefinition> definitions) {
    var ttp = 'TypeTransformerProvider';
    if (_dartsonPrefix != null) {
      ttp = '${_dartsonPrefix}.${ttp}';
    }

    List<String> resp = ['Map ${_DARTSON_ENCODE_METHOD}(${ttp} dson) {'];
    resp.add('var obj = {};');

    resp.addAll(definitions.map((def) {
      if (def.isSimpleType) {
        return _simpleTransformer.encode('this', 'obj', def);
      } else if (def.isMap) {
        return _mapTransformer.encode('this', 'obj', def);
      } else if (def.isList) {
        return _listTransformer.encode('this', 'obj', def);
      } else {
        return _entityTransformer.encode('this', 'obj', def);
      }
    }));

    resp.add('return obj;');
    resp.add('}');

    return resp.join('\n');
  }

  /// Builds the decoding method for the [Entity] annotated class.
  String buildDecodingMethod(List<PropertyDefinition> definitions) {
    var ttp = 'TypeTransformerProvider';
    if (_dartsonPrefix != null) {
      ttp = '${_dartsonPrefix}.${ttp}';
    }

    List<String> resp = [
      "void ${_DARTSON_DECODE_METHOD}(Map obj, ${ttp} dson) {"
    ];
    resp.addAll(definitions.map((def) {
      if (def.isSimpleType) {
        return _simpleTransformer.decode('this', 'obj', def);
      } else if (def.isMap) {
        return _mapTransformer.decode('this', 'obj', def);
      } else if (def.isList) {
        return _listTransformer.decode('this', 'obj', def);
      } else {
        return _entityTransformer.decode('this', 'obj', def);
      }
    }));
    resp.add("}");

    return resp.join('\n');
  }

  String _buildNewEntityMethod(ClassDeclaration entity) =>
      '${entity.name.toString()} newEntity() => new ${entity.name.toString()}();';
}

/// The visitor checks for dartson calls like fill, parse and then replaces the Type
/// argument with an initiated object of "Type".
class DartsonMethodVisitor<R> extends AstVisitor<R> {
  final String prefix;
  final List<MethodInvocation> methodInvocations = [];

  /// [prefix] is the identifier of the dartson package. If empty set it to null.
  DartsonMethodVisitor(this.prefix);

  /// Visits all method invocations and checks if it's a dartson call.
  @override
  R visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.toString() == 'addTransformer') {
      methodInvocations.add(node);
    }

    return null;
  }

  /// Simple method to loop through all children elements until a MethodInvocation is hit.
  /// TODO: Check for performance issues because this method is called by noSuchMethod handler.
  R _visitChild(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) {
    Function.apply(_visitChild, invocation.positionalArguments);
    return null;
  }
}

class Editor {
  SourceFile sourceFile;
  TextEditTransaction editor;

  Editor(String path, String code) {
    sourceFile = new SourceFile.text(path, code);
    editor = new TextEditTransaction(code, sourceFile);
  }
}

class _ErrorCollector extends AnalysisErrorListener {
  final errors = <AnalysisError>[];
  onError(err) => errors.add(err);
}

/// A wrapper for the serializable properties.
class PropertyDefinition {
  /// FieldDeclaration / MethodDeclaration within the dart code.
  //final Declaration declaration;

  /// Type declaration as a string.
  final String type;

  /// Type arguments are the generic informations like: "List<ARGUMENTS>"
  final List<String> typeArguments;

  /// Property of the serialized map.
  final String serializedName;

  /// Property name of the dart object.
  final String name;

  PropertyDefinition(
      this.type, this.typeArguments, this.serializedName, this.name);

  bool get isSimpleType => SIMPLE_TYPES.contains(type) &&
      (typeArguments == null || typeArguments.isEmpty);
  bool get isGenericType => typeArguments != null && !typeArguments.isEmpty;
  bool get isList => type == 'List';
  bool get isMap => type == 'Map';
}

/// An internal transformer that generates the code snippet for static encoding
/// and decoding of a specific type.
abstract class _TypeTransformWriter {

  /// Generates the code snippet to add the values / [key]s of an object member
  /// [property] to the [target] json map.
  String encode(String target, String object, [PropertyDefinition definition]);

  /// Generates the code snippet to add the values of a json map to the object.
  String decode(String target, String object, [PropertyDefinition definition]);
}

/// A simple transform writer which just puts the value into the property and the
/// other way around.
class _SimpleTransformWriter extends _TypeTransformWriter {
  @override
  String decode(String target, String object,
      [PropertyDefinition definition]) => definition != null
          ? '${target}.${definition.name} = ${object}["${definition.serializedName}"];'
          : '${target} = ${object};';

  @override
  String encode(String target, String object,
      [PropertyDefinition definition]) => definition != null
          ? '${object}["${definition.serializedName}"] = ${target}.${definition.name};'
          : '${object} = ${target};';
}

/// A transform writer that initiates an entity by it's constructor and than
/// calls the fromJson or toJson method.
class _EntityTransformWriter extends _TypeTransformWriter {
  @override
  String decode(String target, String object, [PropertyDefinition definition]) => definition ==
          null
      ? throw 'Unable to decode Entity without a definition.'
      : definition.name != null
          ? 'if (${object}["${definition.serializedName}"] != null) {\n' +
              '  if (dson.hasTransformer(${definition.type})) {' +
              '    ${target}.${definition.name} = dson.getTransformer(${definition.type}).decode(${object}["${definition.serializedName}"]);\n' +
              '  } else {\n' +
              '    ${target}.${definition.name} = new ${definition.type}();\n' +
              '    (${target}.${definition.name} as StaticEntity).${_DARTSON_DECODE_METHOD}(${object}["${definition.serializedName}"], dson);\n'
              '  }\n' + '}'
          : 'if (${object} != null) {\n' +
              '  if (dson.hasTransformer(${definition.type})) {' +
              '    ${target} = dson.getTransformer(${definition.type}).decode(${object});\n' +
              '  } else {\n' +
              '    ${target} = new ${definition.type}();\n' +
              '    (${target} as StaticEntity).${_DARTSON_DECODE_METHOD}(${object}, dson);\n' +
              '  }\n' +
              '}';

  @override
  String encode(String target, String object, [PropertyDefinition definition]) => definition ==
          null
      ? throw 'Unable to encode Entity without a definition.'
      : definition.name != null
          ? 'if (${target}.${definition.name} != null) {\n' +
              '  if (dson.hasTransformer(${definition.type})) {' +
              '    ${object}["${definition.serializedName}"] = dson.getTransformer(${definition.type}).encode(${target}.${definition.name});\n' +
              '  } else {\n' +
              '    ${object}["${definition.serializedName}"] = (${target}.${definition.name} as StaticEntity).${_DARTSON_ENCODE_METHOD}(dson);\n' +
              '  }\n' +
              '}'
          : 'if (${target} != null) {\n' +
              '  if (dson.hasTransformer(${definition.type})) {' +
              '    ${object} = dson.getTransformer(${definition.type}).encode(${target});\n' +
              '  } else {\n' +
              '    ${object} = (${target} as StaticEntity).${_DARTSON_ENCODE_METHOD}(dson);\n' +
              '  }\n' +
              '}';
}

/// A transform writer which initiates a map if the value exists and then
/// adds the values.
class _MapTransformWriter extends _TypeTransformWriter {
  static final _simpleTransformer = new _SimpleTransformWriter();
  static final _entityTransformer = new _EntityTransformWriter();

  @override
  String decode(String target, String object, [PropertyDefinition definition]) {
    var resp = [
      'if (${object}["${definition.serializedName}"] != null) {',
      '  ${target}.${definition.name} = new Map();',
      '  ${object}["${definition.serializedName}"].forEach((key, val) {',
      '    var keyVal = key;'
    ];

    // parse the key if necessary
    if (definition.typeArguments[0] == 'int') {
      resp.add('keyVal = int.parse(key);');
    } else if (definition.typeArguments[0] == 'num') {
      resp.add('keyVal = num.parse(key);');
    }

    if (SIMPLE_TYPES.contains(definition.typeArguments[1])) {
      resp.add(_simpleTransformer.decode(
          '${target}.${definition.name}[keyVal]', 'val'));
    } else {
      resp.add(_entityTransformer.decode('${target}.${definition.name}[keyVal]',
          'val', new PropertyDefinition(
              definition.typeArguments[1], null, null, null)));
    }

    resp.add('  });');
    resp.add('}');

    return resp.join('\n');
  }

  @override
  String encode(String target, String object, [PropertyDefinition definition]) {
    if (definition ==
        null) throw 'Unable to decode Map without arguments. Use SimpleTransformWriter instead.';

    var resp = [
      'if (${target}.${definition.name} != null) {',
      '  ${object}["${definition.serializedName}"] = {};',
      '  ${target}.${definition.name}.forEach((key, val) {'
    ];

    if (SIMPLE_TYPES.contains(definition.typeArguments[1])) {
      resp.add(_simpleTransformer.encode(
          'val', '${object}["${definition.serializedName}"][key]'));

      // TODO: Add nested generics support
    } else {
      resp.add(_entityTransformer.encode('val',
          '${object}["${definition.serializedName}"][key]',
          new PropertyDefinition(
              definition.typeArguments[1], null, null, null)));
    }

    resp.add('  });');
    resp.add('}');
    return resp.join('\n');
  }
}

class _ListTransformWriter extends _TypeTransformWriter {
  static final _simpleTransformer = new _SimpleTransformWriter();
  static final _entityTransformer = new _EntityTransformWriter();

  @override
  String decode(String target, String object, [PropertyDefinition definition]) {
    if (definition ==
        null) throw 'Unable to decode List without arguments. Use SimpleTransformWriter instead.';

    var resp = [
      'if (${object}["${definition.serializedName}"] != null) {',
      '  ${target}.${definition.name} = new List();',
      '  ${object}["${definition.serializedName}"].forEach((val) {',
      '    var el;'
    ];

    if (SIMPLE_TYPES.contains(definition.typeArguments[0])) {
      resp.add(_simpleTransformer.decode('el', 'val'));
    } else {
      resp.add(_entityTransformer.decode('el', 'val', new PropertyDefinition(
          definition.typeArguments[0], null, null, null)));
    }
    resp.add('    ${target}.${definition.name}.add(el);');
    resp.add('  });');
    resp.add('}');
    return resp.join('\n');
  }

  @override
  String encode(String target, String object, [PropertyDefinition definition]) {
    if (definition ==
        null) throw 'Unable to encode List without arguments. Use SimpleTransformWriter instead.';

    var resp = [
      'if (${target}.${definition.name} != null) {',
      '  ${object}["${definition.serializedName}"] = new List();',
      '  ${target}.${definition.name}.forEach((val) {',
      '  var el;'
    ];

    if (SIMPLE_TYPES.contains(definition.typeArguments[0])) {
      resp.add(_simpleTransformer.encode('val', 'el'));

      // TODO: Add nested generics support
    } else {
      resp.add(_entityTransformer.encode('val', 'el', new PropertyDefinition(
          definition.typeArguments[0], null, null, null)));
    }
    resp.add('  ${object}["${definition.serializedName}"].add(el);');
    resp.add('  });');
    resp.add('}');
    return resp.join('\n');
  }
}
