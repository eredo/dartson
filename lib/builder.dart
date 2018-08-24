library dartson.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder dartsonBuilder(_) =>
    SharedPartBuilder([SerializerGenerator()], 'dartson');
