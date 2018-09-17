library dartson.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/generator.dart';

/// Provides a [SharedPartBuilder] for the dartson generator. See README.md for
/// usage.
Builder dartsonBuilder(_) =>
    SharedPartBuilder([SerializerGenerator()], 'dartson');
