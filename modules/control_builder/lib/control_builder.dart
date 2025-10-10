import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/parser_generator.dart';

Builder parserBuilder(BuilderOptions options) => PartBuilder([ParserGenerator()], '.g.dart');
